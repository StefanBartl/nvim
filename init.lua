vim.g.base46_cache = vim.fn.stdpath "data" .. "/base46/"
vim.g.mapleader = " "

-- bootstrap lazy and all plugins
local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"

if not vim.uv.fs_stat(lazypath) then
  local repo = "https://github.com/folke/lazy.nvim.git"
  vim.fn.system { "git", "clone", "--filter=blob:none", repo, "--branch=stable", lazypath }
end

vim.opt.rtp:prepend(lazypath)

local lazy_config = require "configs.lazy_config"

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
local require_dir = require("custom.require_dir")
require_dir("autocmd")
require_dir("custom")

vim.schedule(function()
  require "mappings"
end)

vim.api.nvim_create_user_command("MDUnfatHeadings", function()
  vim.cmd([[%s/\*\*\([^*]\{-}\)\*\*/\1/g]])
end, {})

vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    local clients = vim.lsp.get_clients({ name = "lua_ls" })
    if #clients > 0 then return end

    local lua_files = vim.fn.globpath(vim.fn.getcwd(), "**/*.lua", true, true)
    local first_file = lua_files[1]
    if not first_file then return end

    local buf = vim.fn.bufadd(first_file)
    vim.fn.bufload(buf)
    vim.api.nvim_buf_set_option(buf, "filetype", "lua")

    vim.lsp.start(require("configs.lua_ls_config"))
  end,
})
