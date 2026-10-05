-- TESTS/sync/sync_state_scope_spec.lua -- scope, saved result and persistence of `:MyPlugins sync`.
--
-- No git needed: absent repos and hand-written records exercise the summary of an empty scope,
-- the dry-run guard of the state file, the read-modify-write of the dashboard saves and the
-- base dir restored by `sync issues`.

return function(H)
  local eq, ok, has = H.eq, H.ok, H.has

  local sync = require("bindings.usrcmds.plugin_repos.sync")
  local state = require("bindings.usrcmds.plugin_repos.sync_state")
  local dash = require("bindings.usrcmds.plugin_repos.sync_dash")

  local notes = {}
  local orig_notify, orig_open, orig_interval = vim.notify, dash.open, sync.SAVE_WARN_INTERVAL_MS
  vim.notify = function(msg, level)
    notes[#notes + 1] = { msg = msg, level = level or vim.log.levels.INFO }
  end

  local function rec(name, st, extra)
    return vim.tbl_extend("force", {
      name = name,
      path = "/nowhere/" .. name,
      state = st,
      detail = "",
      branch = "main",
      ahead = 0,
      behind = 0,
      dirty = false,
      changed = 0,
      skipped = false,
    }, extra or {})
  end
  local function by_name(records)
    local out = {}
    for _, r in ipairs(records) do
      out[r.name] = r
    end
    return out
  end

  local passed, err = pcall(function()
    -- ── every entry absent: say so, save nothing ──────────────────────────
    do
      local empty = H.tmpdir() .. "/empty-base"
      vim.fn.mkdir(empty, "p")
      local path = H.tmpdir() .. "/absent-state.json"
      local got = nil
      notes = {}
      sync.run({
        dir = empty,
        names = { "a.nvim", "b.nvim", "c.nvim" },
        state_path = path,
        ui = false,
        on_done = function(records)
          got = records
        end,
      })
      ok(got ~= nil, "the run ends at once")
      eq(#got, 0, "no records")
      ok(not H.exists(path), "no result is saved")
      local text = notes[#notes].msg
      has(text, "no local checkouts in scope (remote mode?)", "says why")
      has(text, "3 not cloned/not a repo", "and how many")
      ok(not text:find("up to date", 1, true), "no assurance")
      eq(notes[#notes].level, vim.log.levels.WARN, "warn level")
    end

    -- ── sync issues restores the saved base dir ──────────────────────────
    do
      local path = H.tmpdir() .. "/issues-state.json"
      assert(state.save("D:/some/base", { rec("x", "no_upstream") }, { path = path }))
      local opened = nil
      dash.open = function(session)
        opened = session
        return true
      end
      sync.issues({ state_path = path, quiet = true })
      dash.open = orig_open
      ok(opened ~= nil, "the list opens")
      eq(opened.dir, "D:/some/base", "session dir")
      eq(opened.opts.dir, "D:/some/base", "a re-run uses the dir that made the list")
    end

    -- ── a dry run never replaces a real saved result ─────────────────────
    do
      local path = H.tmpdir() .. "/dry-state.json"
      local function records()
        return { rec("a", "diverged"), rec("b", "no_upstream") }
      end
      assert(state.save("/base", records(), { path = path }))
      local dry = {
        dir = "/base",
        records = records(),
        dry_run = true,
        opts = { state_path = path, quiet = true },
      }
      sync.set_skipped(dry, { "a" }, true)
      local saved = assert(state.load({ path = path }))
      eq(saved.dry_run, false, "the file is still a real result")
      eq(by_name(saved.records)["a"].skipped, false, "the dry session did not write into it")

      -- a dry run with no real result behind it is saved (as a dry one)
      local fresh = H.tmpdir() .. "/dry-only-state.json"
      dry.opts.state_path = fresh
      sync.set_skipped(dry, { "a" }, true)
      eq(assert(state.load({ path = fresh })).dry_run, true, "saved as a dry result")
    end

    -- ── read-modify-write: a stale session cannot clobber a newer result ──
    do
      local path = H.tmpdir() .. "/rmw-state.json"
      local stale = {
        dir = "/base",
        dry_run = false,
        opts = { state_path = path, quiet = true },
        records = { rec("a", "diverged"), rec("b", "no_upstream"), rec("c", "detached") },
      }
      -- a newer run (another nvim, picker S) resolved b and c in the meantime
      assert(
        state.save(
          "/base",
          { rec("a", "diverged"), rec("b", "pulled"), rec("c", "current") },
          { path = path }
        )
      )
      sync.set_skipped(stale, { "a" }, true)
      local got = by_name(assert(state.load({ path = path })).records)
      eq(got["a"].skipped, true, "the skip is saved")
      eq(got["b"].state, "pulled", "the newer result of b survives")
      eq(got["c"].state, "current", "the newer result of c survives")
      -- a skip never lands on a record the newer run resolved
      sync.set_skipped(stale, { "b" }, true)
      got = by_name(assert(state.load({ path = path })).records)
      eq(got["b"].skipped, false, "no skip on a pulled repo")
    end

    -- ── a failed save is reported, rate-limited ──────────────────────────
    do
      local dir_as_file = H.tmpdir() .. "/blocked-state.json"
      vim.fn.mkdir(dir_as_file, "p") -- a directory where the file belongs: the rename fails
      local session = {
        dir = "/base",
        dry_run = false,
        opts = { state_path = dir_as_file, quiet = false },
        records = { rec("a", "diverged") },
      }
      notes = {}
      sync.SAVE_WARN_INTERVAL_MS = 0
      sync.set_skipped(session, { "a" }, true)
      eq(#notes, 1, "a failed save warns")
      has(notes[1].msg, "could not save", "...as such")
      eq(notes[1].level, vim.log.levels.WARN, "warn level")
      sync.SAVE_WARN_INTERVAL_MS = 1e9
      sync.set_skipped(session, { "a" }, false)
      sync.set_skipped(session, { "a" }, true)
      eq(#notes, 1, "...but not on every key press")
    end
  end)

  vim.notify, dash.open, sync.SAVE_WARN_INTERVAL_MS = orig_notify, orig_open, orig_interval
  if not passed then
    error(err, 0)
  end
end
