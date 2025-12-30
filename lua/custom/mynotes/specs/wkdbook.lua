---@module 'mynotes.specs.wkdbook'

local register = require("custom.mynotes.register")

register.register(
  "WKDBook",
  {
    title = "WKDBook",
    dir = vim.env.REPOS_DIR .. "/WKDBooks",
  },
  {
    files = "WkdFiles",
    grep  = "WkdGrep",
  },
  {
    files = "<leader>wkf",
    grep  = "<leader>wkg",
  }
)
