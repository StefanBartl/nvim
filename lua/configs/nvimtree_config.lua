---@module 'configs.nvimtree_config'
---@brief on_attach function for nvim-tree with default mappings and custom file opener

local on_attach = require("configs.nvimtree.on_attach")

require("nvim-tree").setup({
  on_attach = on_attach,
  view = {
    width = 30,
    side = "left",
    relativenumber = false,
  },
  renderer = {
    highlight_git = true,
    icons = {
      show = {
        file = true,
        folder = true,
        folder_arrow = true,
        git = true,
      },
    },
  },
  filters = {
    dotfiles = false,
  },
  trash = {
    cmd = "trash",
    require_confirm = true,
  },
})
