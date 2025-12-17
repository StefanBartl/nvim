---@module 'mynotes.specs.wkdbook_lua'

local register = require("mynotes.register")

register.register(
  "WKDBook Lua",
  {
    title = "WKDBook Lua",
    dir = vim.env.REPOS_DIR .. "/WKDBook/Development/wkdbook-Lua",
  },
  {
    files = "WkdLuaFiles",
    grep  = "WkdLuaGrep",
  },
  {
    files = "<leader>wlf",
    grep  = "<leader>wlg",
  }
)
