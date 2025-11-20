-- File: lua/myoptions/Highlight_Cfg/path_cache.lua
-- Purpose: buffer-local caching for repo root and relative path; tiny + dependency-free.

---@module 'myoptions.Highlight_Cfg.path_cache'
--- Buffer-local cache for repo root and repo-relative path. Reduces repeated
--- upward searches on every CursorMoved/WinScrolled event when the winbar updates.

local M = {}

-- Namespace augroup for cache refresh
local AUG_PATHCACHE = vim.api.nvim_create_augroup("myopt_PathCache", { clear = true })

--- Compute the repo root for a given directory by searching for ".git" upwards.
--- Returns: absolute root dir (string) or nil when no .git is found.
---@param dir string
---@return string|nil
local function compute_repo_root(dir)
  if not dir or dir == "" then
    return nil
  end
  local gitdir = vim.fs.find(".git", { upward = true, path = dir })[1]
  if not gitdir then
    return nil
  end
  -- gitdir may be ".../<root>/.git" (file or directory); root is its parent
  return vim.fn.fnamemodify(gitdir, ":h")
end

--- Compute a repo-relative or "~"-shortened path without touching buffer cache.
---@param path string
---@return string
local function compute_repo_relative(path)
  if path == "" then
    return "[No Name]"
  end
  local dir = vim.fn.fnamemodify(path, ":h")
  local root = compute_repo_root(dir)
  if root then
    -- Build a relative path to the root (with home/relative fallback kept)
    local rel = vim.fn.fnamemodify(path, (":~:%s"):format(root))
    if rel == path then
      -- Path did not change after substitution (edge case: different device, UNC, etc.)
      return vim.fn.fnamemodify(path, ":t")
    end
    rel = rel:gsub("^%./", ""):gsub("^/", "")
    return rel
  else
    return vim.fn.fnamemodify(path, ":~:.")
  end
end

--- Prime the cache for a specific buffer number (0 = current).
--- Writes: b.myopt_repo_root, b.myopt_repo_rel, b.myopt_repo_rel_path, b.myopt_repo_rel_cwd
---@param bufnr integer
---@return nil
function M.refresh_buffer_cache(bufnr)
  bufnr = bufnr or 0
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end
  local path = vim.api.nvim_buf_get_name(bufnr)
  if path == "" then
    vim.b[bufnr].myopt_repo_root = nil
    vim.b[bufnr].myopt_repo_rel = "[No Name]"
    vim.b[bufnr].myopt_repo_rel_path = ""
    vim.b[bufnr].myopt_repo_rel_cwd = vim.loop.cwd()
    return
  end
  local dir = vim.fn.fnamemodify(path, ":h")
  local root = compute_repo_root(dir)
  vim.b[bufnr].myopt_repo_root = root
  vim.b[bufnr].myopt_repo_rel = compute_repo_relative(path)
  vim.b[bufnr].myopt_repo_rel_path = path
  vim.b[bufnr].myopt_repo_rel_cwd = vim.loop.cwd()
end

--- Get repo-relative path from cache; recompute lazily on mismatch.
---@param path string
---@param bufnr integer|nil
---@return string
function M.repo_relative_cached(path, bufnr)
  bufnr = bufnr or 0
  local b = vim.b[bufnr]
  -- Recompute if path changed, cwd changed (rare but relevant), or cache missing.
  if b.myopt_repo_rel and b.myopt_repo_rel_path == path and b.myopt_repo_rel_cwd == vim.loop.cwd() then
    return b.myopt_repo_rel
  end
  M.refresh_buffer_cache(bufnr)
  return vim.b[bufnr].myopt_repo_rel or compute_repo_relative(path)
end

--- Install autocmds that keep the cache reasonably fresh.
--- Triggers:
---   * BufEnter/BufFilePost: new buffer or file assigned
---   * DirChanged: project root moves (e.g., :cd, :tcd)
---@return nil
function M.ensure_autocmds()
  vim.api.nvim_clear_autocmds({ group = AUG_PATHCACHE })
  vim.api.nvim_create_autocmd({ "BufEnter", "BufFilePost" }, {
    group = AUG_PATHCACHE,
    callback = function(args)
      M.refresh_buffer_cache(args.buf)
    end,
    desc = "Prime repo path cache per buffer",
  })
  vim.api.nvim_create_autocmd("DirChanged", {
    group = AUG_PATHCACHE,
    callback = function()
      -- CWD changed: refresh current buffer cache
      M.refresh_buffer_cache(0)
    end,
    desc = "Refresh repo path cache on :cd/:tcd",
  })
end

return M
