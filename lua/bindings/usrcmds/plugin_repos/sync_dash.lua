---@module 'bindings.usrcmds.plugin_repos.sync_dash'
---@brief The triage list of `:MyPlugins sync`: every repo that could not be brought up to date.
---@description
--- A Snacks picker in the style of `tasks_dash.lua` (one row per problem repo, a preview of
--- what blocks it), with a plain `vim.ui.select` fallback when snacks.nvim is not installed.
--- The point is to get out of the list with nothing unresolved: go INTO a repo (lazygit, or a
--- terminal in its directory), fix it there, and the moment that window closes the repo is
--- re-checked and pulled again -- a solved repo drops out of the list by itself. What the user
--- does not want to deal with now is skipped (it stays visible as `skipped`, and is named in
--- the closing line); a skip lasts for this synchronization only.
---
--- Keys (list window; in the search window the same actions are on Alt chords):
---   `<CR>` / `L` lazygit in the repo       `t` terminal in the repo
---   `s` skip / `u` un-skip                 `r` try the pull again   `R` run it all again
---   `a` show / hide the hints (ahead, dirty)   `y` yank the path   `g?` help
---   `A` assist: rebase / merge a diverged repo, stash-pull-pop a blocked one (asks first)
---   `<Tab>` marks (skip, un-skip and retry act on the marks, else on the row)
---
--- Not its job: git calls for the run (`sync.lua`), the decisions (`sync_classify.lua`).

local ops = require("bindings.usrcmds.plugin_repos.ops")
local classify = require("bindings.usrcmds.plugin_repos.sync_classify")
local confirm = require("bindings.usrcmds.plugin_repos.confirm")
local notify = require("lib.nvim.notify").create("[usrcmds.plugin_repos.sync]")

local M = {}

---Timeout of one git call of the preview.
M.PREVIEW_TIMEOUT_MS = 20000

---@class MyPlugins.SyncDash
---@field session MyPlugins.SyncSession
---@field show_hints boolean
---@field detour boolean       The picker was closed on purpose (lazygit, rerun ...): no closing line yet.
---@field finished boolean     The closing line was said.
---@field loading table<string, boolean>  Previews being loaded.
---@field pending integer      Re-checks started with `r` that have not ended.
---@field finish_when_idle boolean  The list was closed while re-checks were pending: the closing line waits for them.

local function sync()
  return require("bindings.usrcmds.plugin_repos.sync")
end

-- ── Preview ───────────────────────────────────────────────────────────────────

---@class MyPlugins.SyncPreviewParts
---@field status string[]      `git status -sb`
---@field incoming string[]    `git log --oneline HEAD..@{u}`
---@field outgoing string[]    `git log --oneline @{u}..HEAD`
---@field blocking string[]    Local changes that the incoming commits also touch (dirty_blocked).
---@field blocking_known? boolean  Both the status and the incoming files were read (an empty `blocking` is then a real "no overlap").

---The preview text of one repo. Pure.
---@param rec MyPlugins.SyncRecord
---@param parts MyPlugins.SyncPreviewParts
---@return string[]
function M.preview_lines(rec, parts)
  local lines = {
    ("%s   %s"):format(rec.name, rec.path),
    ("%s%s   %s%s"):format(
      rec.skipped and "skipped, " or "",
      rec.state,
      rec.branch or "(no branch)",
      rec.upstream and (" -> " .. rec.upstream) or ""
    ),
  }
  if rec.detail and rec.detail ~= "" then
    lines[#lines + 1] = rec.detail
  end
  ---@param title string
  ---@param list string[]
  ---@param empty string
  local function section(title, list, empty)
    lines[#lines + 1] = ""
    lines[#lines + 1] = "## " .. title
    if #list == 0 then
      lines[#lines + 1] = empty
    else
      vim.list_extend(lines, list)
    end
  end
  section("git status -sb", parts.status, "(unavailable)")
  section("Coming in (HEAD..@{u})", parts.incoming, "(nothing)")
  section("Going out (@{u}..HEAD)", parts.outgoing, "(nothing)")
  if rec.state == "dirty_blocked" or #parts.blocking > 0 then
    section(
      "Blocking the pull (changed here AND by the incoming commits)",
      parts.blocking,
      parts.blocking_known and "(no overlap: the pull failed for another reason, see above)"
        or "(could not be determined)"
    )
  end
  return lines
end

---@param text string
---@return string[]
local function split_lines(text)
  local out = {}
  for line in text:gmatch("[^\r\n]+") do
    out[#out + 1] = line
  end
  return out
end

---Load the preview of one record (several git calls, one after the other) into `rec.preview`.
---@param rec MyPlugins.SyncRecord
---@param on_done fun()
function M.load_preview(rec, on_done)
  local t = M.PREVIEW_TIMEOUT_MS
  ---@type MyPlugins.SyncPreviewParts
  local parts = { status = {}, incoming = {}, outgoing = {}, blocking = {} }
  ops.git_async(rec.path, { "status", "-sb" }, { timeout_ms = t, read_only = true }, function(run)
    if run.code == 0 then
      parts.status = split_lines(run.stdout)
    end
    ops.sync_log(rec.path, "HEAD..@{u}", t, function(incoming)
      parts.incoming = incoming
      ops.sync_log(rec.path, "@{u}..HEAD", t, function(outgoing)
        parts.outgoing = outgoing
        local function done()
          rec.preview_parts = parts
          rec.preview = M.preview_lines(rec, parts)
          on_done()
        end
        if rec.state ~= "dirty_blocked" then
          done()
          return
        end
        ops.sync_status(rec.path, t, function(text)
          local mine = text and classify.parse_status(text).files or nil
          ops.sync_incoming_files(rec.path, t, function(theirs)
            -- the same rule as `after_pull`: an untracked directory (`d/`) blocks when anything
            -- incoming lives below it
            parts.blocking = classify.blocking_files(mine, theirs)
            parts.blocking_known = mine ~= nil and theirs ~= nil
            done()
          end)
        end)
      end)
    end)
  end)
end

---The preview lines of a record, rebuilt from the loaded git output so the header (state,
---`skipped, `) is always the record's current one.
---@param rec MyPlugins.SyncRecord
---@return string[]|nil
local function preview_of(rec)
  if rec.preview_parts then
    return M.preview_lines(rec, rec.preview_parts)
  end
  return rec.preview
end

---Load the previews the list will show that are not loaded yet; `on_done` runs after.
---@param dash MyPlugins.SyncDash
---@param on_done fun()
local function prefetch(dash, on_done)
  local missing = {}
  for _, r in ipairs(classify.visible(dash.session.records, dash.show_hints)) do
    if not r.preview and not dash.loading[r.name] then
      dash.loading[r.name] = true
      missing[#missing + 1] = r
    end
  end
  ops.run_pool(
    missing,
    3,
    function(rec, done)
      M.load_preview(rec, function()
        dash.loading[rec.name] = nil
        done(true)
      end)
      return nil
    end,
    nil,
    function()
      on_done()
    end
  )
end

-- ── Going into a repo ─────────────────────────────────────────────────────────

---Run `on_close` once, when window `win` closes.
---@param win integer
---@param on_close fun()
local function after_close(win, on_close)
  vim.api.nvim_create_autocmd("WinClosed", {
    pattern = tostring(win),
    once = true,
    callback = function()
      vim.schedule(on_close)
    end,
  })
end

---A terminal split in the repo's directory.
---@param path string
---@param on_close fun()
local function open_terminal(path, on_close)
  vim.cmd("botright 15new")
  local win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_get_current_buf()
  vim.bo[buf].bufhidden = "wipe"
  after_close(win, on_close)
  local job = vim.fn.jobstart(vim.o.shell, {
    term = true,
    cwd = path,
    on_exit = function()
      vim.schedule(function()
        if vim.api.nvim_win_is_valid(win) then
          pcall(vim.api.nvim_win_close, win, true)
        end
      end)
    end,
  })
  if job <= 0 then
    notify.error("cannot start a shell in " .. path)
    pcall(vim.api.nvim_win_close, win, true)
    return
  end
  vim.cmd("startinsert")
end

---Go into a repo: lazygit (gitsuite.nvim) or a terminal in its directory. `on_close` runs when
---that window is gone -- the signal to check the repo again. Replaceable (the specs do).
---@param path string
---@param how "lazygit"|"terminal"
---@param on_close fun()
function M.go_into(path, how, on_close)
  if how == "lazygit" and vim.fn.executable("lazygit") == 1 then
    local ok_ui, ui = pcall(require, "gitsuite.features.ui")
    if ok_ui and type(ui.lazygit) == "function" then
      local before = vim.api.nvim_get_current_win()
      local ok_open = pcall(ui.lazygit, path)
      local win = vim.api.nvim_get_current_win()
      if ok_open and win ~= before then
        after_close(win, on_close)
        return
      end
    end
  end
  open_terminal(path, on_close)
end

-- ── Help ──────────────────────────────────────────────────────────────────────

M.HELP = {
  " Sync triage ",
  "",
  " <CR> / L   lazygit in the repo; when it closes the repo is checked and pulled again",
  " t          a terminal in the repo (same re-check when it closes)",
  " s / u      skip / un-skip (for this synchronization only; marked rows, else the row)",
  " r          try the pull again (marked rows, else the row; fetches again if the fetch failed)",
  " R          run the whole sync again",
  " a          show / hide the hints (ahead of upstream, local changes only)",
  " A          assist: rebase / merge (diverged), stash-pull-pop (blocked); asks first, names the commands",
  " y          yank the repo path",
  " <Tab>      mark / unmark",
  " g?         this help",
  "",
  " Letters work in the list. In the search window use Alt:",
  " <M-l> <M-t> <M-s> <M-u> <M-r> <M-R> <M-a> <M-A> <M-y> <M-?>",
  " (any key closes this help)",
}

function M.show_help()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, M.HELP)
  local width = 0
  for _, l in ipairs(M.HELP) do
    width = math.max(width, vim.fn.strdisplaywidth(l))
  end
  local win = vim.api.nvim_open_win(buf, false, {
    relative = "editor",
    row = math.max(0, math.floor((vim.o.lines - #M.HELP) / 2) - 1),
    col = math.max(0, math.floor((vim.o.columns - width - 2) / 2)),
    width = width + 2,
    height = #M.HELP,
    style = "minimal",
    border = "rounded",
    zindex = 250,
  })
  local ns = vim.api.nvim_create_namespace("sync_dash_help")
  vim.on_key(function()
    vim.on_key(nil, ns)
    vim.schedule(function()
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
      end
      if vim.api.nvim_buf_is_valid(buf) then
        vim.api.nvim_buf_delete(buf, { force = true })
      end
    end)
    -- The focus stays in the list: an empty string discards the key, otherwise the key that
    -- closes the help would also run there (`s` would skip a repo, any other one fails with E21).
    return ""
  end, ns)
end

-- ── Shared actions ────────────────────────────────────────────────────────────

---@param dash MyPlugins.SyncDash
local function finish(dash)
  if dash.finished then
    return
  end
  dash.finished = true
  sync().finish(dash.session)
end

---A row whose repo has an operation in flight ignores r / A / L / t (with a short notice).
---@param rec MyPlugins.SyncRecord
---@return boolean busy
local function ignore_busy(rec)
  local why = sync().busy_reason(rec.path)
  if why then
    notify.info(("%s: %s -- ignored"):format(rec.name, why))
    return true
  end
  return false
end

---@param dash MyPlugins.SyncDash
---@return string
local function title_of(dash)
  local s = classify.summarize(dash.session.records)
  return ("Sync: %d unresolved, %d skipped%s"):format(
    #s.unresolved,
    #s.skipped,
    dash.show_hints and " (+ hints)" or ""
  )
end

---The options of a full re-run: the same as the run that made this list (base dir, dry run), but
---for every repo -- not only the picker's selection or the `--only` repo.
---@param dash MyPlugins.SyncDash
---@return MyPlugins.SyncOpts
local function rerun_opts(dash)
  local opts = vim.deepcopy(dash.session.opts)
  opts.only = nil
  opts.names = nil
  opts.partial = nil
  opts.on_done = nil
  opts.on_declined = nil
  return opts
end

---Run the whole sync again; the new run reports for itself. When it does not start (the user
---declined to cancel the sync that is running) this list's closing line is still due.
---@param dash MyPlugins.SyncDash
local function rerun(dash)
  dash.finished = true
  local opts = rerun_opts(dash)
  opts.on_declined = function()
    dash.finished = false
    finish(dash)
  end
  sync().run(opts)
end

---@param names string[]
---@return string
local function join_names(names)
  return table.concat(names, ", ")
end

local show

---Offer the assist actions of a repo, ask (the question names the exact commands), run the one
---chosen and re-check the repo. `on_done` runs whatever the answer was.
---@param dash MyPlugins.SyncDash
---@param rec MyPlugins.SyncRecord
---@param ids MyPlugins.SyncAssist[]
---@param on_done fun()
function M.assist_flow(dash, rec, ids, on_done)
  ---@param id MyPlugins.SyncAssist
  local function ask(id)
    confirm.yesno(classify.assist_prompt(rec, id), classify.ASSISTS[id].label, function(yes)
      if not yes then
        on_done()
        return
      end
      sync().assist(dash.session, rec.name, id, on_done)
    end)
  end
  if #ids == 1 then
    ask(ids[1])
    return
  end
  vim.ui.select(ids, {
    prompt = rec.name .. ": assist",
    format_item = function(id)
      return classify.ASSISTS[id].label
    end,
  }, function(id)
    if id then
      ask(id)
    else
      on_done()
    end
  end)
end

-- ── Snacks backend ────────────────────────────────────────────────────────────

---@param Snacks table
---@param dash MyPlugins.SyncDash
local function open_snacks(Snacks, dash)
  local session = dash.session

  ---@return table[]
  local function items()
    local out = {}
    for _, r in ipairs(classify.visible(session.records, dash.show_hints)) do
      out[#out + 1] = {
        text = ("%s %s %s"):format(r.name, r.state, r.detail or ""),
        rec = r,
        preview = {
          text = table.concat(preview_of(r) or { "(loading ...)" }, "\n"),
          loc = false,
        },
      }
    end
    return out
  end

  ---Rebuild the rows in place; close the list when nothing unresolved or skipped is left.
  ---@param picker table
  local function refresh(picker)
    if picker.closed then
      return
    end
    if #classify.visible(session.records, false) == 0 then
      picker:close()
      return
    end
    prefetch(dash, function()
      if picker.closed then
        return
      end
      picker.title = title_of(dash)
      pcall(picker.update_titles, picker)
      picker.list:set_selected()
      picker:find({ refresh = true })
    end)
  end

  ---Marked records, else (with `fallback`) the current one.
  ---@param picker table
  ---@param fallback boolean
  ---@return MyPlugins.SyncRecord[]
  local function targets(picker, fallback)
    local out = {}
    for _, item in ipairs(picker:selected({ fallback = fallback })) do
      if item and item.rec then
        out[#out + 1] = item.rec
      end
    end
    return out
  end

  ---@param recs MyPlugins.SyncRecord[]
  ---@return string[]
  local function names_of(recs)
    local out = {}
    for _, r in ipairs(recs) do
      out[#out + 1] = r.name
    end
    return out
  end

  ---Close the list, run `fn`, and say nothing yet (the closing line comes when it really ends).
  ---@param picker table
  ---@param fn fun()
  local function detour(picker, fn)
    dash.detour = true
    picker:close()
    vim.schedule(fn)
  end

  ---@param how "lazygit"|"terminal"
  ---@return fun(picker: table)
  local function enter(how)
    return function(picker)
      local item = picker:current()
      local rec = item and item.rec
      if not rec or ignore_busy(rec) then
        return
      end
      detour(picker, function()
        M.go_into(rec.path, how, function()
          sync().recheck(session, { rec.name }, function()
            dash.detour = false
            show(dash)
          end)
        end)
      end)
    end
  end

  local actions = {
    sync_lazygit = enter("lazygit"),
    sync_terminal = enter("terminal"),
    sync_skip = function(picker)
      local names = names_of(targets(picker, true))
      sync().set_skipped(session, names, true)
      refresh(picker)
    end,
    sync_unskip = function(picker)
      local names = names_of(targets(picker, true))
      sync().set_skipped(session, names, false)
      refresh(picker)
    end,
    sync_retry = function(picker)
      local names = {}
      for _, r in ipairs(targets(picker, true)) do
        if not ignore_busy(r) then
          names[#names + 1] = r.name
        end
      end
      if #names == 0 then
        return
      end
      notify.info("re-checking " .. join_names(names) .. " ...")
      dash.pending = dash.pending + 1
      -- ended or stopped (cancel, a new run): either way the closing line may stop waiting
      local function settle()
        dash.pending = dash.pending - 1
        -- closed meanwhile: the closing line was waiting for this result
        if dash.finish_when_idle and dash.pending == 0 then
          finish(dash)
        end
      end
      sync().recheck(session, names, function()
        settle()
        refresh(picker)
      end, settle)
    end,
    sync_rerun = function(picker)
      detour(picker, function()
        rerun(dash)
      end)
    end,
    sync_assist = function(picker)
      local item = picker:current()
      local rec = item and item.rec
      if not rec or ignore_busy(rec) then
        return
      end
      local ids = classify.assists_for(rec)
      if #ids == 0 then
        notify.info(("no assist action for a %s repo -- L opens lazygit"):format(rec.state))
        return
      end
      detour(picker, function()
        M.assist_flow(dash, rec, ids, function()
          dash.detour = false
          show(dash)
        end)
      end)
    end,
    sync_hints = function(picker)
      dash.show_hints = not dash.show_hints
      refresh(picker)
    end,
    sync_yank = function(picker)
      local item = picker:current()
      if item and item.rec then
        vim.fn.setreg("+", item.rec.path)
        vim.fn.setreg('"', item.rec.path)
        notify.info("yanked " .. item.rec.path)
      end
    end,
    sync_help = function()
      M.show_help()
    end,
  }

  -- Letters in the list window (nothing is typed there); Alt chords in the input window.
  local letters = {
    L = { "sync_lazygit", "<M-l>" },
    t = { "sync_terminal", "<M-t>" },
    s = { "sync_skip", "<M-s>" },
    u = { "sync_unskip", "<M-u>" },
    r = { "sync_retry", "<M-r>" },
    R = { "sync_rerun", "<M-R>" },
    a = { "sync_hints", "<M-a>" },
    A = { "sync_assist", "<M-A>" },
    y = { "sync_yank", "<M-y>" },
    ["g?"] = { "sync_help", "<M-?>" },
  }
  local list_keys, input_keys = {}, {}
  for key, spec in pairs(letters) do
    list_keys[key] = spec[1]
    input_keys[spec[2]] = { spec[1], mode = { "n", "i" } }
  end

  Snacks.picker({
    source = "myplugins_sync",
    title = title_of(dash),
    finder = function()
      return items()
    end,
    format = function(item)
      local r = item.rec
      local hl = "DiagnosticError"
      if r.skipped then
        hl = "DiagnosticWarn"
      elseif classify.is_hint(r.state) then
        hl = "Comment"
      elseif r.state == "pulled" or r.state == "current" then
        hl = "DiagnosticOk"
      end
      local line = classify.format_line(r)
      -- one highlight for the whole row: the columns are already aligned in the text
      return { { line, hl } }
    end,
    preview = "preview",
    confirm = "sync_lazygit",
    show_empty = true,
    actions = actions,
    win = { input = { keys = input_keys }, list = { keys = list_keys } },
    on_close = function()
      if dash.detour then
        return
      end
      if dash.pending > 0 then
        dash.finish_when_idle = true
        return
      end
      finish(dash)
    end,
  })
end

-- ── Fallback backend (no snacks.nvim) ─────────────────────────────────────────

---@param dash MyPlugins.SyncDash
local function open_select(dash)
  local session = dash.session
  local rows = classify.visible(session.records, dash.show_hints)
  local function again()
    show(dash)
  end
  vim.ui.select(rows, {
    prompt = title_of(dash),
    format_item = function(r)
      return classify.format_line(r)
    end,
  }, function(rec)
    if not rec then
      finish(dash)
      return
    end
    local menu = {
      {
        label = "go into the repo (lazygit)",
        run = function()
          M.go_into(rec.path, "lazygit", function()
            sync().recheck(session, { rec.name }, again)
          end)
        end,
      },
      {
        label = "terminal in the repo",
        run = function()
          M.go_into(rec.path, "terminal", function()
            sync().recheck(session, { rec.name }, again)
          end)
        end,
      },
      {
        label = rec.skipped and "un-skip" or "skip (for this sync only)",
        run = function()
          sync().set_skipped(session, { rec.name }, not rec.skipped)
          again()
        end,
      },
      {
        label = "try the pull again",
        run = function()
          sync().recheck(session, { rec.name }, again)
        end,
      },
      {
        label = "run the whole sync again",
        run = function()
          rerun(dash)
        end,
      },
      {
        label = dash.show_hints and "hide the hints" or "show the hints (ahead, dirty)",
        run = function()
          dash.show_hints = not dash.show_hints
          again()
        end,
      },
      {
        label = "yank the path",
        run = function()
          vim.fn.setreg("+", rec.path)
          vim.fn.setreg('"', rec.path)
          notify.info("yanked " .. rec.path)
          again()
        end,
      },
      {
        label = "show the preview",
        run = function()
          local text = table.concat(preview_of(rec) or { "(not loaded)" }, "\n")
          notify.info(text)
          again()
        end,
      },
    }
    for _, id in ipairs(classify.assists_for(rec)) do
      table.insert(menu, 3, {
        label = "assist: " .. classify.ASSISTS[id].label,
        run = function()
          M.assist_flow(dash, rec, { id }, again)
        end,
      })
    end
    vim.ui.select(menu, {
      prompt = rec.name .. "  " .. rec.state,
      format_item = function(m)
        return m.label
      end,
    }, function(choice)
      if choice then
        choice.run()
      else
        again()
      end
    end)
  end)
end

-- ── Entry ─────────────────────────────────────────────────────────────────────

---Open (or reopen after a detour) the list: previews first, then the picker.
---@param dash MyPlugins.SyncDash
---@return boolean opened  false: nothing unresolved or skipped is left (the closing line was said)
function show(dash)
  if #classify.visible(dash.session.records, false) == 0 then
    finish(dash)
    return false
  end
  prefetch(dash, function()
    local ok_snacks, Snacks = pcall(require, "snacks")
    if M.backend ~= "select" and ok_snacks and type(Snacks) == "table" and Snacks.picker then
      local opened, err = pcall(open_snacks, Snacks, dash)
      if opened then
        return
      end
      notify.warn(("snacks picker failed (%s), using the plain list"):format(tostring(err)))
    end
    open_select(dash)
  end)
  return true
end

---Force a backend (`"select"`: the plain list). nil: snacks when it is there.
---@type "select"|nil
M.backend = nil

---Open the triage list of a session.
---@param session MyPlugins.SyncSession
---@return boolean opened  false when there is nothing unresolved or skipped to triage
function M.open(session)
  ---@type MyPlugins.SyncDash
  local dash = {
    session = session,
    show_hints = false,
    detour = false,
    finished = false,
    loading = {},
    pending = 0,
    finish_when_idle = false,
  }
  return show(dash)
end

return M
