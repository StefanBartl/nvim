---@module 'utils.safe_call'
--- Robust wrappers around pcall/xpcall with structured return values.
--- No UI side-effects here; callers decide how to handle errors.

-- AUDIT: safe calls in config should use this module

local M = {}

---@param fn fun(...): any
---@param ... any
---@return boolean, any, string|nil
local function raw_safe(fn, ...)
  local ok, res = pcall(fn, ...)
  if ok then
    return true, res, nil
  end
  return false, nil, tostring(res)
end

---@param fn fun(...): any
---@param ... any
---@return SafeCallResult
function M.safe_call(fn, ...)
  local ok, res, err = raw_safe(fn, ...)
  return { ok = ok, result = res, err = err }
end

return M
