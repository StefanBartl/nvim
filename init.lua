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

require "autocmds"
require "custom"
require("lsp").setup()
require "mynotes"
require "options"
require("myoptions").setup { highlights = true, options = false }
require "system.env"
require "usrcmds"
require "sessions"

vim.schedule(function()
  require("mappings").setup()
end)

pcall(function()
  require("pathprobe").setup_keymaps()
end)
