-- TESTS/sync/sync_integration_spec.lua -- `:MyPlugins sync` against REAL git repositories.
--
-- One throwaway bare remote + developer clone + clone under test per case, so every state of
-- the table is produced by git itself (and the porcelain-v2 text the parser reads is the real
-- one, not a hand-written one). Needs `git` on $PATH; runs on Windows (paths, git.exe).

return function(H)
  local eq, ok, has = H.eq, H.ok, H.has

  if vim.fn.executable("git") ~= 1 then
    return -- nothing to test without git
  end

  local sync = require("bindings.usrcmds.plugin_repos.sync")
  local ops = require("bindings.usrcmds.plugin_repos.ops")
  local classify = require("bindings.usrcmds.plugin_repos.sync_classify")
  local state = require("bindings.usrcmds.plugin_repos.sync_state")

  local fx = dofile(vim.fs.dirname(debug.getinfo(1, "S").source:sub(2)) .. "/fixture.lua")(H)
  local base, git, commit_file, make, incoming =
    fx.base, fx.git, fx.commit_file, fx.make, fx.incoming
  local state_path = H.tmpdir() .. "/sync-state.json"

  -- ── the cases ───────────────────────────────────────────────────────────
  local cases = {}
  local order = {}
  local function case(name, setup)
    cases[name] = make(name)
    order[#order + 1] = name
    setup(cases[name])
  end

  case("current", function() end)
  case("behind", function(c)
    incoming(c, "new.txt", "new\n")
    incoming(c, "newer.txt", "newer\n")
  end)
  case("ahead", function(c)
    commit_file(c.repo, "mine.txt", "mine\n", "unpushed")
  end)
  case("diverged", function(c)
    incoming(c, "theirs.txt", "theirs\n")
    commit_file(c.repo, "mine.txt", "mine\n", "unpushed")
  end)
  case("dirty-pullable", function(c)
    H.write(c.repo .. "/a.txt", "a1\nlocal edit\n") -- tracked, not touched by the incoming commit
    incoming(c, "b.txt", "b2\n")
  end)
  case("dirty-blocked", function(c)
    H.write(c.repo .. "/b.txt", "b1\nlocal edit\n")
    incoming(c, "b.txt", "b-from-the-other-machine\n") -- the very file that is edited here
  end)
  case("dirty-only", function(c)
    H.write(c.repo .. "/untracked.txt", "x\n") -- nothing incoming
  end)
  case("no-upstream", function(c)
    git(c.repo, "checkout", "-q", "-b", "feature")
  end)
  case("detached", function(c)
    git(c.repo, "checkout", "-q", "--detach")
  end)
  case("unreachable", function(c)
    git(c.repo, "remote", "set-url", "origin", base .. "/no-such-remote.git")
  end)
  -- a listed name that is not on disk, and a folder that is no repo
  vim.fn.mkdir(base .. "/not-a-repo", "p")
  local names = vim.list_extend(vim.deepcopy(order), { "missing-one", "not-a-repo" })

  ---@param opts table
  ---@return MyPlugins.SyncRecord[] records
  ---@return MyPlugins.SyncSummary summary
  local function run(opts)
    local done, recs, sum = false, nil, nil
    sync.run(vim.tbl_extend("force", {
      dir = base,
      names = names,
      ui = false,
      quiet = true,
      state_path = state_path,
      on_done = function(r, s)
        done, recs, sum = true, r, s
      end,
    }, opts or {}))
    ok(
      vim.wait(60000, function()
        return done
      end, 20),
      "the sync finished"
    )
    return recs, sum
  end
  ---@param recs MyPlugins.SyncRecord[]
  ---@return table<string, MyPlugins.SyncRecord>
  local function by_name(recs)
    local out = {}
    for _, r in ipairs(recs) do
      out[r.name] = r
    end
    return out
  end

  -- ── --dry-run: classify everything, pull nothing ───────────────────────
  do
    local recs = run({ dry_run = true })
    local r = by_name(recs)
    eq(r["behind"].state, "behind", "dry run: behind is only reported")
    ok(not H.exists(cases["behind"].repo .. "/new.txt"), "dry run: nothing was pulled")
    eq(r["dirty-pullable"].state, "behind", "dry run: a dirty tree with incoming commits is behind")
    eq(#recs, #names, "every listed name has a record")
    local line = classify.summary_line(recs, true)
    has(line, "would be pulled", "the dry-run line says what would happen")
  end

  -- ── the real run ────────────────────────────────────────────────────────
  local recs, summary = run({ jobs = 3 })
  local r = by_name(recs)
  eq(r["current"].state, "current", "nothing to do")
  eq(r["behind"].state, "pulled", "behind is pulled")
  eq(r["behind"].pulled, 2, "two commits came in")
  eq(H.read(cases["behind"].repo .. "/new.txt"), "new\n", "the pulled file is really there")
  eq(H.read(cases["behind"].repo .. "/newer.txt"), "newer\n", "both commits")
  eq(r["ahead"].state, "ahead", "unpushed commits are a hint")
  eq(r["diverged"].state, "diverged", "ahead and behind")
  has(r["diverged"].detail, "ahead 1 / behind 1", "diverged detail from the counts")
  eq(
    r["dirty-pullable"].state,
    "pulled",
    "a dirty tree that does not touch the incoming files still pulls"
  )
  eq(H.read(cases["dirty-pullable"].repo .. "/b.txt"), "b2\n", "...and got the incoming change")
  eq(
    H.read(cases["dirty-pullable"].repo .. "/a.txt"),
    "a1\nlocal edit\n",
    "...and kept the local edit"
  )
  eq(r["dirty-blocked"].state, "dirty_blocked", "the pull was refused because of the local edit")
  has(r["dirty-blocked"].detail, "changed file", "how many files are in the way")
  eq(
    H.read(cases["dirty-blocked"].repo .. "/b.txt"),
    "b1\nlocal edit\n",
    "git did not touch the edited file"
  )
  eq(r["dirty-only"].state, "dirty", "local changes, nothing incoming: a hint")
  eq(r["no-upstream"].state, "no_upstream", "a branch without an upstream")
  eq(r["detached"].state, "detached", "a detached HEAD")
  eq(r["unreachable"].state, "fetch_failed", "a remote that does not exist")
  ok((r["unreachable"].detail or "") ~= "", "...with a reason")
  eq(r["missing-one"].state, "missing", "a listed name that is not on disk")
  eq(r["not-a-repo"].state, "not_git", "a folder that is no repository")

  eq(summary.pulled, 2, "two repos were pulled")
  eq(
    #summary.unresolved,
    5,
    "unresolved: diverged, dirty-blocked, no-upstream, detached, unreachable"
  )
  ok(not summary.all_clear, "not clear")
  eq(classify.sort(recs)[1].state, "diverged", "the worst problem comes first")

  -- the saved result survives a restart of the dashboard
  local saved = assert(state.load({ path = state_path }))
  eq(#saved.records, #names, "the result was saved")
  eq(saved.dir, base:gsub("[/\\]+$", ""), "with the base dir")

  -- ── a second run changes nothing it should not ─────────────────────────
  local recs2, summary2 = run({})
  local r2 = by_name(recs2)
  eq(r2["behind"].state, "current", "the repo pulled before is up to date now")
  eq(r2["dirty-pullable"].state, "dirty", "...and a dirty one is a hint again, not a problem")
  eq(summary2.pulled, 0, "nothing left to pull")
  eq(r2["dirty-blocked"].state, "dirty_blocked", "the blocked repo is still blocked")

  -- ── --no-fetch, --only ─────────────────────────────────────────────────
  incoming(cases["current"], "late.txt", "late\n")
  local nf = by_name(run({ no_fetch = true }))
  eq(nf["current"].state, "current", "--no-fetch does not see a commit that was never fetched")
  local only = by_name(run({ only = "current" }))
  eq(only["current"].state, "pulled", "--only fetches and pulls just that repo")
  eq(H.read(cases["current"].repo .. "/late.txt"), "late\n", "the commit arrived")
  local none = 0
  for _ in pairs(only) do
    none = none + 1
  end
  eq(none, 1, "--only: one record")
  -- ...but the saved result still holds every repo: a partial run must not wipe the others
  local after_only = assert(state.load({ path = state_path }))
  eq(#after_only.records, #names, "--only keeps the saved result of the repos it did not look at")
  local kept = by_name(after_only.records)
  eq(kept["current"].state, "pulled", "the repo it did look at is fresh")
  eq(kept["diverged"].state, "diverged", "another repo keeps the result of the earlier run")

  -- ── re-check after the user resolved a problem ─────────────────────────
  do
    local session = {
      dir = base,
      records = recs2,
      dry_run = false,
      opts = { state_path = state_path, quiet = true, ui = false },
    }
    -- the user stashes the blocking edit (in lazygit, say) ...
    git(cases["dirty-blocked"].repo, "stash", "-q")
    local finished = false
    sync.recheck(session, { "dirty-blocked" }, function()
      finished = true
    end)
    ok(
      vim.wait(30000, function()
        return finished
      end, 20),
      "the re-check finished"
    )
    local blocked = by_name(session.records)["dirty-blocked"]
    eq(blocked.state, "pulled", "...and the re-check pulls it")
    eq(
      H.read(cases["dirty-blocked"].repo .. "/b.txt"),
      "b-from-the-other-machine\n",
      "the incoming change is in"
    )

    -- skipping keeps a problem visible but off the unresolved list
    sync.set_skipped(session, { "diverged", "detached" }, true)
    local s = classify.summarize(session.records)
    eq(#s.skipped, 2, "two skipped")
    eq(#s.unresolved, 2, "unresolved: no-upstream, unreachable")
    local line, level = classify.summary_line(session.records)
    has(line, "2 skipped: ", "the closing line names them")
    eq(level, "warn", "still a warning while something is unresolved")
    local reread = assert(state.load({ path = state_path }))
    local skipped_saved = 0
    for _, rec in ipairs(reread.records) do
      if rec.skipped then
        skipped_saved = skipped_saved + 1
      end
    end
    eq(skipped_saved, 2, "the skips were saved")
    sync.set_skipped(session, { "diverged" }, false)
    eq(#classify.summarize(session.records).skipped, 1, "un-skip")
    -- a skip never outlives the next full run
    local fresh = by_name(run({}))
    ok(not fresh["detached"].skipped, "the next full run asks about it again")
  end

  -- ── scope: the remote mode / nothing listed ────────────────────────────
  do
    local done, got = false, nil
    sync.run({
      dir = base,
      names = {},
      ui = false,
      quiet = true,
      state_path = state_path,
      on_done = function(records)
        done, got = true, records
      end,
    })
    ok(
      vim.wait(5000, function()
        return done
      end, 20),
      "an empty scope returns at once"
    )
    eq(#got, 0, "no records")
  end

  -- ── ops primitives ─────────────────────────────────────────────────────
  do
    -- the pool never runs more than `jobs` at once, and uses all of them
    local running, peak, finished = 0, 0, false
    local items = {}
    for i = 1, 9 do
      items[i] = i
    end
    ops.run_pool(
      items,
      3,
      function(item, done)
        running = running + 1
        peak = math.max(peak, running)
        vim.defer_fn(function()
          running = running - 1
          done(item * 2)
        end, 20)
        return { stop = function() end }
      end,
      nil,
      function(results)
        finished = true
        eq(table.concat(results, ","), "2,4,6,8,10,12,14,16,18", "results come back in item order")
      end
    )
    ok(
      vim.wait(5000, function()
        return finished
      end, 10),
      "the pool finished"
    )
    eq(peak, 3, "three at a time, no more")

    -- stop(): nothing runs afterwards, no callback fires
    local started, fired = 0, false
    local ctl = ops.run_pool(
      { 1, 2, 3, 4 },
      1,
      function(_, done)
        started = started + 1
        vim.defer_fn(function()
          done(true)
        end, 50)
        return { stop = function() end }
      end,
      nil,
      function()
        fired = true
      end
    )
    ctl.stop()
    vim.wait(300, function()
      return false
    end, 20)
    eq(started, 1, "stop() starts nothing new")
    ok(not fired, "and finishes nothing")

    -- a call that outlives its timeout is killed and says so (git alias `slow` sleeps)
    local t0 = vim.uv.hrtime()
    local result
    ops.git_async(
      cases["current"].repo,
      { "-c", "alias.slow=!sleep 10", "slow" },
      { timeout_ms = 400 },
      function(run_result)
        result = run_result
      end
    )
    ok(
      vim.wait(8000, function()
        return result ~= nil
      end, 20),
      "the slow call came back"
    )
    ok(result.timed_out, "flagged as timed out")
    ok((vim.uv.hrtime() - t0) / 1e9 < 6, "well before the sleep ended")
    has(ops.describe_failure(result, "git slow", 400), "timed out", "and described that way")

    -- no credential prompt can block a job
    eq(ops.NO_PROMPT_ENV.GIT_TERMINAL_PROMPT, "0", "git never asks on a terminal")
  end
end
