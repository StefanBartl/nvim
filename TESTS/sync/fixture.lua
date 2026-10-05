-- TESTS/sync/fixture.lua -- throwaway git repositories for the `:MyPlugins sync` specs.
--
-- `require`d through dofile by the specs: `local fx = dofile(dir .. "/fixture.lua")(H)`.
-- Everything lives under `H.tmpdir()`; the real repositories are never touched. The helpers are
-- synchronous on purpose (fixture code, not the code under test).

---@param H table  The spec harness (`H.tmpdir`, `H.write`).
return function(H)
  local F = {}

  ---Where the clones under test live (the sync's base directory).
  F.base = H.tmpdir() .. "/repos"
  vim.fn.mkdir(F.base, "p")

  local ENV = { GIT_TERMINAL_PROMPT = "0", GIT_CONFIG_NOSYSTEM = "1" }
  local ID =
    { "-c", "user.name=Spec", "-c", "user.email=spec@example.invalid", "-c", "core.autocrlf=false" }

  ---Run git in `dir`; raises with git's own complaint on failure.
  ---@param dir string
  ---@param ... string
  ---@return string stdout
  function F.git(dir, ...)
    local cmd = { "git", "-C", dir }
    vim.list_extend(cmd, ID)
    vim.list_extend(cmd, { ... })
    local res = vim.system(cmd, { text = true, env = ENV }):wait(30000)
    if res.code ~= 0 then
      error(
        ("git %s failed in %s: %s"):format(table.concat({ ... }, " "), dir, res.stderr or ""),
        2
      )
    end
    return res.stdout or ""
  end

  ---@param dir string
  ---@param file string
  ---@param text string
  ---@param message string
  function F.commit_file(dir, file, text, message)
    H.write(dir .. "/" .. file, text)
    F.git(dir, "add", file)
    F.git(dir, "commit", "-q", "-m", message)
  end

  ---A bare remote with `a.txt` and `b.txt` on `main`, a developer clone of it (what the other
  ---machine pushes from) and the clone under test `F.base/<name>`.
  ---@param name string
  ---@return { remote: string, dev: string, repo: string }
  function F.make(name)
    local remote = H.tmpdir() .. "/remotes/" .. name .. ".git"
    local dev = H.tmpdir() .. "/dev/" .. name
    local repo = F.base .. "/" .. name
    vim.fn.mkdir(vim.fs.dirname(remote), "p")
    vim.fn.mkdir(vim.fs.dirname(dev), "p")
    local res = vim
      .system({ "git", "init", "-q", "--bare", "-b", "main", remote }, { env = ENV })
      :wait(30000)
    assert(res.code == 0, res.stderr)
    F.git(vim.fs.dirname(dev), "clone", "-q", remote, dev)
    F.git(dev, "checkout", "-q", "-B", "main")
    F.commit_file(dev, "a.txt", "a1\n", "a")
    F.commit_file(dev, "b.txt", "b1\n", "b")
    F.git(dev, "push", "-q", "-u", "origin", "main")
    F.git(F.base, "clone", "-q", remote, repo)
    return { remote = remote, dev = dev, repo = repo }
  end

  ---A new commit pushed from the developer clone.
  ---@param c { dev: string }
  ---@param file string
  ---@param text string
  function F.incoming(c, file, text)
    F.commit_file(c.dev, file, text, "incoming " .. file)
    F.git(c.dev, "push", "-q")
  end

  return F
end
