---@module 'tasks.scan'
---@brief Collect task files for one area or the whole vault.
---@description
--- Walks `<area>/ROADMAP/tasks/` (open tasks) and `<area>/Backlog/` (finished
--- ones) with `lib.nvim.fs.collect_recursive`, optionally through the TTL cache
--- `lib.nvim.fs.scan_cached` for callers that filter repeatedly (a dashboard).
---
--- Key responsibilities:
---  - one `Tasks.Task` per `*.md` file, in path order; a file that cannot be
---    read or parsed comes back as an invalid task, it never aborts the scan
---  - nested files under `tasks/` are returned too (flagged), so `check` can
---    report them instead of them silently not existing
---  - `Backlog/` files count as tasks only when they carry frontmatter with a
---    `status`: the old free-form documents there are not tasks
---
--- Not its job: ranking or filtering (`model`), rendering (`index`).

local collect = require("lib.nvim.fs.collect_recursive")
local scan_cached = require("lib.nvim.fs.scan_cached")

local fsio = require("tasks.fsio")
local model = require("tasks.model")
local vault = require("tasks.vault")

local M = {}

---@class Tasks.ScanOpts
---@field root? string                 # Vault root (default: `vault.root()`).
---@field ttl_seconds? integer         # Use the in-memory TTL cache for the directory walk.
---@field refresh? boolean             # With `ttl_seconds`: force a fresh walk.

---Markdown files below `dir`, sorted. A missing directory is an empty result,
---not an error: an area without tasks has no `tasks/` folder.
---@param dir string
---@param opts Tasks.ScanOpts
---@return string[] paths
---@return string[] errors
local function markdown_files(dir, opts)
  if not fsio.is_dir(dir) then
    return {}, {}
  end
  local paths, errors
  if opts.ttl_seconds then
    paths, errors = scan_cached.scan(dir, {
      kind = "files",
      ttl_seconds = opts.ttl_seconds,
      refresh = opts.refresh,
    })
  else
    paths, errors = collect.files(dir)
  end
  local out = {}
  for _, p in ipairs(paths) do
    if p:match("%.md$") then
      out[#out + 1] = fsio.norm(p)
    end
  end
  table.sort(out)
  return out, errors or {}
end

---@param opts? Tasks.ScanOpts
---@return string|nil root
---@return string|nil err
local function resolve_root(opts)
  return vault.root(opts)
end

---The task files of one area's `ROADMAP/tasks/` (any status), in path order.
---@param area string
---@param opts? Tasks.ScanOpts
---@return Tasks.Task[]|nil tasks
---@return string[]|string errors  walk errors, or the failure message when `tasks` is nil
function M.area(area, opts)
  opts = opts or {}
  local root, err = resolve_root(opts)
  if not root then
    return nil, err
  end
  if not vault.valid_area(area) then
    return nil, "invalid area name: " .. tostring(area)
  end
  local dir = vault.tasks_dir(root, area)
  local files, errors = markdown_files(dir, opts)
  local tasks = {}
  for _, path in ipairs(files) do
    local rel = path:sub(#dir + 2)
    tasks[#tasks + 1] = model.from_file(path, {
      area = area,
      location = "roadmap",
      nested = rel:find("/", 1, true) ~= nil,
    })
  end
  return tasks, errors
end

---Every area's `ROADMAP/tasks/`, areas in name order.
---@param opts? Tasks.ScanOpts
---@return Tasks.Task[]|nil tasks
---@return string[]|string errors
function M.all(opts)
  opts = opts or {}
  local root, err = resolve_root(opts)
  if not root then
    return nil, err
  end
  local all, all_errors = {}, {}
  for _, area in ipairs(vault.areas(root)) do
    local tasks, errors = M.area(area.name, vim.tbl_extend("force", opts, { root = root }))
    for _, t in ipairs(tasks or {}) do
      all[#all + 1] = t
    end
    for _, e in ipairs(type(errors) == "table" and errors or { errors }) do
      all_errors[#all_errors + 1] = e
    end
  end
  return all, all_errors
end

---Backlog files of one area that are task files (frontmatter with `status`).
---@param area string
---@param opts? Tasks.ScanOpts
---@return Tasks.Task[]|nil tasks
---@return string[]|string errors
function M.backlog(area, opts)
  opts = opts or {}
  local root, err = resolve_root(opts)
  if not root then
    return nil, err
  end
  if not vault.valid_area(area) then
    return nil, "invalid area name: " .. tostring(area)
  end
  local tasks, all_errors = {}, {}
  for _, bucket in ipairs({ "FEATURES", "TASKS" }) do
    local files, errors = markdown_files(vault.backlog_dir(root, area, bucket), opts)
    for _, e in ipairs(errors) do
      all_errors[#all_errors + 1] = e
    end
    for _, path in ipairs(files) do
      local text = fsio.read(path)
      -- Cheap pre-test: most old Backlog documents have no frontmatter at all.
      if text and text:match("^\239?\187?\191?%-%-%-") then
        local task = model.parse_text(text, { path = path, area = area, location = "backlog" })
        if task.meta.status ~= nil then
          tasks[#tasks + 1] = task
        end
      end
    end
  end
  return tasks, all_errors
end

---Every slug already used by a file below `<area>/Backlog/` (date prefix
---stripped), whether or not that file is a task. A new task must not reuse one:
---ids are global and `done` would otherwise produce two files with one id.
---@param area string
---@param opts? Tasks.ScanOpts
---@return table<string, string>|nil slugs  slug -> path
---@return string|nil err
function M.backlog_slugs(area, opts)
  opts = opts or {}
  local root, err = resolve_root(opts)
  if not root then
    return nil, err
  end
  if not vault.valid_area(area) then
    return nil, "invalid area name: " .. tostring(area)
  end
  local slugs = {}
  for _, bucket in ipairs({ "FEATURES", "TASKS" }) do
    for _, path in ipairs((markdown_files(vault.backlog_dir(root, area, bucket), opts))) do
      slugs[model.slug_of(path, "backlog")] = path
    end
  end
  return slugs, nil
end

---The open task `<area>/<slug>`.
---@param id string
---@param opts? Tasks.ScanOpts
---@return Tasks.Task|nil task
---@return string|nil err
function M.find(id, opts)
  local root, err = resolve_root(opts)
  if not root then
    return nil, err
  end
  local area, slug, id_err = vault.parse_id(id)
  if not area or not slug then
    return nil, id_err or ("expected <area>/<slug>, got " .. tostring(id))
  end
  local path = vault.task_path(root, area, slug)
  if not fsio.is_file(path) then
    return nil, "no such open task: " .. id
  end
  return model.from_file(path, { area = area, location = "roadmap", slug = slug }), nil
end

---The finished task `<area>/<slug>` from `Backlog/`, whatever its date prefix.
---@param id string
---@param opts? Tasks.ScanOpts
---@return Tasks.Task|nil task
function M.find_done(id, opts)
  local root = resolve_root(opts)
  if not root then
    return nil
  end
  local area, slug = vault.parse_id(id)
  if not area or not slug then
    return nil
  end
  for _, bucket in ipairs({ "FEATURES", "TASKS" }) do
    local files = markdown_files(vault.backlog_dir(root, area, bucket), opts or {})
    for _, path in ipairs(files) do
      if model.slug_of(path, "backlog") == slug then
        return model.from_file(path, { area = area, location = "backlog" })
      end
    end
  end
  return nil
end

return M
