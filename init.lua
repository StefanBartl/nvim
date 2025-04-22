vim.g.base46_cache = vim.fn.stdpath "data" .. "/base46/"
vim.g.mapleader = " "

-- bootstrap lazy and all plugins
local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"

if not vim.uv.fs_stat(lazypath) then
  local repo = "https://github.com/folke/lazy.nvim.git"
  vim.fn.system { "git", "clone", "--filter=blob:none", repo, "--branch=stable", lazypath }
end

vim.opt.rtp:prepend(lazypath)

local lazy_config = require "configs.lazy"

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
dofile(vim.g.base46_cache .. "defaults")
dofile(vim.g.base46_cache .. "statusline")

require "options"
require "autocmds.text"
require "autocmds.terminals"
require "autocmds.workspace"

--require "configs.nvimtree"

vim.schedule(function()
  require "mappings"
end)

vim.api.nvim_create_user_command("LspDoctor", function()
  require("custom.lspdoctor").check()
end, {})

vim.api.nvim_create_user_command("FindKeymap", function()
  require("custom.run_mappings").find_keymap()
end, {})

vim.api.nvim_create_user_command("MDUnfatHeadings", function()
  vim.cmd([[%s/\*\*\([^*]\{-}\)\*\*/\1/g]])
end, {})
