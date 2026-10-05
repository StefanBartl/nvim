-- TESTS/sync/sync_classify_spec.lua -- the pure core of `:MyPlugins sync`:
-- the status parser, every row of the state table, the order, the summary line.
-- No git, no process: the porcelain strings below are written by hand (the integration spec
-- feeds the same functions with what a real git prints).

return function(H)
  local eq, ok, has = H.eq, H.ok, H.has
  local C = require("bindings.usrcmds.plugin_repos.sync_classify")

  ---NUL-joined status text like `git status --porcelain=v2 --branch -z`.
  ---@param ... string
  ---@return string
  local function z(...)
    return table.concat({ ... }, "\0") .. "\0"
  end

  local HEAD = "# branch.oid 1111111111111111111111111111111111111111"
  local function ab(a, b)
    return ("# branch.ab +%d -%d"):format(a, b)
  end
  local function track(a, b, ...)
    return z(HEAD, "# branch.head main", "# branch.upstream origin/main", ab(a, b), ...)
  end

  -- ── parser ──────────────────────────────────────────────────────────────
  do
    local st = C.parse_status(track(2, 3))
    eq(st.branch, "main", "branch")
    eq(st.upstream, "origin/main", "upstream")
    eq(st.ahead, 2, "ahead")
    eq(st.behind, 3, "behind")
    ok(st.has_ab, "ahead/behind reported")
    eq(st.changed + st.untracked, 0, "clean tree")

    local dirty = C.parse_status(
      track(
        0,
        0,
        "1 .M N... 100644 100644 100644 aaa bbb lua/with space.lua",
        "2 R. N... 100644 100644 100644 aaa bbb R100 new name.lua",
        "old name.lua",
        "u UU N... 100644 100644 100644 100644 aaa bbb ccc conflict.lua",
        "? untracked file.txt",
        "! ignored.log"
      )
    )
    eq(dirty.changed, 3, "ordinary, rename and unmerged entries count as changed")
    eq(dirty.untracked, 1, "untracked")
    eq(dirty.conflicted, 1, "conflicted")
    eq(
      table.concat(dirty.files, "|"),
      "lua/with space.lua|new name.lua|conflict.lua|untracked file.txt",
      "paths come out raw (spaces kept), the rename's old name is its own field and not an entry"
    )

    local det = C.parse_status(z(HEAD, "# branch.head (detached)"))
    ok(det.detached, "detached head")
    eq(det.branch, nil, "no branch name when detached")
    eq(det.upstream, nil, "no upstream when detached")

    local init = C.parse_status(z("# branch.oid (initial)", "# branch.head main"))
    ok(init.initial, "no commit yet")

    local gone = C.parse_status(z(HEAD, "# branch.head main", "# branch.upstream origin/main"))
    eq(gone.upstream, "origin/main", "upstream named")
    ok(not gone.has_ab, "no ahead/behind line: the upstream is gone")

    local empty = C.parse_status("")
    eq(empty.changed, 0, "empty text")
    eq(C.parse_status(nil).ahead, 0, "nil text")
    eq(C.parse_status(42).behind, 0, "a non-string")
  end

  -- ── classify: every row of the table ───────────────────────────────────
  local function state_of(raw, fetch_err)
    return C.classify("x", "/r/x", raw and C.parse_status(raw), fetch_err)
  end

  eq(state_of(track(0, 0)).state, "current", "behind 0, ahead 0, clean")
  eq(state_of(track(0, 4)).state, "behind", "something to pull")
  eq(state_of(track(0, 4)).detail, "behind 4", "behind detail")
  eq(
    state_of(track(0, 4, "1 .M N... 100644 100644 100644 a b f.lua")).state,
    "behind",
    "behind with a dirty tree is still tried (git decides)"
  )
  eq(state_of(track(2, 0)).state, "ahead", "unpushed commits")
  eq(state_of(track(2, 3)).state, "diverged", "ahead and behind")
  eq(state_of(track(2, 3)).detail, "ahead 2 / behind 3", "diverged detail")
  eq(
    state_of(track(0, 0, "? n.txt")).state,
    "dirty",
    "nothing incoming, local changes (untracked counts)"
  )
  eq(
    state_of(track(2, 0, "1 .M N... 100644 100644 100644 a b f.lua")).state,
    "ahead",
    "ahead wins over dirty (the record still says dirty)"
  )
  ok(
    state_of(track(2, 0, "1 .M N... 100644 100644 100644 a b f.lua")).dirty,
    "...and carries dirty = true"
  )
  eq(state_of(z(HEAD, "# branch.head main")).state, "no_upstream", "no upstream configured")
  eq(
    state_of(z(HEAD, "# branch.head main", "# branch.upstream origin/main")).state,
    "no_upstream",
    "upstream configured but gone"
  )
  has(
    state_of(z(HEAD, "# branch.head main", "# branch.upstream origin/main")).detail,
    "no longer exists",
    "gone upstream says so"
  )
  do
    local conflict = "u UU N... 100644 100644 100644 100644 a b c conflict.lua"
    local c0 = state_of(track(0, 0, conflict))
    eq(c0.state, "conflicted", "conflict markers in the tree are a problem, never the hint `dirty`")
    has(c0.detail, "1 file(s) in conflict", "...and named in the row")
    has(c0.detail, "git stash drop", "...with the way out")
    eq(state_of(track(0, 3, conflict)).state, "conflicted", "also when behind: no pull on a mess")
    eq(state_of(track(2, 3, conflict)).state, "conflicted", "also when diverged: no assist either")
    eq(state_of(track(2, 0, conflict)).state, "conflicted", "also when ahead")
  end
  eq(state_of(z(HEAD, "# branch.head (detached)")).state, "detached", "detached head")
  eq(
    state_of(z(HEAD, "# branch.head (detached)", "# branch.upstream origin/main", ab(0, 3))).state,
    "detached",
    "detached + behind is still just detached (nothing pullable)"
  )
  eq(
    state_of(z(HEAD, "# branch.head main", "? n.txt")).state,
    "no_upstream",
    "no upstream + dirty is no_upstream (the problem, not the hint)"
  )
  eq(state_of(track(0, 0), "could not resolve host").state, "fetch_failed", "fetch failed")
  eq(state_of(track(0, 0), "could not resolve host").detail, "could not resolve host", "its reason")
  eq(
    state_of(track(2, 3), "timeout").state,
    "fetch_failed",
    "a failed fetch wins: the remote refs are stale"
  )
  eq(state_of(nil).state, "status_failed", "git gave no status")

  -- ── after_pull ──────────────────────────────────────────────────────────
  do
    local rec = state_of(track(0, 4))
    local done = C.after_pull(rec, true, nil, nil)
    eq(done.state, "pulled", "pull ok")
    eq(done.pulled, 4, "commits brought in")
    eq(done.behind, 0, "nothing behind afterwards")
    eq(rec.state, "behind", "the input record is not mutated")

    local dirty_after = C.parse_status(track(0, 4, "1 .M N... 100644 100644 100644 a b f.lua"))
    local blocked = C.after_pull(
      rec,
      false,
      "error: Your local changes would be overwritten\nmore",
      dirty_after,
      { "f.lua", "other.lua" }
    )
    eq(blocked.state, "dirty_blocked", "failed pull + dirty tree + the incoming files hit it")
    has(blocked.detail, "1 changed file", "how many files are in the way")
    has(blocked.detail, "Your local changes", "the first error line, shown")
    ok(not blocked.detail:find("more", 1, true), "only the first line")

    local clean_after = C.parse_status(track(0, 4))
    local failed = C.after_pull(rec, false, "fatal: unable to access", clean_after)
    eq(failed.state, "pull_failed", "failed pull, clean tree")
    eq(failed.detail, "fatal: unable to access", "its reason")
    eq(
      C.after_pull(rec, false, nil, nil).state,
      "pull_failed",
      "no status after the failure either"
    )
    eq(
      C.after_pull(rec, false, "", nil).detail,
      "git merge --ff-only @{u} failed",
      "no text at all"
    )

    -- a dirty tree alone is not "blocked": the incoming files must hit the changed ones
    local lock_err = "fatal: Unable to create index.lock"
    local unrelated = C.after_pull(rec, false, lock_err, dirty_after, { "x.lua" })
    eq(unrelated.state, "pull_failed", "dirty tree, but the incoming files are other ones")
    eq(unrelated.detail, lock_err, "the real reason, not 'in the way'")
    eq(
      C.after_pull(rec, false, "boom", dirty_after, nil).state,
      "pull_failed",
      "incoming files unknown: no claim that the local changes are the cause"
    )
    eq(C.after_pull(rec, false, "boom", dirty_after, {}).state, "pull_failed", "nothing incoming")
    local dir_after = C.parse_status(track(0, 4, "? newdir/"))
    eq(
      C.after_pull(rec, false, "e", dir_after, { "newdir/inner.txt" }).state,
      "dirty_blocked",
      "an untracked directory blocks when an incoming file lives below it"
    )
    eq(
      C.after_pull(rec, false, "e", dir_after, { "newdir2/inner.txt" }).state,
      "pull_failed",
      "...but not a sibling with the same prefix"
    )
  end

  -- ── problem / hint ──────────────────────────────────────────────────────
  for _, s in ipairs({
    "fetch_failed",
    "status_failed",
    "no_upstream",
    "detached",
    "diverged",
    "conflicted",
    "dirty_blocked",
    "pull_failed",
  }) do
    ok(C.is_problem(s), s .. " is a problem")
  end
  for _, s in ipairs({ "current", "pulled", "behind", "ahead", "dirty", "not_git", "missing" }) do
    ok(not C.is_problem(s), s .. " is no problem")
  end
  for _, s in ipairs({ "ahead", "dirty", "not_git", "missing" }) do
    ok(C.is_hint(s), s .. " is a hint")
  end
  ok(not C.is_hint("current") and not C.is_hint("diverged"), "current and diverged are no hints")

  -- ── order, visible, summary ─────────────────────────────────────────────
  ---@return MyPlugins.SyncRecord
  local function rec(name, state, extra)
    return vim.tbl_extend("force", {
      name = name,
      path = "/r/" .. name,
      state = state,
      ahead = 0,
      behind = 0,
      dirty = false,
      changed = 0,
      skipped = false,
    }, extra or {})
  end

  local records = {
    rec("zeta", "current"),
    rec("alpha", "pulled"),
    rec("mid", "ahead"),
    rec("nope", "no_upstream"),
    rec("skipme", "diverged", { skipped = true }),
    rec("blocked", "dirty_blocked"),
    rec("split", "diverged"),
    rec("dirtyone", "dirty"),
  }
  local sorted = C.sort(records)
  local order = {}
  for _, r in ipairs(sorted) do
    order[#order + 1] = r.name
  end
  eq(
    table.concat(order, ","),
    "split,blocked,nope,skipme,mid,dirtyone,alpha,zeta",
    "open problems (worst first), skipped, hints, then pulled and current; by name within a state"
  )
  eq(records[1].name, "zeta", "sort leaves its argument alone")

  local shown = C.visible(records, false)
  eq(#shown, 4, "problems and the skipped one, no hints")
  eq(#C.visible(records, true), 6, "with hints: ahead and dirty join")

  local s = C.summarize(records)
  eq(s.total, 8, "total")
  eq(s.pulled, 1, "pulled")
  eq(s.current, 3, "current + two hints count as up to date")
  eq(s.hints, 2, "hints")
  eq(#s.unresolved, 3, "unresolved: split, blocked, nope")
  eq(#s.skipped, 1, "skipped: one")
  ok(not s.all_clear, "not clear with unresolved problems")

  local line, level = C.summary_line(records)
  has(line, "4 up to date (1 pulled)", "up to date incl. pulled")
  has(line, "1 skipped: skipme", "skipped, named")
  has(line, "3 unresolved: split, blocked, nope", "unresolved, named")
  eq(level, "warn", "warn while something is unresolved")

  local clear = {
    rec("a", "current"),
    rec("b", "pulled"),
    rec("c", "ahead"),
    rec("d", "no_upstream", { skipped = true }),
  }
  local cline, clevel = C.summary_line(clear)
  has(cline, "0 unresolved", "nothing unresolved")
  has(cline, "all repositories are up to date except the skipped ones", "the assurance, with skips")
  eq(clevel, "info", "info when nothing is unresolved")
  local only = C.summary_line({ rec("a", "current"), rec("b", "pulled") })
  has(only, "all repositories are up to date", "the assurance, no skips")
  ok(not only:find("except", 1, true), "no 'except' without skips")

  local dry, _ = C.summary_line({ rec("a", "behind"), rec("b", "current") }, true)
  has(dry, "Sync (dry run)", "dry-run prefix")
  has(dry, "1 would be pulled", "pending count")
  ok(not dry:find("all repositories", 1, true), "no assurance in a dry run")
  ok(not C.summarize({ rec("a", "behind") }).all_clear, "a pending pull is not clear")

  -- ── a conflicted repo stays on the list and is never "up to date" ──────
  do
    local mess = { rec("m", "conflicted", { dirty = true }), rec("ok", "current") }
    eq(C.visible(mess, false)[1].name, "m", "conflicted is visible without the hints")
    eq(C.sort({ rec("z", "diverged"), rec("a", "conflicted") })[1].name, "a", "and sorts first")
    local sm = C.summarize(mess)
    eq(#sm.unresolved, 1, "unresolved")
    eq(sm.current, 1, "not counted as up to date")
    ok(not sm.all_clear, "not clear")
    local text, lvl = C.summary_line(mess)
    has(text, "1 unresolved: m", "named in the closing line")
    ok(not text:find("all repositories are up to date", 1, true), "no false assurance")
    eq(lvl, "warn", "warn")
    has(C.format_line(mess[1]), "x ", "problem mark")
  end

  -- ── repos that are not there were not synced: never "up to date" ───────
  do
    local gone = { rec("a", "missing"), rec("b", "not_git"), rec("c", "missing") }
    local sm = C.summarize(gone)
    eq(sm.absent, 3, "counted separately")
    eq(sm.current, 0, "not up to date")
    eq(sm.hints, 0, "not a hint either")
    local text, lvl = C.summary_line(gone)
    has(text, "0 up to date", "nothing is up to date")
    has(text, "3 not cloned/not a repo", "the absent ones are named as such")
    ok(not text:find("all repositories", 1, true), "no assurance with nothing present")
    ok(not text:find("all cloned", 1, true), "...not even a narrowed one")
    eq(lvl, "warn", "warn level")
    local mixed = C.summary_line({ rec("a", "current"), rec("m", "missing") })
    has(mixed, "1 up to date", "present repos are counted")
    has(mixed, "1 not cloned/not a repo", "absent ones too")
    has(mixed, "all cloned repositories are up to date", "the assurance covers the present ones")
    ok(not mixed:find("all repositories are", 1, true), "never claims all of them")
  end

  -- ── one row of the list ─────────────────────────────────────────────────
  local row = C.format_line(rec("filetree.nvim", "dirty_blocked", {
    branch = "main",
    behind = 1,
    detail = "4 changed file(s) in the way",
  }))
  has(row, "x ", "problem mark")
  has(row, "dirty_blocked", "state")
  has(row, "filetree.nvim", "name")
  has(row, "+0 -1", "ahead/behind")
  has(row, "4 changed file(s) in the way", "detail")
  has(C.format_line(rec("a", "diverged", { skipped = true })), "skipped", "a skipped row says so")
  has(C.format_line(rec("a", "diverged", { skipped = true })), ">>", "and has its own mark")

  -- ── assist actions ─────────────────────────────────────────────────────
  do
    eq(
      table.concat(C.assists_for(rec("a", "diverged")), ","),
      "rebase,merge",
      "diverged: rebase or merge"
    )
    eq(
      table.concat(C.assists_for(rec("a", "dirty_blocked")), ","),
      "stash_pull",
      "dirty_blocked: stash, pull, pop"
    )
    for _, st in ipairs({
      "current",
      "pulled",
      "ahead",
      "dirty",
      "no_upstream",
      "detached",
      "fetch_failed",
      "conflicted",
    }) do
      eq(#C.assists_for(rec("a", st)), 0, st .. ": no assist (lazygit is the way)")
    end

    -- the promise to the user: nothing here can destroy work
    for id, info in pairs(C.ASSISTS) do
      for _, command in ipairs(info.commands) do
        ok(not command:find("reset", 1, true), id .. ": no reset in `" .. command .. "`")
        ok(not command:find("clean", 1, true), id .. ": no clean in `" .. command .. "`")
        ok(not command:find("--force", 1, true), id .. ": no force in `" .. command .. "`")
        ok(not command:find("checkout", 1, true), id .. ": no checkout in `" .. command .. "`")
      end
      ok(info.safety ~= "", id .. ": says what happens when it goes wrong")
    end

    local text = C.assist_prompt(rec("filetree.nvim", "dirty_blocked"), "stash_pull")
    has(text, "filetree.nvim", "the question names the repo")
    has(text, "git stash push --include-untracked", "...and the exact commands")
    has(text, "git merge --ff-only @{u}", "...all of them")
    has(text, "git stash pop", "...in order")
    has(text, "popped again even when the pull fails", "...and what protects the work")
    has(
      C.assist_prompt(rec("a", "diverged"), "rebase"),
      "git rebase --rebase-merges @{u}",
      "rebase names its exact command, local merge commits are kept"
    )
    eq(
      C.ASSISTS.rebase.commands[1],
      "git rebase --rebase-merges @{u}",
      "the prompt and the command that runs are one string"
    )
    has(
      C.assist_prompt(rec("a", "diverged"), "merge"),
      "git merge --no-edit @{u}",
      "merge names its command"
    )
  end

  -- ── absent, merge ───────────────────────────────────────────────────────
  do
    local gone = C.absent("x", "/r/x", "missing")
    eq(gone.state, "missing", "absent: missing")
    has(gone.detail, ":MyPlugins clone", "a missing repo points to clone")
    eq(C.absent("y", "/r/y", "not_git").state, "not_git", "absent: not a repo")
    local merged = C.merge(
      { rec("a", "diverged"), rec("b", "current"), rec("c", "detached") },
      { rec("b", "pulled"), rec("d", "ahead") }
    )
    local out = {}
    for _, r in ipairs(merged) do
      out[#out + 1] = r.name .. ":" .. r.state
    end
    eq(
      table.concat(out, ","),
      "a:diverged,b:pulled,c:detached,d:ahead",
      "a partial run replaces its own repos, keeps the others and appends new ones"
    )
  end
end
