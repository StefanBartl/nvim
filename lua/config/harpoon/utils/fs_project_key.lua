---@module 'config.harpoon.utils.fs_project_key'
--- Compute a stable project key for Harpoon.
--- Prefers Git root; falls back to current working directory.
--- Always returns an absolute, normalized path.

---@type table
local M = {}

local uv = vim.uv or vim.loop

---@return string
local function cwd_abs()
  return uv.cwd() or vim.loop.cwd() or vim.fn.getcwd()
end

---@param path string
---@return string
local function normalize_abs(path)
  -- Normalize to absolute, POSIX-like separators for cross-platform stability.
  local p = path
  if p:match("^%a:[/\\]") then
    -- Windows drive: uppercase drive letter for stable key
    p = p:gsub("\\", "/")
    p = (p:sub(1,1):upper() .. p:sub(2))
  else
    p = p:gsub("\\", "/")
  end
  return p
end

---@return string
function M.project_key()
  local cwd = cwd_abs()
  local search_start = cwd
  local found = vim.fs.find(".git", { upward = true, type = "directory", path = search_start })[1]
  if found then
    local root = vim.fs.dirname(found)
    return normalize_abs(root)
  end
  return normalize_abs(cwd)
end

return M

