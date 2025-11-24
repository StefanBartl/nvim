---@module 'custom.lsp_signature.utils.helper'

local M = {}

-- Convert numeric hex (0xRRGGBB) to hex string "#rrggbb"
---@param n integer
---@return string
function M.hexnum_to_hexstr(n)
  -- clamp and format to 6 hex digits
  n = math.max(0, math.floor(n))
  local s = string.format("#%06x", n)
  return s
end

return M
