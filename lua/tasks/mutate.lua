---@module 'tasks.mutate'
---@brief Create, change and finish tasks (the only module of the engine that writes task files).
---@description
--- `new` writes a task file, `set` patches its frontmatter, `done` moves it to
--- `Backlog/` (rule R6). Each regenerates the area index afterwards.
---
--- Key responsibilities:
---  - `template` / `new`: the file text, a collision-safe kebab slug, `created`
---    and `updated`; the file is created with `O_CREAT|O_EXCL`, never overwritten
---  - `set`: validate the patch, then change only the named keys through
---    `lib.nvim.markdown.frontmatter`; `updated` is bumped only when something
---    actually changed
---  - `done`: `status: done` + `done_in`, move to `Backlog/FEATURES|TASKS` with a
---    `YYYY-MM-DD_` prefix, add the row to that `Backlog/README.md`, regenerate
---    the index. The files involved are snapshotted with `lib.nvim.checkpoint`
---    and restored byte-exact when any step fails; a second run of an already
---    finished task changes nothing, and a run interrupted half way resumes
---
--- Not its job: prompting for input, opening the file, notifying (all UI).

local checkpoint = require("lib.nvim.checkpoint")
local fm = require("lib.nvim.markdown.frontmatter")

local fsio = require("tasks.fsio")
local index = require("tasks.index")
local model = require("tasks.model")
local scan = require("tasks.scan")
local vault = require("tasks.vault")

local M = {}

---Patch value that deletes a key (`set`).
M.REMOVE = fm.REMOVE

---Longest slug generated from a title.
M.MAX_SLUG = 60

---@param s string
---@return string
local function trim(s)
  return (s:match("^%s*(.-)%s*$"))
end

-- ── Slugs ────────────────────────────────────────────────────────────────────

---Lower-case letters with a diacritic -> ASCII. Anything else non-ASCII is dropped.
---@type table<string, string>
local FOLD = {
  ["ä"] = "ae",
  ["ö"] = "oe",
  ["ü"] = "ue",
  ["ß"] = "ss",
  ["à"] = "a",
  ["á"] = "a",
  ["â"] = "a",
  ["ã"] = "a",
  ["å"] = "a",
  ["æ"] = "ae",
  ["ç"] = "c",
  ["è"] = "e",
  ["é"] = "e",
  ["ê"] = "e",
  ["ë"] = "e",
  ["ì"] = "i",
  ["í"] = "i",
  ["î"] = "i",
  ["ï"] = "i",
  ["ñ"] = "n",
  ["ò"] = "o",
  ["ó"] = "o",
  ["ô"] = "o",
  ["õ"] = "o",
  ["ø"] = "o",
  ["œ"] = "oe",
  ["ù"] = "u",
  ["ú"] = "u",
  ["û"] = "u",
  ["ý"] = "y",
  ["ÿ"] = "y",
}

---A kebab-case ASCII slug from free text: umlauts folded (`ü` -> `ue`), other
---characters turned into hyphens, runs of hyphens collapsed, at most
---`MAX_SLUG` characters. Text with no usable character gives `"task"`.
---@param title string
---@return string
function M.slugify(title)
  local lowered = vim.fn.tolower(title)
  local out = {}
  for ch in lowered:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
    if ch:match("^[a-z0-9]$") then
      out[#out + 1] = ch
    elseif FOLD[ch] then
      out[#out + 1] = FOLD[ch]
    else
      out[#out + 1] = "-"
    end
  end
  local slug = table.concat(out):gsub("%-+", "-"):gsub("^%-", ""):gsub("%-$", "")
  if #slug > M.MAX_SLUG then
    slug = slug:sub(1, M.MAX_SLUG):gsub("%-$", "")
  end
  return slug ~= "" and slug or "task"
end

-- ── Template ─────────────────────────────────────────────────────────────────

---Visible placeholders: the text to paste into an editor and fill in.
local TEMPLATE_BODY = table.concat({
  "",
  "Eine Zeile Zusammenfassung — sie landet im Index.",
  "",
  "## Kontext",
  "",
  "Warum, woher kam das.",
  "",
  "## Akzeptanz",
  "",
  "- [ ] was am Ende wahr sein muss",
  "",
  "## Notizen",
  "",
  "Entscheidungen, Sackgassen, Verweise.",
  "",
}, "\n")

---Invisible placeholders (HTML comments): a task created without a summary must
---not get a placeholder sentence as its index summary.
local NEW_BODY_SECTIONS = table.concat({
  "## Kontext",
  "",
  "<!-- Warum, woher kam das. -->",
  "",
  "## Akzeptanz",
  "",
  "<!-- was am Ende wahr sein muss, als Checkliste -->",
  "",
  "## Notizen",
  "",
  "<!-- Entscheidungen, Sackgassen, Verweise. -->",
  "",
}, "\n")

---Frontmatter keys in the order concept section 3 shows them.
---@param meta { title: string, status: string, kind?: string, prio?: integer|string, effort?: string, tags?: string[], created: string, updated: string }
---@return table[] pairs
local function meta_pairs(meta)
  local pairs_ = {
    { "title", meta.title },
    { "status", meta.status },
  }
  if meta.kind then
    pairs_[#pairs_ + 1] = { "kind", meta.kind }
  end
  if meta.prio then
    pairs_[#pairs_ + 1] = { "prio", tostring(meta.prio) }
  end
  if meta.effort then
    pairs_[#pairs_ + 1] = { "effort", meta.effort }
  end
  if meta.tags then
    pairs_[#pairs_ + 1] = { "tags", meta.tags }
  end
  pairs_[#pairs_ + 1] = { "created", meta.created }
  pairs_[#pairs_ + 1] = { "updated", meta.updated }
  return pairs_
end

---The task template as text, with every field present and visible placeholders.
---@param opts? { title?: string, kind?: string, prio?: integer, effort?: string, tags?: string[], today?: string }
---@return string text
function M.template(opts)
  opts = opts or {}
  local today = opts.today or model.today()
  local text = fm.update_text(
    TEMPLATE_BODY,
    meta_pairs({
      title = opts.title or "Titel",
      status = "open",
      kind = opts.kind or "task",
      prio = opts.prio or 2,
      effort = opts.effort or "M",
      tags = opts.tags or {},
      created = today,
      updated = today,
    }),
    { create = true }
  )
  return text or ""
end

-- ── Validation ───────────────────────────────────────────────────────────────

---@param value any
---@param what string
---@return string|nil text
---@return string|nil err
local function one_line(value, what)
  if type(value) ~= "string" then
    return nil, what .. " must be text"
  end
  local t = trim(value)
  if t == "" then
    return nil, what .. " must not be empty"
  end
  if t:find("[\r\n]") then
    return nil, what .. " must be a single line"
  end
  return t, nil
end

---A list of single-line strings. A string is split at commas.
---With `strict`, an item must also be safe inside an inline `[a, b]` list
---(tags: no comma, bracket, quote or `#`); refs and commits may contain them.
---@param value any
---@param what string
---@param strict? boolean
---@return string[]|nil list
---@return string|nil err
local function string_list(value, what, strict)
  if type(value) == "string" then
    local out = {}
    for item in value:gmatch("[^,]+") do
      local t = trim(item)
      if t ~= "" then
        out[#out + 1] = t
      end
    end
    value = out
  end
  if type(value) ~= "table" then
    return nil, what .. " must be a list"
  end
  local out = {}
  for _, item in ipairs(value) do
    local t, err = one_line(item, what .. " item")
    if not t then
      return nil, err
    end
    if strict and t:find("[,%[%]\"'#]") then
      return nil, ("%s item '%s' must not contain , [ ] quotes or #"):format(what, t)
    end
    out[#out + 1] = t
  end
  return out, nil
end

---@param value any
---@return string[]|nil ids
---@return string|nil err
local function id_list(value)
  local list, err = string_list(value, "blocked_by")
  if not list then
    return nil, err
  end
  for _, id in ipairs(list) do
    local _, slug, id_err = vault.parse_id(id)
    if id_err or not slug then
      return nil, "blocked_by: " .. (id_err or ("expected <area>/<slug>, got " .. id))
    end
  end
  return list, nil
end

---Keys `set` accepts, in the order they are written when new. `updated` is
---deliberately absent: the tool sets it. Exported as `M.SETTABLE` for front
---ends that complete or document the keys.
local SETTABLE = {
  "title",
  "status",
  "kind",
  "prio",
  "effort",
  "tags",
  "summary",
  "blocked_by",
  "refs",
  "done_in",
  "created",
}

---@type string[]
M.SETTABLE = SETTABLE

---Check and normalise a `set` patch into an ordered list of `{ key, value }`.
---A value of `REMOVE` deletes the key (not for `title` and `status`).
---@param patch table<string, any>
---@param opts? { allow_unknown?: boolean }
---@return table[]|nil pairs
---@return string|nil err
local function normalize_patch(patch, opts)
  local result = {}
  local known = {}
  for _, key in ipairs(SETTABLE) do
    known[key] = true
  end
  local keys = {}
  for key in pairs(patch) do
    keys[#keys + 1] = key
  end
  table.sort(keys, function(a, b)
    local ia, ib = #SETTABLE + 1, #SETTABLE + 1
    for i, k in ipairs(SETTABLE) do
      ia = k == a and i or ia
      ib = k == b and i or ib
    end
    if ia ~= ib then
      return ia < ib
    end
    return a < b
  end)
  if #keys == 0 then
    return nil, "nothing to set"
  end

  for _, key in ipairs(keys) do
    local value = patch[key]
    local removing = value == M.REMOVE
    if key == "updated" then
      return nil, "updated is set by the tool, not by hand"
    elseif not known[key] and not (opts and opts.allow_unknown) then
      return nil, ("unknown field '%s' (settable: %s)"):format(key, table.concat(SETTABLE, ", "))
    elseif not key:match("^[%a_][%w_]*$") then
      return nil, "invalid field name: " .. tostring(key)
    elseif removing and (key == "title" or key == "status") then
      return nil, key .. " cannot be removed"
    elseif removing then
      result[#result + 1] = { key, M.REMOVE }
    elseif key == "title" then
      local t, err = one_line(value, "title")
      if not t then
        return nil, err
      end
      result[#result + 1] = { key, t }
    elseif key == "status" then
      if value == "done" then
        return nil, "status 'done' is set by finishing the task (tasks done), which also moves it"
      end
      if not model.is_open_status(value) then
        return nil,
          ("unknown status '%s' (expected %s)"):format(
            tostring(value),
            table.concat(model.OPEN_STATUSES, ", ")
          )
      end
      result[#result + 1] = { key, value }
    elseif key == "kind" then
      if not model.is_kind(value) then
        return nil,
          ("unknown kind '%s' (expected %s)"):format(
            tostring(value),
            table.concat(model.KINDS, ", ")
          )
      end
      result[#result + 1] = { key, value }
    elseif key == "prio" then
      local prio = model.to_prio(value)
      if not prio then
        return nil, "prio must be 1, 2 or 3, got " .. tostring(value)
      end
      result[#result + 1] = { key, tostring(prio) }
    elseif key == "effort" then
      if not model.is_effort(value) then
        return nil, ("effort '%s' is neither XS..XL nor days like 0.5d"):format(tostring(value))
      end
      result[#result + 1] = { key, value }
    elseif key == "created" then
      if not model.is_date(value) then
        return nil, ("created '%s' is not a date (YYYY-MM-DD)"):format(tostring(value))
      end
      result[#result + 1] = { key, value }
    elseif key == "tags" or key == "refs" or key == "done_in" then
      local list, err = string_list(value, key, key == "tags")
      if not list then
        return nil, err
      end
      if #list == 0 then
        result[#result + 1] = { key, M.REMOVE }
      elseif key == "done_in" then
        result[#result + 1] = { key, table.concat(list, ", ") }
      else
        result[#result + 1] = { key, list }
      end
    elseif key == "blocked_by" then
      local ids, err = id_list(value)
      if not ids then
        return nil, err
      end
      if #ids == 0 then
        result[#result + 1] = { key, M.REMOVE }
      elseif #ids == 1 then
        result[#result + 1] = { key, ids[1] }
      else
        result[#result + 1] = { key, ids }
      end
    else
      -- summary, or an allowed unknown field: a single-line text.
      local t, err = one_line(value, key)
      if not t then
        return nil, err
      end
      result[#result + 1] = { key, t }
    end
  end
  return result, nil
end

-- ── new ──────────────────────────────────────────────────────────────────────

---Create a task file under `<area>/ROADMAP/tasks/`.
---
---The slug comes from the title (`opts.slug` overrides it); a taken slug gets
---`-2`, `-3`, ... unless it was given explicitly, which is then an error.
---`status` defaults to `open`, `kind` to `task`; `prio`, `effort`, `tags` and
---`summary` are written only when given.
---@param area string
---@param opts Tasks.NewOpts
---@return { id: string, area: string, slug: string, path: string, index?: Tasks.IndexResult, index_err?: string }|nil result
---@return string|nil err
function M.new(area, opts)
  opts = opts or {}
  local root, rerr = vault.root(opts)
  if not root then
    return nil, rerr
  end
  if not vault.has_area(root, area) then
    return nil, "unknown area: " .. tostring(area)
  end

  local title, terr = one_line(opts.title, "title")
  if not title then
    return nil, terr
  end
  local status = opts.status or "open"
  if not model.is_open_status(status) then
    return nil,
      ("unknown status '%s' (expected %s)"):format(
        tostring(status),
        table.concat(model.OPEN_STATUSES, ", ")
      )
  end
  local kind = opts.kind or "task"
  if not model.is_kind(kind) then
    return nil,
      ("unknown kind '%s' (expected %s)"):format(tostring(kind), table.concat(model.KINDS, ", "))
  end
  local prio
  if opts.prio ~= nil then
    prio = model.to_prio(opts.prio)
    if not prio then
      return nil, "prio must be 1, 2 or 3, got " .. tostring(opts.prio)
    end
  end
  if opts.effort ~= nil and not model.is_effort(opts.effort) then
    return nil, ("effort '%s' is neither XS..XL nor days like 0.5d"):format(tostring(opts.effort))
  end
  local tags
  if opts.tags ~= nil then
    local list, lerr = string_list(opts.tags, "tags", true)
    if not list then
      return nil, lerr
    end
    tags = #list > 0 and list or nil
  end
  local summary
  if opts.summary ~= nil then
    local s, serr = one_line(opts.summary, "summary")
    if not s then
      return nil, serr
    end
    summary = s
  end
  local today = opts.today or model.today()
  if not model.is_date(today) then
    return nil, "today is not a date (YYYY-MM-DD): " .. tostring(today)
  end
  if opts.slug ~= nil and not vault.valid_slug(opts.slug) then
    return nil, "invalid slug: " .. tostring(opts.slug)
  end

  local lead = summary and (summary .. "\n\n") or ""
  local body = "\n" .. lead .. NEW_BODY_SECTIONS
  local text, ferr = fm.update_text(
    body,
    meta_pairs({
      title = title,
      status = status,
      kind = kind,
      prio = prio,
      effort = opts.effort,
      tags = tags,
      created = today,
      updated = today,
    }),
    { create = true }
  )
  if not text then
    return nil, "cannot build the task file: " .. tostring(ferr)
  end

  local taken, berr = scan.backlog_slugs(area, { root = root })
  if not taken then
    return nil, berr
  end

  local base = opts.slug or M.slugify(title)
  local n = 1
  while true do
    local slug = n == 1 and base or (base .. "-" .. n)
    if not taken[slug] then
      local path = vault.task_path(root, area, slug)
      local ok, err = fsio.create_exclusive(path, text)
      if ok then
        ---@type table
        local result = { id = area .. "/" .. slug, area = area, slug = slug, path = path }
        if opts.index ~= false then
          result.index, result.index_err = index.write_area(area, { root = root })
        end
        return result, nil
      elseif err ~= "exists" then
        return nil, "cannot create " .. path .. ": " .. tostring(err)
      end
    end
    if opts.slug then
      return nil, "task already exists: " .. area .. "/" .. opts.slug
    end
    n = n + 1
    if n > 999 then
      return nil, "no free slug for " .. base
    end
  end
end

-- ── set ──────────────────────────────────────────────────────────────────────

---Change frontmatter keys of an open task and set `updated`.
---
---`patch` maps key -> value (`REMOVE` deletes). Nothing is written, and
---`updated` stays as it was, when the patch would not change the file.
---@param id string
---@param patch table<string, any>
---@param opts? { root?: string, today?: string, index?: boolean, allow_unknown?: boolean }
---@return { id: string, path: string, changed: boolean, index?: Tasks.IndexResult, index_err?: string }|nil result
---@return string|nil err
function M.set(id, patch, opts)
  opts = opts or {}
  local root, rerr = vault.root(opts)
  if not root then
    return nil, rerr
  end
  local task, ferr = scan.find(id, { root = root })
  if not task then
    return nil, ferr
  end
  local today = opts.today or model.today()
  if not model.is_date(today) then
    return nil, "today is not a date (YYYY-MM-DD): " .. tostring(today)
  end
  local pairs_, perr = normalize_patch(patch, opts)
  if not pairs_ then
    return nil, perr
  end

  local text, rd_err = fsio.read(task.path)
  if not text then
    return nil, "cannot read " .. task.path .. ": " .. tostring(rd_err)
  end
  local probe, uerr = fm.update_text(text, pairs_)
  if not probe then
    return nil, "cannot update " .. task.path .. ": " .. tostring(uerr)
  end
  local result = { id = task.id, path = task.path, changed = probe ~= text }
  if not result.changed then
    return result, nil
  end

  pairs_[#pairs_ + 1] = { "updated", today }
  local ok, werr = fm.update(task.path, pairs_)
  if not ok then
    return nil, "cannot write " .. task.path .. ": " .. tostring(werr)
  end
  if opts.index ~= false then
    result.index, result.index_err = index.write_area(task.area, { root = root })
  end
  return result, nil
end

-- ── Backlog README ───────────────────────────────────────────────────────────

---@param s string
---@return string
local function cell(s)
  return (s:gsub("[\r\n]+", " "):gsub("|", "\\|"))
end

---The README row of a finished task.
---@param bucket Tasks.Bucket
---@param filename string
---@param task Tasks.Task
---@param date string
---@return string
local function readme_row(bucket, filename, task, date)
  local content = cell(task.title)
  if task.summary ~= "" and task.summary ~= task.title then
    local summary = task.summary
    if vim.fn.strchars(summary) > 120 then
      summary = vim.fn.strcharpart(summary, 0, 119) .. "…"
    end
    content = content .. " — " .. cell(summary)
  end
  -- The filename is `YYYY-MM-DD_<slug>.md` with a validated slug: nothing to escape.
  return ("| [`%s`](./%s/%s) | %s (%s) |"):format(filename, bucket, filename, content, date)
end

---Add `row` to the `## <bucket> (N)` section of a `Backlog/README.md` text.
---
---A section holding the `_noch leer_` placeholder gets a table instead; a
---missing section is appended. The row goes first (newest on top), the count is
---recomputed from the table, the file's line ending and its trailing newline
---are kept, and a row for the same file that is already there changes nothing.
---@param text string
---@param bucket Tasks.Bucket
---@param filename string
---@param row string
---@return string text
---@return boolean changed
function M.readme_add_row(text, bucket, filename, row)
  local eol = fsio.eol_of(text)
  local body = fsio.lf(text)
  local trailing = body:sub(-1) == "\n"
  if trailing then
    body = body:sub(1, -2)
  end
  local lines = vim.split(body, "\n", { plain = true })
  local marker = ("(./%s/%s)"):format(bucket, filename)
  local table_head = { "| Datei | Inhalt |", "|---|---|" }

  local heading
  for i, line in ipairs(lines) do
    if line:match("^##%s+" .. bucket .. "%f[%W]") then
      heading = i
      break
    end
  end

  if not heading then
    if #lines > 0 and lines[#lines] ~= "" then
      lines[#lines + 1] = ""
    end
    lines[#lines + 1] = ("## %s (1)"):format(bucket)
    lines[#lines + 1] = ""
    lines[#lines + 1] = table_head[1]
    lines[#lines + 1] = table_head[2]
    lines[#lines + 1] = row
  else
    local last = #lines
    for i = heading + 1, #lines do
      if lines[i]:match("^##%s") then
        last = i - 1
        break
      end
    end
    local sep, placeholder
    for i = heading + 1, last do
      if lines[i]:find(marker, 1, true) then
        return text, false
      end
      if not sep and lines[i]:match("^|%s*%-%-%-") then
        sep = i
      end
      if not placeholder and trim(lines[i]) == "_noch leer_" then
        placeholder = i
      end
    end
    if sep then
      table.insert(lines, sep + 1, row)
    elseif placeholder then
      lines[placeholder] = table_head[1]
      table.insert(lines, placeholder + 1, table_head[2])
      table.insert(lines, placeholder + 2, row)
    else
      -- A section with neither a table nor the placeholder: start the table
      -- after the heading, separated by a blank line.
      table.insert(lines, heading + 1, "")
      table.insert(lines, heading + 2, table_head[1])
      table.insert(lines, heading + 3, table_head[2])
      table.insert(lines, heading + 4, row)
    end
    -- Recount the rows of that section for the heading.
    local count, from, to = 0, heading + 1, #lines
    for i = heading + 1, #lines do
      if lines[i]:match("^##%s") then
        to = i - 1
        break
      end
    end
    local after_sep = false
    for i = from, to do
      if lines[i]:match("^|%s*%-%-%-") then
        after_sep = true
      elseif after_sep and lines[i]:match("^|") then
        count = count + 1
      end
    end
    lines[heading] = ("## %s (%d)"):format(bucket, count)
  end

  local out = table.concat(lines, "\n") .. (trailing and "\n" or "")
  if eol == "\r\n" then
    out = out:gsub("\n", "\r\n")
  end
  return out, true
end

-- ── done ─────────────────────────────────────────────────────────────────────

---@class Tasks.DoneOpts
---@field root? string
---@field done_in? string|string[]   # Commit(s) that delivered the task.
---@field date? string               # `YYYY-MM-DD` filename prefix (default: today).
---@field today? string              # Sets `updated` (default: today).
---@field index? boolean             # Regenerate the area index (default true).
---@field checkpoint_dir? string     # Where the safety snapshot goes.

---Finish an open task (rule R6): set `status: done` and `done_in`, move the
---file to `Backlog/FEATURES` (feature, idea, research) or `Backlog/TASKS` (task,
---bug) as `YYYY-MM-DD_<slug>.md`, add its row to that `Backlog/README.md`, and
---regenerate the area index.
---
---The four files involved are snapshotted first; if any step fails they are
---restored byte-exact. A task that is already finished answers
---`already = true` and changes nothing; if an earlier run died between creating
---the Backlog file and deleting the old one, this run completes it.
---@param id string
---@param opts? Tasks.DoneOpts
---@return table|nil result
---@return string|nil err
function M.done(id, opts)
  opts = opts or {}
  local root, rerr = vault.root(opts)
  if not root then
    return nil, rerr
  end
  local area, slug, id_err = vault.parse_id(id)
  if not area or not slug then
    return nil, id_err or ("expected <area>/<slug>, got " .. tostring(id))
  end

  local task = scan.find(id, { root = root })
  if not task then
    local finished = scan.find_done(id, { root = root })
    if finished then
      return { id = id, already = true, to = finished.path }, nil
    end
    return nil, "no such open task: " .. id
  end

  local kind = task.kind or "task"
  local bucket = vault.BUCKET_OF_KIND[kind]
  if not bucket then
    return nil,
      ("task has unknown kind '%s'; fix it first (tasks set %s kind=...)"):format(kind, id)
  end
  local today = opts.today or model.today()
  local date = opts.date or today
  if not (model.is_date(today) and model.is_date(date)) then
    return nil, "date must be YYYY-MM-DD"
  end

  local patch = { { "status", "done" } }
  if opts.done_in ~= nil then
    local list, lerr = string_list(opts.done_in, "done_in")
    if not list then
      return nil, lerr
    end
    if #list > 0 then
      patch[#patch + 1] = { "done_in", table.concat(list, ", ") }
    end
  end
  patch[#patch + 1] = { "updated", today }

  local old_text, rd_err = fsio.read(task.path)
  if not old_text then
    return nil, "cannot read " .. task.path .. ": " .. tostring(rd_err)
  end
  local new_text, uerr = fm.update_text(old_text, patch)
  if not new_text then
    return nil, "cannot update " .. task.path .. ": " .. tostring(uerr)
  end

  local filename = date .. "_" .. slug .. ".md"
  local target = vault.backlog_dir(root, area, bucket) .. "/" .. filename
  local resume = false
  local existing = scan.find_done(id, { root = root })
  if existing and existing.path ~= target then
    return nil, ("a finished task with this id already exists: %s"):format(existing.path)
  end
  if fsio.is_file(target) then
    local present = fsio.read(target)
    if present ~= new_text then
      return nil, "target exists with different content: " .. target
    end
    resume = true
  end

  local readme_path = vault.backlog_readme(root, area)
  local readme_old = fsio.is_file(readme_path) and fsio.read(readme_path) or nil
  local readme_new, readme_state = readme_old, "missing"
  if readme_old then
    local changed
    readme_new, changed =
      M.readme_add_row(readme_old, bucket, filename, readme_row(bucket, filename, task, date))
    readme_state = changed and "updated" or "unchanged"
  end

  local tracked = { task.path, target, vault.index_path(root, area) }
  if readme_old then
    tracked[#tracked + 1] = readme_path
  end
  local cp, cerr = checkpoint.create(tracked, { dir = opts.checkpoint_dir })
  if not cp then
    return nil, "cannot snapshot before moving: " .. tostring(cerr)
  end

  local function run()
    if not resume then
      local ok, err = fsio.create_exclusive(target, new_text)
      if not ok then
        return nil, "cannot create " .. target .. ": " .. tostring(err)
      end
    end
    local removed, rm_err = fsio.remove(task.path)
    if not removed then
      return nil, "cannot remove " .. task.path .. ": " .. tostring(rm_err)
    end
    if readme_old and readme_new ~= readme_old then
      local ok, err = fsio.write_atomic(readme_path, readme_new)
      if not ok then
        return nil, "cannot write " .. readme_path .. ": " .. tostring(err)
      end
    end
    if opts.index ~= false then
      local res, ierr = index.write_area(area, { root = root })
      if not res then
        return nil, "cannot regenerate the index: " .. tostring(ierr)
      end
      return res, nil
    end
    return true, nil
  end

  local ok, res, err = pcall(run)
  if not ok then
    err = tostring(res)
    res = nil
  end
  if not res then
    local restored, restore_errors = checkpoint.restore(cp)
    checkpoint.discard(cp)
    local msg = tostring(err)
    if not restored then
      local paths = {}
      for _, e in ipairs(restore_errors) do
        paths[#paths + 1] = e.path
      end
      msg = msg .. " (rollback incomplete: " .. table.concat(paths, ", ") .. ")"
    end
    return nil, msg
  end
  checkpoint.discard(cp)

  return {
    id = id,
    area = area,
    from = task.path,
    to = target,
    bucket = bucket,
    resumed = resume,
    readme = readme_state,
    index = type(res) == "table" and res or nil,
  },
    nil
end

return M
