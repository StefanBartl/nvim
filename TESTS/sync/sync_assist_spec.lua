-- TESTS/sync/sync_assist_spec.lua -- the assist actions of the triage list against REAL git:
-- rebase, merge and stash-pull-pop, and what each does when it goes wrong. The promise under
-- test: a failed action leaves the repo as it was (a conflicting rebase/merge is aborted, the
-- stash is popped again), and nothing ever resets, cleans or forces.

return function(H)
  local eq, ok, has = H.eq, H.ok, H.has

  if vim.fn.executable("git") ~= 1 then
    return
  end

  local sync = require("bindings.usrcmds.plugin_repos.sync")
  local ops = require("bindings.usrcmds.plugin_repos.ops")
  local classify = require("bindings.usrcmds.plugin_repos.sync_classify")

  local fx = dofile(vim.fs.dirname(debug.getinfo(1, "S").source:sub(2)) .. "/fixture.lua")(H)
  local base, git, commit_file, make, incoming =
    fx.base, fx.git, fx.commit_file, fx.make, fx.incoming
  local state_path = H.tmpdir() .. "/sync-state.json"

  -- `rebase`, `merge` and `stash` create commits: they need an identity the production code
  -- takes from the user's config
  local saved_env = {}
  for k, v in pairs({
    GIT_AUTHOR_NAME = "Spec",
    GIT_AUTHOR_EMAIL = "spec@example.invalid",
    GIT_COMMITTER_NAME = "Spec",
    GIT_COMMITTER_EMAIL = "spec@example.invalid",
  }) do
    saved_env[k] = vim.env[k]
    vim.env[k] = v
  end

  local lines20 = {}
  for i = 1, 20 do
    lines20[i] = "line " .. i
  end
  local function text20(edits)
    local copy = vim.deepcopy(lines20)
    for n, v in pairs(edits or {}) do
      copy[n] = v
    end
    return table.concat(copy, "\n") .. "\n"
  end

  -- diverged, and the two sides do not touch the same lines: rebase and merge both work
  local rb = make("rebase-ok")
  incoming(rb, "theirs.txt", "theirs\n")
  commit_file(rb.repo, "mine.txt", "mine\n", "unpushed")
  local mg = make("merge-ok")
  incoming(mg, "theirs.txt", "theirs\n")
  commit_file(mg.repo, "mine.txt", "mine\n", "unpushed")
  -- diverged on the SAME line: both actions conflict and must be undone
  local rc = make("rebase-conflict")
  commit_file(rc.dev, "c.txt", text20(), "c base")
  git(rc.dev, "push", "-q")
  git(rc.repo, "pull", "-q", "--ff-only")
  incoming(rc, "c.txt", text20({ [10] = "THEIRS" }))
  commit_file(rc.repo, "c.txt", text20({ [10] = "MINE" }), "unpushed conflicting")
  local mc = make("merge-conflict")
  commit_file(mc.dev, "c.txt", text20(), "c base")
  git(mc.dev, "push", "-q")
  git(mc.repo, "pull", "-q", "--ff-only")
  incoming(mc, "c.txt", text20({ [10] = "THEIRS" }))
  commit_file(mc.repo, "c.txt", text20({ [10] = "MINE" }), "unpushed conflicting")
  -- blocked by a local edit, but the edit and the incoming change are far apart: stash-pull-pop works
  local sp = make("stash-ok")
  commit_file(sp.dev, "c.txt", text20(), "c base")
  git(sp.dev, "push", "-q")
  git(sp.repo, "pull", "-q", "--ff-only")
  H.write(sp.repo .. "/c.txt", text20({ [1] = "local edit at the top" }))
  incoming(sp, "c.txt", text20({ [20] = "incoming edit at the bottom" }))
  -- blocked, and the edit collides with the incoming change: the pop conflicts
  local sc = make("stash-conflict")
  commit_file(sc.dev, "c.txt", text20(), "c base")
  git(sc.dev, "push", "-q")
  git(sc.repo, "pull", "-q", "--ff-only")
  H.write(sc.repo .. "/c.txt", text20({ [10] = "local edit" }))
  incoming(sc, "c.txt", text20({ [10] = "incoming edit" }))
  -- nothing to stash although the repo reads as blocked is not reachable, but an older stash of
  -- the user must never be popped: a repo with an unrelated stash and a clean tree
  local keep = make("keeps-old-stash")
  H.write(keep.repo .. "/a.txt", "a1\nold work\n")
  git(keep.repo, "stash", "-q")
  incoming(keep, "b.txt", "b2\n")

  local names = {
    "rebase-ok",
    "merge-ok",
    "rebase-conflict",
    "merge-conflict",
    "stash-ok",
    "stash-conflict",
    "keeps-old-stash",
  }

  local done, session = false, nil
  sync.run({
    dir = base,
    names = names,
    ui = false,
    quiet = true,
    state_path = state_path,
    on_done = function(records)
      done = true
      session = {
        dir = base,
        records = records,
        dry_run = false,
        opts = { ui = false, quiet = true, state_path = state_path },
      }
    end,
  })
  ok(
    vim.wait(60000, function()
      return done
    end, 20),
    "the sync finished"
  )
  local function state_of(name)
    for _, r in ipairs(session.records) do
      if r.name == name then
        return r.state
      end
    end
  end
  eq(state_of("rebase-ok"), "diverged", "setup: diverged")
  eq(state_of("stash-ok"), "dirty_blocked", "setup: blocked by the edit")
  eq(state_of("stash-conflict"), "dirty_blocked", "setup: blocked by the edit")
  eq(state_of("keeps-old-stash"), "pulled", "setup: a clean tree with an old stash just pulls")

  ---@param name string
  ---@param id string
  local function assist(name, id)
    local finished = false
    sync.assist(session, name, id, function()
      finished = true
    end)
    ok(
      vim.wait(60000, function()
        return finished
      end, 20),
      name .. ": the assist finished"
    )
  end
  local function head(dir)
    return vim.trim(git(dir, "rev-parse", "HEAD"))
  end

  -- ── rebase ──────────────────────────────────────────────────────────────
  assist("rebase-ok", "rebase")
  eq(state_of("rebase-ok"), "ahead", "rebased: my commit sits on top of theirs, nothing behind")
  eq(H.read(rb.repo .. "/theirs.txt"), "theirs\n", "their commit is in")
  eq(H.read(rb.repo .. "/mine.txt"), "mine\n", "mine is still in")
  eq(vim.trim(git(rb.repo, "status", "--porcelain")), "", "a clean tree")

  -- ── merge ───────────────────────────────────────────────────────────────
  assist("merge-ok", "merge")
  eq(state_of("merge-ok"), "ahead", "merged: the merge commit is mine to push")
  eq(H.read(mg.repo .. "/theirs.txt"), "theirs\n", "their commit is in")
  has(git(mg.repo, "log", "--oneline", "-1"), "Merge", "a merge commit")

  -- ── a conflict is undone, not left in the middle of something ───────────
  local before_rc = head(rc.repo)
  assist("rebase-conflict", "rebase")
  eq(state_of("rebase-conflict"), "diverged", "still diverged: nothing was decided for the user")
  eq(head(rc.repo), before_rc, "HEAD is where it was")
  ok(
    vim.fn.isdirectory(rc.repo .. "/.git/rebase-merge") == 0
      and vim.fn.isdirectory(rc.repo .. "/.git/rebase-apply") == 0,
    "no rebase is left running"
  )
  eq(vim.trim(git(rc.repo, "status", "--porcelain")), "", "a clean tree, my change intact")
  has(H.read(rc.repo .. "/c.txt"), "MINE", "my edit is still there")

  local before_mc = head(mc.repo)
  assist("merge-conflict", "merge")
  eq(state_of("merge-conflict"), "diverged", "still diverged")
  eq(head(mc.repo), before_mc, "HEAD is where it was")
  ok(vim.fn.filereadable(mc.repo .. "/.git/MERGE_HEAD") == 0, "no merge is left running")
  eq(vim.trim(git(mc.repo, "status", "--porcelain")), "", "a clean tree")

  -- ── stash, pull, pop ────────────────────────────────────────────────────
  assist("stash-ok", "stash_pull")
  eq(state_of("stash-ok"), "dirty", "pulled, and the local edit is back: only a hint now")
  local c = H.read(sp.repo .. "/c.txt")
  has(c, "local edit at the top", "the local edit survived")
  has(c, "incoming edit at the bottom", "the incoming change is in")
  eq(vim.trim(git(sp.repo, "stash", "list")), "", "the stash was popped, nothing left in it")

  assist("stash-conflict", "stash_pull")
  eq(
    state_of("stash-conflict"),
    "conflicted",
    "a pop that conflicts is a PROBLEM (conflict markers), not a hint that drops off the list"
  )
  ok(
    #classify.visible(session.records, false) > 0
      and vim.tbl_contains(
        vim.tbl_map(function(r)
          return r.name
        end, classify.visible(session.records, false)),
        "stash-conflict"
      ),
    "...and it stays in the list without the hints"
  )
  has(
    git(sc.repo, "stash", "list"),
    "myplugins sync",
    "the changes are safe in the stash when the pop conflicts"
  )
  has(H.read(sc.repo .. "/c.txt"), "incoming edit", "the pull itself did happen")

  -- the user's own older stash is never popped by an action that stashed nothing
  local stash_before = vim.trim(git(keep.repo, "stash", "list"))
  ok(stash_before ~= "", "setup: the old stash is there")
  local result_ok, result_err
  local fin = false
  ops.run_assist(keep.repo, "stash_pull", 30000, function(o, e)
    result_ok, result_err, fin = o, e, true
  end)
  ok(
    vim.wait(30000, function()
      return fin
    end, 20),
    "stash_pull on a clean tree finished"
  )
  ok(
    result_ok,
    "it succeeds (there was nothing to stash, the pull had nothing to do)" .. tostring(result_err)
  )
  eq(
    vim.trim(git(keep.repo, "stash", "list")),
    stash_before,
    "the old stash of the user is still there, untouched"
  )

  -- ── safety: never abort or flatten what is not ours ─────────────────────
  ---@param repo string
  ---@param id string
  ---@return boolean ok, string|nil err
  local function run_assist(repo, id)
    local result, finished = nil, false
    ops.run_assist(repo, id, 30000, function(o, e)
      result, finished = { o, e }, true
    end)
    ok(
      vim.wait(30000, function()
        return finished
      end, 20),
      id .. " finished in " .. repo
    )
    return result[1], result[2]
  end
  ---raw git that may fail (the fixture helper raises)
  local function git_try(dir, ...)
    local cmd = { "git", "-C", dir, ... }
    return vim.system(cmd, { text = true }):wait(30000)
  end
  ---a repo that is diverged on the same line of c.txt, upstream fetched
  local function conflicting(name)
    local cl = make(name)
    commit_file(cl.dev, "c.txt", text20(), "c base")
    git(cl.dev, "push", "-q")
    git(cl.repo, "pull", "-q", "--ff-only")
    incoming(cl, "c.txt", text20({ [10] = "THEIRS" }))
    commit_file(cl.repo, "c.txt", text20({ [10] = "MINE" }), "unpushed conflicting")
    git(cl.repo, "fetch", "-q")
    return cl
  end

  -- #13/#16: a merge the user is resolving is refused, not aborted
  local mip = conflicting("merge-in-progress")
  ok(git_try(mip.repo, "merge", "--no-edit", "@{u}").code ~= 0, "setup: the merge conflicts")
  -- (a) markers still in the tree
  for _, id in ipairs({ "merge", "rebase" }) do
    local o, e = run_assist(mip.repo, id)
    eq(o, false, id .. " refused on an unresolved merge")
    has(e or "", "already in progress", id .. ": says why")
    has(e or "", "nothing was touched", id .. ": and that nothing was touched")
    ok(vim.fn.filereadable(mip.repo .. "/.git/MERGE_HEAD") == 1, id .. ": the merge is still there")
    has(H.read(mip.repo .. "/c.txt"), "<<<<<<<", id .. ": the conflict markers are untouched")
  end
  -- (b) resolved and staged, only MERGE_HEAD is left (the repo reads as plain `diverged`)
  H.write(mip.repo .. "/c.txt", text20({ [10] = "RESOLVED" }))
  git(mip.repo, "add", "c.txt")
  local o13, e13 = run_assist(mip.repo, "merge")
  eq(o13, false, "merge refused on a resolved but unconcluded merge")
  has(e13 or "", "already in progress", "...says why")
  has(
    H.read(mip.repo .. "/c.txt"),
    "RESOLVED",
    "the user's resolution survives (it was aborted before)"
  )
  ok(vim.fn.filereadable(mip.repo .. "/.git/MERGE_HEAD") == 1, "MERGE_HEAD is still there")
  git(mip.repo, "merge", "--abort")

  -- a rebase in progress (detached, but the assist must still never touch it)
  local rip = conflicting("rebase-in-progress")
  ok(git_try(rip.repo, "rebase", "@{u}").code ~= 0, "setup: the rebase stops on the conflict")
  local orb, erb = run_assist(rip.repo, "merge")
  eq(orb, false, "merge refused in the middle of a rebase")
  has(erb or "", "already in progress", "...says why")
  ok(
    vim.fn.isdirectory(rip.repo .. "/.git/rebase-merge") == 1
      or vim.fn.isdirectory(rip.repo .. "/.git/rebase-apply") == 1,
    "the rebase is still running (not aborted)"
  )
  git(rip.repo, "rebase", "--abort")

  -- #14: the abort result is checked, the message names the command and the path
  do
    local failing = conflicting("abort-fails")
    local real, aborts = ops.git_async, 0
    ops.git_async = function(path, args, opts, cb)
      if vim.tbl_contains(args, "--abort") then
        aborts = aborts + 1
        vim.schedule(function()
          cb({ code = 1, stdout = "", stderr = "fatal: Unable to create index.lock\n" })
        end)
        return { stop = function() end }
      end
      return real(path, args, opts, cb)
    end
    local called, o, e = pcall(run_assist, failing.repo, "merge")
    ops.git_async = real
    ok(called, "the stubbed run finished")
    eq(aborts, 1, "the abort was tried once")
    eq(o, false, "a conflicting merge is a failure")
    has(e or "", "abort failed", "the failed abort is reported as such")
    has(e or "", "git merge --abort", "...with the command to run")
    has(e or "", failing.repo, "...and the path to run it in")
    ok(not (e or ""):find("nothing changed", 1, true), "...and never claims nothing changed")
    git(failing.repo, "merge", "--abort")
  end

  -- a merge git refuses to START (local edit in the way) has nothing to abort: no --abort at all
  do
    local refused = make("merge-refused")
    commit_file(refused.dev, "c.txt", text20(), "c base")
    git(refused.dev, "push", "-q")
    git(refused.repo, "pull", "-q", "--ff-only")
    incoming(refused, "c.txt", text20({ [20] = "THEIRS" }))
    commit_file(refused.repo, "other.txt", "mine\n", "unpushed")
    git(refused.repo, "fetch", "-q")
    H.write(refused.repo .. "/c.txt", text20({ [1] = "uncommitted edit" }))
    local real, aborts = ops.git_async, 0
    ops.git_async = function(path, args, opts, cb)
      if vim.tbl_contains(args, "--abort") then
        aborts = aborts + 1
      end
      return real(path, args, opts, cb)
    end
    local called, o, e = pcall(run_assist, refused.repo, "merge")
    ops.git_async = real
    ok(called, "the run finished")
    eq(o, false, "git refuses the merge over the uncommitted edit")
    eq(aborts, 0, "nothing was started, so nothing is aborted")
    has(e or "", "nothing changed", "the message is true")
    has(H.read(refused.repo .. "/c.txt"), "uncommitted edit", "the edit is intact")
  end

  -- #15: a local merge commit survives the rebase
  do
    local m = make("rebase-merges")
    git(m.repo, "checkout", "-q", "-b", "feat")
    commit_file(m.repo, "f.txt", "feature\n", "feature work")
    git(m.repo, "checkout", "-q", "main")
    commit_file(m.repo, "m.txt", "main work\n", "main work")
    git(m.repo, "merge", "-q", "--no-ff", "--no-edit", "feat")
    incoming(m, "theirs.txt", "theirs\n")
    git(m.repo, "fetch", "-q")
    eq(
      vim.trim(git(m.repo, "rev-list", "--merges", "--count", "@{u}..HEAD")),
      "1",
      "setup: a local merge"
    )
    local o, e = run_assist(m.repo, "rebase")
    ok(o, "the rebase works: " .. tostring(e))
    eq(
      vim.trim(git(m.repo, "rev-list", "--merges", "--count", "@{u}..HEAD")),
      "1",
      "the local merge commit is still a merge commit"
    )
    eq(H.read(m.repo .. "/f.txt"), "feature\n", "the merged branch is in")
    eq(H.read(m.repo .. "/theirs.txt"), "theirs\n", "their commit is in")
  end

  -- #24: a conflicting pop says what the tree looks like and how to get out
  do
    local p = make("pop-conflict")
    commit_file(p.dev, "c.txt", text20(), "c base")
    git(p.dev, "push", "-q")
    git(p.repo, "pull", "-q", "--ff-only")
    H.write(p.repo .. "/c.txt", text20({ [10] = "local edit" }))
    incoming(p, "c.txt", text20({ [10] = "incoming edit" }))
    git(p.repo, "fetch", "-q")
    local o, e = run_assist(p.repo, "stash_pull")
    eq(o, false, "a conflicting pop is a failure")
    has(e or "", "conflict markers", "the tree is said to hold conflict markers")
    has(e or "", "git stash drop", "...and the way out is named")
    has(H.read(p.repo .. "/c.txt"), "<<<<<<<", "(the markers really are there)")
    -- a pop that fails for another reason must not claim markers
  end

  -- an unknown action is refused, not run
  local refused
  ops.run_assist(keep.repo, "reset_hard", 1000, function(o, e)
    refused = { ok = o, err = e }
  end)
  ok(
    vim.wait(2000, function()
      return refused ~= nil
    end, 10),
    "an unknown action answers"
  )
  eq(refused.ok, false, "...with a refusal")
  has(refused.err, "unknown assist action", "...that says why")

  -- the summary after the actions counts what is left
  local s = classify.summarize(session.records)
  eq(#s.unresolved, 3, "the two diverged repos and the conflicted one are unresolved")
  ok(not s.all_clear, "so the run is not clear")
  local conflicted
  for _, r in ipairs(session.records) do
    if r.name == "stash-conflict" then
      conflicted = r
    end
  end
  has(conflicted.detail or "", "in conflict", "the repo with a conflicting pop says so in its row")

  for k, v in pairs(saved_env) do
    vim.env[k] = v
  end
end
