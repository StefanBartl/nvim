---@module 'utils.open_path.targets.tab'
--- Open under cursor in a new tab.

---@class TargetTab
local T = {}

local H = require("utils.open_path.helpers")

---@param require_existing boolean
---@param notify boolean
---@return boolean
function T.open(require_existing, notify)
  local raw, line, col = H.token_under_cursor()
  if not raw then return false end
  local info = H.normalize_and_probe(raw)
  if require_existing and not info then
    return false
  end
  if not info then
    if notify then vim.notify("open_path: path does not exist", vim.log.levels.WARN) end
    return false
  end
  vim.api.nvim_cmd({ cmd = "tabedit", args = { info.abs } }, {})
  H.jump_if_needed(line, col)
  return true
end

return T
