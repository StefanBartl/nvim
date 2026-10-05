-- TESTS/sync/sync_dash_picker_spec.lua -- the triage list as a real Snacks picker (headless):
-- rows, title, the keys of the plan, the detour into a repo and the closing line. Records are
-- written by hand (no git is needed for the keys); the git-backed flow is in sync_dash_spec.lua.
-- Skipped (reported, not failed) when snacks.nvim is not installed.

return function(H)
  local eq, ok, has = H.eq, H.ok, H.has

  local function find_snacks()
    -- No ipairs: the first candidate is nil when $SNACKS_DIR is unset.
    local candidates = { vim.env.SNACKS_DIR or "", vim.fn.stdpath("data") .. "/lazy/snacks.nvim" }
    for _, dir in ipairs(candidates) do
      if dir ~= "" and vim.fn.isdirectory(dir .. "/lua/snacks/picker") == 1 then
        return dir
      end
    end
    return nil
  end
  local snacks_dir = find_snacks()
  if not snacks_dir then
    io.stdout:write("      (snacks.nvim not found: this spec is skipped)\n")
    return
  end
  vim.opt.rtp:append(snacks_dir)
  local Snacks = require("snacks")

  local sync = require("bindings.usrcmds.plugin_repos.sync")
  local dash = require("bindings.usrcmds.plugin_repos.sync_dash")
  local classify = require("bindings.usrcmds.plugin_repos.sync_classify")

  local state_path = H.tmpdir() .. "/sync-state.json"
  local nowhere = H.tmpdir() .. "/nowhere" -- no such folder: previews degrade, nothing is run

  ---@return MyPlugins.SyncRecord
  local function rec(name, state, extra)
    return vim.tbl_extend("force", {
      name = name,
      path = nowhere .. "/" .. name,
      state = state,
      detail = state .. " detail",
      branch = "main",
      ahead = 0,
      behind = 0,
      dirty = false,
      changed = 0,
      skipped = false,
    }, extra or {})
  end
  local session = {
    dir = nowhere,
    dry_run = false,
    -- a run from the picker's selection: "R" must still run the WHOLE sync, in the same base dir
    opts = {
      state_path = state_path,
      quiet = false,
      dir = nowhere,
      names = { "alpha" },
      partial = true,
      only = "alpha",
      dry_run = false,
    },
    records = {
      rec("alpha", "diverged", { ahead = 1, behind = 2 }),
      rec("beta", "dirty_blocked", { behind = 1 }),
      rec("gamma", "no_upstream"),
      rec("delta", "ahead", { ahead = 3 }),
      rec("eps", "current"),
    },
  }

  local orig = {
    notify = vim.notify,
    go_into = dash.go_into,
    recheck = sync.recheck,
    run = sync.run,
    busy_reason = sync.busy_reason,
  }
  local notes = {}
  vim.notify = function(msg, level)
    notes[#notes + 1] = { msg = msg, level = level or vim.log.levels.INFO }
  end
  local entered, rechecked, reran, rerun_opts, decline = {}, {}, 0, nil, false
  -- `held`: the re-check does not end until the spec says so; `busy`: repo name -> reason
  local held, busy = nil, {}
  -- the `on_stopped` callbacks of held re-checks (what a cancel / a new run triggers)
  local held_stop = {}
  dash.go_into = function(path, how, on_close)
    entered[#entered + 1] = { path = path, how = how }
    vim.schedule(on_close)
  end
  sync.recheck = function(_, names, cb, on_stopped)
    for _, n in ipairs(names) do
      rechecked[#rechecked + 1] = n
    end
    if held then
      held[#held + 1] = cb
      held_stop[#held_stop + 1] = on_stopped
      return { stop = function() end }
    end
    vim.schedule(cb)
    return { stop = function() end }
  end
  sync.busy_reason = function(path)
    return busy[vim.fs.basename(path)]
  end
  sync.run = function(o)
    reran = reran + 1
    rerun_opts = o
    if decline and o.on_declined then
      o.on_declined() -- "A sync is already running": the user said no
    end
  end

  local function wait_for(cond, ms)
    return vim.wait(ms or 5000, cond, 10)
  end
  local function flush()
    vim.wait(60, function()
      return false
    end)
  end
  local function current_picker()
    for _, p in ipairs(Snacks.picker.get({ source = "myplugins_sync" })) do
      if not p.closed then
        return p
      end
    end
    return nil
  end
  local function opened(n)
    ok(
      wait_for(function()
        local p = current_picker()
        return p ~= nil and p:count() == n and not p.finder.task:running()
      end),
      "the list opens with " .. n .. " row(s)"
    )
    local p = assert(current_picker())
    flush()
    return p
  end
  local function names(p)
    return vim.tbl_map(function(i)
      return i.rec.name
    end, p:items())
  end
  local function keys(k)
    vim.api.nvim_feedkeys(vim.keycode(k), "mx", false)
    flush()
  end
  local function said()
    local out = {}
    for _, n in ipairs(notes) do
      out[#out + 1] = n.msg
    end
    return table.concat(out, "\n")
  end

  local function restore()
    vim.notify, dash.go_into, sync.recheck, sync.run, sync.busy_reason =
      orig.notify, orig.go_into, orig.recheck, orig.run, orig.busy_reason
    for _, p in ipairs(Snacks.picker.get({ source = "myplugins_sync" })) do
      pcall(p.close, p)
    end
    pcall(vim.cmd, "silent! %bwipeout!")
  end

  local passed, err = pcall(function()
    ok(dash.open(session), "the list opens")
    local p = opened(3)
    eq(names(p), { "alpha", "beta", "gamma" }, "problems only, the worst first (hints are hidden)")
    has(p.title, "3 unresolved, 0 skipped", "title")
    local lines = vim.api.nvim_buf_get_lines(p.list.win.buf, 0, 3, false)
    has(lines[1], "diverged", "a row shows the state")
    has(lines[1], "alpha", "...the name")
    has(lines[1], "+1 -2", "...and ahead/behind")
    ok(p.opts.preview == "preview", "items carry their own preview text")

    -- ── a: the hints come and go ──────────────────────────────────────────
    p:focus("list")
    flush()
    keys("a")
    p = opened(4)
    eq(names(p)[4], "delta", "the repo that is only ahead appears as a hint")
    keys("a")
    opened(3)

    -- ── s on the row: skipped, still listed, saved ────────────────────────
    keys("s")
    p = opened(3)
    eq(session.records[1].skipped, true, "alpha is skipped")
    has(p.title, "2 unresolved, 1 skipped", "the title counts it")
    eq(names(p)[3], "alpha", "a skipped row sorts after the open problems")
    local function preview_of_row(n)
      for _, i in ipairs(p:items()) do
        if i.rec.name == n then
          return i.preview.text
        end
      end
    end
    has(
      preview_of_row("alpha"),
      "skipped, diverged",
      "the preview header says skipped right after the skip"
    )
    ok(vim.fn.filereadable(state_path) == 1, "the skip was saved")
    -- after a skip the next row is under the cursor (triage moves on); alpha is last now
    keys("G")
    keys("u")
    p = opened(3)
    eq(session.records[1].skipped, false, "u un-skips the row under the cursor")
    H.lacks(preview_of_row("alpha"), "skipped, ", "...and the preview header drops it again")

    -- ── <Tab> marks: s acts on all of them ────────────────────────────────
    keys("<Tab>")
    keys("<Tab>")
    eq(#p:selected(), 2, "two rows are marked")
    keys("s")
    opened(3)
    local skipped = 0
    for _, r in ipairs(session.records) do
      if r.skipped then
        skipped = skipped + 1
      end
    end
    eq(skipped, 2, "both marked rows were skipped")
    sync.set_skipped(session, { "alpha", "beta", "gamma" }, false)
    keys("a") -- a refresh through the hints toggle, twice
    keys("a")
    opened(3)

    -- ── y yanks the path ──────────────────────────────────────────────────
    keys("y")
    has(said(), "yanked", "y says what it yanked")

    -- ── r re-checks the row (no fetch) and the list refreshes ────────────
    rechecked = {}
    p:focus("list")
    keys("gg")
    keys("r")
    ok(
      wait_for(function()
        return #rechecked > 0
      end),
      "r asked for a re-check"
    )
    eq(rechecked, { "alpha" }, "...of the row under the cursor, and only of it")
    p = opened(3)

    -- ── a busy row ignores r / L / A / t with a notice, nothing starts ────
    busy.alpha = "a re-check is running"
    p:focus("list")
    keys("gg")
    rechecked, entered, notes = {}, {}, {}
    keys("r")
    keys("L")
    keys("t")
    keys("A")
    flush()
    eq(rechecked, {}, "busy: r starts no second re-check")
    eq(entered, {}, "busy: L and t do not go into the repo")
    ok(current_picker() == p, "busy: the list stays open (no detour)")
    has(said(), "alpha: a re-check is running -- ignored", "busy: the notice says why")
    busy.alpha = nil
    p = opened(3)

    -- ── L goes into the repo: the list closes without a closing line ──────
    notes = {}
    entered = {}
    keys("L")
    ok(
      wait_for(function()
        return #entered > 0
      end),
      "L went into a repo"
    )
    eq(entered[1].how, "lazygit", "L is lazygit")
    eq(
      vim.fs.normalize(entered[1].path),
      vim.fs.normalize(nowhere .. "/alpha"),
      "...in the repo of the row under the cursor"
    )
    ok(
      wait_for(function()
        return current_picker() ~= nil
      end),
      "after the re-check the list opens again"
    )
    ok(
      not said():find("unresolved", 1, true),
      "a detour is no end: no closing line while the user is in a repo"
    )

    -- ── t is the terminal way in ──────────────────────────────────────────
    p = opened(3)
    p:focus("list")
    flush()
    keys("G")
    entered = {}
    keys("t")
    ok(
      wait_for(function()
        return #entered > 0
      end),
      "t went into a repo"
    )
    eq(entered[1].how, "terminal", "t is the terminal")
    eq(
      vim.fs.normalize(entered[1].path),
      vim.fs.normalize(nowhere .. "/gamma"),
      "...in the repo of the row under the cursor (the last one)"
    )
    opened(3)

    -- ── R runs everything again (a detour as well) ────────────────────────
    p = assert(current_picker())
    p:focus("list")
    flush()
    notes = {}
    keys("R")
    ok(
      wait_for(function()
        return reran == 1
      end),
      "R started a full run"
    )
    ok(not said():find("unresolved", 1, true), "...without a closing line of its own")
    eq(rerun_opts.names, nil, "R drops the picker's selection")
    eq(rerun_opts.partial, nil, "R drops the partial flag")
    eq(rerun_opts.only, nil, "R drops --only")
    eq(rerun_opts.dir, nowhere, "R keeps the base dir")

    -- ── ...and declining the restart prompt must not lose the closing line ──
    dash.open(session)
    p = opened(3)
    p:focus("list")
    flush()
    notes, decline = {}, true
    keys("R")
    ok(
      wait_for(function()
        return said():find("3 unresolved: ", 1, true) ~= nil
      end),
      "declined restart: the closing line is still said"
    )
    decline = false
    for _, q in ipairs(Snacks.picker.get({ source = "myplugins_sync" })) do
      pcall(q.close, q)
    end
    flush()

    -- ── closing the list says the one closing line ───────────────────────
    dash.open(session)
    p = opened(3)
    p:focus("list")
    flush()
    notes = {}
    p:close()
    ok(
      wait_for(function()
        return said():find("unresolved", 1, true) ~= nil
      end),
      "closing the list says the closing line"
    )
    has(said(), "3 unresolved: ", "with the unresolved repos named")
    has(said(), "alpha", "alpha")
    has(said(), "gamma", "gamma")
    local summary = classify.summarize(session.records)
    eq(#summary.unresolved, 3, "nothing was lost on the way")

    -- ── g? opens the help and the list survives it ───────────────────────
    dash.open(session)
    p = opened(3)
    p:focus("list")
    flush()
    keys("g?")
    ok(current_picker() == p, "the picker survived the help")
    -- any key closes the help and is discarded: `s` would otherwise skip the row under the cursor
    local before = vim.deepcopy(session.records)
    keys("s")
    eq(session.records, before, "the key that closes the help does not act in the list")
    flush()
    ok(current_picker() == p, "the picker is still open after the help closed")
    local help_open = false
    for _, w in ipairs(vim.api.nvim_list_wins()) do
      if vim.api.nvim_win_get_config(w).zindex == 250 then
        help_open = true
      end
    end
    ok(not help_open, "the help window is gone")
    -- the key hook is really gone: the next `s` is an ordinary key again
    keys("gg")
    keys("s")
    eq(session.records[1].skipped, true, "after the help closed, s skips again")
    sync.set_skipped(session, { "alpha" }, false)

    -- ── closing the list while a re-check is pending: the closing line waits ──
    for _, q in ipairs(Snacks.picker.get({ source = "myplugins_sync" })) do
      pcall(q.close, q)
    end
    flush()
    dash.open(session)
    p = opened(3)
    p:focus("list")
    flush()
    notes, held, rechecked = {}, {}, {}
    keys("gg")
    keys("r")
    ok(
      wait_for(function()
        return #held == 1
      end),
      "a re-check is pending"
    )
    p:close()
    flush()
    ok(not said():find("unresolved", 1, true), "closed while pending: no stale closing line yet")
    -- the re-check ends: the repo is fixed in the meantime
    session.records[1] = rec("alpha", "pulled")
    local pending = held
    held = nil
    pending[1]()
    ok(
      wait_for(function()
        return said():find("unresolved", 1, true) ~= nil
      end),
      "the closing line comes when the re-check ended"
    )
    has(said(), "2 unresolved: ", "...and it counts the result of the re-check, not the old state")
    H.lacks(notes[#notes].msg, "alpha", "alpha is no longer named in the closing line")

    -- ── a re-check that is STOPPED (cancel, a new run) is no longer pending ──
    for _, q in ipairs(Snacks.picker.get({ source = "myplugins_sync" })) do
      pcall(q.close, q)
    end
    flush()
    session.records[1] = rec("alpha", "pull_failed")
    dash.open(session)
    p = opened(3)
    p:focus("list")
    flush()
    notes, held, held_stop, rechecked = {}, {}, {}, {}
    keys("gg")
    keys("r")
    ok(
      wait_for(function()
        return #held == 1
      end),
      "a re-check is pending again"
    )
    eq(type(held_stop[1]), "function", "the list hears when the re-check is stopped")
    held_stop[1]() -- :MyPlugins sync cancel: stopped, on_done never comes
    held = nil
    p:close()
    flush()
    ok(
      wait_for(function()
        return said():find("unresolved", 1, true) ~= nil
      end),
      "closing after a stopped re-check still says the closing line"
    )
  end)

  restore()
  if not passed then
    error(err, 0)
  end
end
