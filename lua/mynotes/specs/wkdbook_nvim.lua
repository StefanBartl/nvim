---@module 'mynotes.specs.wkdbook_nvim'

local register = require("mynotes.register")

register.register(
  "WKDBook Neovim",
  {
    title = "WKDBook Neovim",
    dir = vim.env.REPOS_DIR .. "/WKDBook/Development/wkdbook-Neovim",
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
