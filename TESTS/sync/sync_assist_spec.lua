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
  ok(state_of("stash-conflict") ~= "pulled", "a pop that conflicts is not reported as solved")
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
  eq(#s.unresolved, 2, "the two diverged repos are still unresolved")
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
