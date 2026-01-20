---@module 'lib.terminals'
-- Terminal helper functions

local M = {}

-- Cross-platform path escaping for terminal commands
-- Escape spaces and special characters for shell
---@param path string
---@return string
function M.escape(path)
  return (path:gsub("([%s%$`\\])", "\\%1"))
end

---@param bufnr integer
---@return boolean|nil
function M.is_terminal_buf(bufnr)
  local buftype = vim.bo[bufnr].buftype
  if not buftype then
    return nil
  end

  if buftype == "terminal" then
    return true
  else
    return false
  end
end

---@param bufnr integer
---@return boolean|nil
function M.delete_terminal_buf(bufnr)
  if not bufnr or type(bufnr) ~= "number" then
    return nil
  end
  local ok, _ = pcall(function()
    vim.api.nvim_buf_delete(bufnr, { force = true })
  end)
  if ok then
    return true
  else
    return false
  end
end

return M
