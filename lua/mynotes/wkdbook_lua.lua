---@module 'mynotes.wkdbook_lua'

local helpers = require("mynotes.helpers")

local tel_files = helpers.tel_files
local tel_grep  = helpers.tel_grep
local norm_dir  = helpers.norm_dir

local M = {}

local nvim_create_user_command = vim.api.nvim_create_user_command

local CFG = {
  title  = "WKD Book · Lua",
  dir    = vim.fn.expand(vim.env.REPOS_DIR .. "/WKDBooks/Development/wkdbook-Lua"),
  notify = true,
}

---@nodiscard
---@return string|nil cwd
local function cwd_or_nil()
  return norm_dir(CFG.dir)
end

pcall(nvim_create_user_command, "WkdLuaFiles", function()
  tel_files(cwd_or_nil, CFG.title)
end, { desc = "WKD Lua (Telescope): Find files" })

pcall(nvim_create_user_command, "WkdLuaGrep", function()
  tel_grep(cwd_or_nil, CFG.title)
end, { desc = "WKD Lua (Telescope): Live grep" })

return M
