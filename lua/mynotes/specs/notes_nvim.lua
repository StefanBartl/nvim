---@module 'mynotes.specs.notes_neovim'

local register = require("mynotes.register")

register.register(
  "Neovim Notes",
  {
    title = "Neovim Notes",
    dir = vim.env.REPOS_DIR .. "/Notes/MyNotes/Neovim",
  },
  {
    files = "NvimNotesFiles",
    grep  = "NvimNotesGrep",
  },
  {
    files = "<leader>mvf",
    grep  = "<leader>mvg",
  }
)
