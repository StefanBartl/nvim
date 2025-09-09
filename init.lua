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
require "ui.ibl_shim" -- fzf colorschenme picker depends on this to work correctly
require "ui.ibl"      -- fzf colorschenme picker depends on this to work correctly
require "system.env"
require "options"
require('myoptions').enable({ highlights = true, options = true })
-- require "hl_options"
require("utils.open_path").setup() -- 'autocmds.lua_require' depends on open_path functionality, load it before autocmds
require "custom.last_file.init"
require("custom.ctrl_cycle")
local require_dir = require "lib.require_dir"
require_dir "autocmds"
require_dir "usrcmds"
require_dir "lsp"
require_dir "utils"
require_dir "mynotes"
vim.schedule(function()
	require("mappings").setup()
end)
require("config.image_preview.pdf.buffer").setup({
  open_mode = "vsplit",
  focus = false,          -- keep focus in Neo-tree/editor
  density = 144,          -- 72..600
  notify = true,
  clear_on_leave = true,
  bg_hex = "#ffffff",
  cleanup_png = false,    -- set to true to delete PNG on close
})
require("custom.smart_edit").setup({ set_cr = true })
-- require("config.noice.signature_focus_guard").setup() -- WATCH: Noice pr

require("usrcmds.md_tablewrap").setup({
  inner_pad        = 1,
  outer_left       = 3,
  outer_right      = 3,
  auto_width       = true,
	width_mode    = "minflex",
  max_col_width    = nil,
  min_col_width    = 6,
  wrap_all_default = false,
  on_save_enabled  = false,
})
