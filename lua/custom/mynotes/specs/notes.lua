---@module 'mynotes.specs.notes'

local register = require("custom.mynotes.register")

register.register(
  "Notes",
  {
    title = "Notes",
    dir = vim.env.REPOS_DIR .. "/Notes",
  },
  {
    files = "NotesFiles",
    grep  = "NotesGrep",
  },
  {
    files = "<leader>mnf",
    grep  = "<leader>mng",
  }
)
