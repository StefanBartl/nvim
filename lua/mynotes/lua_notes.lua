---@module 'mynotes.notes'

-- local fzf_files = require("mynotes.helpers").fzf_files
-- local fzf_grep = require("mynotes.helpers").fzf_grep
local tel_files = require("mynotes.helpers").tel_files
local tel_grep = require("mynotes.helpers").tel_grep
local norm_dir = require("mynotes.helpers").norm_dir

local M = {}

local nvim_create_user_command = vim.api.nvim_create_user_command
local km_set = vim.keymap.set

local CFG = {
  title = "LuaNotes",
  dir = vim.fn.expand(vim.env.REPOS_DIR .. "/WKDBooks/Development/wkdbook-Lua"),
  notify = true,
}

---@nodiscard
---@return string|nil cwd
local function cwd_or_nil()
  return norm_dir(CFG.dir)
end

-- User commands --------------------------------------------------------------

-- pcall(nvim_create_user_command, "LuaNotesFiles", function()
--   fzf_files(cwd_or_nil, CFG.title)
-- end, { desc = "LuaNotes (fzf-lua): Find files with preview in configured directory" })
--
-- pcall(nvim_create_user_command, "LuaNotesGrep", function()
--   fzf_grep(cwd_or_nil, CFG.title)
-- end, { desc = "LuaNotes (fzf-lua): Live grep with preview in configured directory" })

pcall(nvim_create_user_command, "LuaNotesFiles", function()
  tel_files(cwd_or_nil, CFG.title)
end, { desc = "WKD Lua (Telescope): Find files with preview in configured directory" })

pcall(nvim_create_user_command, "LuaNotesGrep", function()
  tel_grep(cwd_or_nil, CFG.title)
end, { desc = "WKD Lua (Telescope): Live grep with preview in configured directory" })

-- Keymaps (normal mode) ------------------------------------------------------

-- km_set("n", "<leader>lnf", function() fzf_files(cwd_or_nil, CFG.title) end, { desc = "WKD Neovim: fzf files" })
-- km_set("n", "<leader>lng",  function() fzf_grep(cwd_or_nil, CFG.title) end, { desc = "WKD Neovim: fzf grep" })

km_set("n", "<leader>lnf", function()
  tel_files(cwd_or_nil, CFG.title)
end, {
  desc = "LuaNotes: telescope files",
})

km_set("n", "<leader>lng", function()
  tel_grep(cwd_or_nil, CFG.title)
end, {
  desc = "LuaNotes: telescope grep",
})

return M
