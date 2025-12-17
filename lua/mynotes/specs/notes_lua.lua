---@module 'mynotes.specs.notes_lua'

local register = require("mynotes.register")

register.register(
  "Lua Notes",
  {
    title = "Lua Notes",
    dir = vim.env.REPOS_DIR .. "/Notes/MyNotes/Lua",
  },
  {
    files = "LuaNotesFiles",
    grep  = "LuaNotesGrep",
  },
  {
    files = "<leader>nlf",
    grep  = "<leader>nlg",
  }
)
