---@module 'tasks.model'
---@brief The task record: read one file, validate it, rank and filter lists of them.
---@description
--- A task is one Markdown file with flat-YAML frontmatter (concept section 3).
--- `parse_text` / `from_file` turn it into a `Tasks.Task` -- always, even for a
--- broken file: the problems go into `errors` and `valid` is false, so one bad
--- file can never hide the rest. The frontmatter itself is read by
--- `lib.nvim.markdown.frontmatter`; this module only interprets the fields.
---
--- Key responsibilities:
---  - the enums (status, kind, prio, effort) and the date check
---  - `summary`: frontmatter `summary`, else the first body paragraph
---  - `compare` / `sort`: status rank, then prio, then area, then slug
---  - `filter`: status, prio, kind, tag, category, area, blocked, stale
---
--- Not its job: finding files (`scan`), rendering (`index`), writing (`mutate`).

local fm = require("lib.nvim.markdown.frontmatter")
local fsio = require("tasks.fsio")
local vault = require("tasks.vault")

local M = {}

---Status words in rank order: the order tasks are listed in.
---@type Tasks.Status[]
M.STATUSES = { "doing", "decision", "blocked", "open", "parked", "done" }

---The statuses an open task may have (everything but `done`).
---@type Tasks.Status[]
M.OPEN_STATUSES = { "doing", "decision", "blocked", "open", "parked" }

---@type Tasks.Kind[]
M.KINDS = { "feature", "task", "bug", "idea", "research" }

---Concerns a task can serve (concept section 12.1). Independent of `kind`:
---`kind: bug` implies `bug`, a tag of the same name counts as well.
---@type string[]
M.CATEGORIES = { "bug", "security", "performance", "docs", "ruleset" }

---@type integer[]
M.PRIOS = { 1, 2, 3 }

---@type string[]
M.EFFORTS = { "XS", "S", "M", "L", "XL" }

---@type table<string, integer>
local STATUS_RANK = {}
for i, s in ipairs(M.STATUSES) do
  STATUS_RANK[s] = i
end

---@type table<string, boolean>
local KIND_SET = {}
for _, k in ipairs(M.KINDS) do
  KIND_SET[k] = true
end

---@type table<string, boolean>
local CATEGORY_SET = {}
for _, c in ipairs(M.CATEGORIES) do
  CATEGORY_SET[c] = true
end

---@type table<string, boolean>
local EFFORT_SET = {}
for _, e in ipairs(M.EFFORTS) do
  EFFORT_SET[e] = true
end

---Sorts after prio 3: a task without a (valid) prio is the least urgent.
local NO_PRIO_RANK = 4

---@param s any
---@return boolean
function M.is_status(s)
  return type(s) == "string" and STATUS_RANK[s] ~= nil
end

---@param s any
---@return boolean
function M.is_open_status(s)
  return type(s) == "string" and STATUS_RANK[s] ~= nil and s ~= "done"
end

---@param s any
---@return boolean
function M.is_kind(s)
  return type(s) == "string" and KIND_SET[s] == true
end

---@param s any
---@return boolean
function M.is_category(s)
  return type(s) == "string" and CATEGORY_SET[s] == true
end

---The categories a task counts for: its `category` list, `bug` when `kind` is
---`bug`, and every tag that is spelled like a category. In `CATEGORIES` order.
---@param task { category?: string[], kind?: string, tags?: string[] }
---@return string[]
function M.categories(task)
  local have = {}
  for _, c in ipairs(task.category or {}) do
    have[c] = true
  end
  if task.kind == "bug" then
    have.bug = true
  end
  for _, tag in ipairs(task.tags or {}) do
    if CATEGORY_SET[tag] then
      have[tag] = true
    end
  end
  local out = {}
  for _, c in ipairs(M.CATEGORIES) do
    if have[c] then
      out[#out + 1] = c
    end
  end
  return out
end

---`XS`..`XL`, or days: `3d`, `0.5d`.
---@param s any
---@return boolean
function M.is_effort(s)
  if type(s) ~= "string" then
    return false
  end
  return EFFORT_SET[s] == true or s:match("^%d+d$") ~= nil or s:match("^%d*%.%d+d$") ~= nil
end

---@param s any
---@return integer|nil prio  1..3, or nil when `s` is no valid prio
function M.to_prio(s)
  if type(s) == "number" then
    s = tostring(s)
  end
  if type(s) == "string" and s:match("^[123]$") then
    return tonumber(s)
  end
  return nil
end

---@param y integer
---@param m integer
---@return integer
local function days_in_month(y, m)
  if m == 2 then
    local leap = (y % 4 == 0 and y % 100 ~= 0) or y % 400 == 0
    return leap and 29 or 28
  end
  return (m == 4 or m == 6 or m == 9 or m == 11) and 30 or 31
end

---`YYYY-MM-DD` that is a real calendar date.
---@param s any
---@return boolean
function M.is_date(s)
  if type(s) ~= "string" then
    return false
  end
  local ys, ms, ds = s:match("^(%d%d%d%d)-(%d%d)-(%d%d)$")
  if not ys then
    return false
  end
  local y, m, d = tonumber(ys), tonumber(ms), tonumber(ds)
  return m >= 1 and m <= 12 and d >= 1 and d <= days_in_month(y, m)
end

---Days since 1970-01-01 of a valid `YYYY-MM-DD` (proleptic Gregorian).
---@param s string
---@return integer
local function day_number(s)
  local y, m, d = s:match("^(%d+)-(%d+)-(%d+)$")
  y, m, d = tonumber(y), tonumber(m), tonumber(d)
  if m <= 2 then
    y = y - 1
  end
  local era = math.floor(y / 400)
  local yoe = y - era * 400
  local mp = (m + 9) % 12
  local doy = math.floor((153 * mp + 2) / 5) + d - 1
  local doe = yoe * 365 + math.floor(yoe / 4) - math.floor(yoe / 100) + doy
  return era * 146097 + doe - 719468
end

---Whole days from date `a` to date `b` (positive when `b` is later).
---@param a string
---@param b string
---@return integer|nil days  nil when either is not a valid date
function M.days_between(a, b)
  if not (M.is_date(a) and M.is_date(b)) then
    return nil
  end
  return day_number(b) - day_number(a)
end

---Today as `YYYY-MM-DD` (local time).
---@return string
function M.today()
  return os.date("%Y-%m-%d") --[[@as string]]
end

---@param s string
---@return string
local function trim(s)
  return (s:match("^%s*(.-)%s*$"))
end

---The first paragraph of a body: consecutive text lines, skipping blank lines,
---headings, single-line HTML comments and fenced code. Whitespace is collapsed.
---@param body string
---@return string
function M.first_paragraph(body)
  local para = {}
  local in_fence = false
  for line in (body .. "\n"):gmatch("([^\n]*)\n") do
    local t = trim(line)
    if t:match("^```") or t:match("^~~~") then
      in_fence = not in_fence
      if #para > 0 then
        break
      end
    elseif in_fence then
      if #para > 0 then
        break
      end
    elseif t == "" or t:match("^#+%s") or t:match("^<!%-%-.*%-%->$") then
      if #para > 0 then
        break
      end
    else
      para[#para + 1] = t
    end
  end
  return (table.concat(para, " "):gsub("%s+", " "))
end

---@param value any
---@param field string
---@param bad fun(code: string, msg: string)
---@return string|nil
local function as_text(value, field, bad)
  if value == nil then
    return nil
  end
  if type(value) ~= "string" then
    bad("field-type", field .. " must be text")
    return nil
  end
  local t = trim(value)
  return t ~= "" and t or nil
end

---A scalar counts as a one-element list.
---@param value any
---@param field string
---@param bad fun(code: string, msg: string)
---@return string[]
local function as_list(value, field, bad)
  if value == nil then
    return {}
  end
  if type(value) == "string" then
    local t = trim(value)
    return t ~= "" and { t } or {}
  end
  if type(value) == "table" then
    local out = {}
    for _, item in ipairs(value) do
      if type(item) == "string" and trim(item) ~= "" then
        out[#out + 1] = trim(item)
      end
    end
    return out
  end
  bad("field-type", field .. " must be a list")
  return {}
end

---The slug of a task file: the filename without `.md`, and without the
---`YYYY-MM-DD_` prefix `done` gives files in `Backlog/`.
---@param path string
---@param location Tasks.Location
---@return string
function M.slug_of(path, location)
  local name = fsio.norm(path):match("([^/]*)$") or path
  name = name:gsub("%.md$", "")
  if location == "backlog" then
    name = name:gsub("^%d%d%d%d%-%d%d%-%d%d_", "")
  end
  return name
end

---Interpret the text of a task file.
---
---`ctx.path` and `ctx.area` are required; `ctx.location` defaults to
---`"roadmap"`; `ctx.slug` defaults to the one derived from the filename.
---Never raises on bad content.
---@param text string
---@param ctx { path: string, area: string, location?: Tasks.Location, slug?: string, nested?: boolean, folder?: boolean }
---@return Tasks.Task
function M.parse_text(text, ctx)
  local location = ctx.location or "roadmap"
  local slug = ctx.slug or M.slug_of(ctx.path, location)
  local errors, codes, warnings, hints = {}, {}, {}, {}

  ---@param code string
  ---@param msg string
  local function bad(code, msg)
    errors[#errors + 1] = msg
    codes[#codes + 1] = code
  end

  ---@type Tasks.Task
  local task = {
    id = ctx.area .. "/" .. slug,
    area = ctx.area,
    slug = slug,
    path = fsio.norm(ctx.path),
    location = location,
    folder = ctx.folder == true,
    title = slug,
    tags = {},
    category = {},
    blocked_by = {},
    refs = {},
    summary = "",
    meta = {},
    errors = errors,
    error_codes = codes,
    warnings = warnings,
    hints = hints,
    valid = false,
  }

  if not vault.valid_slug(slug) then
    bad("slug", "filename is not a kebab-case ASCII slug: " .. slug)
  end
  if ctx.nested then
    bad(
      "slug",
      "task file must lie directly in tasks/ or be <slug>/<slug>.md, not in another subfolder"
    )
  end

  local parsed, perr = fm.parse(text)
  if not parsed then
    bad("frontmatter-missing", "frontmatter unreadable: " .. tostring(perr))
  elseif not parsed.has_block then
    if parsed.unterminated then
      bad("frontmatter-missing", "frontmatter block is never closed (no closing ---)")
    else
      bad("frontmatter-missing", "no frontmatter block")
    end
  else
    local meta = parsed.meta
    task.meta = meta
    for _, w in ipairs(parsed.warnings) do
      -- A key with an unsupported value is already an error below; its warning
      -- would only say the same thing twice.
      local repeated = false
      for key in pairs(parsed.opaque) do
        if w:find(("key '%s'"):format(key), 1, true) then
          repeated = true
        end
      end
      if not repeated then
        warnings[#warnings + 1] = w
      end
    end
    for key, reason in pairs(parsed.opaque) do
      bad("frontmatter-invalid", ("%s: unsupported value (%s)"):format(key, reason))
    end

    local title = as_text(meta.title, "title", bad)
    if title then
      task.title = title
      local tentry = parsed.by_key.title
      -- A quoted title ends at its closing quote, so a comment after it is a real comment.
      local quoted = tentry and tentry.raw:match("^[^:]*:%s*[\"']") ~= nil
      if tentry and tentry.comment and not quoted then
        -- `title: Fix bug #12` reads "Fix bug": a ` #` starts a YAML comment.
        hints[#hints + 1] = {
          code = "title-comment",
          msg = ("title ends at ' #' (the rest is a YAML comment: '%s'); quote the title if the # belongs to it"):format(
            vim.trim(tentry.comment)
          ),
        }
      end
    elseif meta.title == nil then
      bad("title-missing", "title is missing")
    else
      bad("title-missing", "title is empty")
    end

    local status = as_text(meta.status, "status", bad)
    if status then
      task.status = status
      if not M.is_status(status) then
        bad(
          "unknown-status",
          ("unknown status '%s' (expected %s)"):format(status, table.concat(M.STATUSES, ", "))
        )
      end
    elseif meta.status == nil then
      bad("status-missing", "status is missing")
    end

    local kind = as_text(meta.kind, "kind", bad)
    if kind then
      task.kind = kind
      if not M.is_kind(kind) then
        bad(
          "unknown-kind",
          ("unknown kind '%s' (expected %s)"):format(kind, table.concat(M.KINDS, ", "))
        )
      end
    end

    if meta.prio ~= nil then
      local prio = M.to_prio(meta.prio)
      if prio then
        task.prio = prio
      else
        bad("bad-prio", "prio must be 1, 2 or 3, got " .. vim.inspect(meta.prio))
      end
    end

    local effort = as_text(meta.effort, "effort", bad)
    if effort then
      task.effort = effort
      if not M.is_effort(effort) then
        bad("bad-effort", ("effort '%s' is neither XS..XL nor days like 0.5d"):format(effort))
      end
    end

    task.tags = as_list(meta.tags, "tags", bad)
    task.refs = as_list(meta.refs, "refs", bad)
    task.category = as_list(meta.category, "category", bad)
    for _, c in ipairs(task.category) do
      if not M.is_category(c) then
        bad(
          "unknown-category",
          ("unknown category '%s' (expected %s)"):format(c, table.concat(M.CATEGORIES, ", "))
        )
      end
    end

    for _, field in ipairs({ "created", "updated" }) do
      local date = as_text(meta[field], field, bad)
      if date then
        task[field] = date
        if not M.is_date(date) then
          bad("bad-date", ("%s '%s' is not a date (YYYY-MM-DD)"):format(field, date))
        end
      end
    end

    task.blocked_by = as_list(meta.blocked_by, "blocked_by", bad)
    for _, ref in ipairs(task.blocked_by) do
      local _, ref_slug, id_err = vault.parse_id(ref)
      if id_err or not ref_slug then
        bad("bad-blocked-by", "blocked_by: " .. (id_err or ("expected <area>/<slug>, got " .. ref)))
      end
    end

    if type(meta.done_in) == "table" then
      task.done_in = table.concat(as_list(meta.done_in, "done_in", bad), ", ")
    else
      task.done_in = as_text(meta.done_in, "done_in", bad)
    end

    task.summary = as_text(meta.summary, "summary", bad) or M.first_paragraph(parsed.body)
  end

  task.valid = #errors == 0
  return task
end

---Read and interpret one task file. An unreadable file yields an invalid task
---carrying the read error, never a raise.
---@param path string
---@param ctx { area: string, location?: Tasks.Location, slug?: string, nested?: boolean, folder?: boolean }
---@return Tasks.Task
function M.from_file(path, ctx)
  local full = vim.tbl_extend("force", { path = path }, ctx)
  local text, err = fsio.read(path)
  if not text then
    local task = M.parse_text("", full)
    task.errors = { "cannot read file: " .. tostring(err) }
    task.error_codes = { "unreadable" }
    task.valid = false
    return task
  end
  return M.parse_text(text, full)
end

---@param task Tasks.Task
---@return integer
local function status_rank(task)
  return STATUS_RANK[task.status or ""] or (#M.STATUSES + 1)
end

---Strict ordering: status rank, prio, area, slug, path. Total, so a sort is
---deterministic whatever order the files were found in.
---@param a Tasks.Task
---@param b Tasks.Task
---@return boolean
function M.compare(a, b)
  local ra, rb = status_rank(a), status_rank(b)
  if ra ~= rb then
    return ra < rb
  end
  local pa, pb = a.prio or NO_PRIO_RANK, b.prio or NO_PRIO_RANK
  if pa ~= pb then
    return pa < pb
  end
  if a.area ~= b.area then
    return a.area < b.area
  end
  if a.slug ~= b.slug then
    return a.slug < b.slug
  end
  return a.path < b.path
end

---Sort in place and return the list.
---@param tasks Tasks.Task[]
---@return Tasks.Task[]
function M.sort(tasks)
  table.sort(tasks, M.compare)
  return tasks
end

---@param value any
---@return table<any, boolean>|nil set
local function to_set(value)
  if value == nil then
    return nil
  end
  local set = {}
  if type(value) == "table" then
    for _, v in ipairs(value) do
      set[v] = true
    end
  else
    set[value] = true
  end
  return set
end

---@param task Tasks.Task
---@param today string
---@param days integer
---@return boolean
local function is_stale(task, today, days)
  local last = task.updated or task.created
  if not last then
    return true
  end
  local age = M.days_between(last, today)
  return age == nil or age >= days
end

---Split a comma list (`doing, decision`) into trimmed, non-empty items.
---@param s string
---@return string[]
function M.split_commas(s)
  local out = {}
  for item in s:gmatch("[^,]+") do
    local t = trim(item)
    if t ~= "" then
      out[#out + 1] = t
    end
  end
  return out
end

---Turn the textual filter options of a front end (`--status=a,b`, `--prio=<=2`,
---`--kind`, `--tag`, `--stale=<days>`, `--blocked`) into a `Tasks.Filter`.
---Shared by the headless CLI and the editor commands so both read the same
---words the same way. Unknown words are an error, never silently ignored.
---`stale` may be a number or a digit string; `today` is passed through.
---@param opt { status?: string, prio?: string|integer, kind?: string, tag?: string, category?: string, stale?: string|integer, blocked?: boolean, today?: string }
---@return Tasks.Filter|nil filter
---@return string|nil err
function M.filter_from_options(opt)
  ---@type Tasks.Filter
  local f = { today = opt.today }
  if opt.status then
    f.status = M.split_commas(opt.status)
    for _, s in ipairs(f.status) do
      if not M.is_status(s) then
        return nil, "unknown status in --status: " .. s
      end
    end
  end
  if opt.prio ~= nil then
    local raw = tostring(opt.prio)
    local max = raw:match("^<=(%d)$")
    if max then
      f.prio_max = tonumber(max)
    else
      f.prio = {}
      for _, p in ipairs(M.split_commas(raw)) do
        local n = M.to_prio(p)
        if not n then
          return nil, "--prio must be 1, 2, 3 (comma list) or <=N, got " .. raw
        end
        f.prio[#f.prio + 1] = n
      end
    end
  end
  if opt.kind then
    f.kind = M.split_commas(opt.kind)
    for _, k in ipairs(f.kind) do
      if not M.is_kind(k) then
        return nil, "unknown kind in --kind: " .. k
      end
    end
  end
  if opt.tag then
    f.tag = M.split_commas(opt.tag)
  end
  if opt.category then
    f.category = M.split_commas(opt.category)
    for _, c in ipairs(f.category) do
      if not M.is_category(c) then
        return nil, "unknown category in --category: " .. c
      end
    end
  end
  if opt.stale ~= nil then
    local raw = tostring(opt.stale)
    if not raw:match("^%d+$") then
      return nil, ("--stale must be a whole number, got '%s'"):format(raw)
    end
    f.stale = tonumber(raw)
  end
  if opt.blocked then
    f.blocked = true
  end
  return f, nil
end

---Keep the tasks matching every given criterion. Does not reorder.
---@param tasks Tasks.Task[]
---@param f? Tasks.Filter
---@return Tasks.Task[]
function M.filter(tasks, f)
  f = f or {}
  local status, kind, area = to_set(f.status), to_set(f.kind), to_set(f.area)
  local prio, tag = to_set(f.prio), to_set(f.tag)
  local category = to_set(f.category)
  local today = f.today or M.today()

  local out = {}
  for _, t in ipairs(tasks) do
    local keep = true
    if status and not (t.status and status[t.status]) then
      keep = false
    elseif kind and not (t.kind and kind[t.kind]) then
      keep = false
    elseif area and not area[t.area] then
      keep = false
    elseif prio and not (t.prio and prio[t.prio]) then
      keep = false
    elseif f.prio_max and not (t.prio and t.prio <= f.prio_max) then
      keep = false
    elseif tag then
      keep = false
      for _, name in ipairs(t.tags) do
        if tag[name] then
          keep = true
          break
        end
      end
    end
    if keep and category then
      keep = false
      for _, c in ipairs(M.categories(t)) do
        if category[c] then
          keep = true
          break
        end
      end
    end
    if keep and f.blocked and not (t.status == "blocked" or #t.blocked_by > 0) then
      keep = false
    end
    if keep and f.stale and not is_stale(t, today, f.stale) then
      keep = false
    end
    if keep then
      out[#out + 1] = t
    end
  end
  return out
end

return M
