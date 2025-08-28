vim.g.base46_cache = vim.fn.stdpath "data" .. "/base46/"
vim.g.mapleader = " "

-- bootstrap lazy and all plugins
local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"

if not vim.uv.fs_stat(lazypath) then
	local repo = "https://github.com/folke/lazy.nvim.git"
	vim.fn.system { "git", "clone", "--filter=blob:none", repo, "--branch=stable", lazypath }
end

vim.opt.rtp:prepend(lazypath)

local lazy_config = require "config.lazy"

-- load plugins
require("lazy").setup({
	{
		"NvChad/NvChad",
		lazy = false,
		branch = "v2.5",
		import = "nvchad.plugins",
	},

	{ import = "plugins" },
}, lazy_config)

-- Apply NvChad Base46 theme caches immediately at startup.
-- This ensures the colorscheme & statusline palette is active from the first frame.
pcall(dofile, vim.g.base46_cache .. "syntax")
pcall(dofile, vim.g.base46_cache .. "defaults")
pcall(dofile, vim.g.base46_cache .. "statusline")
require "ui.ibl_shim"
require "ui.ibl"
require "system.env"
require "options"
require "custom.last_file.init"

local require_dir = require "lib.require_dir"
require_dir "autocmds"
require_dir "usrcmds"
require_dir "lsp"
require_dir "utils"
require_dir "mynotes"
vim.schedule(function()
	require("mappings").setup()
end)

-- Vim like theme
-- require "ui.tty_look"
-- require "ui.vim_default_like"
-- vim.api.nvim_create_autocmd("User", {
--   pattern = "VeryLazy",
--   once = true,
--   callback = function()
--     vim.opt.termguicolors = false
--     pcall(vim.cmd.colorscheme, "vim_default_like")
--   end,
-- })

-- if exist, apply persistent theme selecion
-- require("custom.themes_picker").apply_persisted()
-- vim.api.nvim_create_user_command("ThemePicker", function()
--   require("custom.themes_picker").pick()
-- end, {})
-- vim.keymap.set("n", "<leader>tp", function()
--   require("csutom.themes_picker").pick()
-- end, { desc = "Unified theme picker (fzf-lua)" })
--
-- -- optional tuning
-- require("custom.themes_picker").setup({
--   disable_base46_when_colorscheme = true,  -- recommended for mixed operation
--   prompt = "Themes❯ ",
--   height = 0.55,
--   width  = 0.32,
--   preview_window = "nohidden:right:0",
--   -- persist_dir = vim.fn.stdpath("data") .. "/my_theme_prefs",
-- })
