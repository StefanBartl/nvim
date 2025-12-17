---@module 'mynotes.notes'

local helpers = require("mynotes.helpers")

local tel_files = helpers.tel_files
local tel_grep  = helpers.tel_grep
local norm_dir  = helpers.norm_dir

local M = {}

local nvim_create_user_command = vim.api.nvim_create_user_command
local km_set = vim.keymap.set

local CFG = {
  title  = "Notes",
  dir    = vim.fn.expand(vim.env.REPOS_DIR .. "/Notes"),
  notify = true,
}

---@nodiscard
---@return string|nil cwd
local function cwd_or_nil()
  return norm_dir(CFG.dir)
end

pcall(nvim_create_user_command, "NotesFiles", function()
  tel_files(cwd_or_nil, CFG.title)
end, { desc = "Notes (Telescope): Find files" })

pcall(nvim_create_user_command, "NotesGrep", function()
  tel_grep(cwd_or_nil, CFG.title)
end, { desc = "Notes (Telescope): Live grep" })

km_set("n", "<leader>mnf", function()
  tel_files(cwd_or_nil, CFG.title)
end, { desc = "Notes: telescope files" })

km_set("n", "<leader>mng", function()
  tel_grep(cwd_or_nil, CFG.title)
end, { desc = "Notes: telescope grep" })

return M
