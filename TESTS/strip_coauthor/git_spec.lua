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
end
