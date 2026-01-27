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

local function time_module(name, fn)
  local start = vim.uv.hrtime()
  fn()
  local elapsed = (vim.uv.hrtime() - start) / 1e6
  print(string.format("%s: %.2fms", name, elapsed))
end

-- Setup lazy.nvim with plugins
time_module("Setup lazy.nvim with plugins", function()
local lazy_config = require("config.lazy")
require("lazy").setup({
  {
    "NvChad/NvChad",
    lazy = false,
    branch = "v2.5",
  },
  { import = "nvchad.plugins" },
  { import = "plugins" },
  -- { import = "nvchad.blink.lazyspec" },
}, lazy_config)
end)

-- Load base46
time_module("load base46 cache", function()
pcall(dofile, vim.g.base46_cache .. "syntax")
pcall(dofile, vim.g.base46_cache .. "defaults")
pcall(dofile, vim.g.base46_cache .. "statusline")
end)

-- Load core modules
time_module("system.env", function()
  require("system.env").compute_env()
end)
time_module("options", function()
  require("options")
end)
time_module("wkdoptions", function()
  require("wkdoptions").setup({ highlights = false, options = true })
end)
time_module("lsp", function()
  require("lsp").setup({ ensure_installing = false })
end)
time_module("autocmds", function()
  require("autocmds")
end)
time_module("custom", function()
  require("custom")
end)
time_module("sessions", function()
  require("sessions").enable({ autocommands = true, usercmds = true, keymaps = true })
end)
time_module("usercmds", function()
  require("usrcmds")
end)

time_module("mappings", function()
  require("mappings").setup()
end)

time_module("wkddap", function()
  require("wkddap").setup({
    languages = { "lua", "go", "python", "javascript" },
    ui = { enable = true },
    keymaps = { enable = false, prefix = "<leader>d" },
    auto_install = true, -- Mason auto-install
  })
end)

-- ===================================================================================
-- Start a predictable RPC server at startup on Windows (named pipe).
-- This allows `nvr --server \\.\pipe\nvim-<USERNAME>` to always target this instance.
-- ===================================================================================
time_module("system.rcp_pipe", function()
  require("system.rpc_pipe").setup({ debug = false })
end)

-- ===================================================================================
--                              Debugging Modul
-- ===================================================================================
--[[                             Kurzübersicht
Setup:
require("debugging").setup({
all = false,        -- aktiviert alle Module
autocmds = nil,     -- Dbg.Autocmds.Modules|nil
markdown = nil,     -- Dbg.Markdown.Modules|nil
terminals = nil,    -- Dbg.Terminals.Modules|nil
views = nil,        -- Dbg.Views.Setup|nil
tools = nil,        -- Dbg.Tools.Modules|nil
usercmds = true,    -- :BufReport/:TabReport/:WinReport
})

Module & Optionen:
1. Autocmds:
all? boolean, list_autocmds? boolean
2. Markdown:
all? boolean, inline_debug_fixed? boolean
3. Terminals:
all? boolean, keylogger? boolean
4. Views:
keymaps: enable?, map?, prefix? ("<lt>" default)
    autocmds: enable?, group_name?, auto_refresh?
    timings: delay_messages_ms?, delay_noice_ms?, retry_delay_ms?, attempts?
    capture: debug?, clipboard?, save_file?, output_dir?
5. Tools:
    all?, buffer_inspector?, cursor_state?, vardump?
6. Nvim Options:
    all?, indent_helpers?
7. User Commands:
    usercmds? boolean

Beispiele:
-- Alle Views + Vardump aktivieren
require("debugging").setup({
    views = { all = true },
    tools = { vardump = true },
})
-- Nur Tools aktivieren
require("debugging").setup({
    tools = { cursor_state = true, vardump = true }
})
-- Alles aktivieren
require("debugging").setup({ all = true })

]]

time_module("debugging", function()
  require("debugging").setup({
    views = { all = true }, -- Dbg.Views.Setup|nil
    all = false, -- optional: aktiviert alle Module
    autocmds = nil, -- Dbg.Autocmds.Modules|nil
    markdown = nil, -- Dbg.Markdown.Modules|nil
    terminals = nil, -- Dbg.Terminals.Modules|nil
    usercmds = false, -- boolean|nil
    tools = nil, -- Dbg.Tools.Modules|nil
  })
end)

-- Show startup time (optional)
vim.defer_fn(function()
  if vim.g.start_time then
    local load_time = (vim.uv.hrtime() - vim.g.start_time) / 1e6
    vim.notify(string.format("Config loaded in %.2f ms", load_time), vim.log.levels.INFO)
  end
end, 0)

