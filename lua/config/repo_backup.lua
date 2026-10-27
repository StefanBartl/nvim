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

---@param repo_dir string
---@param bundle string
---@param on_done fun(ok: boolean, err: string|nil)
local function backup(repo_dir, bundle, on_done)
  local tmp = bundle .. ".tmp"
  vim.system(
    { "git", "-C", repo_dir, "bundle", "create", tmp, "--all" },
    { text = true },
    function(created)
      if created.code ~= 0 then
        os.remove(tmp)
        return on_done(false, vim.trim(created.stderr or ""))
      end
      vim.system(
        { "git", "-C", repo_dir, "bundle", "verify", tmp },
        { text = true },
        function(verified)
          if verified.code ~= 0 then
            os.remove(tmp)
            return on_done(false, "verify failed: " .. vim.trim(verified.stderr or ""))
          end
          -- libuv renames with MOVEFILE_REPLACE_EXISTING on Windows: replaces the old bundle.
          local ok, err = vim.uv.fs_rename(tmp, bundle)
          on_done(ok == true, err)
        end
      )
    end
  )
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
