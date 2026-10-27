-- TESTS/repo_backup/repo_backup_spec.lua -- `config.repo_backup`: a due repo gets a verified
-- bundle, a fresh bundle is left alone, an old one is replaced, a missing repo is skipped,
-- and a failing run keeps the previous bundle.

return function(H)
  local eq, ok = H.eq, H.ok

  local saved_repos = package.loaded["config.repo_backup"]
  package.loaded["config.repo_backup"] = nil
  local backup = require("config.repo_backup")
  local saved_list = backup.REPOS

  ---@param args string[]
  local function git(args)
    local r = vim.system(vim.list_extend({ "git" }, args), { text = true }):wait()
    assert(r.code == 0, table.concat(args, " ") .. ": " .. (r.stderr or ""))
    return vim.trim(r.stdout or "")
  end

  ---@param opts table
  ---@return integer started
  ---@return table<string, boolean> results
  local function run(opts)
    local results
    opts.on_done = function(r)
      results = r
    end
    local started = backup.run(opts)
    vim.wait(30000, function()
      return results ~= nil
    end, 50)
    return started, results
  end

  local done, err = pcall(function()
    local root = H.tmpdir()
    local repos = root .. "/repos"
    local dest = root .. "/backup"
    vim.fn.mkdir(repos .. "/Local-Repo", "p")
    git({ "-C", repos .. "/Local-Repo", "init", "-q" })
    H.write(repos .. "/Local-Repo/a.md", "one\n")
    git({ "-C", repos .. "/Local-Repo", "add", "a.md" })
    git({
      "-C",
      repos .. "/Local-Repo",
      "-c",
      "user.name=t",
      "-c",
      "user.email=t@t",
      "commit",
      "-q",
      "-m",
      "one",
    })
    backup.REPOS = { "Local-Repo", "Not-Here" }
    local bundle = dest .. "/Local-Repo.bundle"

    local started, results = run({ repos_dir = repos, backup_dir = dest })
    eq(started, 1, "only the existing repo is backed up")
    eq(results, { ["Local-Repo"] = true }, "the backup succeeded")
    ok(vim.uv.fs_stat(bundle) ~= nil, "bundle written")
    ok(vim.uv.fs_stat(bundle .. ".tmp") == nil, "no temp file left")
    git({ "bundle", "verify", bundle })

    started = run({ repos_dir = repos, backup_dir = dest })
    eq(started, 0, "a fresh bundle is not redone")

    H.write(repos .. "/Local-Repo/b.md", "two\n")
    git({ "-C", repos .. "/Local-Repo", "add", "b.md" })
    git({
      "-C",
      repos .. "/Local-Repo",
      "-c",
      "user.name=t",
      "-c",
      "user.email=t@t",
      "commit",
      "-q",
      "-m",
      "two",
    })
    local head = git({ "-C", repos .. "/Local-Repo", "rev-parse", "HEAD" })
    started = run({ repos_dir = repos, backup_dir = dest, now = os.time() + backup.EVERY })
    eq(started, 1, "a week later the bundle is due again")
    local heads = git({ "bundle", "list-heads", bundle })
    ok(heads:find(head, 1, true) ~= nil, "the replaced bundle holds the new commit")

    -- A failing run (not a git repo any more) must keep the last good bundle.
    local before = H.read(bundle)
    vim.fn.delete(repos .. "/Local-Repo/.git/HEAD")
    local s2, r2 = run({ repos_dir = repos, backup_dir = dest, now = os.time() + 2 * backup.EVERY })
    eq(s2, 1, "the broken repo is still attempted")
    eq(r2, { ["Local-Repo"] = false }, "the run reports the failure")
    eq(H.read(bundle), before, "the previous bundle is untouched")
  end)

  backup.REPOS = saved_list
  package.loaded["config.repo_backup"] = saved_repos
  if not done then
    error(err, 0)
  end
end
