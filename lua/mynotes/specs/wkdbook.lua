---@module 'mynotes.specs.wkdbook'

local register = require("mynotes.register")

register.register(
  "WKDBook",
  {
    title = "WKDBook",
    dir = vim.env.REPOS_DIR .. "/WKDBook",
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
