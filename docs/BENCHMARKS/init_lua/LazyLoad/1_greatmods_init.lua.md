-- Lazy-Loading für große Module
vim.g.start_time = vim.uv.hrtime()

-- Enable vim.loader for faster module loading
local loader_ok = pcall(function()
    vim.loader.enable()
end)

if not loader_ok then
    vim.notify('Using standard Neovim loader (vim.loader failed)', vim.log.levels.INFO)
end

-- Bootstrap lazy.nvim
vim.g.base46_cache = vim.fn.stdpath("data") .. "/base46/"
vim.g.mapleader = " "

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  local repo = "https://github.com/folke/lazy.nvim.git"
  vim.fn.system({ "git", "clone", "--filter=blob:none", repo, "--branch=stable", lazypath })
end
vim.opt.rtp:prepend(lazypath)

-- Setup lazy.nvim with plugins
local lazy_config = require("config.lazy")
require("lazy").setup({
  {
    "NvChad/NvChad",
    lazy = false,
    branch = "v2.5",
  },
  { import = "nvchad.plugins" },
  { import = "plugins" },
}, lazy_config)

-- Load base46 cache
pcall(dofile, vim.g.base46_cache .. "syntax")
pcall(dofile, vim.g.base46_cache .. "defaults")
pcall(dofile, vim.g.base46_cache .. "statusline")

-- KRITISCH: Sofort laden (notwendig für Basic-Funktionalität)
require("system.env").compute_env()
require("options")

-- PHASE 1: Sehr früh, aber async (10ms delay)
vim.defer_fn(function()
  require("wkdoptions").setup({ highlights = false, options = true })
  require("autocmds")
end, 10)

-- PHASE 2: Früh laden (50ms delay)
vim.defer_fn(function()
  require("lsp").setup({ ensure_installing = false })
  require("custom")
end, 50)

-- PHASE 3: Mittel-priorität (100ms delay)
vim.defer_fn(function()
  require("sessions").enable({ autocommands = true, usercmds = true, keymaps = true })
  require("usrcmds")
  require("mappings").setup()
end, 100)

-- PHASE 4: Niedrige Priorität (200ms delay)
vim.defer_fn(function()
  require('wkddap').setup({
    languages = { 'lua', 'go', 'python', 'javascript' },
    ui = { enable = true, },
    keymaps = { enable = false, prefix = '<leader>d' },
    auto_install = true,
  })
end, 200)

-- PHASE 5: Sehr niedrige Priorität (500ms delay)
vim.defer_fn(function()
  require("system.rpc_pipe").setup({ debug = false })

  require("debugging").setup({
    views = { all = true },
    all = false,
    autocmds = nil,
    markdown = nil,
    terminals = nil,
    usercmds = false,
    tools = nil,
  })
end, 500)

-- Show startup time
vim.defer_fn(function()
    if vim.g.start_time then
        local load_time = (vim.uv.hrtime() - vim.g.start_time) / 1e6
        vim.notify(string.format('Config loaded in %.2f ms', load_time), vim.log.levels.INFO)
    end
end, 0)
