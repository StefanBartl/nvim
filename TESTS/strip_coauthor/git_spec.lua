-- TESTS/strip_coauthor/git_spec.lua -- scripts/strip_coauthor/git.lua: planning and rewriting on a throwaway repo.
--
-- Pins the three things the first version got wrong: a trailer on the root commit was refused, a
-- trailer past the 120th trailer commit was not seen, and `Co-authored-by:` (other case) was not
-- matched. Works only on a repository created here; nothing real is touched.

return function(H)
  local eq, ok = H.eq, H.ok
  local here = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p")
  local config_root = vim.fs.dirname(vim.fs.dirname(vim.fs.dirname(vim.fs.normalize(here))))
  local gitx = dofile(config_root .. "/scripts/strip_coauthor/git.lua")

  ---@param dir string
  ---@param args string[]
  ---@return string
  local function git(dir, args)
    local cmd = { "git", "-C", dir }
    vim.list_extend(cmd, args)
    local res = vim.system(cmd, { text = true }):wait()
    assert(res.code == 0, table.concat(cmd, " ") .. ": " .. (res.stderr or ""))
    local text = (res.stdout or ""):gsub("\n$", "")
    return text
  end

  ---@param dir string
  ---@param file string
  ---@param subject string
  ---@param trailer string|nil
  local function commit(dir, file, subject, trailer)
    H.write(dir .. "/" .. file, file)
    git(dir, { "add", file })
    local args =
      { "-c", "user.name=T", "-c", "user.email=t@example.com", "commit", "-q", "-m", subject }
    if trailer then
      vim.list_extend(args, { "-m", trailer })
    end
    git(dir, args)
  end

  -- A repository whose ROOT commit carries the trailer, with a second one (other case) on top and
  -- a clean commit last.
  local dir = H.tmpdir()
  git(dir, { "init", "-q", "-b", "main" })
  commit(dir, "a", "root", "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>")
  commit(dir, "b", "second")
  commit(dir, "c", "third", "Co-authored-by: Claude Opus <noreply@anthropic.com>")
  commit(dir, "d", "fourth")
  -- A lightweight tag on "second" and an annotated one on "third" (both change with the rewrite),
  -- one on "fourth" is above them and changes too.
  git(dir, { "tag", "light-v1", "main~2" })
  git(dir, {
    "-c",
    "user.name=T",
    "-c",
    "user.email=t@example.com",
    "tag",
    "-a",
    "-m",
    "release two",
    "annotated-v2",
    "main~1",
  })

  -- The way back: a verified bundle of every ref.
  local bundle = H.tmpdir() .. "/before.bundle"
  local backed, backup_err = gitx.backup(dir, bundle)
  ok(backed, "the backup bundle is written and verifies: " .. tostring(backup_err))
  ok(H.exists(bundle), "the bundle file exists")

  local old_tip = git(dir, { "rev-parse", "main" })
  local old_tree = git(dir, { "rev-parse", "main^{tree}" })

  local plan, err = gitx.plan(dir)
  eq(err, nil, "a trailer on the root commit is planned, not refused")
  ok(plan ~= nil, "the repository needs a rewrite")
  eq(#plan.trailers, 2, "both spellings of the trailer are found")
  eq(#plan.commits, 4, "the root and everything above it is rebuilt")
  eq(plan.branches, { "main" }, "main is affected")

  local result, rewrite_err = gitx.rewrite(dir, plan)
  eq(rewrite_err, nil, "the rewrite succeeds")
  ok(result ~= nil, "the rewrite returns a result")
  eq(result.rebuilt, 4, "four commits rebuilt")

  -- The old -> new map is returned (it re-pins references afterwards) and the tags moved along.
  eq(result.map[old_tip], git(dir, { "rev-parse", "main" }), "the map names the new tip of main")
  eq(#result.tags, 2, "both tags moved")
  eq(
    git(dir, { "cat-file", "-t", "annotated-v2" }),
    "tag",
    "the annotated tag is still a tag object"
  )
  eq(
    git(dir, { "tag", "-l", "--format=%(contents:subject)", "annotated-v2" }),
    "release two",
    "its message is kept"
  )
  eq(
    git(dir, { "log", "-1", "--format=%s", "light-v1" }),
    "second",
    "the lightweight tag sits on the same subject"
  )
  eq(
    git(dir, { "log", "-1", "--format=%s", "annotated-v2^{commit}" }),
    "third",
    "the annotated tag too"
  )
  eq(
    git(dir, { "rev-list", "-i", "--count", "--grep=co-authored-by: claude", "--all" }),
    "0",
    "no ref reaches a trailer"
  )

  local new_tip = git(dir, { "rev-parse", "main" })
  ok(new_tip ~= old_tip, "main moved")
  eq(git(dir, { "rev-parse", "main^{tree}" }), old_tree, "the tree is untouched")
  eq(
    git(dir, { "log", "--format=%s", "main" }),
    "fourth\nthird\nsecond\nroot",
    "the subjects are untouched"
  )
  eq(
    git(dir, { "rev-list", "-i", "--count", "--grep=co-authored-by: claude", "main" }),
    "0",
    "no trailer is left"
  )
  eq(gitx.plan(dir), nil, "a clean repository needs nothing")

  -- The cap is gone: git counts the *matching* commits for -N, so the old default of 120 left
  -- every trailer commit past the 120th standing (docmap-desktop has 155). With a cap of 2 only two
  -- of three are found, by default all of them are.
  local many = H.tmpdir()
  git(many, { "init", "-q", "-b", "main" })
  for i = 1, 3 do
    commit(many, "t" .. i, "trailer " .. i, "Co-Authored-By: Claude <noreply@anthropic.com>")
  end
  eq(gitx.SEARCH_DEPTH, nil, "the default is the whole history")
  eq(#gitx.plan(many).trailers, 3, "by default every trailer commit is found")
  gitx.SEARCH_DEPTH = 2
  eq(#gitx.plan(many).trailers, 2, "a cap limits the trailer commits found")
  gitx.SEARCH_DEPTH = nil

  -- Against a real (bare) origin: the rewritten branch and the moved tags are found pending, pushed
  -- with a lease, and afterwards origin holds no trailer and the tags at their new place.
  local bare = H.tmpdir()
  git(bare, { "init", "-q", "--bare", "-b", "main" })
  local work = H.tmpdir()
  git(work, { "init", "-q", "-b", "main" })
  git(work, { "remote", "add", "origin", bare })
  commit(work, "a", "root", "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>")
  commit(work, "b", "second")
  git(work, { "tag", "light-v1", "main~1" })
  git(work, {
    "-c",
    "user.name=T",
    "-c",
    "user.email=t@example.com",
    "tag",
    "-a",
    "-m",
    "release",
    "annotated-v2",
    "main",
  })
  git(work, { "push", "-q", "origin", "main", "--tags" })
  eq(gitx.pending_push(work), {}, "nothing is pending while local and origin agree")
  eq(gitx.pending_tags(work), {}, "no tag is pending while local and origin agree")

  local work_plan = gitx.plan(work)
  local work_result = gitx.rewrite(work, work_plan)
  ok(work_result ~= nil, "the rewrite of the clone works")
  local pending = gitx.pending_push(work)
  eq(#pending, 1, "main is pending")
  local pending_tags = gitx.pending_tags(work)
  eq(#pending_tags, 2, "both moved tags are pending")

  for _, r in ipairs(gitx.push(work, pending)) do
    eq(r.status, "pushed", "branch pushed: " .. tostring(r.detail))
  end
  for _, r in ipairs(gitx.push_tags(work, pending_tags)) do
    eq(r.status, "pushed", "tag pushed: " .. tostring(r.detail))
  end
  eq(
    git(bare, { "rev-list", "-i", "--count", "--grep=co-authored-by: claude", "--all" }),
    "0",
    "origin holds no trailer any more"
  )
  eq(
    git(bare, { "rev-parse", "annotated-v2^{commit}" }),
    git(work, { "rev-parse", "main" }),
    "the annotated tag on origin is at the new commit"
  )
  eq(gitx.pending_tags(work), {}, "nothing is pending after the push")

  -- More than three moved tags go out in ONE push (GitHub creates no push events for that, so tag-
  -- triggered release workflows stay quiet); all of them still arrive with their new value.
  local bare4 = H.tmpdir()
  git(bare4, { "init", "-q", "--bare", "-b", "main" })
  -- A hook that counts the pushes the remote receives: one line per push.
  local counter = bare4 .. "/pushes.log"
  H.write(
    bare4 .. "/hooks/pre-receive",
    "#!/bin/sh\necho x >> '" .. counter .. "'\ncat > /dev/null\n"
  )
  vim.uv.fs_chmod(bare4 .. "/hooks/pre-receive", 493)
  local function pushes()
    local lines = vim.fn.filereadable(counter) == 1 and vim.fn.readfile(counter) or {}
    return #lines
  end
  local work4 = H.tmpdir()
  git(work4, { "init", "-q", "-b", "main" })
  git(work4, { "remote", "add", "origin", bare4 })
  commit(work4, "a", "root", "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>")
  commit(work4, "b", "second")
  for i = 1, 4 do
    git(work4, { "tag", "rel-" .. i, i % 2 == 0 and "main" or "main~1" })
  end
  git(work4, { "push", "-q", "origin", "main", "--tags" })
  ok(gitx.rewrite(work4, gitx.plan(work4)) ~= nil, "the rewrite of the four-tag repository works")
  local pending4 = gitx.pending_tags(work4)
  eq(#pending4, 4, "all four moved tags are pending")
  local before = pushes()
  local results4 = gitx.push_tags(work4, pending4)
  eq(pushes() - before, 1, "four tags are ONE push (GitHub creates no push events for that)")
  eq(#results4, 4, "one result per tag")
  for _, r in ipairs(results4) do
    eq(r.status, "pushed", "tag pushed in the batch: " .. tostring(r.detail))
  end
  for i = 1, 4 do
    eq(
      git(bare4, { "rev-parse", "rel-" .. i }),
      git(work4, { "rev-parse", "rel-" .. i }),
      "tag rel-" .. i .. " has the new value on origin"
    )
  end
  eq(gitx.pending_tags(work4), {}, "nothing is pending after the batch push")
end
