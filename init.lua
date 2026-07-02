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

-- Bootstrap lib.nvim
-- lib.nvim is a foundational dependency: plugin specs in lua/plugins/*.lua
-- require config modules that use lib.* already during the spec-import phase of
-- lazy.setup(). It must therefore be on the runtimepath BEFORE the specs are
-- imported, so we bootstrap it the same way as lazy.nvim itself. The lazy spec
-- in plugins/personal.lua keeps it updatable; this only guarantees early
-- availability.
local libpath = vim.fn.stdpath("data") .. "/lazy/lib.nvim"
if not vim.uv.fs_stat(libpath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/StefanBartl/lib.nvim.git",
    libpath,
  })
end
vim.opt.rtp:prepend(libpath)
-- lazy.nvim installs its own module loader that does not search runtimepath
-- entries we add here, so during the plugin spec-import phase `require("lib.*")`
-- would still fail. Register lib.nvim on package.path as well — the C require
-- searcher is the universal fallback that lazy does not replace.
package.path = table.concat({
  libpath .. "/lua/?.lua",
  libpath .. "/lua/?/init.lua",
  package.path,
}, ";")

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
  { import = "plugins.ai" },
}, lazy_config)

-- Load base46 cache
pcall(dofile, vim.g.base46_cache .. "syntax")
pcall(dofile, vim.g.base46_cache .. "defaults")
pcall(dofile, vim.g.base46_cache .. "statusline")

-- =============================================================================
-- PHASE 0: SOFORT (Kritisch für Basic-Funktionalität)
-- =============================================================================
-- Host environment snapshot (OS/shell/paths). Lives in lib.nvim now; the
-- `publish_globals` feature mirrors it to vim.g.is_windows/is_wsl/... for the
-- few consumers that read the globals (e.g. plugins/markdown.lua).
require("lib.nvim.system").setup({ publish_globals = true })
require("options")

-- =============================================================================
-- PHASE 1: SEHR FRÜH (10ms) - Grundlegende Config
-- =============================================================================
vim.defer_fn(function()
  require("wkdoptions").setup({ highlights = true, options = true, italic_keywords = true })
  require("autocmds")
end, 10)

-- =============================================================================
-- PHASE 2: FRÜH (50ms) - Keymaps & Sessions
-- =============================================================================
vim.defer_fn(function()
  require("bindings.usrcmds")
  require("bindings.mappings").setup()
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
-- vim.api.nvim_create_autocmd("FileType", {
  -- pattern = { "lua", "go", "python", "javascript" },
  -- once = true,
  -- callback = function()
 --   require("wkddap").setup({
 --     languages = {},
 --    ui = { enable = true },
 --     keymaps = { enable = true, prefix = "<leader>d" },
 --    auto_install = true,
 --   })
  -- end,
-- })

-- =============================================================================
-- PHASE 5: SEHR NIEDRIG (600ms) - RPC
-- =============================================================================

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

-- -- FIX: einstweiliger fix für: Error in event handler for event before_render[buffers.before_render
-- vim.defer_fn(function()
  -- require("neo-tree.command").execute({
    -- source = "tests",
    -- position = "left",
    -- toggle = true,
  -- })

  -- vim.defer_fn(function()
    -- require("neo-tree.command").execute({
      -- source = "tests",
      -- position = "left",
      -- toggle = true,
    -- })
  -- end, 400)
-- end, 10)

-- Für einen harten Kontrast: Weißer Hintergrund, schwarzer Text
vim.api.nvim_set_hl(0, "Visual", { bg = "#FFFFFF", fg = "#000000", bold = true })
