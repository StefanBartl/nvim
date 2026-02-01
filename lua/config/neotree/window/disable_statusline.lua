---@module 'config.neotree.window.disable_statusline'
-- Disables the statusline for neo-tree windows only

local M = {}

---Disable statusline in the current window if it is a neo-tree window.
function M.disable_statusline()
  -- Ensure this only applies to neo-tree buffers
  if vim.bo.filetype ~= "neo-tree" then
    return
  end

  -- Window-local statusline override
  vim.wo.statusline = " "
end

return M

