---@module 'chadrc.lua'

local M = {}

local utl = require "ui.custom_stl_module" -- Helpers for statusline

M.ui = {
	statusline = {
		theme = "vscode_colored",

		order = { "mode", "git", "%=", "breadcrumbs", "%=", "diagnostics", "lsp", "cursor", "cwd" },
		modules = {
			breadcrumbs = function()
				local s = utl.stl_strip_hl(utl.render_breadcrumbs())
				s = (s:gsub("^%s*(.-)%s*$", "%1"))
				return utl.hl_open(utl.mode_band_group()) .. s
			end,

			diagnostics = function()
				local s = require("nvchad.stl.utils").diagnostics()
				return utl.hl_wrap(utl.mode_band_group(), utl.stl_strip_hl(s))
			end,

			lsp = function()
				local s = require("nvchad.stl.utils").lsp()
				return utl.hl_wrap(utl.mode_band_group(), utl.stl_strip_hl(s))
			end,

			cursor = function()
				return utl.hl_wrap(utl.mode_band_group(), " Ln %l, Col %v ")
			end,
		},
	},
}

M.base46 = {
	transparency = true,

 theme = "vim_default",
	-- theme = "github_dark",
	-- theme = "aylin",
	-- theme = "tokyonight",
	-- theme = "solarized_dark",
	-- theme = "scaryforest",
	-- theme = "starlight",
	-- theme = "vesper",
	-- theme = "eldritch",
	-- theme = "gruvchad",
	-- theme = "gruvbox",
	-- theme = "poimandres",
	-- theme = "radium",
	-- theme = "rosepine",
	-- theme = "flouromachine",
}

-- depends on /system/env.lua
if vim.g.is_windows and vim.g.is_pwsh then
	vim.opt.shell = "pwsh"
	vim.opt.shellcmdflag = "-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command"
	vim.opt.shellquote = ""
	vim.opt.shellxquote = ""
end

return M
