-- TESTS/sync/sync_busy_spec.lua -- one writer per repo: re-checks, assists and full runs of
-- `:MyPlugins sync` are serialized per repo (REAL git). Two concurrent `git merge --ff-only`
-- on one repo collide on index.lock, and whichever chain ends last overwrites the record.

return function(H)
  local eq, ok, has = H.eq, H.ok, H.has

  if vim.fn.executable("git") ~= 1 then
    return
  end

  local sync = require("bindings.usrcmds.plugin_repos.sync")

  local fx = dofile(vim.fs.dirname(debug.getinfo(1, "S").source:sub(2)) .. "/fixture.lua")(H)
  local base, git, make, incoming = fx.base, fx.git, fx.make, fx.incoming
  local state_path = H.tmpdir() .. "/sync-state.json"

  local orig_notify = vim.notify
  local notes = {}
  vim.notify = function(msg)
    notes[#notes + 1] = msg
  end

  local function said()
    return table.concat(notes, "\n")
  end
  local function wait_for(cond, ms)
    return vim.wait(ms or 30000, cond, 10)
  end
  local function settle(ms)
    vim.wait(ms or 400, function()
      return false
    end)
  end

  ---A repo that is one commit behind (fetched), and a dashboard session holding its `behind`
  ---record: what a re-check starts from.
  ---@param name string
  local function behind_session(name)
    local c = make(name)
    incoming(c, "b.txt", "new " .. name .. "\n")
    git(c.repo, "fetch", "-q")
    local records
    sync.run({
      dir = base,
      names = { name },
      dry_run = true,
      no_fetch = true,
      quiet = true,
      ui = false,
      state_path = state_path,
      on_done = function(r)
        records = r
      end,
    })
    ok(
      wait_for(function()
        return records ~= nil
      end),
      name .. ": the dry run classified the repo"
    )
    eq(records[1].state, "behind", name .. ": it is behind")
    local session = {
      dir = base,
      records = records,
      dry_run = false,
      opts = { state_path = state_path, quiet = false, ui = false },
    }
    return c, session, records[1].path
  end

  local passed, err = pcall(function()
    -- ── two re-checks of one repo: the second is refused, the pull succeeds ──
    do
      local c, session, path = behind_session("twice")
      local ended = 0
      local first = sync.recheck(session, { "twice" }, function()
        ended = ended + 1
      end)
      eq(type(first.stop), "function", "recheck returns a controller")
      has(sync.busy_reason(path) or "", "re-check", "the repo is busy while it is re-checked")
      notes = {}
      sync.recheck(session, { "twice" }, function()
        ended = ended + 1
      end)
      has(said(), "twice: a re-check is running -- not checked again now", "the second says why")
      ok(
        wait_for(function()
          return ended == 2
        end),
        "both re-checks reported back"
      )
      eq(session.records[1].state, "pulled", "one pull ran, and it worked (not pull_failed)")
      eq(H.read(c.repo .. "/b.txt"), "new twice\n", "the incoming change is in the tree")
      eq(sync.busy_reason(path), nil, "the repo is free again")
    end

    -- ── an assist is refused on a busy repo and never touches it ────────────
    do
      local c, session, path = behind_session("assist-busy")
      local ctl = sync.recheck(session, { "assist-busy" }, function() end)
      notes = {}
      local answered = false
      sync.assist(session, "assist-busy", "merge", function()
        answered = true
      end)
      ok(answered, "the refused assist still answers (the caller waits for it)")
      has(said(), "not started -- a re-check is running", "the assist says why it did not run")
      ctl.stop()
      eq(sync.busy_reason(path), nil, "stop frees the repo")
      eq(H.read(c.repo .. "/b.txt"), "b1\n", "nothing was pulled")
    end

    -- ── stop: no result, no save, no callback ──────────────────────────────
    do
      local _, session, path = behind_session("stopped")
      local ended = false
      local ctl = sync.recheck(session, { "stopped" }, function()
        ended = true
      end)
      ctl.stop()
      eq(sync.busy_reason(path), nil, "a stopped re-check frees the repo")
      settle()
      ok(not ended, "a stopped re-check never reports back")
      eq(session.records[1].state, "behind", "...and never changes the record")
    end

    -- ── M.cancel stops a pending re-check ──────────────────────────────────
    do
      local _, session, path = behind_session("cancelled")
      local ended = false
      sync.recheck(session, { "cancelled" }, function()
        ended = true
      end)
      eq(sync.cancel(), false, "no full run was running")
      eq(sync.busy_reason(path), nil, "cancel stopped the re-check")
      settle()
      ok(not ended, "...which never reports back")
    end

    -- ── a full run supersedes a pending re-check; both never touch one repo ──
    do
      local c, session, path = behind_session("superseded")
      local ended = false
      sync.recheck(session, { "superseded" }, function()
        ended = true
      end)
      local run_done = false
      sync.run({
        dir = base,
        names = { "superseded" },
        no_fetch = true,
        quiet = true,
        ui = false,
        state_path = H.tmpdir() .. "/run-state.json",
        on_done = function()
          run_done = true
        end,
      })
      has(
        sync.busy_reason(path) or "",
        "sync is running",
        "while the run is in flight, it owns the repo"
      )
      ok(
        wait_for(function()
          return run_done
        end),
        "the run finished"
      )
      ok(not ended, "the superseded re-check never reported back")
      eq(sync.busy_reason(path), nil, "everything is free again")
      eq(H.read(c.repo .. "/b.txt"), "new superseded\n", "the run pulled")
    end
  end)

  vim.notify = orig_notify
  if not passed then
    error(err, 0)
  end
end
