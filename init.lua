vim.g.start_time = vim.uv.hrtime()

-- Enable vim.loader for faster module loading
local loader_ok = pcall(function()
  vim.loader.enable()
end)

if not loader_ok then
  vim.notify("Using standard Neovim loader (vim.loader failed)", vim.log.levels.INFO)
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
  -- { import = "nvchad.blink.lazyspec" },
  { import = "plugins" },
  { import = "plugins.colorscheme" },
}, lazy_config)

-- Load base46 cache
pcall(dofile, vim.g.base46_cache .. "syntax")
pcall(dofile, vim.g.base46_cache .. "defaults")
pcall(dofile, vim.g.base46_cache .. "statusline")

-- =============================================================================
-- PHASE 0: SOFORT (Kritisch für Basic-Funktionalität)
-- =============================================================================
require("system.env").compute_env()
require("options")
require("sessions").enable({ autocommands = true, usercmds = true, keymaps = true })

-- =============================================================================
-- PHASE 1: SEHR FRÜH (10ms) - Grundlegende Config
-- =============================================================================
vim.defer_fn(function()
  require("wkdoptions").setup({ highlights = true, options = true, italic_keywords = true })
  require("autocmds")
  require("custom")
end, 10)

-- =============================================================================
-- PHASE 2: FRÜH (50ms) - Keymaps & Sessions
-- =============================================================================
vim.defer_fn(function()
  require("usrcmds")
  require("mappings").setup()
end, 50)

-- =============================================================================
-- PHASE 3: LSP BufReadPost - wenn der erste Buffer geladen ist
-- =============================================================================
vim.env.LUA_LS_PROFILE = "normal" -- "minimal"|"normal"|"full"
-- vim.api.nvim_create_autocmd("BufReadPost", {
-- once = true,
-- callback = function()
-- vim.defer_fn(function()
-- require("lsp").setup({ ensure_installing = false })
-- end, 100)
-- end,
-- })

-- LSP Setup
require("lsp").setup({ ensure_installing = false })
-- LSP Setup direkt nach Keymaps
-- Capabilities müssen GLOBAL applied werden
local ok_caps, caps = pcall(require, "lsp.core.capabilities")
if ok_caps and type(caps.apply_globally) == "function" then
  caps.apply_globally()
end

-- =============================================================================
-- PHASE 4: DAP (Filetype Lazy-Load)
-- =============================================================================
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "lua", "go", "python", "javascript" },
  once = true,
  callback = function()
    require("wkddap").setup({
      languages = { "lua", "go", "python", "javascript" },
      ui = { enable = true },
      keymaps = { enable = false, prefix = "<leader>d" },
      auto_install = true,
    })
  end,
})

-- =============================================================================
-- PHASE 5: SEHR NIEDRIG (600ms) - RPC & Debugging
-- =============================================================================
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

  -- require("benchmarks").setup()
end, 600)

-- vim.defer_fn(function()
  -- local ok, astro = pcall(require, "astro_lsp_standalone")
  -- if ok then
    -- astro.setup()
  -- else
    -- print("[ERROR] Failed to load astro-lsp-standalone: " .. tostring(astro))
  -- end
-- end, 800)

-- Show startup time
vim.defer_fn(function()
  if vim.g.start_time then
    local load_time = (vim.uv.hrtime() - vim.g.start_time) / 1e6
    vim.notify(string.format("Config loaded in %.2f ms", load_time), vim.log.levels.INFO)
  end
end, 0)
