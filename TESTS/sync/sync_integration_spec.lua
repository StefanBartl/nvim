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

  -- A hostile global git config (the Git for Windows defaults and a few usual extras): the
  -- clones under test must not depend on the machine's own config. Without the pinned
  -- settings in `fixture.lua` this makes the run fail (CRLF checkouts, signing, hooks).
  local hostile = H.tmpdir() .. "/hostile-gitconfig"
  vim.fn.writefile({
    "[core]",
    "  autocrlf = true",
    "  hooksPath = " .. H.tmpdir() .. "/no-such-hooks",
    "[commit]",
    "  gpgsign = true",
    "[tag]",
    "  gpgsign = true",
  }, hostile)
  local saved_global = vim.env.GIT_CONFIG_GLOBAL
  vim.env.GIT_CONFIG_GLOBAL = hostile

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

  -- a dry run, even a partial one, must not turn the saved real result into a dry one
  do
    run({ dry_run = true, only = "current" })
    local after_dry = assert(state.load({ path = state_path }))
    eq(after_dry.dry_run, false, "a dry --only run leaves the real result real")
    eq(#after_dry.records, #names, "...and complete")
  end

  -- declining the restart prompt still reports back (on_declined and on_done)
  do
    local confirm = require("bindings.usrcmds.plugin_repos.confirm")
    local orig_yesno = confirm.yesno
    local asked, declined, done = false, false, false
    confirm.yesno = function(_, _, cb)
      asked = true
      cb(false)
    end
    sync.run({ dir = base, names = names, ui = false, quiet = true, state_path = state_path })
    ok(sync.is_running(), "a run is in flight")
    sync.run({
      dir = base,
      names = names,
      ui = false,
      quiet = true,
      state_path = state_path,
      on_declined = function()
        declined = true
      end,
      on_done = function()
        done = true
      end,
    })
    confirm.yesno = orig_yesno
    ok(asked, "the restart prompt was shown")
    ok(declined, "on_declined ran")
    ok(done, "on_done ran")
    ok(sync.is_running(), "the first run was not cancelled")
    sync.cancel()
  end

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

    -- ── processes: a timeout, a stop and a cancel must leave NOTHING of the tree alive ──
    local is_win = vim.fn.has("win32") == 1
    local pid = vim.uv.os_getpid()

    ---How many processes have `marker` in their command line (the sleeping child of an alias).
    ---@param marker string
    ---@return integer
    local function alive(marker)
      local cmd
      if is_win then
        local filter = "$_.ProcessId -ne $PID -and $_.CommandLine -like '*" .. marker .. "*'"
        cmd = {
          "powershell",
          "-NoProfile",
          "-NonInteractive",
          "-Command",
          "@(Get-CimInstance Win32_Process | Where-Object { " .. filter .. " }).Count",
        }
      else
        cmd = { "sh", "-c", ("ps -eo args | grep -F '%s' | grep -v grep | wc -l"):format(marker) }
      end
      local res = vim.system(cmd, { text = true }):wait(30000)
      return tonumber(vim.trim(res.stdout or "")) or -1
    end
    ---@param marker string
    ---@param timeout_ms integer
    ---@return boolean gone
    local function wait_gone(marker, timeout_ms)
      return vim.wait(timeout_ms, function()
        return alive(marker) == 0
      end, 500)
    end
    local sleepers = 0
    ---A git alias that announces itself in `flag`, then waits ~30 s in a CHILD of the shell (the
    ---`;` keeps the shell alive, so the job is a tree: git -> sh -> child). On Windows the child
    ---is `ping`, a native process: Git's msys `sleep` is forked by sh in a way that hides its
    ---parent from `taskkill /T`, which is no model of a real transport (`ssh`, `git-remote-https`).
    ---@param tag string
    ---@return string marker  unique in the command line of the child
    ---@return string flag  created when the shell started
    ---@return string alias
    ---@return string hold  the waiting shell command alone
    local function sleeper(tag)
      sleepers = sleepers + 1
      local marker, hold
      if is_win then
        marker = ("127.77.%d.%d"):format(pid % 250 + 1, sleepers)
        hold = "ping -n 31 " .. marker .. " >/dev/null"
      else
        marker = ("31.%d%d"):format(pid, sleepers)
        hold = "sleep " .. marker
      end
      local flag = vim.fs.normalize(H.tmpdir() .. "/started-" .. tag)
      local alias = ("!echo started > '%s'; %s; echo done"):format(flag, hold)
      return marker, flag, alias, hold
    end
    local function has_started(flag)
      return vim.wait(10000, function()
        return H.exists(flag)
      end, 20)
    end
    local function pause(ms)
      vim.wait(ms, function()
        return false
      end, 20)
    end

    -- the check itself works: a live sleeper is seen, and stop() takes the whole tree
    do
      local marker, flag, alias = sleeper("stop")
      local called = false
      local handle = ops.git_async(
        cases["current"].repo,
        { "-c", "alias.slow=" .. alias, "slow" },
        {},
        function()
          called = true
        end
      )
      ok(has_started(flag), "the sleeper started")
      pause(300)
      ok(alive(marker) >= 1, "control: the sleeping child is visible to the check")
      handle.stop()
      ok(wait_gone(marker, 10000), "stop() killed the whole process tree, children included")
      ok(not called, "and on_done does not run after stop()")
    end

    -- a call that outlives its timeout is killed (the tree too) and says so
    do
      local marker, flag, alias = sleeper("timeout")
      local t0 = vim.uv.hrtime()
      local result
      ops.git_async(
        cases["current"].repo,
        { "-c", "alias.slow=" .. alias, "slow" },
        { timeout_ms = 2500 },
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
      ok(H.exists(flag), "the sleeper really ran")
      ok(result.timed_out, "flagged as timed out")
      ok((vim.uv.hrtime() - t0) / 1e9 < 6, "well before the sleep ended")
      has(ops.describe_failure(result, "git slow", 2500), "timed out", "and described that way")
      ok(wait_gone(marker, 10000), "the timeout killed the whole process tree, children included")
    end

    -- a hung fetch (the transport is a child process): the timeout and a cancel both end it
    do
      local hung = make("hang")
      local marker, flag, _, hold = sleeper("hang")
      local hung_state = H.tmpdir() .. "/hang-state.json"
      git(
        hung.repo,
        "config",
        "remote.origin.uploadpack",
        ("echo started > '%s'; %s; git-upload-pack"):format(flag, hold)
      )
      local function hung_run(extra)
        local o = { done = false }
        sync.run(vim.tbl_extend("force", {
          dir = base,
          names = { "hang" },
          ui = false,
          quiet = true,
          state_path = hung_state,
          on_done = function(records)
            o.done, o.records = true, records
          end,
        }, extra))
        return o
      end

      local by_timeout = hung_run({ fetch_timeout_ms = 2500 })
      ok(
        vim.wait(15000, function()
          return by_timeout.done
        end, 20),
        "a hung fetch ends by its timeout"
      )
      eq(by_timeout.records[1].state, "fetch_failed", "as a failed fetch")
      has(by_timeout.records[1].detail, "timed out", "that says why")
      ok(wait_gone(marker, 10000), "no transport child of the timed-out fetch survives")
      os.remove(flag)

      local cancelled = hung_run({ fetch_timeout_ms = 60000 })
      ok(has_started(flag), "the second hung fetch started")
      pause(300)
      ok(alive(marker) >= 1, "its transport child is running")
      ok(sync.cancel(), "cancel reports that a run was stopped")
      ok(not sync.is_running(), "nothing is running afterwards")
      ok(wait_gone(marker, 10000), "no transport child of the cancelled run survives")
      pause(500)
      ok(not cancelled.done, "a cancelled run never reports")

      -- quitting Neovim stops a run in flight, so no git outlives the editor
      os.remove(flag)
      local quitting = hung_run({ fetch_timeout_ms = 60000 })
      ok(has_started(flag), "the third hung fetch started")
      pause(300)
      ok(alive(marker) >= 1, "its transport child is running")
      vim.api.nvim_exec_autocmds("VimLeavePre", { group = "MyPluginsSyncExit" })
      ok(not sync.is_running(), "VimLeavePre stopped the run")
      ok(wait_gone(marker, 10000), "no transport child survives the exit")
      ok(not quitting.done, "and it never reports")
    end

    -- no credential prompt can block a job: the variables really reach git
    do
      local seen
      ops.git_async(
        cases["current"].repo,
        { "-c", "alias.e=!echo $GIT_TERMINAL_PROMPT $GCM_INTERACTIVE", "e" },
        { read_only = true },
        function(run_result)
          seen = run_result
        end
      )
      ok(
        vim.wait(8000, function()
          return seen ~= nil
        end, 20),
        "the env probe came back"
      )
      eq(
        vim.trim(seen.stdout),
        "0 never",
        "git sees GIT_TERMINAL_PROMPT=0 and GCM_INTERACTIVE=never"
      )
    end

    -- a writing command is never killed: neither by a timeout nor by stop()
    do
      local flag = vim.fs.normalize(H.tmpdir() .. "/started-write")
      local alias = ("!echo started > '%s'; sleep 2; echo done"):format(flag)
      local result
      ops.git_async(
        cases["current"].repo,
        { "-c", "alias.slow=" .. alias, "slow" },
        { timeout_ms = 300, write = true },
        function(run_result)
          result = run_result
        end
      )
      ok(has_started(flag), "the writer started")
      ok(
        vim.wait(15000, function()
          return result ~= nil
        end, 20),
        "it ran to its end"
      )
      ok(not result.timed_out, "the short timeout did not apply to a writing command")
      eq(result.code, 0, "and it finished by itself")
      has(result.stdout, "done", "all of it ran")

      local stopped_flag = vim.fs.normalize(H.tmpdir() .. "/write-stopped")
      local called = false
      local handle = ops.git_async(
        cases["current"].repo,
        { "-c", "alias.w=!sleep 1; echo x > '" .. stopped_flag .. "'", "w" },
        { write = true },
        function()
          called = true
        end
      )
      handle.stop()
      ok(
        vim.wait(8000, function()
          return H.exists(stopped_flag)
        end, 20),
        "stop() did not kill a writing command: it still wrote its result"
      )
      pause(200)
      ok(not called, "...but its callback was dropped")
    end

    -- ── pull: local only, accurate, honest about why it failed ───────────────
    do
      local off = make("offline")
      incoming(off, "o1.txt", "o1\n")
      incoming(off, "o2.txt", "o2\n")
      git(off.repo, "fetch", "-q") -- the fetch phase of an earlier run
      git(off.repo, "remote", "set-url", "origin", base .. "/no-such-remote.git")
      local o = by_name(run({ names = { "offline" }, no_fetch = true }))
      eq(o["offline"].state, "pulled", "--no-fetch pulls what is fetched without any network")
      eq(o["offline"].pulled, 2, "and the count is the one of the status")
      eq(H.read(off.repo .. "/o2.txt"), "o2\n", "the files are there")

      -- a pull that fails for a reason of its own is not "blocked by your changes"
      local lk = make("locked")
      incoming(lk, "l1.txt", "l1\n")
      git(lk.repo, "fetch", "-q")
      H.write(lk.repo .. "/a.txt", "a1\nlocal edit\n") -- dirty, but not a file that comes in
      H.write(lk.repo .. "/.git/index.lock", "")
      local l = by_name(run({ names = { "locked" }, no_fetch = true }))
      eq(l["locked"].state, "pull_failed", "a lock is a failed pull, not a dirty_blocked one")
      has(l["locked"].detail, "index.lock", "with git's own reason")
      has(l["locked"].detail, "stale", "and the hint what to do")
      os.remove(lk.repo .. "/.git/index.lock")
    end
  end
  vim.env.GIT_CONFIG_GLOBAL = saved_global
end
