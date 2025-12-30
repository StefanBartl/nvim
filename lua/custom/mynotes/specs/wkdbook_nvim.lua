---@module 'mynotes.specs.wkdbook_nvim'

local register = require("custom.mynotes.register")

register.register(
  "WKDBook Neovim",
  {
    title = "WKDBook Neovim",
    dir = vim.env.REPOS_DIR .. "/WKDBooks/Development/wkdbook-Neovim",
  },
  {
    files = "WkdNeovimFiles",
    grep  = "WkdNeovimGrep",
  },
  {
    files = "<leader>wvf",
    grep  = "<leader>wvg",
  }
)
