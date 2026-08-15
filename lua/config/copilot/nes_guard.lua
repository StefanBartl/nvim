---@module 'config.copilot.nes_guard'
--- Small helpers to guard calls into copilot-lsp.nes safely.

local M = {}

-- English comments: safely require the nes module if available.
-- Returns module or nil and a boolean indicating success.
function M.safe_require_nes()
  local ok, mod = pcall(require, "copilot-lsp.nes")
  if ok and type(mod) == "table" then
    return mod, true
  end
  return nil, false
end

return M
