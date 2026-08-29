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

--- Truncate to exactly `width` display cells and pad back up to it, so
--- picker rows line up in columns. `%-Ns` can't do this: it counts BYTES,
--- and one `—` or `…` in a row is enough to shift the whole column.
---
--- `strwidth`, NOT `strdisplaywidth`: the latter simulates how the string
--- would render in the CURRENT window, so once a row is longer than
--- `'columns'` it adds this config's `'showbreak'` ("⤷ ") for every wrapped
--- screen line. A 75-space pad measured as 131 cells that way, and every
--- padding calculation built on it drifted — visible as picker columns that
--- lined up on short rows and wandered on long ones.
---@param s string
---@param width integer
---@return string
local function fit(s, width)
  s = (s:gsub("[\r\n\t]+", " "))
  if vim.fn.strwidth(s) > width then
    s = vim.fn.strcharpart(s, 0, width - 1) .. "…"
  end
  return s .. string.rep(" ", math.max(0, width - vim.fn.strwidth(s)))
end

--- `×3` for a hit seen three times, blanks of the same width otherwise —
--- blanks rather than nothing so the column after it stays aligned.
---@param count integer|nil
---@return string
local function count_col(count)
  if not count or count < 2 then
    return "    "
  end
  return fit(("×%d"):format(count), 4)
end

-- ── :Case new ────────────────────────────────────────────────────────────

---@param case_arg string|nil
function M.new(case_arg)
  local function with_case(short)
    -- The only truly required input: without a plausible number there's no
    -- folder name to create. `kit.form`'s `required` only guards `<Esc>`
    -- (see form.lua) — hitting Enter on an empty field submits "" and moves
    -- on, so title/company/name/link are validated by their own absence
    -- being harmless downstream, not by blocking here. An implausible
    -- number (empty, "12", a stray word) used to reach `registry.new_dir`
    -- unchecked and could land blueprint files straight in `Cases/Open/`
    -- itself (see config.lua's `case_number_min_digits` comment).
    if not render.is_plausible_case_number(short) then
      notify.error(
        ("not a case number: %q (expected %d-%d digits)"):format(
          tostring(short),
          config.case_number_min_digits,
          config.case_number_max_digits
        )
      )
      return
    end
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
        { name = "title", label = "Title" },
        { name = "company", label = "Company" },
        { name = "name", label = "Name" },
        { name = "snow_link", label = "SNOW Link (optional)" },
        { name = "resolve_link", label = "SAP Resolve Link (optional)" },
      },
      on_submit = function(values)
        M.create(
          short,
          values.title,
          values.company,
          values.name,
          values.snow_link,
          values.resolve_link
        )
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
---@param title string|nil
---@param company string|nil
---@param name string|nil
---@param snow_link string|nil
---@param resolve_link string|nil
function M.create(short, title, company, name, snow_link, resolve_link)
  local dir = registry.new_dir(short)
  local year = os.date("%Y")
  local tokens = {
    case = short,
    title = (title and title ~= "") and title or nil,
    company = (company and company ~= "") and company or nil,
    name = (name and name ~= "") and name or nil,
    year = year,
    today = os.date("%Y-%m-%d"),
    snow = render.to_snow(short, year),
  }

  -- ROADMAP.md v7: a company can be routed to its own blueprint; unmapped
  -- (the common case today — the table starts empty) falls through to the
  -- same default every case has always used.
  local blueprint_name = (tokens.company and config.company_blueprints[tokens.company])
    or config.default_blueprint
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

      local links = {}
      if snow_link and snow_link ~= "" then
        links[#links + 1] = snow_link
      end
      if resolve_link and resolve_link ~= "" then
        links[#links + 1] = resolve_link
      end

      meta.write(dir, {
        case = short,
        year = year,
        title = tokens.title,
        company = tokens.company,
        name = tokens.name,
        notes = "",
        links = links,
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

      -- SESSIONS.md §3: every case gets a session from birth, not just
      -- after the first manual <leader>cs save. Optional dependency, same
      -- pcall-guard pattern as every other plugin integration (CONCEPT.md §9).
      local ok_sessions, sessions = pcall(require, "sessions")
      if ok_sessions then
        sessions.save(short)
      end

      -- ROADMAP.md: offer to pull in whatever the customer already sent —
      -- Windows-only (no cross-platform equivalent of a native multi-select
      -- file dialog exists here), and silently skipped elsewhere rather
      -- than asking a question that can't be answered.
      if require("lib.nvim.system.env").get().is_windows then
        kit.confirm({
          question = "Attachments aus Downloads laden?",
          on_answer = function(load_attachments)
            if not load_attachments then
              return
            end
            local attachments = require("bindings.usrcmds.case.attachments")
            attachments.pick_from_downloads(function(paths)
              if #paths == 0 then
                return
              end
              local result = attachments.ingest(
                { dir = dir, short = short, state = config.default_state },
                paths
              )
              if result.ok > 0 then
                notify.info(
                  ("%d attachment(s) moved into %s/initial"):format(
                    result.ok,
                    config.assets_dirname
                  )
                )
              end
              if #result.errors > 0 then
                notify.error("attachment move failed:\n" .. table.concat(result.errors, "\n"))
              end
            end)
          end,
        })
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
    ("Case      %s%s"):format(
      entry.short,
      m.year and (" (%s)"):format(render.to_snow_display(entry.short, m.year)) or ""
    ),
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

    local map = require("lib.nvim.bindings.keymap")
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
      {
        name = "tosca_version",
        label = "Tosca-Version",
        default = m.tosca_version or guess.tosca_version or "",
      },
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

---@param dir string Case directory to look in.
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

---@param node Lib.Case.NodeRef
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
      notify.warn(
        ("%s does not exist yet in case %s — run :Case sync"):format(node.path, entry.short)
      )
      return
    end
    edit(path)
  end)
end

---@param case_arg string|nil
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

  -- EXTRACTION.md §6/§11 Q5: doc-link version check, resolved synchronously
  -- up front (unlike replygate's async link-liveness check below, this is
  -- pure local file scanning, no network) so it lands in the same report.
  -- Not reused by the `m` keymap below, which deliberately re-resolves its
  -- own case from whatever buffer is current when it's actually pressed.
  local doclink_mismatches, doclink_customer_version, doclink_source
  do
    local report_entry = resolve.sync(nil)
    if report_entry then
      local doclinks = require("bindings.usrcmds.case.extract.doclinks")
      local case_meta = meta.read(report_entry.dir)
      doclink_mismatches, doclink_customer_version, doclink_source =
        doclinks.check(report_entry.dir, case_meta and case_meta.tosca_version)
    end
  end

  notify.info("checking reply…")
  replygate.check(bufnr, function(report)
    vim.schedule(function()
      local lines = {}

      if report.emoji_count == nil then
        lines[#lines + 1] = "Emojis      (emojis.nvim not installed, skipped)"
      elseif report.emoji_count > 0 then
        lines[#lines + 1] = ("Emojis      %d found — press 'c' to remove"):format(
          report.emoji_count
        )
      else
        lines[#lines + 1] = "Emojis      none"
      end

      if #report.headline_lines > 0 then
        lines[#lines + 1] = ("Headlines   markdown heading on line(s): %s"):format(
          table.concat(report.headline_lines, ", ")
        )
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

      -- EXTRACTION.md §6: a live doc link on the WRONG Tosca version is
      -- worse than a dead one — the customer follows it.
      if doclink_customer_version then
        if #doclink_mismatches > 0 then
          lines[#lines + 1] = ("Doc links   %d on the wrong version (customer: %s, %s)"):format(
            #doclink_mismatches,
            doclink_customer_version,
            doclink_source
          )
          for _, mm in ipairs(doclink_mismatches) do
            lines[#lines + 1] = ("  tosca-%s  %s"):format(mm.found_version, mm.file)
          end
        else
          lines[#lines + 1] = ("Doc links   none on a different version (customer: %s)"):format(
            doclink_customer_version
          )
        end
      end

      lines[#lines + 1] = ""
      lines[#lines + 1] =
        "s: run spellcheck on this buffer (language.nvim) · m: mark as sent (SLA) · q: close"

      local surf = kit.viewer({ title = "Reply check", lines = lines })
      if not surf then
        return
      end

      local map = require("lib.nvim.bindings.keymap")
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
      -- SLA.md §6A: the ONE signal the cadence clock can't derive from the
      -- Activity Stream — the buffer being checked is not necessarily
      -- what's about to be sent (could be Notes.md too), so this stays a
      -- deliberate keypress rather than firing on every `:Case reply check`.
      map("n", "m", function()
        surf:close()
        local entry = resolve.sync(nil)
        if not entry then
          notify.warn("mark as sent: buffer doesn't belong to a known case")
          return
        end
        local ok_meta, err_meta =
          meta.patch(entry.dir, entry.short, { last_reply_sent = os.date("!%Y-%m-%dT%H:%M:%SZ") })
        if ok_meta then
          notify.info(("%s: marked as sent — SLA cadence clock reset"):format(entry.short))
        else
          notify.error("mark as sent failed: " .. tostring(err_meta))
        end
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

--- EXTRACTION.md §13, Paket 6c — the first of the two signals SAP Resolve's
--- Conversations export simply doesn't carry (§13 "zwei echte Lücken"): no
--- Priority field in any form, so there is nothing to parse harder for.
--- Without it `sla.status` returns nil and every SLA feature goes quiet for
--- this case, which is the worst outcome — silently no clock at all.
---
--- So: ask, once, exactly when it matters. Only for a detected SAP-Resolve
--- paste (SNOW's own streams carry the field and get it for free), only
--- when neither the stream nor `.case.json` already knows one, and
--- cancelling is a real answer — `:Case info`'s edit form still sets it
--- later, this is a convenience, not a gate.
---@param entry Lib.Case.RegistryEntry
---@param content string  the pasted stream
---@param parsed Lib.Case.SlaStreamData
---@param known string|nil  the priority .case.json already has, if any
local function ask_priority_if_unknowable(entry, content, parsed, known)
  if parsed.priority or known then
    return
  end
  if require("bindings.usrcmds.case.stream_format").detect(content) ~= "saperesolve" then
    return
  end

  local digits = vim.tbl_keys(config.sla)
  table.sort(digits)
  local choices = vim.tbl_map(function(digit)
    return { digit = digit, label = config.sla[digit].label }
  end, digits)

  kit.select({
    message = "SAP Resolve carries no priority — set it for " .. entry.short .. "?",
    selection = choices,
    format_item = function(c)
      return ("%s - %s"):format(c.digit, c.label)
    end,
    on_select = function(c)
      local value = ("%s - %s"):format(c.digit, c.label)
      local ok, err = meta.patch(entry.dir, entry.short, { priority = value })
      if ok then
        notify.info("priority set: " .. value)
      else
        notify.warn("could not save priority: " .. tostring(err))
      end
    end,
    on_cancel = function()
      notify.info("priority left unset — :Case info 'e' sets it later")
    end,
  })
end

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

    -- SLA.md §6A: pull Priority straight off the fresh stream into
    -- .case.json — the field :Case sla/the statusline badge need, filled
    -- without a manual step every single case.
    local sla_stream = require("bindings.usrcmds.case.sla.stream")
    local parsed = sla_stream.parse(content)
    if parsed.priority and parsed.priority ~= (m and m.priority) then
      local ok_meta, err_meta = meta.patch(entry.dir, entry.short, { priority = parsed.priority })
      if ok_meta then
        notify.info("priority detected: " .. parsed.priority)
      else
        notify.warn("could not save detected priority: " .. tostring(err_meta))
      end
    end

    -- EXTRACTION.md §8/Paket 2: SAP Component and the Tosca Server version
    -- — the server version exists NOWHERE else, not even the support-info
    -- (that only knows the Commander, EXTRACTION.md §4.1) — cached into
    -- .case.json the same way, for free on every :Case activity.
    local extract_stream = require("bindings.usrcmds.case.extract.stream")
    local signals = extract_stream.parse(content)
    local facts = {}
    local sap_component = signals.stammdaten["SAP Component"]
    if sap_component and sap_component ~= (m and m.sap_component) then
      facts.sap_component = sap_component
    end
    if signals.versions.server or signals.versions.commander then
      local existing = (m and m.versions) or {}
      local merged = {
        server = signals.versions.server or existing.server,
        commander = signals.versions.commander or existing.commander,
      }
      if merged.server ~= existing.server or merged.commander ~= existing.commander then
        facts.versions = merged
      end
    end
    -- EXTRACTION.md §5/Paket 4: "Send to Customer" is the one memo type
    -- that unambiguously means the reply is already out — auto-fills the
    -- same last_reply_sent field :Case reply check's manual "sent?" prompt
    -- sets (SLA.md §2). Only ever advances it: a manual stamp newer than
    -- what this stream detects must not be regressed by an older-looking
    -- auto-detection (ISO-8601 UTC strings sort chronologically as text).
    if signals.last_reply_sent_at then
      local detected_iso = os.date("!%Y-%m-%dT%H:%M:%SZ", signals.last_reply_sent_at)
      local existing_iso = m and m.last_reply_sent
      if not existing_iso or detected_iso > existing_iso then
        facts.last_reply_sent = detected_iso
      end
    end
    if next(facts) then
      local ok_facts, err_facts = meta.patch(entry.dir, entry.short, facts)
      if not ok_facts then
        notify.warn("could not save detected facts: " .. tostring(err_facts))
      end
    end

    edit(full)
    -- Last, and only after everything auto-detectable is already filed:
    -- the one field that CAN'T be, and only for the source that lacks it.
    ask_priority_if_unknowable(entry, content, parsed, m and m.priority)
  end)
end

-- ── :Case ki / :Case ki import ───────────────────────────────────────────

--- SLA.md §6E: one line of urgency context for `:Case ki`'s prompt (the
--- `{sla}` token, KiPrompt.md) — so the model scopes its answer to how much
--- time this case actually has, instead of always defaulting to an
--- exhaustive write-up. Never fails: no priority or no anchored clock both
--- degrade to a plain sentence saying so, rather than omitting the line.
---@param entry Lib.Case.RegistryEntry
---@return string
local function sla_context_line(entry)
  local ok_sla, sla = pcall(require, "bindings.usrcmds.case.sla")
  if not ok_sla then
    return "not available"
  end
  local ok_status, status = pcall(sla.status, entry)
  if not ok_status or not status then
    return "Priorität nicht gesetzt"
  end
  local worst = sla.most_urgent(status)
  if not worst then
    return ("Priorität %s (%s) — keine Frist anker-bar (fehlende Zeitangaben im Stream)"):format(
      status.digit,
      status.level.label
    )
  end
  return ("Priorität %s (%s) — dringlichste Frist: %s in %s"):format(
    status.digit,
    status.level.label,
    worst.label,
    sla.format_duration(worst.remaining)
  )
end

--- `:Case ki [nr]` — build the AI-analysis prompt for this case (role +
--- policies + this case's activity stream from the clipboard, `ki.lua`,
--- CONCEPT.md §8i) and put it back on the clipboard, ready to paste into
--- whichever AI chat is open. Also saved as a numbered Research/ file — the
--- same "clipboard in, numbered record out" shape as `M.activity`.
---@param case_arg string|nil
function M.ki(case_arg)
  resolve.pick(case_arg, function(entry)
    if not entry then
      notify.warn("no case to build a prompt for")
      return
    end
    local content = vim.fn.getreg("+")
    if not content or vim.trim(content) == "" then
      notify.warn("clipboard is empty — copy the activity stream first")
      return
    end
    local ki = require("bindings.usrcmds.case.ki")
    local m = meta.read(entry.dir)
    local ok_facts, facts_lines =
      pcall(require("bindings.usrcmds.case.extract.facts").render, entry)
    local prompt = ki.build_prompt({
      case = entry.short,
      title = m and m.title,
      company = m and m.company,
      name = m and m.name,
      sla = sla_context_line(entry),
      facts = ok_facts and table.concat(facts_lines, "\n") or nil,
    }, content)
    if prompt == "" then
      notify.error("ki: prompt template missing or empty (templates/KiPrompt.md)")
      return
    end

    local research_dir = entry.dir .. "/Research"
    mkdirp(research_dir)
    local next_n = next_nn_prefix(research_dir)
    local stem = next_n .. "_KiPrompt"
    local full = research_dir .. "/" .. stem .. ".md"
    local lines = { render.headline(entry.short, m and m.title, stem), "", prompt }
    local ok, err = write_to_file(full, table.concat(lines, "\n"))
    if not ok then
      notify.error("ki: write failed: " .. tostring(err))
      return
    end

    require("lib.nvim.cross.copy_to_clipboard")(prompt)
    notify.info(
      "prompt copied to clipboard, saved as " .. stem .. ".md — paste it into your AI chat"
    )
    edit(full)
  end)
end

--- `:Case ki import [nr]` — paste an AI answer (in the format `:Case ki`
--- asked for) from the clipboard and file its three parts: analysis +
--- difficulty + solution into a numbered Research/ file (the record), the
--- reply draft into a new numbered Replies/ file (still has to pass
--- `:Case reply check` like any other draft — never auto-sent), the
--- internal notes appended to Notes.md.
---@param case_arg string|nil
function M.ki_import(case_arg)
  resolve.pick(case_arg, function(entry)
    if not entry then
      notify.warn("no case to import into")
      return
    end
    local content = vim.fn.getreg("+")
    if not content or vim.trim(content) == "" then
      notify.warn("clipboard is empty — copy the AI's answer first")
      return
    end
    local ki = require("bindings.usrcmds.case.ki")
    local sections, err = ki.parse_response(content)
    if not sections then
      notify.warn("ki import: " .. err)
      return
    end

    local m = meta.read(entry.dir)
    local written = {}

    if sections.analysis or sections.difficulty or sections.solution then
      local research_dir = entry.dir .. "/Research"
      mkdirp(research_dir)
      local next_n = next_nn_prefix(research_dir)
      local stem = next_n .. "_KiAnalysis"
      local full = research_dir .. "/" .. stem .. ".md"
      local parts = { render.headline(entry.short, m and m.title, stem), "" }
      if sections.analysis then
        vim.list_extend(parts, { "## Activity Stream Analysis", "", sections.analysis, "" })
      end
      if sections.difficulty then
        vim.list_extend(parts, { "## Difficulty Assessment", "", sections.difficulty, "" })
      end
      if sections.solution then
        vim.list_extend(parts, { "## Solution / Next Steps", "", sections.solution, "" })
      end
      local ok, werr = write_to_file(full, table.concat(parts, "\n"))
      if ok then
        written[#written + 1] = stem .. ".md"
      else
        notify.error("ki import: research write failed: " .. tostring(werr))
      end
    end

    if sections.reply then
      local replies_dir = entry.dir .. "/Replies"
      mkdirp(replies_dir)
      local next_n = next_nn_prefix(replies_dir)
      local stem = next_n .. "_Reply"
      local full = replies_dir .. "/" .. stem .. ".md"
      local body = render.headline(entry.short, m and m.title, stem) .. "\n\n" .. sections.reply
      local ok, werr = write_to_file(full, body)
      if ok then
        written[#written + 1] = stem .. ".md"
      else
        notify.error("ki import: reply write failed: " .. tostring(werr))
      end
    end

    if sections.notes then
      local append = require("lib.nvim.fs.write.append")
      local block = ("\n---\n## KI-Analyse — %s\n\n%s\n"):format(
        os.date("%Y-%m-%d %H:%M"),
        sections.notes
      )
      local ok, werr = append(entry.dir .. "/Notes.md", block)
      if ok then
        written[#written + 1] = "Notes.md (appended)"
      else
        notify.error("ki import: notes append failed: " .. tostring(werr))
      end
    end

    if #written == 0 then
      notify.warn("ki import: nothing recognized in the clipboard")
      return
    end
    notify.info("ki import: " .. table.concat(written, ", "))

    -- EXTRACTION.md §7 Richtung 2: a second line of defense beyond the
    -- prompt-guard above — if the answer's own solution/reply text cites a
    -- docs.tricentis.com link on a DIFFERENT Tosca version than the
    -- customer's own, flag it now, before it's read as ready-to-send
    -- (M.ki_import already wrote it to Replies/ — `:Case reply check`
    -- catches this too on save, but a warning here is immediate, not
    -- deferred to the next check).
    local doclinks = require("bindings.usrcmds.case.extract.doclinks")
    local customer_version = doclinks.resolve_customer_version(entry.dir, m and m.tosca_version)
    if customer_version then
      local stream_extract = require("bindings.usrcmds.case.extract.stream")
      local contradictions = {}
      for _, text in ipairs({ sections.solution, sections.reply }) do
        if text then
          for _, link in ipairs(stream_extract.doc_links(text)) do
            local norm = doclinks.normalize_version(link.version)
            if norm and norm ~= customer_version then
              contradictions[#contradictions + 1] = link
            end
          end
        end
      end
      if #contradictions > 0 then
        local urls = {}
        for _, c in ipairs(contradictions) do
          urls[#urls + 1] = ("tosca-%s"):format(c.version)
        end
        notify.warn(
          ("ki import: answer cites %s, but the customer runs %s — check before sending"):format(
            table.concat(urls, ", "),
            customer_version
          )
        )
      end
    end
  end)
end

-- ── :Tricentis links ─────────────────────────────────────────────────────

--- `:Tricentis links [scope]` — every link across the work repo (or one
--- area of it), picked and opened externally. Supersedes hand-maintaining
--- `Notes/Links.md`: this reads what's already written everywhere else
--- instead of asking you to copy it a second time.
---@param scope string|nil
--- What a link row shows instead of the raw URL. First three cuts, all of
--- them removing characters that are identical on nearly every row of this
--- bestand and therefore carry no information: the scheme, a `www.`, and
--- the query string (`?Highlight=XBrowser` and friends — a search term from
--- whoever copied the link, never the reason you are picking it).
---
--- What is left is still routinely too long, and a plain right-truncation
--- cuts off exactly the wrong end: `docs.tricentis.com/tosca-2026.1/en-us/
--- content/engines_3.0/xbrowser/xbrowser_steer_remote_browser.htm` becomes
--- ".../engines_3.0/xbrow…", losing the page name that identifies it. So
--- the middle collapses instead, keeping host, version segment and page.
--- The full URL is still what gets opened.
---@param url string
---@param width integer
---@return string
local function link_label(url, width)
  local s = url:gsub("^https?://", ""):gsub("^www%.", "")
  local base = s:match("^([^?]*)") or s
  if #base < #s then
    base = base .. " ?…"
  end
  if vim.fn.strwidth(base) <= width then
    return base
  end

  local host, path = base:match("^([^/]+)/(.+)$")
  if not host then
    return base
  end
  -- Keep the first path segment too: on docs.tricentis.com that is the
  -- product version (`tosca-2026.1`), which is exactly what you check a
  -- link for when a customer is on a different one.
  local first = path:match("^([^/]+)")
  local last = path:match("([^/]+)$")
  if not first or not last or first == last then
    return base
  end
  return ("%s/%s/…/%s"):format(host, first, last)
end

function M.tricentis_links(scope)
  local links = require("bindings.usrcmds.case.links")
  local hits = links.dedupe(links.find(scope))
  if #hits == 0 then
    notify.warn(("no links found%s"):format(scope and scope ~= "" and (" in " .. scope) or ""))
    return
  end

  kit.select({
    message = ("Links%s (%d)"):format(scope and scope ~= "" and (" — " .. scope) or "", #hits),
    selection = hits,
    format_item = function(h)
      return table.concat({
        "[" .. fit(h.area, 6) .. "] ",
        fit(link_label(h.url, 88), 88),
        "  ",
        count_col(h.count),
        "  ",
        vim.fn.fnamemodify(h.path, ":t") .. ":" .. h.line,
      })
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

-- ── :Case solution / :Cases solutions ────────────────────────────────────

--- Wie viele Zeilen der Lösungsdatei der Viewer zeigt, bevor er auf "e
--- öffnet die Datei" verweist. Eine Lösung SOLL kurz sein; wenn sie es
--- nicht ist, ist der Puffer der richtige Ort dafür, nicht ein Float.
local SOLUTION_PREVIEW_LINES = 60

--- Cursor auf die erste Zeile UNTER einer Überschrift setzen — nach dem
--- Anlegen landet man so direkt im leeren `## Problem` statt auf Zeile 1
--- über der Headline.
---@param label string  Plain text, keine Pattern-Sonderzeichen.
local function cursor_below_heading(label)
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  for i, line in ipairs(lines) do
    if line:lower():match("^##+%s+" .. label:lower()) then
      vim.api.nvim_win_set_cursor(0, { math.min(i + 1, #lines), 0 })
      return
    end
  end
end

---@param entry Lib.Case.RegistryEntry
local function create_solution(entry)
  local solution = require("bindings.usrcmds.case.solution")
  local path, err = solution.create(entry)
  if not path then
    notify.error("could not create solution: " .. tostring(err))
    return
  end
  edit(path)
  cursor_below_heading("problem")
  notify.info(
    ("%s: %s angelegt — Status, Problem, Ursache, Lösung ausfüllen"):format(
      entry.short,
      path:sub(#entry.dir + 2)
    )
  )
end

--- `:Case solution [nr] [--edit]` — die Lösung des Cases: vorhanden wird sie
--- gezeigt, nicht vorhanden nach Rückfrage angelegt.
---
--- Zeigen statt direkt öffnen ist Absicht: im Alltag will man wissen "was
--- war da nochmal die Lösung", nicht in einer Datei landen, in der ein
--- unbedachtes `x` die Antwort beschädigt. `e` (oder gleich `--edit`) führt
--- in den Puffer, `y` legt den reinen Lösungsabschnitt in die
--- Zwischenablage — das ist der Text, der in die Antwort an den Kunden oder
--- ins `Summary.md` wandert.
---@param case_arg string|nil
---@param flags { edit: boolean|nil }|nil
function M.solution(case_arg, flags)
  flags = flags or {}
  resolve.pick(case_arg, function(entry)
    if not entry then
      notify.warn("no case to show a solution for")
      return
    end
    local solution = require("bindings.usrcmds.case.solution")
    local doc = solution.read(entry)

    if not doc then
      kit.confirm({
        question = ("Case %s hat noch keine Lösung — jetzt anlegen?"):format(entry.short),
        on_answer = function(yes)
          if yes then
            create_solution(entry)
          end
        end,
      })
      return
    end

    if flags.edit then
      edit(doc.path)
      return
    end

    local header = { ("%s  ·  %s"):format(entry.short, doc.status or "Status offen") }
    if doc.title ~= "" then
      header[#header + 1] = doc.title
    end
    if #doc.keywords > 0 then
      header[#header + 1] = "Schlagworte: " .. table.concat(doc.keywords, ", ")
    end
    if not doc.canonical then
      -- Altlage: gelesen wird sie trotzdem, aber `:Cases normalize` räumt
      -- sie auf die Konvention um (doctor.lua's naming-variant-Regeln).
      header[#header + 1] = ("Altlage: %s — :Cases normalize räumt das um"):format(
        doc.path:sub(#entry.dir + 2)
      )
    end
    header[#header + 1] = ""

    local body = vim.split(doc.text, "\n", { plain = true })
    if #body > SOLUTION_PREVIEW_LINES then
      local rest = #body - SOLUTION_PREVIEW_LINES
      body = vim.list_slice(body, 1, SOLUTION_PREVIEW_LINES)
      body[#body + 1] = ("… (%d weitere Zeilen — e öffnet die Datei)"):format(rest)
    end

    local lines = vim.list_extend(header, body)
    lines[#lines + 1] = ""
    lines[#lines + 1] = "e: bearbeiten · y: Lösungsabschnitt kopieren · q: schließen"

    local surf = kit.viewer({ title = "Solution " .. entry.short, lines = lines })
    if not surf then
      return
    end
    local map = require("lib.nvim.bindings.keymap")
    local mo = { buffer = surf.bufnr, nowait = true }
    map("n", "e", function()
      surf:close()
      edit(doc.path)
    end, mo)
    map("n", "y", function()
      surf:close()
      -- Der Abschnitt, nicht die ganze Datei: Status/Problem/Ursache sind
      -- interne Einordnung, kopiert werden will die Maßnahme selbst.
      local text = doc.sections.solution
      if not text or text == "" then
        text = doc.text
        notify.warn("kein '## Lösung'-Abschnitt — ganze Datei kopiert")
      end
      require("lib.nvim.cross.copy_to_clipboard")(text)
      notify.info(("Lösung von %s kopiert"):format(entry.short))
    end, mo)
  end)
end

--- Eine Zeile im Lösungs-Picker. Ohne Suchbegriff sind die Schlagworte die
--- nützlichste rechte Spalte (sie sagen, worum es ging), mit Suchbegriff die
--- Trefferbegriffe (sie sagen, WARUM der Eintrag hier steht — dieselbe
--- Begründung wie bei `:Case similar`).
---@param hit Lib.Case.SolutionHit
---@return string
local function solution_row(hit)
  local doc = hit.doc
  local right
  if hit.wanted > 0 then
    right = ("%d/%d  %s%s"):format(
      hit.matched,
      hit.wanted,
      table.concat(hit.terms, ", "),
      hit.phrase and "  [wörtlich]" or ""
    )
  else
    right = table.concat(doc.keywords, ", ")
  end
  return ("%-8s %-11s %-32s  %s"):format(
    doc.entry.short,
    doc.status or "—",
    (doc.title ~= "" and doc.title or doc.entry.state):sub(1, 32),
    right
  )
end

--- `:Cases solutions [begriff]` — die Wissensbasis über alle Cases hinweg.
---
--- Der Grund, warum `:Case solution` überhaupt ein festes Format schreibt:
--- ohne Suchbegriff eine Liste aller dokumentierten Lösungen, mit Begriff
--- eine gewichtete Rangfolge (`solution.search` — Schlagworte zählen
--- dreifach, Titel doppelt, wörtliche Phrase schlägt verstreute Wörter).
--- Rein lexikalisch, ohne KI, mit derselben bekannten Grenze wie
--- `:Case similar`: dasselbe Problem in völlig anderen Worten trifft nicht.
--- Genau deshalb gibt es `## Schlagworte` — das ist die Stelle, an der man
--- diese Grenze von Hand aufweicht.
---@param pattern string|nil
function M.solutions(pattern)
  local solution = require("bindings.usrcmds.case.solution")
  local hits, err = solution.search(pattern)
  if err then
    notify.warn(err)
    return
  end
  if #hits == 0 then
    notify.info(("keine Lösung passt zu %q"):format(pattern or ""))
    return
  end

  local label = (pattern and pattern ~= "") and (" — " .. pattern) or ""
  kit.select({
    message = ("Lösungen%s (%d)"):format(label, #hits),
    selection = hits,
    format_item = solution_row,
    on_select = function(hit)
      edit(hit.doc.path)
    end,
    on_cancel = function() end,
  })
end

-- ── :Case timeline ───────────────────────────────────────────────────────

--- `:Case timeline [nr]` — work sessions reconstructed from file mtimes
--- (`timeline.lua`, CONCEPT.md §8h), oldest first. No separate logbook to
--- keep in sync — same "derive it from what's already there" reasoning as
--- `detect.last_touched`. Each session's span is a LOWER BOUND on time
--- spent: an mtime marks when a save happened, not when editing began.
---@param case_arg string|nil
function M.timeline(case_arg)
  resolve.pick(case_arg, function(entry)
    if not entry then
      notify.warn("no case to show a timeline for")
      return
    end
    local timeline = require("bindings.usrcmds.case.timeline")
    local sessions = timeline.sessions(entry.dir)
    if #sessions == 0 then
      notify.info(("%s has no files to build a timeline from"):format(entry.short))
      return
    end

    local total = 0
    for _, s in ipairs(sessions) do
      total = total + (s.finish - s.start)
    end

    local m = meta.read(entry.dir)
    local lines = {
      ("%s — %s"):format(entry.short, (m and m.title) or ""),
      ("%d session%s, ~%s focused (lower bound — saves, not edit-start)"):format(
        #sessions,
        #sessions == 1 and "" or "s",
        timeline.format_duration(total)
      ),
      "",
    }

    for _, s in ipairs(sessions) do
      local day = os.date("%Y-%m-%d", s.start)
      local span = s.start == s.finish and os.date("%H:%M", s.start)
        or ("%s–%s"):format(os.date("%H:%M", s.start), os.date("%H:%M", s.finish))
      lines[#lines + 1] = ("%s  %-13s (%s, %d file%s)"):format(
        day,
        span,
        timeline.format_duration(s.finish - s.start),
        #s.events,
        #s.events == 1 and "" or "s"
      )
      for _, e in ipairs(s.events) do
        lines[#lines + 1] = ("      %s  %s"):format(os.date("%H:%M", e.mtime), e.path)
      end
      lines[#lines + 1] = ""
    end

    kit.viewer({ title = ("Timeline — %s"):format(entry.short), lines = lines })
  end)
end

-- ── :Case sla ────────────────────────────────────────────────────────────

--- `:Case sla [nr] [--doc]` — SLA.md §6B. Which of the three SAP-SLA
--- clocks apply and how much of each is left, as an absolute deadline (not
--- just a duration — SLA.md §6B's whole point: "2h übrig" makes you do the
--- business-hours math yourself and you'll get it wrong). `--doc` opens
--- the source SLA agreement instead — no case needed for that one.
---@param case_arg string|nil
---@param flags { doc: boolean }|nil
function M.sla(case_arg, flags)
  if flags and flags.doc then
    edit(config.sla_doc_path)
    return
  end
  resolve.pick(case_arg, function(entry)
    if not entry then
      notify.warn("no case to show SLA status for")
      return
    end
    local sla = require("bindings.usrcmds.case.sla")
    local status = sla.status(entry)
    if not status then
      notify.warn(
        ("%s: no parseable priority set — :Case activity pulls one from the stream automatically, or set it via :Case info 'e'"):format(
          entry.short
        )
      )
      return
    end

    local lines = {
      ("%s · P%s %s · %s"):format(
        entry.short,
        status.digit,
        status.level.label,
        status.level.window == "24x7" and "24x7" or "10x5 (08-18 CET)"
      ),
      "SAP-SLA — SolEx contracts can differ, never quote this to a customer",
      "",
    }

    ---@param c Lib.Case.SlaClockStatus
    local function clock_line(c)
      local state = c.remaining < 0 and "OVERDUE" or (c.done and "erfüllt" or "fällig")
      lines[#lines + 1] = ("  %-18s %-8s %s  (%s%s)"):format(
        c.label,
        state,
        os.date("%a %d.%m. %H:%M", c.deadline),
        c.remaining < 0 and "" or "in ",
        sla.format_duration(c.remaining)
      )
    end

    lines[#lines + 1] = "Erstreaktion"
    if #status.first_response == 0 then
      lines[#lines + 1] = "  unbekannt — weder .case.json 'created' noch ein Stream-Ereignis"
    end
    for _, c in ipairs(status.first_response) do
      clock_line(c)
    end

    lines[#lines + 1] = ""
    lines[#lines + 1] = "Rückmeldung"
    if status.cadence then
      clock_line(status.cadence)
    elseif status.awaiting_customer then
      lines[#lines + 1] =
        "  wartet auf Kunden (Awaiting User Info) — keine Frist, bis er antwortet"
    else
      lines[#lines + 1] = "  unbekannt"
    end

    lines[#lines + 1] = ""
    lines[#lines + 1] = "Korrekturmaßnahme"
    if status.fix then
      clock_line(status.fix)
    else
      lines[#lines + 1] = "  unbekannt"
    end

    lines[#lines + 1] = ""
    lines[#lines + 1] = status.last_customer_at
        and ("Letzte Kundennachricht:   %s"):format(
          os.date("%d.%m. %H:%M", status.last_customer_at)
        )
      or "Letzte Kundennachricht:   unbekannt"
    lines[#lines + 1] = status.last_reply_sent
        and ("Letzte gesendete Antwort: %s"):format(os.date("%d.%m. %H:%M", status.last_reply_sent))
      or "Letzte gesendete Antwort: unbekannt — 'm' in :Case reply check setzt sie"

    kit.viewer({ title = ("SLA — %s"):format(entry.short), lines = lines })
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
        selection = { "Replies", "Research", config.assets_dirname, "." },
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

-- ── :Case doclinks ───────────────────────────────────────────────────────

--- `:Case doclinks [nr]` — EXTRACTION.md §6: every `docs.tricentis.com`
--- link in the case (Activity Streams + Replies) pointing at a DIFFERENT
--- Tosca version than the customer's own. Also woven into `:Case reply
--- check` below (EXTRACTION.md §11 Q5 answered "both, not either/or" —
--- catching this BEFORE sending is the actual point).
---@param case_arg string|nil
function M.doclinks(case_arg)
  resolve.pick(case_arg, function(entry)
    if not entry then
      notify.warn("no case to check doc links for")
      return
    end
    local doclinks = require("bindings.usrcmds.case.extract.doclinks")
    local m = meta.read(entry.dir)
    local mismatches, customer_version, source = doclinks.check(entry.dir, m and m.tosca_version)
    if not customer_version then
      notify.warn(
        ("%s: no Tosca version known (set it via :Case info's edit form, or paste an Activity Stream first)"):format(
          entry.short
        )
      )
      return
    end
    local lines = {
      ("%s · customer version %s (%s)"):format(entry.short, customer_version, source),
      "",
    }
    if #mismatches == 0 then
      lines[#lines + 1] = "No doc links pointing at a different version."
    else
      lines[#lines + 1] = ("%d doc link(s) pointing at a different version:"):format(#mismatches)
      for _, mm in ipairs(mismatches) do
        lines[#lines + 1] = ("  tosca-%s  %s"):format(mm.found_version, mm.file)
        lines[#lines + 1] = ("           %s"):format(mm.url)
      end
    end
    kit.viewer({ title = "Doc links", lines = lines })
  end)
end

-- ── :Case versions ───────────────────────────────────────────────────────

--- `:Case versions [component] [nr] [--all] [--raw]` — EXTRACTION.md §3.
--- No `component`: the curated digest (testsuite/TBox build/Api Core/
--- install-root + the "Auffällig" custom-DLL section — the point of the
--- digest, not the number list, EXTRACTION.md §2). A `component` copies
--- its version straight to the clipboard, same "one action" shape as
--- `M.insert` — resolves via `config.version_components` first, then any
--- substring of any filename in the report (`extract.supportinfo.lookup`).
---@param component_arg string|nil
---@param case_arg string|nil
---@param flags { all: boolean|nil, raw: boolean|nil }|nil
function M.versions(component_arg, case_arg, flags)
  resolve.pick(case_arg, function(entry)
    if not entry then
      notify.warn("no case to show versions for")
      return
    end

    -- EXTRACTION.md §4.1: the server version exists NOWHERE in the
    -- support-info (that only knows the Commander) — the newest Activity
    -- Stream's "Tosca Server - v…" prose is the only source. Checked
    -- first and returns early: a case can have a stream but no
    -- support-info at all (confirmed for real — case 977392), so this
    -- can't wait behind the "no ToscaSupportInfo*.txt found" bailout below.
    if component_arg and component_arg:lower() == "server" then
      local stream_mod = require("bindings.usrcmds.case.extract.stream")
      local stream_path = stream_mod.find(entry.dir)
      local stream_content = stream_path and read(stream_path)
      local server = stream_content and stream_mod.versions_in_text(stream_content).server
      if server then
        require("lib.nvim.cross.copy_to_clipboard")(server)
        notify.info(
          ("Tosca Server: %s (copied, from %s)"):format(
            server,
            vim.fn.fnamemodify(stream_path, ":t")
          )
        )
      else
        notify.warn(
          "versions: no server version found (needs an Activity Stream with 'Tosca Server - v...')"
        )
      end
      return
    end

    local supportinfo = require("bindings.usrcmds.case.extract.supportinfo")
    local path = supportinfo.find(entry.dir)
    if not path then
      notify.warn(
        ("%s: no ToscaSupportInfo*.txt found under %s/"):format(entry.short, config.assets_dirname)
      )
      return
    end

    if flags and flags.raw then
      edit(path)
      return
    end

    local content = read(path)
    if not content then
      notify.error("could not read " .. path)
      return
    end
    local parsed = supportinfo.parse(content)
    local file_label = vim.fn.fnamemodify(path, ":t")

    if flags and flags.all then
      local lines = { ("%s · %s (full listing)"):format(entry.short, file_label), "" }
      local last_dir = nil
      for _, e in ipairs(parsed.entries) do
        if e.dir ~= last_dir then
          lines[#lines + 1] = ""
          lines[#lines + 1] = e.dir or "(unknown directory)"
          last_dir = e.dir
        end
        lines[#lines + 1] = e.version and ("  %-50s %s"):format(e.name, e.version)
          or ("  " .. e.name)
      end
      kit.viewer({ title = "Versions (all)", lines = lines })
      return
    end

    if not component_arg or component_arg == "" then
      local d = supportinfo.digest(parsed)
      local lines = {
        ("%s · %s · report %s"):format(entry.short, file_label, d.report_created or "unknown"),
        "",
        ("  Testsuite        %s"):format(d.testsuite or "unknown"),
        ("  TBox build       %s"):format(d.tbox_build or "unknown"),
        ("  Api Core         %s"):format(d.api_core or "unknown"),
        ("  Install-Root     %s"):format(d.install_root or "unknown"),
        "",
        "  Auffällig",
      }
      if #d.unusual > 0 then
        for _, e in ipairs(d.unusual) do
          lines[#lines + 1] = ("    %s%s"):format(e.name, e.version and (" · " .. e.version) or "")
        end
      else
        lines[#lines + 1] = "    (keine kundeneigenen DLLs im TBox-Wurzelverzeichnis)"
      end
      if #d.watched > 0 then
        local parts = {}
        for _, e in ipairs(d.watched) do
          parts[#parts + 1] = ("%s %s"):format((e.name:gsub("%.dll$", "")), e.version or "?")
        end
        lines[#lines + 1] = ""
        lines[#lines + 1] = "  Ausgewählt        " .. table.concat(parts, " · ")
      end
      kit.viewer({ title = ("Versions %s"):format(entry.short), lines = lines })
      return
    end

    local header_hits, entry_hits = supportinfo.lookup(parsed, component_arg)
    if #header_hits == 1 and #entry_hits == 0 then
      local h = header_hits[1]
      require("lib.nvim.cross.copy_to_clipboard")(h.value)
      notify.info(("%s: %s (copied)"):format(h.label, h.value))
      return
    end
    if #entry_hits == 0 then
      notify.warn(("versions: no match for %q in %s"):format(component_arg, file_label))
      return
    end
    if #entry_hits == 1 then
      local e = entry_hits[1]
      require("lib.nvim.cross.copy_to_clipboard")(e.version or "")
      notify.info(("%s: %s (copied)"):format(e.name, e.version or "no version line"))
      return
    end
    kit.select({
      message = ("%d matches for %q"):format(#entry_hits, component_arg),
      selection = entry_hits,
      format_item = function(e)
        return ("%-50s %s"):format(e.name, e.version or "")
      end,
      on_select = function(e)
        require("lib.nvim.cross.copy_to_clipboard")(e.version or "")
        notify.info(("%s: %s (copied)"):format(e.name, e.version or "no version line"))
      end,
      on_cancel = function() end,
    })
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

--- Session cleanup shared by every path that removes a case from
--- `config.default_state` (a plain move OR a delete): SESSIONS.md §6 — a
--- case's session is only useful while it's actively worked, so this drops
--- the now-stale session immediately instead of waiting for the next
--- `:Cases doctor` pass to flag it. Optional dependency, silent on "no such
--- session" (the common case: most cases never had one saved).
---@param entry Lib.Case.RegistryEntry
local function drop_session_if_left_open(entry)
  local ok_sessions, sessions = pcall(require, "sessions")
  if ok_sessions then
    sessions.delete(entry.short)
  end
end

--- The general primitive behind every generated state-move verb (init.lua
--- builds one per non-default entry in config.states, using
--- config.state_verbs for the command name) AND the interactive `:Case
--- close`/`:Cases close` destination picker below. The case's state IS the
--- folder it's in (MIGRATION.md §1), so this is a plain rename — no
--- `status` field to keep in sync.
---@param entry Lib.Case.RegistryEntry
---@param state string  One of config.states.
---@return boolean ok
local function do_move(entry, state)
  mkdirp(config.state_dir(state))
  local dest = config.state_dir(state) .. "/" .. entry.short
  -- mutate.rename_file, not a bare uv.fs_rename: a Windows directory
  -- watcher (neo-tree's leaked fs_event handles are the known offender) can
  -- hold a transient lock on the case folder being moved — see
  -- normalize.lua's identical reasoning.
  local ok, err = require("lib.nvim.cross.fs.mutate").rename_file(entry.dir, dest)
  if not ok then
    notify.error(("move to %s failed: %s"):format(state, tostring(err)))
    return false
  end
  registry.invalidate()
  notify.info(("case %s moved to %s"):format(entry.short, state))
  if state ~= config.default_state then
    drop_session_if_left_open(entry)
  end
  -- Der Moment, in dem eine Lösung verlorengeht: Case ist gelöst, wandert
  -- weg, und WAS ihn gelöst hat, steht nur zwischen drei Fehlversuchen in
  -- Notes.md. Nur ein Hinweis (config.solution_reminder_states) — nichts
  -- wird automatisch angelegt, eine leere Solution.md würde die Suche mit
  -- inhaltslosen Treffern fluten. `dest`, nicht `entry.dir`: der Ordner ist
  -- gerade umgezogen.
  if vim.tbl_contains(config.solution_reminder_states, state) then
    if not require("bindings.usrcmds.case.solution").exists(dest) then
      notify.warn(
        ("case %s hat keine dokumentierte Lösung — :Case solution %s"):format(
          entry.short,
          entry.short
        )
      )
    end
  end
  return true
end

--- Permanently remove a case folder — the "LÖSCHEN" destination in
--- ROADMAP.md's `:Case(s) close` request. Same Windows transient-lock risk
--- as `do_move` above (a directory watcher/AV/indexer can hold the folder
--- open a few ms after the last buffer touching it closes), so this goes
--- through the same `mutate.retry` rather than a bare `vim.fn.delete`.
--- Irreversible: callers MUST get an explicit, deliberate confirmation
--- before calling this — see `M.close`/`close_many` below, both require
--- typing the case number (or "DELETE" for a batch) back, not just y/n.
---@param entry Lib.Case.RegistryEntry
---@return boolean ok
local function do_delete(entry)
  local ok = require("lib.nvim.cross.fs.mutate").retry(function()
    if vim.fn.delete(entry.dir, "rf") == 0 then
      return true
    end
    return false, "EBUSY: delete failed"
  end)
  if not ok then
    notify.error(("delete of %s failed"):format(entry.short))
    return false
  end
  registry.invalidate()
  notify.info(("case %s deleted"):format(entry.short))
  drop_session_if_left_open(entry)
  return true
end

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
        if yes then
          do_move(entry, state)
        end
      end,
    })
  end)
end

-- ── :Case close / :Cases close — destination picker + marks ──────────────

--- Sentinel target for M.close/close_many's destination kit.select — not a
--- config.states entry, so it can never collide with a real state name.
local DELETE_TARGET = "__delete__"

---@return { label: string, target: string }[]
local function close_targets()
  local out = {}
  for _, state in ipairs(config.states) do
    if state ~= config.default_state then
      out[#out + 1] = { label = state, target = state }
    end
  end
  out[#out + 1] = { label = "Delete permanently", target = DELETE_TARGET }
  return out
end

---@param message string
---@param cb fun(target: string|nil)  A config.states entry, DELETE_TARGET, or nil on cancel.
local function pick_close_target(message, cb)
  kit.select({
    message = message,
    selection = close_targets(),
    format_item = function(t)
      return t.label
    end,
    on_select = function(t)
      cb(t.target)
    end,
    on_cancel = function()
      cb(nil)
    end,
  })
end

--- Shared bulk-apply for the marks path and the multi-select path of
--- `:Cases close`: one destination picked once, applied to every entry.
---@param entries Lib.Case.RegistryEntry[]
local function close_many(entries)
  if #entries == 0 then
    notify.warn("no cases to close")
    return
  end
  local shorts = {}
  for _, e in ipairs(entries) do
    shorts[#shorts + 1] = e.short
  end
  table.sort(shorts)
  local label = table.concat(shorts, ", ")

  pick_close_target(("Move %d case(s) to...\n%s"):format(#entries, label), function(target)
    if not target then
      return
    end
    local movable = {}
    for _, e in ipairs(entries) do
      if e.state ~= target then
        movable[#movable + 1] = e
      end
    end
    if #movable == 0 then
      notify.warn("all selected cases are already in that state")
      return
    end

    if target == DELETE_TARGET then
      kit.input({
        title = ("Type DELETE to permanently remove %d case(s): %s"):format(#movable, label),
        on_submit = function(typed)
          if typed ~= "DELETE" then
            notify.warn("bulk delete cancelled")
            return
          end
          local n = 0
          for _, e in ipairs(movable) do
            if do_delete(e) then
              n = n + 1
            end
          end
          notify.info(("%d/%d case(s) deleted"):format(n, #movable))
          require("bindings.usrcmds.case.marks").clear()
        end,
      })
      return
    end

    kit.confirm({
      question = ("Move %d case(s) to %s?\n%s"):format(#movable, target, label),
      on_answer = function(yes)
        if not yes then
          return
        end
        local n = 0
        for _, e in ipairs(movable) do
          if do_move(e, target) then
            n = n + 1
          end
        end
        notify.info(("%d/%d case(s) moved to %s"):format(n, #movable, target))
        require("bindings.usrcmds.case.marks").clear()
      end,
    })
  end)
end

--- Shared by `M.close`'s "Delete permanently" target and `M.delete` below —
--- the case number typed back, not a bare y/n, since `do_delete` is
--- irreversible.
---@param entry Lib.Case.RegistryEntry
local function confirm_and_delete(entry)
  kit.input({
    title = ("Type %s to permanently delete"):format(entry.short),
    on_submit = function(typed)
      if typed ~= entry.short then
        notify.warn("delete cancelled (number didn't match)")
        return
      end
      do_delete(entry)
    end,
  })
end

--- `:Case close [nr]` — ROADMAP.md's requested behavior: instead of moving
--- straight to "Closed" (that's still what `:Case reassign` etc. do for
--- their own state via M.move_state above), open a destination picker —
--- any other state, or permanent deletion.
---@param case_arg string|nil
function M.close(case_arg)
  resolve.pick(case_arg, function(entry)
    if not entry then
      notify.warn("no case to close")
      return
    end
    pick_close_target(("Move case %s to..."):format(entry.short), function(target)
      if not target then
        return
      end
      if target == entry.state then
        notify.warn(("%s is already %s"):format(entry.short, target))
        return
      end
      if target == DELETE_TARGET then
        confirm_and_delete(entry)
        return
      end
      kit.confirm({
        question = ("Move case %s to %s?"):format(entry.short, target),
        on_answer = function(yes)
          if yes then
            do_move(entry, target)
          end
        end,
      })
    end)
  end)
end

--- `:Case delete [nr]` — ROADMAP.md's request for a direct path to permanent
--- deletion, without going through `:Case close`'s destination picker first.
--- Same irreversible, typed-confirmation gate as `:Case close`'s "Delete
--- permanently" target — `confirm_and_delete` above, not a new safety check.
---@param case_arg string|nil
function M.delete(case_arg)
  resolve.pick(case_arg, function(entry)
    if not entry then
      notify.warn("no case to delete")
      return
    end
    confirm_and_delete(entry)
  end)
end

--- `:Cases close` — bulk version of M.close above. Prefers whatever's
--- already marked (`:Cases list`'s `m`/Visual-`m`, ROADMAP.md's "marking
--- system wie in filetree.nvim"); with nothing marked, falls back to an
--- interactive `<Tab>`-multi-select/`<CR>`-confirm picker over open cases
--- (kit.select's native `multi = true` chooser). Either way, close_many
--- then asks ONCE where they all go.
function M.cases_close()
  local marks = require("bindings.usrcmds.case.marks")
  if marks.count() > 0 then
    local entries = {}
    for _, short in ipairs(marks.list()) do
      local e = registry.find(short)
      if e then
        entries[#entries + 1] = e
      end
    end
    close_many(entries)
    return
  end

  local open_entries = {}
  for _, e in ipairs(registry.list()) do
    if e.state == config.default_state then
      open_entries[#open_entries + 1] = e
    end
  end
  if #open_entries == 0 then
    notify.warn("no open cases")
    return
  end
  kit.select({
    message = "Which case(s) to close? (<Tab> to multi-select, <CR> to confirm)",
    selection = open_entries,
    multi = true,
    format_item = function(e)
      local m = meta.read(e.dir)
      return (m and m.title and m.title ~= "") and ("%s  %s"):format(e.short, m.title) or e.short
    end,
    on_select = close_many,
    on_cancel = function() end,
  })
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

-- ── :Case insert / :Cases insert ────────────────────────────────────────

--- `:Case insert [field] [case]` — a case's token (number, title, company,
--- ...) needs to land somewhere OUTSIDE a casedesk file just as often as
--- inside one: a SNOW comment, a Teams message, an email subject. Every
--- other command in this module either opens a file or shows a report;
--- this is the "just give me the text, here and on the clipboard" one —
--- insert at the cursor AND copy in the same keypress, so whichever one
--- you actually need (paste target inside vs. outside Neovim) is covered
--- without picking in advance.
--- `preview` is set on the fields whose value can't be shown in the picker
--- because it isn't decided yet (the asset ones need a second pick).
---@type { key: string, label: string, preview: string|nil }[]
M.INSERT_FIELDS = {
  { key = "case", label = "Case number" },
  { key = "snow", label = "SNOW ticket id" },
  { key = "link", label = "SNOW ticket URL (falls back to id if snow_url_format unset)" },
  { key = "title", label = "Title" },
  { key = "company", label = "Company" },
  { key = "name", label = "Contact name" },
  { key = "priority", label = "Priority" },
  { key = "summary", label = "One-line summary (case — title — company — name)" },
  { key = "mail-subject", label = "Email subject: [case] title" },
  {
    key = "asset",
    label = "Asset as a markdown link (absolute path outside the case)",
    preview = "(pick a file from " .. config.assets_dirname .. "/)",
  },
  {
    key = "asset-path",
    label = "Asset as an absolute path (for Teams, Explorer, a shell)",
    preview = "(pick a file from " .. config.assets_dirname .. "/)",
  },
}

---@param entry Lib.Case.RegistryEntry
---@param m Lib.Case.Meta|nil
---@param key string
---@return string|nil
local function insert_value(entry, m, key)
  if key == "case" then
    return entry.short
  elseif key == "snow" then
    return render.to_snow(entry.short, (m and m.year) or os.date("%Y"))
  elseif key == "link" then
    local snow = render.to_snow(entry.short, (m and m.year) or os.date("%Y"))
    return (config.snow_url_format and (config.snow_url_format .. snow)) or snow
  elseif key == "title" then
    return m and m.title
  elseif key == "company" then
    return m and m.company
  elseif key == "name" then
    return m and m.name
  elseif key == "priority" then
    return m and m.priority
  elseif key == "summary" then
    local parts = { entry.short }
    for _, field in ipairs({ "title", "company", "name" }) do
      if m and m[field] and m[field] ~= "" then
        parts[#parts + 1] = m[field]
      end
    end
    return table.concat(parts, " — ")
  elseif key == "mail-subject" then
    if not (m and m.title and m.title ~= "") then
      return nil
    end
    return ("[%s] %s"):format(entry.short, m.title)
  end
  return nil
end

--- Backslashes out, trailing slash off. Every path comparison and every
--- path this module WRITES into a markdown file uses forward slashes —
--- `uv` and `vim.fn` hand out both spellings on Windows, and a `\` in a
--- markdown link target is an escape character, not a separator.
---@param path string
---@return string
local function norm_path(path)
  return (path:gsub("\\", "/"):gsub("/+$", ""))
end

--- Case-insensitively, because this module's cases live on Windows: the
--- registry stores `C:/Cases/...` while a buffer name may come back as
--- `c:/cases/...`, and a case-sensitive prefix test would then call an
--- in-case buffer "outside the case" and silently fall back to absolute
--- paths.
---@param dir string  normalized
---@param path string  normalized
---@return boolean
local function is_inside(dir, path)
  return path:lower():sub(1, #dir + 1) == (dir:lower() .. "/")
end

--- `to` expressed relative to `from_dir`, both normalized absolute paths.
---@param from_dir string
---@param to string
---@return string
local function rel_path(from_dir, to)
  local a = vim.split(from_dir, "/", { trimempty = true })
  local b = vim.split(to, "/", { trimempty = true })
  local i = 1
  while a[i] and b[i] and a[i]:lower() == b[i]:lower() do
    i = i + 1
  end
  local parts = {}
  for _ = i, #a do
    parts[#parts + 1] = ".."
  end
  for j = i, #b do
    parts[#parts + 1] = b[j]
  end
  return table.concat(parts, "/")
end

--- Percent-encode the three characters that break a markdown link target.
--- Attachments arrive named the way a customer named them — `Tosca Server
--- log (2).txt` is an ordinary filename and an unusable link target.
---@param path string
---@return string
local function md_url(path)
  return (path:gsub("[ ()]", function(c)
    return ("%%%02X"):format(c:byte())
  end))
end

--- Insert `value` at the cursor (byte-column, so multibyte titles/company
--- names land correctly) and mirror it to the system clipboard in the same
--- action.
---@param value string
local function insert_and_copy(value)
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local line = vim.api.nvim_get_current_line()
  local before, after = line:sub(1, col), line:sub(col + 1)
  vim.api.nvim_set_current_line(before .. value .. after)
  vim.api.nvim_win_set_cursor(0, { row, col + #value })
  require("lib.nvim.cross.copy_to_clipboard")(value)
  notify.info("inserted + copied: " .. value)
end

--- Replace whatever a Visual selection covered with `value`, instead of
--- inserting at the cursor — `:'<,'>Case insert case` on a placeholder like
--- `<CASE>` replaces it in place. Charwise + single-line uses the exact
--- column span (`ctx.range.col1`/`col2`); linewise, blockwise, or a
--- multi-line charwise span all fall back to "replace the whole line
--- range with one line" — precise per-column blockwise editing isn't
--- worth the complexity for a single-token replacement.
---@param range Lib.UserCmd.Composer.RangeInfo
---@param value string
local function replace_range_and_copy(range, value)
  if range.mode == "v" and range.line1 == range.line2 and range.col1 and range.col2 then
    local line = vim.api.nvim_buf_get_lines(0, range.line1 - 1, range.line1, false)[1] or ""
    local before = line:sub(1, range.col1 - 1)
    local after = line:sub(range.col2 + 1)
    vim.api.nvim_buf_set_lines(0, range.line1 - 1, range.line1, false, { before .. value .. after })
    vim.api.nvim_win_set_cursor(0, { range.line1, #before + #value })
  else
    vim.api.nvim_buf_set_lines(0, range.line1 - 1, range.line2, false, { value })
    vim.api.nvim_win_set_cursor(0, { range.line1, 0 })
  end
  require("lib.nvim.cross.copy_to_clipboard")(value)
  notify.info("replaced selection + copied: " .. value)
end

--- The text for one chosen asset file. `asset-path` is always the absolute
--- path; `asset` is a markdown link relative to the buffer being written
--- into — which only means anything while that buffer sits inside the same
--- case, so from anywhere else it degrades to the absolute path rather
--- than writing a link that resolves to nothing.
---@param entry Lib.Case.RegistryEntry
---@param key string  `"asset"` | `"asset-path"`
---@param file string  absolute path of the chosen asset
---@return string
local function asset_value(entry, key, file)
  local abs = norm_path(file)
  if key == "asset-path" then
    return abs
  end
  local buf = norm_path(vim.api.nvim_buf_get_name(0))
  if buf == "" or not is_inside(norm_path(entry.dir), buf) then
    notify.info(("buffer is outside %s — inserting the absolute path"):format(entry.short))
    return abs
  end
  local rel = rel_path(buf:match("^(.*)/[^/]*$") or buf, abs)
  return ("[%s](%s)"):format(abs:match("[^/]*$"), md_url(rel))
end

--- Assets are the one insert field whose value isn't already sitting in the
--- case's metadata — WHICH file is a second decision, so this field runs a
--- second picker and hands its result back through `on_value` instead of
--- returning it. Same file list `:Case attachments` shows.
---@param entry Lib.Case.RegistryEntry
---@param key string
---@param on_value fun(value: string)
local function pick_asset_value(entry, key, on_value)
  local dir = norm_path(entry.dir .. "/" .. config.assets_dirname)
  local st = uv.fs_stat(dir)
  if not (st and st.type == "directory") then
    notify.warn(("%s has no %s/ folder"):format(entry.short, config.assets_dirname))
    return
  end
  local files = {}
  for _, f in ipairs(collect_recursive.files(dir)) do
    files[#files + 1] = norm_path(f)
  end
  if #files == 0 then
    notify.warn(("%s: %s/ is empty"):format(entry.short, config.assets_dirname))
    return
  end
  kit.select({
    message = ("Insert asset — %s"):format(entry.short),
    selection = files,
    format_item = function(f)
      return f:sub(#dir + 2)
    end,
    on_select = function(f)
      on_value(asset_value(entry, key, f))
    end,
    on_cancel = function() end,
  })
end

---@param field_arg string|nil
---@param case_arg string|nil
---@param range Lib.UserCmd.Composer.RangeInfo|nil  present + `.range > 0` -> replace the Visual selection instead of inserting at the cursor
function M.insert(field_arg, case_arg, range)
  resolve.pick(case_arg, function(entry)
    if not entry then
      notify.warn("no case to insert from")
      return
    end
    local m = meta.read(entry.dir)

    local function apply(value)
      if range and (range.range or 0) > 0 then
        replace_range_and_copy(range, value)
      else
        insert_and_copy(value)
      end
    end

    local function with_field(key)
      if key == "asset" or key == "asset-path" then
        pick_asset_value(entry, key, apply)
        return
      end
      local value = insert_value(entry, m, key)
      if not value or value == "" then
        notify.warn(("%s has no %s set"):format(entry.short, key))
        return
      end
      if key == "link" and not config.snow_url_format then
        notify.info("config.snow_url_format not set — inserting the ticket id instead of a URL")
      end
      apply(value)
    end

    if field_arg and field_arg ~= "" then
      with_field(field_arg)
      return
    end

    kit.select({
      message = ("Insert — %s"):format(entry.short),
      selection = M.INSERT_FIELDS,
      format_item = function(f)
        return ("%-13s %s"):format(f.key, f.preview or insert_value(entry, m, f.key) or "—")
      end,
      on_select = function(f)
        with_field(f.key)
      end,
      on_cancel = function() end,
    })
  end)
end

--- `:Cases insert [pattern]` — same insert-and-copy, but for a case OTHER
--- than the one you're in: writing a reply that references "see also case
--- 977123" doesn't want you to leave your current buffer's case context to
--- go look that number up. Narrows by number/title/company/name substring;
--- 0 matches warns, 1 match skips straight to the field picker, several go
--- through a case picker first.
---@param pattern string|nil
---@param range Lib.UserCmd.Composer.RangeInfo|nil
function M.cases_insert(pattern, range)
  local candidates
  if pattern and pattern ~= "" then
    candidates = {}
    local needle = pattern:lower()
    for _, e in ipairs(registry.list()) do
      local m = meta.read(e.dir)
      local haystack = table
        .concat({ e.short, (m and m.title) or "", (m and m.company) or "", (m and m.name) or "" }, " ")
        :lower()
      if haystack:find(needle, 1, true) then
        candidates[#candidates + 1] = e
      end
    end
  else
    candidates = registry.list()
  end

  if #candidates == 0 then
    notify.warn(("insert: no case matches %q"):format(pattern or ""))
    return
  end
  if #candidates == 1 then
    M.insert(nil, candidates[1].short, range)
    return
  end

  kit.select({
    message = ("Insert from case (%d)"):format(#candidates),
    selection = candidates,
    format_item = function(e)
      local m = meta.read(e.dir)
      return ("%-10s %s"):format(e.short, (m and m.title) or "")
    end,
    on_select = function(e)
      M.insert(nil, e.short, range)
    end,
    on_cancel = function() end,
  })
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
      return title and ("%s [%s] — %s"):format(e.short, e.state, title)
        or ("%s [%s]"):format(e.short, e.state)
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
  local label = ("%s = %s%s"):format(
    field,
    (pattern and pattern ~= "") and pattern or "*",
    flag_suffix(flags)
  )
  show_results(results, label)
end

--- `:Cases list` — everything, grouped by state. Also the marking view for
--- ROADMAP.md's "marking system wie in filetree.nvim": `m` toggles the case
--- under the cursor, a Visual-line range + `m` toggles every case in it,
--- `c` runs `:Cases close` on whatever ends up marked. Marks persist after
--- this view closes (marks.lua is a flat set, not buffer-scoped) — mark a
--- few cases here, close the view, run `:Cases close` whenever, from
--- anywhere.
function M.list_all()
  local groups = query.by_state()
  local marks = require("bindings.usrcmds.case.marks")

  -- Parallel to `lines`: line_rows[i] is the case entry rendered on line i,
  -- or nil for a header/blank line — built once, stays valid across re-
  -- renders below since marking only changes a line's `[x]`/`[ ]` prefix,
  -- never the line count or order.
  local lines, line_rows = {}, {}
  for _, state in ipairs(config.states) do
    local entries = groups[state] or {}
    lines[#lines + 1] = ("%s (%d)"):format(state, #entries)
    for _, e in ipairs(entries) do
      local m = meta.read(e.dir)
      lines[#lines + 1] = ("%-10s %s"):format(e.short, (m and m.title) or "")
      line_rows[#lines] = e
    end
    lines[#lines + 1] = ""
  end

  local function render_lines()
    local out = {}
    for i, text in ipairs(lines) do
      local e = line_rows[i]
      out[i] = e and ((marks.is_marked(e.short) and "[x] " or "[ ] ") .. text) or text
    end
    return out
  end

  local surf = kit.viewer({
    title = "Cases  (m mark, V+m mark range, c close marked)",
    lines = render_lines(),
  })
  if not surf then
    return
  end

  ---@param lineno integer
  local function toggle_line(lineno)
    local e = line_rows[lineno]
    if e then
      marks.toggle(e.short)
    end
  end

  local map = require("lib.nvim.bindings.keymap")
  local mo = { buffer = surf.bufnr, nowait = true }

  map("n", "m", function()
    toggle_line(vim.api.nvim_win_get_cursor(surf.winid)[1])
    surf:set_lines(render_lines())
  end, mo)

  map("x", "m", function()
    local from, to = vim.fn.line("v"), vim.fn.line(".")
    if from > to then
      from, to = to, from
    end
    for lineno = from, to do
      toggle_line(lineno)
    end
    surf:set_lines(render_lines())
  end, mo)

  map("n", "c", function()
    if marks.count() == 0 then
      notify.warn("no cases marked (press m on a case line first)")
      return
    end
    surf:close()
    M.cases_close()
  end, mo)
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
  local label = (#parts > 0 and table.concat(parts, " ") or "find (no criteria given)")
    .. flag_suffix(flags)
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
      return ("%s  %-10s %s"):format(
        os.date("%Y-%m-%d", row.mtime),
        row.entry.short,
        (m and m.title) or ""
      )
    end,
    on_select = function(item)
      M.info(item.entry.short)
    end,
    on_cancel = function() end,
  })
end

--- `:Cases stale [days]` — open cases untouched at least as long as their
--- threshold, oldest first. Explicit `days` overrides that threshold flat
--- for every case; omitted, each case uses its own priority-derived one
--- (SLA.md §6C, `config.sla_stale_days`) — so the header can't just say
--- "N+ days" the way it used to when there was one N for everyone.
---@param days_arg string|nil
function M.stale(days_arg)
  local days = tonumber(days_arg)
  local rows = query.stale(days)
  if #rows == 0 then
    notify.info(
      days and ("no open case has been idle %d+ days"):format(days)
        or "no open case is stale for its priority"
    )
    return
  end
  kit.select({
    message = days and ("Stale %d+ days (%d)"):format(days, #rows)
      or ("Stale (%d, priority-based threshold)"):format(#rows),
    selection = rows,
    format_item = function(row)
      local m = meta.read(row.entry.dir)
      return ("%3d/%-2d d idle  %-10s %s"):format(
        row.days_idle,
        row.threshold_days,
        row.entry.short,
        (m and m.title) or ""
      )
    end,
    on_select = function(item)
      M.info(item.entry.short)
    end,
    on_cancel = function() end,
  })
end

--- `:Cases sla` — SLA.md §6B dashboard: every open case with a priority,
--- sorted by remaining time on its most urgent clock — "what breaches
--- next" is the actual morning question, not grouped by priority label.
--- Selecting a row opens that case's own `:Case sla` (not the infocard —
--- this dashboard exists specifically to get to the SLA detail, not the
--- general one).
function M.cases_sla()
  local rows = query.sla_dashboard()
  if #rows == 0 then
    notify.info("no open case has a parseable priority with an anchored clock yet")
    return
  end
  local sla = require("bindings.usrcmds.case.sla")
  kit.select({
    message = ("SLA dashboard (%d open, by urgency)"):format(#rows),
    selection = rows,
    format_item = function(row)
      local m = meta.read(row.entry.dir)
      local marker = row.worst.remaining < 0 and "!!"
        or (sla.under_threshold(row.worst, config.sla_warn_at) and "! " or "  ")
      return ("%s P%s %-18s %-10s %s"):format(
        marker,
        row.status.digit,
        row.worst.label,
        row.entry.short,
        (m and m.title) or ""
      )
    end,
    on_select = function(item)
      M.sla(item.entry.short)
    end,
    on_cancel = function() end,
  })
end

--- Both first_response anchors, in a fixed order — `pairs()` iteration
--- order isn't stable, and this report benefits from stable output more
--- than a growing-config-driven list would (there are exactly two, SLA.md
--- §9.1's open question, not something a future state could add a third
--- of the way `config.states` does elsewhere in this module).
local SLA_REPORT_ANCHORS = { "ab Ticket-Eingang", "ab Zuweisung" }

--- `:Cases sla report [--year N]` — SLA.md §6D: ratio of Erstreaktion
--- clocks met per priority (both anchors — SLA.md §9.1 leaves picking one
--- unresolved), outliers named with how late. Unlike `:Cases sla` above,
--- covers every state, not just open cases (SLA.md §9 Q5: a report is
--- retrospective).
---
--- The honesty clause SLA.md §6D calls for isn't a footnote here — it's
--- the report's own second line: this number is only as good as
--- `last_reply_sent` being stamped (`:Case reply check`'s "sent?" prompt),
--- and a case with no stamp yet doesn't count as "missed" — it's excluded
--- from the ratio entirely and reported separately, since counting an
--- un-stamped case as a miss would overstate how bad things actually are.
---@param year_arg string|nil
function M.cases_sla_report(year_arg)
  local rows = query.sla_report(year_arg)
  if #rows == 0 then
    notify.warn(
      year_arg and ("no case with a parseable priority in %s"):format(year_arg)
        or "no case with a parseable priority"
    )
    return
  end

  local sla = require("bindings.usrcmds.case.sla")
  ---@type table<string, table<string, { met: integer, missed: integer, nodata: integer }>>
  local groups = {}
  local outliers = {}
  for _, r in ipairs(rows) do
    groups[r.digit] = groups[r.digit] or {}
    groups[r.digit][r.label] = groups[r.digit][r.label] or { met = 0, missed = 0, nodata = 0 }
    local g = groups[r.digit][r.label]
    if r.met == nil then
      g.nodata = g.nodata + 1
    elseif r.met then
      g.met = g.met + 1
    else
      g.missed = g.missed + 1
      outliers[#outliers + 1] = r
    end
  end

  local lines = {
    ("SLA report — %s"):format(year_arg or "all years"),
    "Meine Sicht, keine SNOW-Wahrheit — nur so gut wie last_reply_sent gepflegt ist.",
    "",
  }
  for _, digit in ipairs({ "1", "2", "3", "4" }) do
    local by_label = groups[digit]
    if by_label then
      lines[#lines + 1] = ("P%s %s"):format(digit, config.sla[digit].label)
      for _, label in ipairs(SLA_REPORT_ANCHORS) do
        local g = by_label[label]
        if g then
          local total = g.met + g.missed
          local pct = total > 0 and (100 * g.met / total) or 0
          lines[#lines + 1] = ("  %-18s %d/%d (%.0f%%) met, %d ohne last_reply_sent"):format(
            label,
            g.met,
            total,
            pct,
            g.nodata
          )
        end
      end
      lines[#lines + 1] = ""
    end
  end

  if #outliers > 0 then
    table.sort(outliers, function(a, b)
      return (a.delta or 0) > (b.delta or 0)
    end)
    lines[#lines + 1] = "Ausreißer (verpasst):"
    for _, r in ipairs(outliers) do
      lines[#lines + 1] = ("  %-10s P%s %-18s +%s"):format(
        r.entry.short,
        r.digit,
        r.label,
        sla.format_duration(r.delta)
      )
    end
  end

  kit.viewer({ title = "SLA report", lines = lines })
end

--- `:Cases history [company]` — "what have we had with this company
--- before": every matching case (same substring match as `:Cases company`)
--- in one screen, grouped by state, most-recently-touched first within
--- each group — instead of picking through `:Cases company`'s
--- `kit.select` one case at a time. Omit `company` to use the company of
--- the case owning the current buffer, same optional-arg idiom every
--- `:Case` route uses (`resolve.sync`, no UI fallback — a report has
--- nothing to prompt into if that fails).
---@param pattern string|nil
function M.company_history(pattern)
  if not pattern or pattern == "" then
    local entry = resolve.sync(nil)
    local m = entry and meta.read(entry.dir)
    pattern = m and m.company
    if not pattern then
      notify.warn("company_history: no company given and current buffer has none set")
      return
    end
  end

  local matches = query.by_field("company", pattern)
  if #matches == 0 then
    notify.info(("no cases found for company matching %q"):format(pattern))
    return
  end

  -- Distinct company spellings actually matched, for the header — a
  -- substring match can pull in more than one (e.g. "Scania" and a typo'd
  -- variant), worth surfacing rather than silently picking one.
  local companies, seen = {}, {}
  for _, e in ipairs(matches) do
    local c = (meta.read(e.dir) or {}).company
    if c and not seen[c] then
      seen[c] = true
      companies[#companies + 1] = c
    end
  end
  table.sort(companies)

  local lines = {
    ("%s — %d case%s"):format(
      table.concat(companies, ", "),
      #matches,
      #matches == 1 and "" or "s"
    ),
    "",
  }

  for _, state in ipairs(config.states) do
    local rows = {}
    for _, e in ipairs(matches) do
      if e.state == state then
        rows[#rows + 1] = { entry = e, mtime = detect.last_touched(e.dir) or 0 }
      end
    end
    if #rows > 0 then
      table.sort(rows, function(a, b)
        return a.mtime > b.mtime
      end)
      lines[#lines + 1] = ("%s (%d)"):format(state, #rows)
      for _, r in ipairs(rows) do
        local m = meta.read(r.entry.dir)
        local touched = r.mtime > 0 and os.date("%Y-%m-%d", r.mtime) or "—"
        lines[#lines + 1] = ("  %-10s %s  %s"):format(r.entry.short, touched, (m and m.title) or "")
      end
      lines[#lines + 1] = ""
    end
  end

  kit.viewer({ title = "Company history", lines = lines })
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
        title = ("Cases — link check (%d dead, %d uncertain / %d)"):format(
          dead,
          uncertain,
          #results
        ),
        lines = lines,
      })
    end)
  end)
end

--- `:Cases export [nr]` — bundle Summary/Notes/Research/Replies into one
--- PDF via `export.lua` (pandoc + headless Chrome/Edge). Async, both
--- external tools; reports whichever step failed rather than a generic
--- error, since "pandoc missing" and "no browser found" need different
--- fixes from the user.
---@param case_arg string|nil
function M.export(case_arg)
  resolve.pick(case_arg, function(entry)
    if not entry then
      notify.warn("no case to export")
      return
    end
    local export = require("bindings.usrcmds.case.export")
    local m = meta.read(entry.dir)
    notify.info(("exporting %s…"):format(entry.short))
    export.export(entry, m, function(result)
      vim.schedule(function()
        if not result.ok then
          notify.error("export failed: " .. tostring(result.err))
          return
        end
        notify.info("exported: " .. result.path)
        local ok = require("lib.nvim.cross.open_default")(result.path)
        if not ok then
          notify.warn("PDF written but could not open it automatically: " .. result.path)
        end
      end)
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
  local dir = entry.dir .. "/" .. config.assets_dirname
  local st = uv.fs_stat(dir)
  if not (st and st.type == "directory") then
    notify.warn(("%s has no %s/ folder"):format(entry.short, config.assets_dirname))
    return
  end
  local files = collect_recursive.files(dir)
  if #files == 0 then
    notify.warn(("%s: %s/ is empty"):format(entry.short, config.assets_dirname))
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

--- `:Case attachments [nr]` — same picker `:Cases pickers` → Attachments
--- menu entry uses, reachable directly instead of through the discovery
--- menu.
---@param case_arg string|nil
function M.attachments(case_arg)
  resolve.pick(case_arg, function(entry)
    if not entry then
      notify.warn("no case to show attachments for")
      return
    end
    pick_attachment(entry)
  end)
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

--- `:Cases terminology` — every term collected from every `Terminologie.md`
--- across the whole work repo (`terminology.lua`), `kit.select`-picked.
--- Selecting one opens its source file with the cursor on the heading —
--- the point is reading the full entry in context, not just the preview
--- line, and jumping straight there beats a second "now open it" step.
function M.terminology()
  local terminology = require("bindings.usrcmds.case.terminology")
  local entries = terminology.list()
  if #entries == 0 then
    notify.warn("no Terminologie.md entries found")
    return
  end
  kit.select({
    message = ("Terminology (%d)"):format(#entries),
    selection = entries,
    format_item = function(e)
      local preview = e.body:gsub("%s+", " ")
      return ("%-30s  %s"):format(e.term, preview:sub(1, 80))
    end,
    on_select = function(e)
      edit(e.path)
      pcall(vim.api.nvim_win_set_cursor, 0, { e.line, 0 })
    end,
    on_cancel = function() end,
  })
end

-- ── :Tricentis commands / cheatsheet ─────────────────────────────────────

--- One picker row, in fixed columns:
--- `[topic ] <command>                  ×3  <heading>`
---
--- The heading is what turns a bare `adb shell pm clear <paket>` back into
--- something you can pick with confidence, so it earns its column. The
--- source file does NOT get one: at ~40 characters of repo-relative path it
--- pushed the command itself off the row, and the notify after selecting
--- names it anyway.
---@param h Lib.Case.CommandHit
---@return string
local function command_row(h)
  local cmd = h.first_line
  if h.extra_lines > 0 then
    cmd = ("%s (+%d)"):format(cmd, h.extra_lines)
  end
  return table.concat({
    "[" .. fit(h.topic, 8) .. "] ",
    fit(cmd, 62),
    "  ",
    count_col(h.count),
    "  ",
    h.context,
  })
end

--- `:Tricentis commands [topic]` — every shell command written down
--- anywhere in the work repo, `kit.select`-picked, selection copied to the
--- clipboard.
---
--- Copy rather than jump-to-source (what `:Cases terminology` does): a term
--- is something you READ in context, a command is something you PASTE — into
--- a terminal, or into a reply telling the customer what to run. The source
--- file is still on the row, so opening it stays one `:e` away when the
--- surrounding note is what you actually wanted.
---@param topic string|nil
function M.commands(topic)
  local commands = require("bindings.usrcmds.case.commands")
  local hits = commands.dedupe(commands.find(topic))
  local suffix = (topic and topic ~= "" and topic ~= "all") and (" — " .. topic) or ""
  if #hits == 0 then
    notify.warn(("no commands found%s"):format(suffix))
    return
  end

  kit.select({
    message = ("Commands%s (%d)"):format(suffix, #hits),
    selection = hits,
    format_item = command_row,
    on_select = function(h)
      require("lib.nvim.cross.copy_to_clipboard")(h.command)
      local rel = h.path:sub(#config.repo_root + 2)
      notify.info(("copied — %s:%d"):format(rel, h.line))
    end,
    on_cancel = function() end,
  })
end

--- `:Tricentis cheatsheet [topic]` — the same index, rendered into a
--- throwaway markdown buffer grouped by source file, in the order the notes
--- write them. That order is the point: for a walkthrough note like
--- `Emulator_AVD.md` the file order IS the run order, which a fuzzy picker
--- necessarily destroys.
---
--- Scratch buffer in a new tab, never written to disk — the repo already
--- holds the source of truth, and a generated file next to it would be a
--- second copy to keep in sync (the exact thing `commands.lua` exists to
--- avoid).
---@param topic string|nil
function M.cheatsheet(topic)
  local commands = require("bindings.usrcmds.case.commands")
  local hits = commands.find(topic)
  local label = (topic and topic ~= "" and topic ~= "all") and topic or "all"
  if #hits == 0 then
    notify.warn(("no commands found — %s"):format(label))
    return
  end

  local lines = {
    ("# CLI-Befehle — %s (%d)"):format(label, #hits),
    "",
    "Aus jedem Shell-Codeblock im Wissens-Repo. Quelle bearbeiten, nicht diesen Puffer.",
    "",
  }
  for _, group in ipairs(commands.group_by_file(hits)) do
    lines[#lines + 1] = "## " .. group.file
    lines[#lines + 1] = ""
    local last_context = nil
    for _, h in ipairs(group.hits) do
      if h.context ~= "" and h.context ~= last_context then
        lines[#lines + 1] = "### " .. h.context
        lines[#lines + 1] = ""
        last_context = h.context
      end
      lines[#lines + 1] = "```bash"
      vim.list_extend(lines, vim.split(h.command, "\n", { plain = true }))
      lines[#lines + 1] = "```"
      lines[#lines + 1] = ""
    end
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].filetype = "markdown"
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].modifiable = false
  pcall(vim.api.nvim_buf_set_name, buf, "casedesk://commands/" .. label)

  vim.cmd("tabnew")
  vim.api.nvim_win_set_buf(0, buf)
end

--- `:Cases pickers` — the discovery menu itself.
function M.pickers()
  kit.menu({
    title = "Cases — pickers",
    items = {
      {
        label = ("Attachments (%s/)"):format(config.assets_dirname),
        action = function()
          M.attachments(nil)
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
      {
        label = "Terminology",
        action = M.terminology,
      },
      {
        label = "CLI commands (whole repo)",
        action = function()
          M.commands(nil)
        end,
      },
      {
        label = "Solutions (every case)",
        action = function()
          M.solutions(nil)
        end,
      },
    },
  })
end

return M
