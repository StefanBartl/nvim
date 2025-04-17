local M = {}

M.find_keymap = function()
  vim.cmd("split | terminal ~/.config/nvim/lua/custom/scripts/find_keymaps.sh")
end

return M
