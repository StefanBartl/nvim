---@module 'lib.terminals'
-- Terminal helper functions

local M = {}

---@return boolean|nil
function M.is_terminal_buf(buf)
  local buftype = vim.bo[buf].buftype
  if not buftype then
    return nil
  end

  if buftype == "terminal" then
    return true
  else
    return false
  end
end

---@return boolean|nil
function M.delete_terminal_buf(buf)
  if not buf or type(buf) ~= "number" then
    return nil
  end
  local ok, _ = pcall(function()
    vim.api.nvim_buf_delete(buf, { force = true })
  end)
  if ok then
    return true
  else
    return false
  end
end

return M
