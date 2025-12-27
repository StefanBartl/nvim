---@module 'custom.repo_pickers.fs'
--- Filesystem helpers: path ops, repo scanning, and display label formatting.
require("custom.repo_pickers.@types.types")

local M = {}

---@type uv
local uv = vim.uv or vim.loop

--- Normalize a path in a cross-platform way.
--- Uses vim.fs.normalize when available; otherwise performs a minimal cleanup.
--- @param p string
--- @return string
function M.normalize(p)
  if type(p) ~= "string" or p == "" then
    return p
  end
  if vim.fs and vim.fs.normalize then
    return vim.fs.normalize(p)
  end
  -- Avoid returning the second value from gsub (substitutions count)
  local s = p:gsub("\\", "/")
  s = s:gsub("//+", "/")
  return s
end

--- Join two path segments while preserving the prevailing separator style from `a`.
--- @param a string
--- @param b string
--- @return string
function M.join(a, b)
  if a:sub(-1) == "/" or a:sub(-1) == "\\" then
    return a .. b
  end
  local sep = a:find("\\", 1, true) and "\\" or "/"
  return a .. sep .. b
end

--- Return true if `p` is a directory.
--- @param p string
--- @return boolean
function M.is_dir(p)
  local st = uv.fs_stat(p)
  return (st and st.type == "directory") or false
end

--- Return true if path contains a `.git` entry (dir or file; supports worktrees).
--- @param dir RepoPickers.RepoDir
--- @return boolean
function M.has_git(dir)
  local git_path = M.join(dir, ".git")
  local st = uv.fs_stat(git_path)
  return st ~= nil
end

--- Scan immediate subdirectories of `root` and optionally filter by `.git` presence.
--- Returns sorted absolute paths.
--- @param root string
--- @param only_git boolean
--- @return RepoPickers.RepoDir[]|nil, string?  -- nil,err on failure
function M.scan_repos(root, only_git)
  if type(root) ~= "string" or root == "" then
    return nil, "Missing repos_dir (set $REPOS_DIR or pass config.repos_dir)"
  end
  root = M.normalize(root)
  if not M.is_dir(root) then
    return nil, ("repos_dir is not a directory: %s"):format(root)
  end

  local req = uv.fs_scandir(root)
  if not req then
    return nil, ("Failed to scan directory: %s"):format(root)
  end

  ---@type RepoPickers.RepoDir[]
  local out = {} -- unknown length; dynamic growth is fine here

  while true do
    local name, ftype = uv.fs_scandir_next(req)
    if not name then
      break
    end
    if ftype == "directory" then
      local full = M.join(root, name)
      if (not only_git) or M.has_git(full) then
        out[#out + 1] = full
      end
    end
  end

  table.sort(out, function(a, b)
    local aa = a:match("([^/\\]+)[/\\]?$") or a
    local bb = b:match("([^/\\]+)[/\\]?$") or b
    return aa:lower() < bb:lower()
  end)

  return out, nil
end

--- Compute a presentation label for a repo path.
--- When `show_relative` is enabled and `repos_dir` is a prefix, return a relative label; else basename.
--- @param cfg RepoPickers.Config
--- @param repo RepoPickers.RepoDir
--- @return string
function M.label_of(cfg, repo)
  if not cfg.show_relative then
    return repo
  end
  local base = cfg.repos_dir and M.normalize(cfg.repos_dir) or ""
  if base ~= "" then
    local pref = base:gsub("([%%%^%$%(%)%.%[%]%*%+%-%?])", "%%%1")
    local rel = repo:gsub("^" .. pref .. "[/\\]", "")
    if rel ~= repo then
      return rel
    end
  end
  return repo:match("([^/\\]+)[/\\]?$") or repo
end

--- Recursively scan all subdirectories of `root` that match the given prefix.
--- Returns sorted absolute paths.
--- @param root string
--- @param prefix string
--- @param max_depth? integer  -- Maximum recursion depth (default: 10)
--- @return RepoPickers.RepoDir[]|nil, string?  -- nil,err on failure
function M.scan_wkdbooks(root, prefix, max_depth)
  if type(root) ~= "string" or root == "" then
    return nil, "Missing wkdbooks_dir (set $REPOS_DIR or pass config.wkdbooks_dir)"
  end
  root = M.normalize(root)
  if not M.is_dir(root) then
    return nil, ("wkdbooks_dir is not a directory: %s"):format(root)
  end

  max_depth = max_depth or 10
  local prefix_lower = prefix:lower()

  ---@type RepoDir[]
  local out = {}

  --- Recursive helper to scan directories
  ---@param dir string
  ---@param depth integer
  local function scan_recursive(dir, depth)
    if depth > max_depth then
      return
    end

    local req = uv.fs_scandir(dir)
    if not req then
      return
    end

    while true do
      local name, ftype = uv.fs_scandir_next(req)
      if not name then
        break
      end

      if ftype == "directory" then
        local full = M.join(dir, name)

        -- Check if directory name starts with prefix (case-insensitive)
        if name:lower():sub(1, #prefix_lower) == prefix_lower then
          out[#out + 1] = full
        end

        -- Continue scanning subdirectories recursively
        scan_recursive(full, depth + 1)
      end
    end
  end

  scan_recursive(root, 0)

  -- Sort by directory basename (case-insensitive)
  table.sort(out, function(a, b)
    local aa = a:match("([^/\\]+)[/\\]?$") or a
    local bb = b:match("([^/\\]+)[/\\]?$") or b
    return aa:lower() < bb:lower()
  end)

  return out, nil
end

--- Compute a presentation label for a wkdbook path.
--- Always returns only the directory basename (e.g., "wkdbook-Git" instead of "SoftwareDokumentationen/wkdbook-Git").
--- @param cfg RepoPickers.Config
--- @param wkdbook RepoPickers.RepoDir
--- @return string
---@diagnostic disable-next-line: unused-local
function M.label_of_wkdbook(cfg, wkdbook)
  -- Always return just the basename for wkdbooks
  return wkdbook:match("([^/\\]+)[/\\]?$") or wkdbook
end

return M
