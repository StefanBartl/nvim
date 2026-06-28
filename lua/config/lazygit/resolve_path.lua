---@module 'config.lazygit.resolve_path'
--- Resolve a path coming from a LazyGit custom command to an absolute path the
--- parent Neovim can open.
---
--- LazyGit always passes paths relative to the repository root (forward slashes).
--- nvr's `-c` does not adjust those (only file *arguments* are adjusted), so we
--- resolve them here:
---   1. git root of the current working directory (the common case), then
---   2. the current working directory itself, as a fallback.
--- The first readable candidate wins; otherwise the cwd-based guess is returned.

local fn = vim.fn

--- True if `path` is already absolute (Windows drive, UNC, or POSIX root).
---@param path string
---@return boolean
local function is_absolute(path)
  return path:match("^%a:[\\/]") ~= nil -- C:\ or C:/
    or path:match("^[\\/][\\/]") ~= nil -- \\share or //share
    or path:match("^/") ~= nil -- /posix
end

--- @param raw string repo-root-relative (or absolute) path from LazyGit
--- @return string absolute path with OS-native separators
return function(raw)
  if is_absolute(raw) then
    return fn.fnamemodify(raw, ":p")
  end

  local candidates = {}

  -- 1) git root of cwd (vim.fs.root exists on Neovim >= 0.10)
  if vim.fs and type(vim.fs.root) == "function" then
    local ok, root = pcall(vim.fs.root, fn.getcwd(), ".git")
    if ok and root and root ~= "" then
      candidates[#candidates + 1] = root .. "/" .. raw
    end
  end

  -- 2) plain cwd resolution
  candidates[#candidates + 1] = fn.fnamemodify(raw, ":p")

  for _, cand in ipairs(candidates) do
    if fn.filereadable(cand) == 1 then
      return cand
    end
  end

  return candidates[#candidates]
end
