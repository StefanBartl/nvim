---@module 'mynotes.neovim_ref_notes'

local helpers = require("mynotes.helpers")

local tel_files = helpers.tel_files
local tel_grep  = helpers.tel_grep
local norm_dir  = helpers.norm_dir

local M = {}

local nvim_create_user_command = vim.api.nvim_create_user_command

local CFG = {
  title  = "WKD Book · Neovim",
  dir    = vim.fn.expand(vim.env.REPOS_DIR .. "/Notes/MyNotes/NVIM_Ref_Notes"),
  notify = true,
}

---@nodiscard
---@return string|nil cwd
local function cwd_or_nil()
  return norm_dir(CFG.dir)
end

pcall(nvim_create_user_command, "NeovimReferenceFiles", function()
  tel_files(cwd_or_nil, CFG.title)
end, { desc = "Neovim Reference (Telescope): Find files" })

pcall(nvim_create_user_command, "NeovimReferenceGrep", function()
  tel_grep(cwd_or_nil, CFG.title)
end, { desc = "Neovim Reference (Telescope): Live grep" })

return M
