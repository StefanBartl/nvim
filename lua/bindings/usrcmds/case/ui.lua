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
local collect_recursive = require("lib.nvim.fs.collect_recursive")

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
    today = os.date("%Y-%m-%d"),
    snow = render.to_snow(short, year),
  }

  -- ROADMAP.md v7: a company can be routed to its own blueprint; unmapped
  -- (the common case today — the table starts empty) falls through to the
  -- same default every case has always used.
  local blueprint_name = (tokens.company and config.company_blueprints[tokens.company]) or config.default_blueprint
  local nodes = blueprint.get(blueprint_name)
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
        blueprint = blueprint_name,
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
    ("Priority  %s"):format(m.priority or "—"),
    ("Tosca Ver %s"):format(m.tosca_version or "—"),
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
      { name = "priority", label = "Priority", default = m.priority or "" },
      { name = "tosca_version", label = "Tosca-Version", default = m.tosca_version or "" },
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
        priority = (values.priority ~= "") and values.priority or nil,
        tosca_version = (values.tosca_version ~= "") and values.tosca_version or nil,
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

-- ── :Case reply check ────────────────────────────────────────────────────

--- `:Case reply check` — the pre-send gate (ROADMAP.md v8): emoji count,
--- stray markdown headlines (a plain-text reply shouldn't carry `##`, same
--- reasoning as `doctor.lua`'s `summary-markdown` check), dead links, and a
--- native spellcheck launched on request.
---
--- Operates on the CURRENT buffer — not "the case's newest reply" via
--- `resolve.pick`, deliberately: the point is checking what's on screen
--- right now, whatever that is (a reply, but nothing stops it running on
--- Notes.md too).
function M.reply_check()
  local replygate = require("bindings.usrcmds.case.replygate")
  local bufnr = vim.api.nvim_get_current_buf()

  notify.info("checking reply…")
  replygate.check(bufnr, function(report)
    vim.schedule(function()
      local lines = {}

      if report.emoji_count == nil then
        lines[#lines + 1] = "Emojis      (emojis.nvim not installed, skipped)"
      elseif report.emoji_count > 0 then
        lines[#lines + 1] = ("Emojis      %d found — press 'c' to remove"):format(report.emoji_count)
      else
        lines[#lines + 1] = "Emojis      none"
      end

      if #report.headline_lines > 0 then
        lines[#lines + 1] =
          ("Headlines   markdown heading on line(s): %s"):format(table.concat(report.headline_lines, ", "))
      else
        lines[#lines + 1] = "Headlines   none"
      end

      if #report.link_results == 0 then
        lines[#lines + 1] = "Links       none found"
      else
        local dead = 0
        for _, r in ipairs(report.link_results) do
          if r.status == "dead" then
            dead = dead + 1
          end
        end
        lines[#lines + 1] = ("Links       %d checked, %d dead"):format(#report.link_results, dead)
        for _, r in ipairs(report.link_results) do
          if r.status ~= "alive" then
            lines[#lines + 1] = ("  %-4s %s (%s)"):format(r.status, r.url, r.detail)
          end
        end
      end

      lines[#lines + 1] = ""
      lines[#lines + 1] = "s: run spellcheck on this buffer (language.nvim) · q: close"

      local surf = kit.viewer({ title = "Reply check", lines = lines })
      if not surf then
        return
      end

      local map = require("lib.nvim.map")
      local mo = { buffer = surf.bufnr, nowait = true }
      if report.emoji_count and report.emoji_count > 0 then
        map("n", "c", function()
          surf:close()
          local removed, err = replygate.clear_emojis(bufnr)
          if removed then
            notify.info(("removed %d emoji(s)"):format(removed))
          else
            notify.error("could not clear emojis: " .. tostring(err))
          end
        end, mo)
      end
      map("n", "s", function()
        surf:close()
        local ok_lang, language = pcall(require, "language")
        if not ok_lang then
          notify.warn("language.nvim not installed")
          return
        end
        vim.api.nvim_set_current_buf(bufnr)
        language.spellcheck(nil, "buffer")
      end, mo)
    end)
  end)
end

-- ── :Case add ────────────────────────────────────────────────────────────

--- "Scan the folder, take the highest `NN_` already there, +1" — the rule
--- behind every auto-numbered file this module creates (Replies/ here,
--- Research/ for `M.activity`). Zero-padded to 2 digits, matching every
--- existing `NN_` file in the bestand.
---@param dir string
---@return string
local function next_nn_prefix(dir)
  local max_n = -1
  local fd = uv.fs_scandir(dir)
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
  return ("%02d"):format(max_n + 1)
end

---@param name string
---@param suffix string|nil  For `name == "reply"`: overrides the "Reply" stem
---  (e.g. "AskForPDF" -> "NN_AskForPDF.md"). Ignored otherwise.
---@param case_arg string|nil
function M.add(name, suffix, case_arg)
  resolve.pick(case_arg, function(entry)
    if not entry then
      notify.warn("no case to add to")
      return
    end

    if name == "reply" then
      local replies_dir = entry.dir .. "/Replies"
      mkdirp(replies_dir)
      local stem = (suffix and suffix ~= "") and suffix or "Reply"
      local ok_name, err_name = fs_is_valid_filename(stem .. ".md")
      if not ok_name then
        notify.error("invalid reply name: " .. tostring(err_name))
        return
      end
      local next_n = next_nn_prefix(replies_dir)
      local filename = next_n .. "_" .. stem .. ".md"
      local full = replies_dir .. "/" .. filename
      local m = meta.read(entry.dir)
      local lines = { render.headline(entry.short, m and m.title, next_n .. "_" .. stem), "" }
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

-- ── :Case activity ───────────────────────────────────────────────────────

--- Paste the system clipboard — a ServiceNow Activity Stream, typically —
--- into a new numbered Research/ file. Clipboard rather than a prompt: the
--- point is copy-in-SNOW, run-the-command, nothing retyped.
---@param case_arg string|nil
function M.activity(case_arg)
  resolve.pick(case_arg, function(entry)
    if not entry then
      notify.warn("no case to add the activity stream to")
      return
    end
    local content = vim.fn.getreg("+")
    if not content or vim.trim(content) == "" then
      notify.warn("clipboard is empty")
      return
    end
    local research_dir = entry.dir .. "/Research"
    mkdirp(research_dir)
    local next_n = next_nn_prefix(research_dir)
    local stem = next_n .. "_ActivityStream"
    local full = research_dir .. "/" .. stem .. ".md"
    local m = meta.read(entry.dir)
    local lines = { render.headline(entry.short, m and m.title, stem), "", content }
    local ok, err = write_to_file(full, table.concat(lines, "\n"))
    if not ok then
      notify.error("activity stream write failed: " .. tostring(err))
      return
    end
    notify.info("activity stream saved: " .. stem .. ".md")
    edit(full)
  end)
end

-- ── :Wkd links ───────────────────────────────────────────────────────────

--- `:Wkd links [scope]` — every link across the work repo (or one area of
--- it), picked and opened externally. Supersedes hand-maintaining
--- `Notes/Links.md`: this reads what's already written everywhere else
--- instead of asking you to copy it a second time.
---@param scope string|nil
function M.wkd_links(scope)
  local links = require("bindings.usrcmds.case.links")
  local hits = links.find(scope)
  if #hits == 0 then
    notify.warn(("no links found%s"):format(scope and scope ~= "" and (" in " .. scope) or ""))
    return
  end

  kit.select({
    message = ("Links%s (%d)"):format(scope and scope ~= "" and (" — " .. scope) or "", #hits),
    selection = hits,
    format_item = function(h)
      local rel = h.path:sub(#config.repo_root + 2)
      return ("[%s] %s:%d  %s"):format(h.area, rel, h.line, h.url)
    end,
    on_select = function(h)
      local ok = require("lib.nvim.cross.open_default")(h.url)
      if not ok then
        require("lib.nvim.cross.copy_to_clipboard")(h.url)
        notify.info(h.url .. " copied to clipboard (could not open a browser)")
      end
    end,
    on_cancel = function() end,
  })
end

-- ── :Case template ───────────────────────────────────────────────────────

--- `:Case template [name]` — insert a reply block from the work repo's
--- `Workflow/Templates/` at the cursor. Tokens are filled from the case the
--- current buffer belongs to, so a block that says `{name}` arrives
--- addressed; blocks that use `_____` blanks (most of them today) come
--- through untouched for you to fill in.
---
--- Inserts into whatever buffer is focused rather than resolving a case
--- first: the point is "I'm writing this reply right now, give me the
--- boilerplate". A case only has to resolve for the token values, and not
--- resolving one is fine — the block still goes in.
---@param name_arg string|nil  Exact block name (as listed); prompts when omitted.
function M.template(name_arg)
  local blocks = require("bindings.usrcmds.case.blocks")
  local available = blocks.list()
  if #available == 0 then
    notify.warn("no reply blocks found in " .. config.workflow_templates_dir)
    return
  end

  local entry = resolve.sync(nil)
  local m = entry and meta.read(entry.dir) or nil
  local tokens = {
    case = entry and entry.short or nil,
    title = m and m.title or nil,
    company = m and m.company or nil,
    name = m and m.name or nil,
    year = m and m.year or os.date("%Y"),
    today = os.date("%Y-%m-%d"),
  }
  if entry then
    tokens.snow = render.to_snow(entry.short, tokens.year)
  end

  local function insert(block)
    local lines, err = blocks.render(block, tokens)
    if not lines then
      notify.error("could not read block: " .. tostring(err))
      return
    end
    local row = vim.api.nvim_win_get_cursor(0)[1]
    vim.api.nvim_buf_set_lines(0, row, row, false, lines)
    notify.info(("inserted %s (%d lines)"):format(block.name, #lines))
  end

  if name_arg and name_arg ~= "" then
    for _, b in ipairs(available) do
      if b.name == name_arg then
        insert(b)
        return
      end
    end
    notify.warn("unknown reply block: " .. name_arg)
    return
  end

  kit.select({
    message = ("Reply blocks (%d)"):format(#available),
    selection = available,
    format_item = function(b)
      return b.name
    end,
    on_select = insert,
    on_cancel = function() end,
  })
end

-- ── :Case similar ────────────────────────────────────────────────────────

--- `:Case similar [nr] [n]` — past cases whose title+Summary.md share the
--- most distinctive vocabulary with this one (ROADMAP.md v8). The matched
--- terms are shown alongside each hit precisely because the ranking is
--- lexical: seeing WHY something matched is what tells you whether the hit
--- is real or a coincidence of shared jargon.
---@param case_arg string|nil
---@param n_arg string|nil
function M.similar(case_arg, n_arg)
  resolve.pick(case_arg, function(entry)
    if not entry then
      notify.warn("no case to compare")
      return
    end
    local similar = require("bindings.usrcmds.case.similar")
    local hits, err = similar.rank(entry.short, tonumber(n_arg) or 5)
    if err then
      notify.warn(err)
      return
    end
    if #hits == 0 then
      notify.info(("no case shares distinctive terms with %s"):format(entry.short))
      return
    end
    kit.select({
      message = ("Similar to %s (%d)"):format(entry.short, #hits),
      selection = hits,
      format_item = function(hit)
        local m = meta.read(hit.entry.dir)
        return ("%3d%%  %-10s %-34s %s"):format(
          math.floor(hit.score * 100 + 0.5),
          hit.entry.short,
          ((m and m.title) or ""):sub(1, 34),
          table.concat(hit.terms, ", ")
        )
      end,
      on_select = function(hit)
        M.info(hit.entry.short)
      end,
      on_cancel = function() end,
    })
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
      today = os.date("%Y-%m-%d"),
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
        -- mutate.rename_file, not a bare uv.fs_rename: a Windows directory
        -- watcher (neo-tree's leaked fs_event handles are the known
        -- offender) can hold a transient lock on the case folder being
        -- moved — see normalize.lua's identical reasoning.
        local ok, err = require("lib.nvim.cross.fs.mutate").rename_file(entry.dir, dest)
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

---@param flags { exact: boolean|nil, re: boolean|nil }|nil
---@return string
local function flag_suffix(flags)
  if flags and flags.exact then
    return " [exact]"
  end
  if flags and flags.re then
    return " [re]"
  end
  return ""
end

--- `:Cases <field> [pattern] [--exact|-e] [--re|-r]` — one route per
--- config.infocard_fields entry, generated in init.lua. A single hit opens
--- its infocard directly (the search WAS the selection); several go through
--- the same kit.select every other multi-result flow in this module uses.
---@param field string
---@param pattern string|nil
---@param flags { exact: boolean|nil, re: boolean|nil }|nil
function M.filter(field, pattern, flags)
  local results = query.by_field(field, pattern, flags)
  local label = ("%s = %s%s"):format(field, (pattern and pattern ~= "") and pattern or "*", flag_suffix(flags))
  show_results(results, label)
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

--- `:Cases find company=Scan year=2026 [--exact|-e] [--re|-r]` —
--- AND-combination across several `config.infocard_fields` at once, via
--- composer's `kv` grammar.
---@param kv table<string, string>
---@param flags { exact: boolean|nil, re: boolean|nil }|nil
function M.filter_many(kv, flags)
  local parts = {}
  for k, v in pairs(kv) do
    parts[#parts + 1] = ("%s=%s"):format(k, v)
  end
  table.sort(parts)
  local label = (#parts > 0 and table.concat(parts, " ") or "find (no criteria given)") .. flag_suffix(flags)
  show_results(query.by_fields(kv, flags), label)
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

--- `:Cases stale [days]` — open cases untouched for at least `days` (default
--- 7), oldest first.
---@param days_arg string|nil
function M.stale(days_arg)
  local days = tonumber(days_arg) or 7
  local rows = query.stale(days)
  if #rows == 0 then
    notify.info(("no open case has been idle %d+ days"):format(days))
    return
  end
  kit.select({
    message = ("Stale %d+ days (%d)"):format(days, #rows),
    selection = rows,
    format_item = function(row)
      local m = meta.read(row.entry.dir)
      return ("%3d d idle  %-10s %s"):format(row.days_idle, row.entry.short, (m and m.title) or "")
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

local GREP_HIT_CAP = 500

--- `:Cases grep <pattern> [--re|-r]` — full-text search across every case's
--- markdown files. Report-shaped like doctor/stats (kit.viewer), not a
--- picker — a grep result set is read top-to-bottom, not picked from.
---@param pattern string|nil
---@param flags { re: boolean|nil }|nil
function M.grep(pattern, flags)
  if not pattern or pattern == "" then
    notify.warn("grep: pattern required")
    return
  end
  local hits = query.grep(pattern, flags)
  local lines
  if #hits == 0 then
    lines = { "No matches." }
  else
    lines = {}
    local shown = math.min(#hits, GREP_HIT_CAP)
    for i = 1, shown do
      local h = hits[i]
      lines[#lines + 1] = ("%-10s %s:%d  %s"):format(h.short, h.path, h.line, h.text)
    end
    if #hits > GREP_HIT_CAP then
      lines[#lines + 1] = ""
      lines[#lines + 1] = ("(showing first %d of %d matches)"):format(GREP_HIT_CAP, #hits)
    end
  end
  kit.viewer({
    title = ("Cases — grep %q%s (%d)"):format(pattern, flag_suffix(flags), #hits),
    lines = lines,
  })
end

--- `:Cases linkcheck [case]` — are this case's (or every case's)
--- docs.tricentis.com links still alive? Async (bounded-concurrency HEAD
--- requests via lib.nvim.net.curl) — the report only renders once every
--- request has settled, there's no partial/streaming view.
---@param case_arg string|nil
function M.linkcheck(case_arg)
  local linkcheck = require("bindings.usrcmds.case.linkcheck")
  local short = (case_arg and case_arg ~= "") and render.to_short(case_arg) or nil
  local targets = linkcheck.targets(short)
  if #targets == 0 then
    notify.info("no docs.tricentis.com links found" .. (short and (" for " .. short) or ""))
    return
  end
  notify.info(("checking %d docs.tricentis.com link(s)…"):format(#targets))
  linkcheck.run(targets, function(results)
    vim.schedule(function()
      local dead, uncertain = 0, 0
      local lines = {}
      for _, r in ipairs(results) do
        local marker = r.status == "alive" and "OK" or (r.status == "dead" and "DEAD" or "??")
        if r.status == "dead" then
          dead = dead + 1
        elseif r.status == "uncertain" then
          uncertain = uncertain + 1
        end
        lines[#lines + 1] = ("%-10s %-4s %s  (%s)"):format(r.short, marker, r.url, r.detail)
      end
      kit.viewer({
        title = ("Cases — link check (%d dead, %d uncertain / %d)"):format(dead, uncertain, #results),
        lines = lines,
      })
    end)
  end)
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

--- `:Cases normalize` — dry-run + confirm fix-it counterpart to doctor
--- (ROADMAP.md v6). Only ever acts on findings doctor.lua marked
--- unambiguous; anything skipped is listed separately so nothing is
--- silently left out of the report.
function M.normalize()
  local normalize = require("bindings.usrcmds.case.normalize")
  local doctor = require("bindings.usrcmds.case.doctor")
  local steps, skipped = normalize.plan()

  local lines = normalize.describe(steps)
  if #skipped > 0 then
    vim.list_extend(lines, { "", ("Skipped (%d, ambiguous — target exists):"):format(#skipped) })
    vim.list_extend(lines, doctor.describe(skipped))
  end

  kit.viewer({
    title = ("Cases — normalize (%d)"):format(#steps),
    lines = lines,
  })

  if #steps == 0 then
    return
  end

  kit.confirm({
    question = ("Rename %d item(s)?"):format(#steps),
    on_answer = function(yes)
      if not yes then
        return
      end
      local results = normalize.run(steps)
      local ok, errs = normalize.errors(results)
      registry.invalidate()
      if ok then
        notify.info(("normalize: %d item(s) renamed"):format(#steps))
      else
        notify.error("normalize errors:\n" .. table.concat(errs, "\n"))
      end
    end,
  })
end

-- ── :Cases pickers ──────────────────────────────────────────────────────
-- ROADMAP.md v5: a kit.menu discovery surface over the picker-shaped flows.
-- Backend is kit.select throughout, same as every other multi-result flow
-- in this module (show_results, M.recent, ...) — the pickers.nvim/
-- snacks.picker cascade v5 also lists is deliberately deferred rather than
-- half-wired against an API this module hasn't otherwise touched; see
-- ROADMAP.md.

local TEXT_ATTACHMENT_EXTENSIONS = { md = true, txt = true, log = true, json = true, csv = true }

---@param path string
local function open_attachment(path)
  local ext = vim.fn.fnamemodify(path, ":e"):lower()
  if TEXT_ATTACHMENT_EXTENSIONS[ext] then
    edit(path)
    return
  end
  local ok, err = require("lib.nvim.cross.open_default")(path)
  if not ok then
    notify.error(("could not open %s: %s"):format(path, tostring(err)))
  end
end

---@param entry Lib.Case.RegistryEntry
local function pick_attachment(entry)
  local dir = entry.dir .. "/Ressources"
  local st = uv.fs_stat(dir)
  if not (st and st.type == "directory") then
    notify.warn(("%s has no Ressources/ folder"):format(entry.short))
    return
  end
  local files = collect_recursive.files(dir)
  if #files == 0 then
    notify.warn(("%s: Ressources/ is empty"):format(entry.short))
    return
  end
  kit.select({
    message = ("Attachments — %s"):format(entry.short),
    selection = files,
    format_item = function(f)
      return f:sub(#dir + 2)
    end,
    on_select = open_attachment,
    on_cancel = function() end,
  })
end

---@param entry Lib.Case.RegistryEntry
local function pick_links(entry)
  local m = meta.read(entry.dir)
  local links = (m and m.links and #m.links > 0) and m.links or detect.links(entry.dir)
  if #links == 0 then
    notify.warn(("%s: no links found"):format(entry.short))
    return
  end
  kit.select({
    message = ("Links — %s"):format(entry.short),
    selection = links,
    format_item = function(l)
      return l
    end,
    on_select = function(url)
      local ok = require("lib.nvim.cross.open_default")(url)
      if not ok then
        require("lib.nvim.cross.copy_to_clipboard")(url)
        notify.info(url .. " copied to clipboard (could not open a browser)")
      end
    end,
    on_cancel = function() end,
  })
end

--- Cases with no `.case.json` at all — distinct from `M.stats`'s per-field
--- "unset" counts, which only look at fields WITHIN an existing sidecar.
local function pick_missing_meta()
  local missing = {}
  for _, e in ipairs(registry.list()) do
    if not meta.read(e.dir) then
      missing[#missing + 1] = e
    end
  end
  if #missing == 0 then
    notify.info(("every case has a %s"):format(config.meta_filename))
    return
  end
  show_results(missing, ("Cases without %s"):format(config.meta_filename))
end

--- `:Cases pickers` — the discovery menu itself.
function M.pickers()
  kit.menu({
    title = "Cases — pickers",
    items = {
      {
        label = "Attachments (Ressources/)",
        action = function()
          resolve.pick(nil, function(entry)
            if entry then
              pick_attachment(entry)
            else
              notify.warn("no case to show attachments for")
            end
          end)
        end,
      },
      {
        label = "Links",
        action = function()
          resolve.pick(nil, function(entry)
            if entry then
              pick_links(entry)
            else
              notify.warn("no case to show links for")
            end
          end)
        end,
      },
      {
        label = ("Cases without %s"):format(config.meta_filename),
        action = pick_missing_meta,
      },
    },
  })
end

return M
