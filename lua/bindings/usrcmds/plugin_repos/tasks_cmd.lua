---@module 'bindings.usrcmds.plugin_repos.tasks_cmd'
---@brief The handlers behind `:MyPlugins tasks | task | open` -- prompts, notifications and windows around the task engine.
---@description
--- Every function takes the composer's `ctx` (`ctx.args`, `ctx.flags`,
--- `ctx.kv`, `ctx.rest`, `ctx.raw.fargs`) and does one command. The engine
--- (`tasks.*`) holds all the rules and returns data or `nil, err`; this module
--- adds what an editor needs: the `--to=` delivery, a form for a missing
--- title, a confirmation before a task is finished, opening files and
--- re-pointing buffers, and a picker over the files of one area folder.
---
--- Key responsibilities:
---  - `list` (`tasks`), `index`, `task_new`, `task_set`, `task_done`,
---    `task_template`, `task_open`, `open_area` (`open`)
---  - `parse_assignments`: `key=value` tokens whose values may contain spaces
---  - `M.dashboard`: the single seam the dashboard step fills in
---
--- Not its job: the route table and the argument types (`tasks_routes`), the
--- rendering (`tasks_view`), any rule about tasks (the engine).

local harvest = require("lib.nvim.harvest")
local notify = require("lib.nvim.notify").create("[usrcmds.plugin_repos.tasks]")

local check = require("tasks.check")
local fsio = require("tasks.fsio")
local index = require("tasks.index")
local model = require("tasks.model")
local mutate = require("tasks.mutate")
local scan = require("tasks.scan")
local vault = require("tasks.vault")

local confirm = require("bindings.usrcmds.plugin_repos.confirm")
local view = require("bindings.usrcmds.plugin_repos.tasks_view")

local M = {}

local is_windows = vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1

---Dashboard seam. The dashboard step assigns a function here; `:MyPlugins
---tasks` calls it instead of opening the scratch buffer when neither `--to=`
---nor `--format=` was given. It receives the filtered, sorted open tasks.
---@type (fun(view: Plugin_repos.TasksView): any)|nil
M.dashboard = nil

---@class Plugin_repos.TasksView
---@field tasks Tasks.Task[]     # Open tasks that passed the filter, sorted.
---@field area string|nil        # nil: every area.
---@field filter Tasks.Filter
---@field root string            # Vault root.

---Longest detail list put into a notification; longer ones open a buffer.
local MAX_NOTIFY_LINES = 10

---The subfolders of an area `:MyPlugins open` can show, relative to the area.
---@type table<string, string>
M.FOLDERS = {
  tasks = "ROADMAP/tasks",
  roadmap = "ROADMAP",
  backlog = "Backlog",
  handover = "handovers",
  notes = "NOTES",
  all = "",
}

-- ── helpers ──────────────────────────────────────────────────────────────────

---@param a string
---@param b string
---@return boolean
local function same_path(a, b)
  a, b = fsio.norm(a), fsio.norm(b)
  if is_windows then
    return a:lower() == b:lower()
  end
  return a == b
end

---@param path string
---@param root string
---@return string
local function rel(path, root)
  local p = fsio.norm(path)
  if p:sub(1, #root + 1) == root .. "/" then
    return p:sub(#root + 2)
  end
  return p
end

---Notify a summary; the detail lines go along when few, into a scratch buffer
---when many.
---@param level "info"|"warn"|"error"
---@param summary string
---@param details? string[]
---@param title? string
local function report(level, summary, details, title)
  details = details or {}
  if #details == 0 then
    notify[level](summary)
  elseif #details <= MAX_NOTIFY_LINES then
    notify[level](summary .. "\n" .. table.concat(details, "\n"))
  else
    harvest.sink.scratch(table.concat(details, "\n") .. "\n", {
      title = title,
      filetype = "text",
      split = "split",
    })
    notify[level](summary)
  end
end

---@return string|nil root
local function vault_root()
  local root, err = vault.root()
  if not root then
    notify.error(tostring(err))
    return nil
  end
  return root
end

---Strip one pair of surrounding double quotes: the command line does not
---interpret them, so `"Fix the thing"` arrives as three tokens with quotes on
---the outer two.
---@param s string
---@return string
local function unquote(s)
  s = vim.trim(s)
  local inner = s:match('^"(.*)"$')
  return inner and vim.trim(inner) or s
end

---Reload unchanged buffers of `path` after the file changed on disk.
---@param path string
local function refresh_buffers(path)
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if
      vim.api.nvim_buf_is_loaded(buf)
      and not vim.bo[buf].modified
      and same_path(vim.api.nvim_buf_get_name(buf), path)
    then
      pcall(vim.cmd, "checktime " .. buf)
    end
  end
end

---Move windows showing `from` to `to` after a task file was moved, and drop
---the old buffer, so no buffer is left on a dead path (what `:File move` of
---fileops.nvim does for its own moves). A modified buffer is left alone.
---@param from string
---@param to string
function M.retarget_buffers(from, to)
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and same_path(vim.api.nvim_buf_get_name(buf), from) then
      if vim.bo[buf].modified then
        notify.warn("buffer for the finished task has unsaved changes and still points at " .. from)
      else
        for _, win in ipairs(vim.fn.win_findbuf(buf)) do
          vim.api.nvim_win_call(win, function()
            vim.cmd("silent keepalt edit " .. vim.fn.fnameescape(to))
          end)
        end
        pcall(vim.api.nvim_buf_delete, buf, {})
      end
    end
  end
end

---@param path string
local function open_file(path)
  vim.cmd("edit " .. vim.fn.fnameescape(path))
end

---Describe the active filter for the table heading.
---@param flags table
---@return string|nil
local function filter_note(flags)
  local parts = {}
  for _, name in ipairs({ "status", "prio", "kind", "tag" }) do
    if flags[name] ~= nil then
      parts[#parts + 1] = ("%s=%s"):format(name, flags[name])
    end
  end
  if flags.stale ~= nil then
    parts[#parts + 1] = "stale>=" .. tostring(flags.stale) .. "d"
  end
  if flags.blocked then
    parts[#parts + 1] = "blocked"
  end
  if #parts == 0 then
    return nil
  end
  return "Filter: " .. table.concat(parts, ", ")
end

-- ── tasks ────────────────────────────────────────────────────────────────────

---`:MyPlugins tasks [<area>|all] [filters] [--to=] [--format=]`
---@param ctx table  composer context
function M.list(ctx)
  local flags = ctx.flags
  local target, terr = view.parse_target(flags.to)
  if terr then
    notify.error(terr)
    return
  end
  local filter, ferr = model.filter_from_options({
    status = flags.status,
    prio = flags.prio,
    kind = flags.kind,
    tag = flags.tag,
    stale = flags.stale,
    blocked = flags.blocked,
  })
  if not filter then
    notify.error(tostring(ferr))
    return
  end
  local root = vault_root()
  if not root then
    return
  end

  local area = ctx.args.area
  if area == "all" then
    area = nil
  end
  local tasks, errors
  if area then
    tasks, errors = scan.area(area, { root = root })
  else
    tasks, errors = scan.all({ root = root })
  end
  if not tasks then
    notify.error(tostring(errors))
    return
  end
  if type(errors) == "table" and #errors > 0 then
    notify.warn("cannot read directory " .. table.concat(errors, ", "))
  end

  local open, skipped = {}, 0
  for _, t in ipairs(tasks) do
    if model.is_open_status(t.status) then
      open[#open + 1] = t
    else
      skipped = skipped + 1
    end
  end
  local shown = model.sort(model.filter(open, filter))
  if skipped > 0 then
    notify.warn(
      ("%d task file(s) not listed (missing or unknown status, or done); run :MyPlugins tasks index --check"):format(
        skipped
      )
    )
  end

  if flags.to == nil and flags.format == nil and M.dashboard then
    M.dashboard({ tasks = shown, area = area, filter = filter, root = root })
    return
  end
  if #shown == 0 then
    notify.info("no open task matches")
    return
  end

  local label = area or "alle Bereiche"
  local ok, err = view.deliver(shown, target, {
    format = flags.format,
    heading = ("Offene Tasks — %s (%d)"):format(label, #shown),
    note = filter_note(flags),
    title = "myplugins://tasks/" .. (area or "all"),
  })
  if not ok then
    notify.error(("cannot deliver the task list: %s"):format(tostring(err)))
    return
  end
  notify.info(("%d open task(s) -> %s"):format(#shown, flags.to or "buffer"))
end

---`:MyPlugins tasks index [<area>] [--all] [--check]`
---@param ctx table
function M.index(ctx)
  local root = vault_root()
  if not root then
    return
  end
  local area = ctx.args.area
  if ctx.flags.all then
    area = nil
  end

  if ctx.flags.check then
    local res, err = check.run({ root = root, area = area })
    if not res then
      notify.error(tostring(err))
      return
    end
    local lines = {}
    for _, f in ipairs(res.findings) do
      lines[#lines + 1] = check.format(f, root)
    end
    local summary = ("tasks check: %d finding(s) (%d error, %d warning) in %d area(s), %d task file(s) read"):format(
      #res.findings,
      res.errors,
      res.warnings,
      res.areas,
      res.tasks
    )
    local level = (not res.ok) and "error" or (res.warnings > 0 and "warn" or "info")
    report(level, summary, lines, "myplugins://tasks-check")
    return
  end

  local results, errors
  if area then
    local res, err = index.write_area(area, { root = root })
    results = res and { res } or {}
    errors = err and { area .. ": " .. err } or {}
  else
    results, errors = index.write_all({ root = root })
  end
  if not results then
    notify.error(tostring(errors[1]))
    return
  end
  local counts = { written = 0, removed = 0, unchanged = 0, stale = 0 }
  local lines = {}
  for _, r in ipairs(results) do
    counts[r.action] = counts[r.action] + 1
    if r.action ~= "unchanged" then
      lines[#lines + 1] = ("%s  %s  (%d open)"):format(r.action, rel(r.path, root), r.open)
    end
  end
  for _, e in ipairs(errors) do
    lines[#lines + 1] = "error  " .. e
  end
  local summary = ("tasks index: %d area(s), %d written, %d removed, %d unchanged, %d error(s)"):format(
    #results,
    counts.written,
    counts.removed,
    counts.unchanged,
    #errors
  )
  report(#errors > 0 and "error" or "info", summary, lines, "myplugins://tasks-index")
end

-- ── task new ─────────────────────────────────────────────────────────────────

---Ask for the fields a `task new` call did not carry. Uses `ui.kit.form`
---(ui.nvim) when it is installed, else a chain of `vim.ui.input` prompts.
---`cb(nil)` means cancelled; otherwise a map of the non-empty answers.
---@param given table<string, string>  kv values already supplied
---@param cb fun(values: table<string, string>|nil)
function M.ask_new_fields(given, cb)
  ---@type { name: string, label: string, required?: boolean, default?: string }[]
  local fields = { { name = "title", label = "Title", required = true } }
  if not given.kind then
    fields[#fields + 1] = {
      name = "kind",
      label = "Kind (" .. table.concat(model.KINDS, "|") .. ")",
      default = "task",
    }
  end
  if not given.prio then
    fields[#fields + 1] = { name = "prio", label = "Prio (1|2|3, empty: none)" }
  end
  if not given.effort then
    fields[#fields + 1] = { name = "effort", label = "Effort (XS|S|M|L|XL|0.5d, empty: none)" }
  end

  ---@param raw table<string, string>
  local function finish(raw)
    local values = {}
    for k, v in pairs(raw) do
      local t = vim.trim(v or "")
      if t ~= "" then
        values[k] = t
      end
    end
    cb(values)
  end

  local ok_kit, kit = pcall(require, "ui.kit")
  if ok_kit and type(kit.form) == "function" then
    kit.form({
      fields = fields,
      on_submit = finish,
      on_cancel = function()
        cb(nil)
      end,
    })
    return
  end

  local answers = {}
  local function step(i)
    local field = fields[i]
    if not field then
      finish(answers)
      return
    end
    vim.ui.input({ prompt = field.label .. ": ", default = field.default }, function(value)
      if value == nil then
        if field.required then
          cb(nil)
          return
        end
        value = field.default or ""
      end
      answers[field.name] = value
      step(i + 1)
    end)
  end
  step(1)
end

---`:MyPlugins task new <area> [title...] [kind= prio= effort= tags= status=]`
---@param ctx table
function M.task_new(ctx)
  local area = ctx.args.area
  local title = unquote(table.concat(ctx.rest, " "))
  local given = {}
  for _, key in ipairs({ "kind", "prio", "effort", "tags", "status" }) do
    if ctx.kv[key] ~= nil and ctx.kv[key] ~= "" then
      given[key] = ctx.kv[key]
    end
  end

  ---@param values table<string, string>
  local function create(values)
    local res, err = mutate.new(area, {
      title = values.title,
      kind = values.kind,
      prio = values.prio,
      effort = values.effort,
      tags = values.tags,
      status = values.status,
    })
    if not res then
      notify.error(tostring(err))
      return
    end
    if res.index_err then
      notify.warn("task created, but the index was not updated: " .. res.index_err)
    end
    notify.info(("created %s"):format(res.id))
    open_file(res.path)
  end

  if title ~= "" then
    create(vim.tbl_extend("force", given, { title = title }))
    return
  end
  M.ask_new_fields(given, function(values)
    if not values then
      notify.info("task new cancelled")
      return
    end
    if not values.title then
      notify.warn("no title given, nothing created")
      return
    end
    create(vim.tbl_extend("force", given, values))
  end)
end

-- ── task set ─────────────────────────────────────────────────────────────────

---Turn `key=value` tokens into a patch. A value may contain spaces: a token
---that does not start with a known `key=` continues the value before it, so
---`title=Fix the thing status=doing` sets two keys. An empty value (`kind=`)
---removes the key.
---@param tokens string[]
---@param known string[]  accepted keys
---@return table<string, any>|nil patch
---@return string|nil err
function M.parse_assignments(tokens, known)
  local is_known = {}
  for _, k in ipairs(known) do
    is_known[k] = true
  end
  ---@type { key: string, words: string[] }[]
  local items = {}
  for _, tok in ipairs(tokens) do
    local key, value = tok:match("^([%a_][%w_]*)=(.*)$")
    if key and is_known[key] then
      items[#items + 1] = { key = key, words = { value } }
    elseif #items > 0 then
      local words = items[#items].words
      words[#words + 1] = tok
    elseif key then
      return nil, ("unknown field '%s' (settable: %s)"):format(key, table.concat(known, ", "))
    else
      return nil, ("expected key=value, got '%s'"):format(tok)
    end
  end
  if #items == 0 then
    return nil, "nothing to set (expected key=value ...)"
  end
  local patch = {}
  for _, item in ipairs(items) do
    if patch[item.key] ~= nil then
      return nil, ("'%s' given twice"):format(item.key)
    end
    local text = vim.trim(table.concat(item.words, " "))
    patch[item.key] = text == "" and mutate.REMOVE or unquote(text)
  end
  return patch, nil
end

---`:MyPlugins task set <id> key=value ...`
---@param ctx table
function M.task_set(ctx)
  local fargs = ctx.raw.fargs or {}
  local tokens = {}
  for i = #ctx.path + 2, #fargs do
    tokens[#tokens + 1] = fargs[i]
  end
  local patch, perr = M.parse_assignments(tokens, mutate.SETTABLE)
  if not patch then
    notify.error(tostring(perr))
    return
  end
  local res, err = mutate.set(ctx.args.id, patch)
  if not res then
    notify.error(tostring(err))
    return
  end
  if res.index_err then
    notify.warn("task changed, but the index was not updated: " .. res.index_err)
  end
  if res.changed then
    refresh_buffers(res.path)
  end
  notify.info(("set %s: %s"):format(res.id, res.changed and "changed" or "unchanged"))
end

-- ── task done ────────────────────────────────────────────────────────────────

---@param id string
---@param opts { done_in?: string, date?: string }
local function finish_task(id, opts)
  local res, err = mutate.done(id, { done_in = opts.done_in, date = opts.date })
  if not res then
    notify.error(tostring(err))
    return
  end
  if res.already then
    notify.info(("%s is already finished (%s)"):format(id, res.to))
    return
  end
  M.retarget_buffers(res.from, res.to)
  if res.index_err then
    notify.warn("task finished, but the index was not updated: " .. res.index_err)
  end
  if res.readme == "missing" then
    notify.warn("Backlog/README.md does not exist: no row added for the finished task")
  end
  local root = vault.root()
  notify.info(("done %s -> %s"):format(id, root and rel(res.to, root) or res.to))
end

---`:MyPlugins task done <id> [done_in=...] [date=YYYY-MM-DD] [--yes]`
---@param ctx table
function M.task_done(ctx)
  if #ctx.rest > 0 then
    notify.error("unexpected argument: " .. table.concat(ctx.rest, " "))
    return
  end
  local id = ctx.args.id
  local opts = { done_in = ctx.kv.done_in, date = ctx.kv.date }
  local task = scan.find(id)
  if not task or ctx.flags.yes then
    -- A finished task answers "already" without asking anything.
    finish_task(id, opts)
    return
  end
  local bucket = vault.BUCKET_OF_KIND[task.kind or "task"] or "?"
  local date = opts.date or model.today()
  confirm.yesno(
    ("Finish task %s?\n\n%s\n\nIt moves to Backlog/%s/%s_%s.md."):format(
      id,
      task.title,
      bucket,
      date,
      task.slug
    ),
    "finish",
    function(accepted)
      if not accepted then
        notify.info("cancelled -- the task stays open")
        return
      end
      finish_task(id, opts)
    end
  )
end

-- ── task template / open ─────────────────────────────────────────────────────

---`:MyPlugins task template [--to=clipboard|buffer|file:<path>]`
---@param ctx table
function M.task_template(ctx)
  local target, terr = view.parse_target(ctx.flags.to or "clipboard")
  if terr or not target or target.kind == "qf" then
    notify.error(terr or "--to=qf makes no sense for the template")
    return
  end
  local text = mutate.template({})
  local ok, err = harvest.emit(text, target.kind, {
    path = target.path,
    title = "myplugins://task-template",
    filetype = "markdown",
  })
  if not ok then
    if target.kind == "clipboard" then
      harvest.sink.scratch(text, { title = "myplugins://task-template", filetype = "markdown" })
      notify.warn(("no clipboard (%s): the template is in a buffer instead"):format(tostring(err)))
      return
    end
    notify.error(tostring(err))
    return
  end
  if target.kind == "clipboard" then
    notify.info("task template copied to the + register")
  else
    notify.info("task template -> " .. target.kind)
  end
end

---`:MyPlugins task open <id>` -- an open task, else its finished copy in `Backlog/`.
---@param ctx table
function M.task_open(ctx)
  local id = ctx.args.id
  local task = scan.find(id) or scan.find_done(id)
  if not task then
    notify.error("no such task: " .. id)
    return
  end
  open_file(task.path)
end

-- ── open <area> <folder> ─────────────────────────────────────────────────────

---Markdown files below `dir`, relative to it, sorted.
---@param dir string
---@return string[]
local function markdown_below(dir)
  local out = {}
  for _, p in ipairs((require("lib.nvim.fs.collect_recursive").files(dir))) do
    local n = fsio.norm(p)
    if n:match("%.md$") then
      out[#out + 1] = n
    end
  end
  table.sort(out)
  return out
end

---The pickers.nvim engine and its dispatcher, when that plugin is installed.
---@return table|nil command  `pickers.command`
---@return table|nil engine
local function pickers_backend()
  local ok, command = pcall(require, "pickers.command")
  if not ok or type(command.dispatch) ~= "function" then
    return nil, nil
  end
  local ok_engines, engines = pcall(require, "pickers.engines")
  if not ok_engines then
    return nil, nil
  end
  local engine = engines.load()
  if not engine then
    return nil, nil
  end
  return command, engine
end

---`:MyPlugins open <area> [folder] [--action=files|grep|smart] [--list] [--to=]`
---
---Opens a pickers.nvim picker whose search root is exactly that one folder of
---the area (`pickers.command.dispatch` with an explicit `roots` source, so
---`:PickersRepeat` replays it). Without pickers.nvim it falls back to a
---`vim.ui.select` over the folder's `*.md` files -- no content search.
---`--list` (or `--to=`) delivers the file list instead of opening a picker.
---@param ctx table
function M.open_area(ctx)
  local root = vault_root()
  if not root then
    return
  end
  local area = ctx.args.area
  local folder = ctx.args.folder or "all"
  local sub = M.FOLDERS[folder]
  if sub == nil then
    notify.error(
      ("unknown folder '%s' (expected %s)"):format(
        folder,
        "tasks|roadmap|backlog|handover|notes|all"
      )
    )
    return
  end
  local dir = root .. "/" .. area .. (sub ~= "" and ("/" .. sub) or "")
  if not fsio.is_dir(dir) then
    notify.warn(("%s has no %s folder (%s)"):format(area, folder, rel(dir, root)))
    return
  end

  local target, terr = view.parse_target(ctx.flags.to)
  if terr or (target and target.kind == "qf") then
    notify.error(terr or "--to=qf is not supported for :MyPlugins open")
    return
  end

  if ctx.flags.list or target then
    local lines = {}
    for _, p in ipairs(markdown_below(dir)) do
      lines[#lines + 1] = p:sub(#dir + 2)
    end
    if #lines == 0 then
      notify.info(("no Markdown file in %s"):format(rel(dir, root)))
      return
    end
    local kind = target and target.kind or "buffer"
    local ok, err = harvest.emit(table.concat(lines, "\n") .. "\n", kind, {
      path = target and target.path or nil,
      title = ("myplugins://open/%s/%s"):format(area, folder),
      filetype = "text",
    })
    if not ok then
      notify.error(tostring(err))
    end
    return
  end

  local action = ctx.flags.action or "files"
  local command, engine = pickers_backend()
  if command then
    command.dispatch(action, {
      roots = { dir },
      prompt = ("%s/%s> "):format(area, folder),
    }, engine)
    return
  end

  if action ~= "files" then
    notify.warn(
      "pickers.nvim is not available: --action=" .. action .. " needs it, listing files instead"
    )
  end
  local files = markdown_below(dir)
  if #files == 0 then
    notify.info(("no Markdown file in %s"):format(rel(dir, root)))
    return
  end
  harvest.sink.select(files, {
    prompt = ("%s/%s"):format(area, folder),
    format = function(p)
      return p:sub(#dir + 2)
    end,
  }, function(path)
    open_file(path)
  end)
end

return M
