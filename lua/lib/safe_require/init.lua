---@module 'lua.lib.safe_require'
--- Small safe require helper used by config modules.
--- Returns (ok, module_or_err). Avoids noisy stack traces during startup.

local M = {}

--- Safely require a module and return (ok, module_or_error)
--- @param name string
--- @return boolean, any
function M.safe_require(name)
  if type(name) ~= "string" then
    return false, "invalid module name"
  end
  local ok, mod = pcall(require, name)
  if not ok then
    return false, mod
  end
  return true, mod
end

return {
  safe_require = M.safe_require,
}
