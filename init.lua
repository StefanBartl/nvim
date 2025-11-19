-- ===================================================================================
-- bootstrap lazy and all plugins
-- ===================================================================================
vim.g.base46_cache = vim.fn.stdpath "data" .. "/base46/"
vim.g.mapleader = " "
local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  local repo = "https://github.com/folke/lazy.nvim.git"
  vim.fn.system { "git", "clone", "--filter=blob:none", repo, "--branch=stable", lazypath }
end

vim.opt.rtp:prepend(lazypath)

local lazy_config = require "config.lazy"
require("lazy").setup({
  {
    "NvChad/NvChad",
    lazy = false,
    branch = "v2.5",
    import = "nvchad.plugins",
  },

  { import = "plugins" },
}, lazy_config)
pcall(dofile, vim.g.base46_cache .. "syntax")
pcall(dofile, vim.g.base46_cache .. "defaults")
pcall(dofile, vim.g.base46_cache .. "statusline")

-- ===================================================================================
-- Load modules
-- ===================================================================================
require("system.env").compute_env()
require("options")
require("myoptions").setup { highlights = true, options = true }
require("lsp").setup { ensure_installing = false }
require("autocmds")
require("custom")
require("debugging").setup()
require("mynotes")
require("usrcmds")
require("utils.column_align").setup()
require("sessions").enable({ autocommands = true, usercmds = true, keymaps = true })
require("utils.help_sync").setup()
vim.schedule(function()
  require("mappings").setup()
end)

-- ===================================================================================
-- Start a predictable RPC server at startup on Windows (named pipe).
-- This allows `nvr --server \\.\pipe\nvim-<USERNAME>` to always target this instance.
-- ===================================================================================
require("system.rpc_pipe").setup({ debug = false })

-- AUDIT:  ab hier:

require("lsp.tools.eslint_prettier").setup({
  -- optional: provide custom binaries if Mason is not in the default location
  -- binaries = {
  --   eslint = "C:\\Users\\me\\AppData\\Local\\nvim-data\\mason\\bin\\eslint_d.cmd",
  --   prettier = "C:\\Users\\me\\AppData\\Local\\nvim-data\\mason\\bin\\prettier.cmd"
  -- },
  filetypes = { "javascript", "typescript", "javascriptreact", "typescriptreact" },
  enable_on_setup = true, -- initial autorun state
})

-- require("lsp.tools.ts_type_lookup").setup()
require("lsp.tools.ts_type_lookup").setup()
