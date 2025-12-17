---@module 'mynotes.neovim_notes'

local helpers = require("mynotes.helpers")

local tel_files = helpers.tel_files
local tel_grep  = helpers.tel_grep
local norm_dir  = helpers.norm_dir

local M = {}

local nvim_create_user_command = vim.api.nvim_create_user_command
local km_set = vim.keymap.set

local CFG = {
  title  = "Neovim Notes",
  dir    = vim.fn.expand(vim.env.REPOS_DIR .. "/Notes/Neovim"),
  notify = true,
}

---@nodiscard
---@return string|nil cwd
local function cwd_or_nil()
  return norm_dir(CFG.dir)
end

pcall(nvim_create_user_command, "NeovimNotesFiles", function()
  tel_files(cwd_or_nil, CFG.title)
end, { desc = "Neovim Notes (Telescope): Find files" })

pcall(nvim_create_user_command, "NeovimNotesGrep", function()
  tel_grep(cwd_or_nil, CFG.title)
end, { desc = "Neovim Notes (Telescope): Live grep" })

km_set("n", "<leader>nvf", function()
  tel_files(cwd_or_nil, CFG.title)
end, { desc = "Neovim Notes: telescope files" })

km_set("n", "<leader>nvg", function()
  tel_grep(cwd_or_nil, CFG.title)
end, { desc = "Neovim Notes: telescope grep" })

return M
