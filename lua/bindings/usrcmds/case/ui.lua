---@module 'bindings.usrcmds.case.ui'
--- All the kit.* wiring: :Case new's prompt chain + dry-run + confirm, the
--- infocard view/edit, and the smaller flows (open/add/copy/sync/close/
--- snow). init.lua only maps composer routes onto these functions.

local kit = require("lib.nvim.ui.kit")
local notify = require("lib.nvim.notify").create("[usrcmds.case]")
local fs_is_valid_filename = require("lib.nvim.fs.is_valid_filename")
local mkdirp = require("lib.nvim.fs.mkdirp")
local write_to_file = require("lib.nvim.fs.write.to_file")
local read = require("lib.nvim.fs.read")

local config = require("bindings.usrcmds.case.config")
local render = require("bindings.usrcmds.case.render")
local registry = require("bindings.usrcmds.case.registry")
local meta = require("bindings.usrcmds.case.meta")
local detect = require("bindings.usrcmds.case.detect")
local blueprint = require("bindings.usrcmds.case.blueprint")
local plan = require("bindings.usrcmds.case.plan")
local apply = require("bindings.usrcmds.case.apply")
local resolve = require("bindings.usrcmds.case.resolve")

local uv = vim.uv or vim.loop

local M = {}

---@param path string
local function edit(path)
  vim.cmd("edit " .. vim.fn.fnameescape(path))
end

-- ── :Case new ────────────────────────────────────────────────────────────

---@param case_arg string|nil
function M.new(case_arg)
  local function with_case(short)
    if not fs_is_valid_filename(short) then
      notify.error("invalid case number: " .. tostring(short))
      return
    end
    if registry.exists(short) then
      notify.warn(("case %s already exists — use :Case sync to add missing pieces"):format(short))
      return
    end

    kit.form({
      fields = {
        { name = "title", label = "Title", required = true },
        { name = "company", label = "Company" },
        { name = "name", label = "Name" },
      },
      on_submit = function(values)
        M.create(short, values.title, values.company, values.name)
      end,
    })
  end

  if case_arg and case_arg ~= "" then
    with_case(render.to_short(case_arg))
  else
    kit.input({
      prompt = "Case number",
      on_submit = with_case,
    })
  end
end

---@param short string
---@param title string
---@param company string|nil
---@param name string|nil
function M.create(short, title, company, name)
  local dir = registry.new_dir(short)
  local year = os.date("%Y")
  local tokens = {
    case = short,
    title = title,
    company = (company and company ~= "") and company or nil,
    name = (name and name ~= "") and name or nil,
    year = year,
    snow = render.to_snow(short, year),
  }

  local nodes = blueprint.get(config.default_blueprint)
  local actions = plan.build(dir, nodes, tokens)

  kit.viewer({
    title = ("New case %s"):format(short),
    lines = plan.describe(actions),
  })

  kit.confirm({
    question = ("Create case %s?"):format(short),
    on_answer = function(yes)
      if not yes then
        return
      end
      local results, opens = apply.run(actions)
      local ok, errs = apply.errors(results)

      meta.write(dir, {
        case = short,
        year = year,
        title = title,
        company = tokens.company,
        name = tokens.name,
        notes = "",
        links = {},
        blueprint = config.default_blueprint,
        created = os.date("!%Y-%m-%dT%H:%M:%SZ"),
      })

      registry.invalidate()

      if ok then
        notify.info(("case %s created"):format(short))
      else
        notify.error(("case %s created with errors:\n%s"):format(short, table.concat(errs, "\n")))
      end

      for _, path in ipairs(opens) do
        edit(path)
      end
    end,
  })
end

-- ── :Case info ───────────────────────────────────────────────────────────

---@param entry Lib.Case.RegistryEntry
---@param m Lib.Case.Meta|nil
---@return string[]
local function infocard_lines(entry, m)
  m = m or {}
  local lines = {
    ("Case      %s%s"):format(entry.short, m.year and (" (%s)"):format(render.to_snow_display(entry.short, m.year)) or ""),
    ("State     %s"):format(entry.state),
    ("Title     %s"):format(m.title or "—"),
    ("Company   %s"):format(m.company or "—"),
    ("Name      %s"):format(m.name or "—"),
    ("Notes     %s"):format((m.notes and m.notes ~= "") and m.notes or "—"),
    ("Links     %d"):format(m.links and #m.links or 0),
    "",
    "e edit · o open folder · s summary · q close",
  }
  return lines
end

---@param case_arg string|nil
function M.info(case_arg)
  resolve.pick(case_arg, function(entry)
    if not entry then
      notify.warn("no case to show")
      return
    end
    local m = meta.read(entry.dir)

    local surf = kit.viewer({
      title = ("Case %s"):format(entry.short),
      lines = infocard_lines(entry, m),
    })
    if not surf then
      return
    end

    local map = require("lib.nvim.map")
    local mo = { buffer = surf.bufnr, nowait = true }
    map("n", "e", function()
      surf:close()
      M.edit_info(entry, m)
    end, mo)
    map("n", "s", function()
      surf:close()
      M.open_summary(entry.short)
    end, mo)
    map("n", "o", function()
      surf:close()
      M.open_dir(entry.short)
    end, mo)
  end)
end

---@param entry Lib.Case.RegistryEntry
---@param m Lib.Case.Meta|nil
function M.edit_info(entry, m)
  m = m or {}
  local guess = detect.guess(entry.dir)

  kit.form({
    fields = {
      { name = "title", label = "Title", default = m.title or guess.title or "" },
      { name = "company", label = "Company", default = m.company or "" },
      { name = "name", label = "Name", default = m.name or guess.name or "" },
      { name = "notes", label = "Notes", default = m.notes or "" },
    },
    on_submit = function(values)
      local links = m.links
      if not links or #links == 0 then
        links = guess.links
      end
      local ok, err = meta.write(entry.dir, {
        case = entry.short,
        year = m.year or os.date("%Y"),
        title = values.title,
        company = (values.company ~= "") and values.company or nil,
        name = (values.name ~= "") and values.name or nil,
        notes = values.notes,
        links = links,
        blueprint = m.blueprint or config.default_blueprint,
        created = m.created or os.date("!%Y-%m-%dT%H:%M:%SZ"),
      })
      if ok then
        notify.info(("case %s updated"):format(entry.short))
        M.info(entry.short)
      else
        notify.error("meta write failed: " .. tostring(err))
      end
    end,
  })
end

-- ── file-verbs (summary/research/reply/... generated from blueprint keys) ─

---@param short string
---@return string|nil
local function newest_reply(dir)
  local replies_dir = dir .. "/Replies"
  if not (uv.fs_stat(replies_dir) and uv.fs_stat(replies_dir).type == "directory") then
    return nil
  end
  local newest, newest_mtime = nil, -1
  local fd = uv.fs_scandir(replies_dir)
  if not fd then
    return nil
  end
  while true do
    local name, typ = uv.fs_scandir_next(fd)
    if not name then
      break
    end
    if typ == "file" then
      local full = replies_dir .. "/" .. name
      local st = uv.fs_stat(full)
      local mtime = st and st.mtime and st.mtime.sec or 0
      if mtime > newest_mtime then
        newest, newest_mtime = full, mtime
      end
    end
  end
  return newest
end

---@param node Lib.Case.BlueprintNode
---@param case_arg string|nil
function M.open_node(node, case_arg)
  resolve.pick(case_arg, function(entry)
    if not entry then
      notify.warn("no case to open " .. node.key .. " for")
      return
    end
    local path = entry.dir .. "/" .. node.path
    if node.key == "reply" then
      path = newest_reply(entry.dir) or path
    end
    if not uv.fs_stat(path) then
      notify.warn(("%s does not exist yet in case %s — run :Case sync"):format(node.path, entry.short))
      return
    end
    edit(path)
  end)
end

function M.open_summary(case_arg)
  M.open_node({ key = "summary", path = "Summary.md" }, case_arg)
end

-- ── :Case open ───────────────────────────────────────────────────────────

---@param case_arg string|nil
function M.open_dir(case_arg)
  resolve.pick(case_arg, function(entry)
    if not entry then
      notify.warn("no case to open")
      return
    end
    local ok_ft, filetree = pcall(require, "filetree")
    if ok_ft and type(filetree.reveal) == "function" then
      pcall(filetree.reveal, entry.dir)
      return
    end
    edit(entry.dir)
  end)
end

-- ── :Case add ────────────────────────────────────────────────────────────

---@param name string
---@param case_arg string|nil
function M.add(name, case_arg)
  resolve.pick(case_arg, function(entry)
    if not entry then
      notify.warn("no case to add to")
      return
    end

    if name == "reply" then
      local replies_dir = entry.dir .. "/Replies"
      mkdirp(replies_dir)
      local max_n = -1
      local fd = uv.fs_scandir(replies_dir)
      if fd then
        while true do
          local fname = uv.fs_scandir_next(fd)
          if not fname then
            break
          end
          local n = fname:match("^(%d+)_")
          if n then
            max_n = math.max(max_n, tonumber(n))
          end
        end
      end
      local next_n = ("%02d"):format(max_n + 1)
      local filename = next_n .. "_Reply.md"
      local full = replies_dir .. "/" .. filename
      local m = meta.read(entry.dir)
      local lines = { render.headline(entry.short, m and m.title, next_n .. "_Reply"), "" }
      local ok, err = write_to_file(full, table.concat(lines, "\n"))
      if not ok then
        notify.error("add reply failed: " .. tostring(err))
        return
      end
      edit(full)
      return
    end

    local ok_name, err_name = fs_is_valid_filename(name .. ".md")
    if not ok_name then
      notify.error("invalid file name: " .. tostring(err_name))
      return
    end
    local full = entry.dir .. "/" .. name .. ".md"
    if uv.fs_stat(full) then
      notify.warn(full .. " already exists")
      edit(full)
      return
    end
    local m = meta.read(entry.dir)
    local lines = { render.headline(entry.short, m and m.title, name), "" }
    local ok, err = write_to_file(full, table.concat(lines, "\n"))
    if not ok then
      notify.error("add failed: " .. tostring(err))
      return
    end
    edit(full)
  end)
end

-- ── :Case copy ───────────────────────────────────────────────────────────

---@param src string|nil
---@param case_arg string|nil
function M.copy(src, case_arg)
  resolve.pick(case_arg, function(entry)
    if not entry then
      notify.warn("no case to copy into")
      return
    end

    local function with_src(source)
      if not source or source == "" then
        return
      end
      source = vim.fn.expand(source)
      if not uv.fs_stat(source) then
        notify.error("source does not exist: " .. source)
        return
      end

      kit.select({
        message = "Target folder",
        selection = { "Replies", "Research", "Ressources", "." },
        format_item = function(s)
          return s == "." and "(case root)" or s
        end,
        on_select = function(target)
          local dest_dir = target == "." and entry.dir or (entry.dir .. "/" .. target)
          mkdirp(dest_dir)
          local dest = dest_dir .. "/" .. vim.fn.fnamemodify(source, ":t")
          local content, rerr = read(source)
          if not content then
            notify.error("copy read failed: " .. tostring(rerr))
            return
          end
          local ok, werr = write_to_file(dest, content)
          if not ok then
            notify.error("copy write failed: " .. tostring(werr))
            return
          end
          notify.info("copied to " .. dest)
          edit(dest)
        end,
      })
    end

    if src and src ~= "" then
      with_src(src)
    else
      kit.input({ prompt = "Source file", completion = "file", on_submit = with_src })
    end
  end)
end

-- ── :Case sync ───────────────────────────────────────────────────────────

---@param case_arg string|nil
function M.sync(case_arg)
  resolve.pick(case_arg, function(entry)
    if not entry then
      notify.warn("no case to sync")
      return
    end
    local m = meta.read(entry.dir)
    local nodes = blueprint.get(m and m.blueprint or config.default_blueprint)
    local tokens = {
      case = entry.short,
      title = m and m.title,
      company = m and m.company,
      name = m and m.name,
      year = m and m.year or os.date("%Y"),
    }
    local actions = plan.build(entry.dir, nodes, tokens)

    local missing = {}
    for _, a in ipairs(actions) do
      if a.kind ~= "skip" then
        missing[#missing + 1] = a
      end
    end
    if #missing == 0 then
      notify.info(("case %s already has the full blueprint"):format(entry.short))
      return
    end

    kit.viewer({ title = "Sync " .. entry.short, lines = plan.describe(missing) })
    kit.confirm({
      question = ("Add %d missing item(s) to %s?"):format(#missing, entry.short),
      on_answer = function(yes)
        if not yes then
          return
        end
        local results, _ = apply.run(missing)
        local ok, errs = apply.errors(results)
        registry.invalidate()
        if ok then
          notify.info(("case %s synced"):format(entry.short))
        else
          notify.error("sync errors:\n" .. table.concat(errs, "\n"))
        end
      end,
    })
  end)
end

-- ── moving a case between states (:Case close / :Case reassign / ...) ────

--- The general primitive behind every generated state-move verb (init.lua
--- builds one per non-default entry in config.states, using
--- config.state_verbs for the command name). The case's state IS the
--- folder it's in (MIGRATION.md §1), so this is a plain rename — no
--- `status` field to keep in sync.
---@param case_arg string|nil
---@param state string  One of config.states.
function M.move_state(case_arg, state)
  resolve.pick(case_arg, function(entry)
    if not entry then
      notify.warn("no case to move")
      return
    end
    if entry.state == state then
      notify.warn(("%s is already %s"):format(entry.short, state))
      return
    end

    kit.confirm({
      question = ("Move case %s to %s?"):format(entry.short, state),
      on_answer = function(yes)
        if not yes then
          return
        end
        mkdirp(config.state_dir(state))
        local dest = config.state_dir(state) .. "/" .. entry.short
        local ok, err = uv.fs_rename(entry.dir, dest)
        if not ok then
          notify.error(("move to %s failed: %s"):format(state, tostring(err)))
          return
        end
        registry.invalidate()
        notify.info(("case %s moved to %s"):format(entry.short, state))
      end,
    })
  end)
end


-- ── :Case snow ───────────────────────────────────────────────────────────

---@param case_arg string|nil
function M.snow(case_arg)
  resolve.pick(case_arg, function(entry)
    if not entry then
      notify.warn("no case to open the ticket for")
      return
    end
    local m = meta.read(entry.dir)
    local year = m and m.year or os.date("%Y")
    local snow = render.to_snow(entry.short, year)

    if config.snow_url_format then
      local ok = require("lib.nvim.cross.open_default")(config.snow_url_format .. snow)
      if not ok then
        notify.error("could not open " .. snow)
      end
    else
      require("lib.nvim.cross.copy_to_clipboard")(snow)
      notify.info(snow .. " copied to clipboard (set config.snow_url_format to open it directly)")
    end
  end)
end

-- ── :Cases — field filters & listing ──────────────────────────────────────

local query = require("bindings.usrcmds.case.query")

---@param results Lib.Case.RegistryEntry[]
---@param label string
local function show_results(results, label)
  if #results == 0 then
    notify.warn(label .. ": no matches")
    return
  end
  if #results == 1 then
    M.info(results[1].short)
    return
  end
  kit.select({
    message = ("%s (%d)"):format(label, #results),
    selection = results,
    format_item = function(e)
      local m = meta.read(e.dir)
      local title = m and m.title
      return title and ("%s [%s] — %s"):format(e.short, e.state, title) or ("%s [%s]"):format(e.short, e.state)
    end,
    on_select = function(item)
      M.info(item.short)
    end,
    on_cancel = function() end,
  })
end

--- `:Cases <field> [pattern]` — one route per config.infocard_fields entry,
--- generated in init.lua. A single hit opens its infocard directly (the
--- search WAS the selection); several go through the same kit.select every
--- other multi-result flow in this module uses.
---@param field string
---@param pattern string|nil
function M.filter(field, pattern)
  local results = query.by_field(field, pattern)
  show_results(results, ("%s = %s"):format(field, (pattern and pattern ~= "") and pattern or "*"))
end

--- `:Cases list` — everything, grouped by state.
function M.list_all()
  local groups = query.by_state()
  local lines = {}
  for _, state in ipairs(config.states) do
    local entries = groups[state] or {}
    lines[#lines + 1] = ("%s (%d)"):format(state, #entries)
    for _, e in ipairs(entries) do
      local m = meta.read(e.dir)
      lines[#lines + 1] = ("  %-10s %s"):format(e.short, (m and m.title) or "")
    end
    lines[#lines + 1] = ""
  end
  kit.viewer({ title = "Cases", lines = lines })
end

--- `:Cases find company=Scan year=2026` — AND-combination across several
--- `config.infocard_fields` at once, via composer's `kv` grammar.
---@param kv table<string, string>
function M.filter_many(kv)
  local parts = {}
  for k, v in pairs(kv) do
    parts[#parts + 1] = ("%s=%s"):format(k, v)
  end
  table.sort(parts)
  local label = #parts > 0 and table.concat(parts, " ") or "find (no criteria given)"
  show_results(query.by_fields(kv), label)
end

--- `:Cases recent [n]` — most recently touched cases first.
---@param n_arg string|nil
function M.recent(n_arg)
  local n = tonumber(n_arg) or 10
  local rows = query.recent(n)
  if #rows == 0 then
    notify.warn("no cases with detectable activity")
    return
  end
  kit.select({
    message = ("Recent (%d)"):format(#rows),
    selection = rows,
    format_item = function(row)
      local m = meta.read(row.entry.dir)
      return ("%s  %-10s %s"):format(os.date("%Y-%m-%d", row.mtime), row.entry.short, (m and m.title) or "")
    end,
    on_select = function(item)
      M.info(item.entry.short)
    end,
    on_cancel = function() end,
  })
end

--- `:Cases stats` — counts by state / company / year.
function M.stats()
  local s = query.stats()
  local lines = { "By state:" }
  for _, state in ipairs(config.states) do
    lines[#lines + 1] = ("  %-14s %d"):format(state, s.by_state[state] or 0)
  end

  lines[#lines + 1] = ""
  lines[#lines + 1] = "By company:"
  local companies = {}
  for c in pairs(s.by_company) do
    companies[#companies + 1] = c
  end
  table.sort(companies)
  for _, c in ipairs(companies) do
    lines[#lines + 1] = ("  %-20s %d"):format(c, s.by_company[c])
  end

  lines[#lines + 1] = ""
  lines[#lines + 1] = "By year:"
  local years = {}
  for y in pairs(s.by_year) do
    years[#years + 1] = y
  end
  table.sort(years)
  for _, y in ipairs(years) do
    lines[#lines + 1] = ("  %-8s %d"):format(y, s.by_year[y])
  end

  kit.viewer({ title = "Cases — stats", lines = lines })
end

--- `:Cases doctor` — read-only bestand-consistency report (MIGRATION.md §4).
function M.doctor()
  local doctor = require("bindings.usrcmds.case.doctor")
  local findings = doctor.check()
  kit.viewer({
    title = ("Cases — doctor (%d)"):format(#findings),
    lines = doctor.describe(findings),
  })
end

return M
