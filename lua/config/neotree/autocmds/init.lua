---@module 'config.neotree.autocmds'

local neotree_statusline = require("config.neotree.window.disable_statusline")

local M = {}

function M.attach()
  -- disable statusline in neotree windows
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "neo-tree",
    callback = function()
      neotree_statusline.disable_statusline()
    end,
  })
end

return M
