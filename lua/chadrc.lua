---@module 'chadrc.lua'

local M = {}
local utl = require "ui.custom_stl_module"
local ctx = require("myoptions.Highlight_Cfg.breadcrumbs.ctx")

M.ui = {
	statusline = {
		theme = "vscode_colored",
		order = { "mode", "git", "%=", "breadcrumbs", "%=", "diagnostics", "lsp", "cursor", "cwd" },
		modules = {
			breadcrumbs = function()
				local C = require("myoptions.config")
				C.cfg.highlight.breadcrumbs_ctx.lua_table_root = { enable = true, mode = "only" }
				local s = ctx.statusline_module({
					include_path = true,
					sep = " ⟶ ",
					path_resolver = require("ui.custom_stl_module").repo_relative,
				})
				local function to_str(x) return (type(x) == "function") and x() or x end  -- AUDIT:
				s = to_str(s)
				if s == "" then return "" end

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
	transparency = false,
	theme_toggle = { "tokyonight", "onedark" },

	-- theme = "vim_default",
	-- theme = "github_dark",
	-- theme = "aylin",
	theme = "onedark",
	--theme = "onedark",
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
