---@module 'mynotes.specs.checklists'

local register = require("custom.mynotes.register")

register.register(
  "Checklists",
  {
    title = "Checklists",
    dir = vim.env.REPOS_DIR .. "/Notes/MyNotes/Checklists",
    notify = true,
  },
  {
    files = "ChecklistsFiles",
    grep  = "ChecklistsGrep",
  },
  {
    files = "<leader>chf",
    grep  = "<leader>chg",
  }
)
