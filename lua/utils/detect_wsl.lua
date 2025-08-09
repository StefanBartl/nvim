---@module 'utils.detect_wsl'

local M = {}

---Return true if running in WSL
---@return boolean
M.is_wsl = function()
  local u = vim.loop.os_uname()
  if u and type(u.release) == "string" and u.release:match("Microsoft") then
    return true
  end
  if type(vim.env.WSL_DISTRO_NAME) == "string" and vim.env.WSL_DISTRO_NAME ~= "" then
    return true
  end
  return false
end

return M
