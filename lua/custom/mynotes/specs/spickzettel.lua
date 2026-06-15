---@module 'mynotes.specs.wkdbook'

local register = require("custom.mynotes.register")

register.register(
  "Spickzettel",
  {
    title = "WKDBook",
    dir = vim.env.REPOS_DIR .. "/Notes/spickzettel",
  },
  {
    files = "SpickFiles",
    grep  = "SpickGrep",
  },
  {
    files = "<leader>spf",
    grep  = "<leader>spg",
  }
)
