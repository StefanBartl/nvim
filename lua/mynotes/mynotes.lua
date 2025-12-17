---@module 'mynotes.mynotes'

-- Shared helpers -------------------------------------------------------------
local helpers = require("mynotes.helpers")

local tel_files = helpers.tel_files
local tel_grep  = helpers.tel_grep
local norm_dir  = helpers.norm_dir

local M = {}

local nvim_create_user_command = vim.api.nvim_create_user_command
local km_set = vim.keymap.set

-- Configuration --------------------------------------------------------------

local CFG = {
  title  = "MyNotes",
  dir    = vim.fn.expand(vim.env.REPOS_DIR .. "/Notes/MyNotes"),
  notify = true,
}

---@nodiscard
---@return string|nil cwd
local function cwd_or_nil()
  return norm_dir(CFG.dir)
end

-- User commands --------------------------------------------------------------

pcall(nvim_create_user_command, "MyNotesFiles", function()
  tel_files(cwd_or_nil, CFG.title)
end, { desc = "MyNotes (Telescope): Find files with preview in configured directory" })

pcall(nvim_create_user_command, "MyNotesGrep", function()
  tel_grep(cwd_or_nil, CFG.title)
end, { desc = "MyNotes (Telescope): Live grep with preview in configured directory" })

-- Keymaps --------------------------------------------------------------------

km_set("n", "<leader>mnf", function()
  tel_files(cwd_or_nil, CFG.title)
end, { desc = "MyNotes: telescope files" })

km_set("n", "<leader>mng", function()
  tel_grep(cwd_or_nil, CFG.title)
end, { desc = "MyNotes: telescope grep" })

return M
