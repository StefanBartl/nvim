---@module 'config.copilot.cmp'
--- Hide Copilot suggestions while nvim-cmp menu is open; safe require and guard.

local M = {}

function M.setup()
  local ok, cmp = pcall(require, "cmp")
  if not ok or type(cmp) ~= "table" then
    -- English comment: cmp not available, nothing to do.
    return
  end

  -- hide Copilot suggestions while cmp menu is open.
  cmp.event:on("menu_opened", function()
    vim.b.copilot_suggestion_hidden = true
  end)

  cmp.event:on("menu_closed", function()
    vim.b.copilot_suggestion_hidden = false
  end)
end

return M
