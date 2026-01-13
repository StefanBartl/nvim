---@module 'wkddap.utils.paths'

local M = {}

--- Normalize path separators
---@param path string Input path
---@return string normalized_path
function M.normalize(path)
  return vim.fs.normalize(path)
end

--- Join path segments
---@param ... string Path segments
---@return string joined_path
function M.join(...)
  local parts = { ... }
  local sep = package.config:sub(1, 1)
  return table.concat(parts, sep)
end

--- Get workspace root
---@return string|nil root
function M.workspace_root()
  return vim.fn.getcwd()
end

return M
