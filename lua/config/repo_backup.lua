---@module 'config.repo_backup'
---@brief Weekly local backup of repos that have no remote (a `git bundle --all`, replaced each time).
---@description
--- Some repos live only on this machine on purpose (WKDBook-Tricentis holds customer
--- data and must not go to GitHub). They get one backup file each, refreshed when the
--- last one is older than `M.EVERY`:
---
---   <backup dir>/<repo>.bundle      restore: git clone <repo>.bundle <dir>
---
--- Backup dir: `$REPO_BACKUP_DIR`, else `<parent of $REPOS_DIR>/repos-backup/weekly`.
--- Runs from init.lua's UIReady phase `repo_backup`, fully async (`vim.system`): the
--- bundle is written to `<repo>.bundle.tmp`, checked with `git bundle verify`, and only
--- then renamed over the old one, so a failed run never destroys the last good backup.
--- A repo folder that does not exist is skipped silently (other machines).
---
--- Same disk as the repo: this protects against git accidents and deleted folders, not
--- against a dead disk. Docs: docs/NOTES/repo-backup.md.

local notify = require("lib.nvim.notify").create("[repo_backup]")

local M = {}

--- Repo folder names below `$REPOS_DIR`.
---@type string[]
M.REPOS = { "WKDBook-Tricentis" }

--- Seconds between two backups of one repo.
M.EVERY = 7 * 24 * 3600

---@return string|nil
function M.dir()
  if vim.env.REPO_BACKUP_DIR and vim.env.REPO_BACKUP_DIR ~= "" then
    return vim.fs.normalize(vim.env.REPO_BACKUP_DIR)
  end
  local repos = vim.env.REPOS_DIR
  if not repos or repos == "" then
    return nil
  end
  return vim.fs.joinpath(vim.fs.dirname(vim.fs.normalize(repos)), "repos-backup", "weekly")
end

--- Whether `bundle` is missing or older than `M.EVERY`.
---@param bundle string
---@param now? integer os.time()
---@return boolean
function M.due(bundle, now)
  local stat = vim.uv.fs_stat(bundle)
  if not stat then
    return true
  end
  return (now or os.time()) - stat.mtime.sec >= M.EVERY
end

--- A temp file left by a run that died (Neovim killed mid-bundle) is removed once
--- it is older than this: a live run of another instance is never that old.
local STALE_TMP = 3600

--- Remove `<bundle>.tmp-<pid>` files of earlier runs that never finished.
---@param bundle string
local function remove_stale_tmps(bundle)
  local dir, base = vim.fs.dirname(bundle), vim.fs.basename(bundle) .. ".tmp-"
  local now = os.time()
  for name, kind in vim.fs.dir(dir) do
    if kind == "file" and name:sub(1, #base) == base then
      local path = vim.fs.joinpath(dir, name)
      local stat = vim.uv.fs_stat(path)
      if stat and now - stat.mtime.sec > STALE_TMP then
        os.remove(path)
      end
    end
  end
end

--- `vim.system`, but a git that cannot be started (not on PATH) is a failed run
--- reported through `on_exit`, not an error thrown into the startup phase.
---@param cmd string[]
---@param on_exit fun(r: { code: integer, stderr: string|nil })
local function run_git(cmd, on_exit)
  local ok, err = pcall(vim.system, cmd, { text = true }, on_exit)
  if not ok then
    on_exit({ code = -1, stderr = tostring(err) })
  end
end

---@param repo_dir string
---@param bundle string
---@param on_done fun(ok: boolean, err: string|nil)
local function backup(repo_dir, bundle, on_done)
  remove_stale_tmps(bundle)
  -- One temp file per process: two Neovim instances started together both find
  -- the bundle due, and a shared name let one verify and rename the file the
  -- other was still writing.
  local tmp = ("%s.tmp-%d"):format(bundle, vim.uv.os_getpid())
  run_git({ "git", "-C", repo_dir, "bundle", "create", tmp, "--all" }, function(created)
    if created.code ~= 0 then
      os.remove(tmp)
      return on_done(false, vim.trim(created.stderr or ""))
    end
    run_git({ "git", "-C", repo_dir, "bundle", "verify", tmp }, function(verified)
      if verified.code ~= 0 then
        os.remove(tmp)
        return on_done(false, "verify failed: " .. vim.trim(verified.stderr or ""))
      end
      -- libuv renames with MOVEFILE_REPLACE_EXISTING on Windows: replaces the old bundle.
      local ok, err = vim.uv.fs_rename(tmp, bundle)
      if not ok then
        os.remove(tmp)
      end
      on_done(ok == true, err)
    end)
  end)
end

--- Back up every repo of `M.REPOS` whose bundle is due.
---@param opts? { repos_dir?: string, backup_dir?: string, now?: integer, on_done?: fun(results: table<string, boolean>) }
---@return integer started  how many backups were started
function M.run(opts)
  opts = opts or {}
  local repos_dir = opts.repos_dir or vim.env.REPOS_DIR
  local backup_dir = opts.backup_dir or M.dir()
  if not repos_dir or repos_dir == "" or not backup_dir then
    return 0
  end

  local results, pending, started = {}, 0, 0
  local function finish(name, ok, err)
    vim.schedule(function()
      results[name] = ok
      if ok then
        notify.info(("%s: weekly backup written"):format(name))
      else
        notify.warn(("%s: backup failed, the previous one is kept (%s)"):format(name, err or "?"))
      end
      pending = pending - 1
      if pending == 0 and opts.on_done then
        opts.on_done(results)
      end
    end)
  end

  for _, name in ipairs(M.REPOS) do
    local repo_dir = vim.fs.joinpath(repos_dir, name)
    local bundle = vim.fs.joinpath(backup_dir, name .. ".bundle")
    if vim.fn.isdirectory(repo_dir .. "/.git") == 1 and M.due(bundle, opts.now) then
      vim.fn.mkdir(backup_dir, "p")
      pending, started = pending + 1, started + 1
      backup(repo_dir, bundle, function(ok, err)
        finish(name, ok, err)
      end)
    end
  end
  if started == 0 and opts.on_done then
    opts.on_done(results)
  end
  return started
end

return M
