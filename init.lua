vim.g.base46_cache = vim.fn.stdpath "data" .. "/base46/"
vim.g.mapleader = " "

-- bootstrap lazy and all plugins
local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"

if not vim.uv.fs_stat(lazypath) then
  local repo = "https://github.com/folke/lazy.nvim.git"
  vim.fn.system { "git", "clone", "--filter=blob:none", repo, "--branch=stable", lazypath }
end

vim.opt.rtp:prepend(lazypath)

local lazy_config = require "config.lazy_config"

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

-- load theme
--dofile(vim.g.base46_cache .. "default")
--dofile(vim.g.base46_cache .. "statusline")


require "system.env"
require "options"
require "custom.last_file.init"

local require_dir = require("lib.require_dir")
require_dir("autocmds")
require_dir("usrcmds")
require_dir("lsp")
require_dir("utils")
vim.schedule(function()
  require "mappings".setup()
end)
require_dir("config")
