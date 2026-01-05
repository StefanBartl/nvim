-- ===================================================================================
-- bootstrap lazy and all plugins
-- ===================================================================================
vim.g.base46_cache = vim.fn.stdpath("data") .. "/base46/"
vim.g.mapleader = " "
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  local repo = "https://github.com/folke/lazy.nvim.git"
  vim.fn.system({ "git", "clone", "--filter=blob:none", repo, "--branch=stable", lazypath })
end

vim.opt.rtp:prepend(lazypath)

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
}, lazy_config)

pcall(dofile, vim.g.base46_cache .. "syntax")
pcall(dofile, vim.g.base46_cache .. "defaults")
pcall(dofile, vim.g.base46_cache .. "statusline")

-- ===================================================================================
-- Load modules
-- ===================================================================================
require("system.env").compute_env()
require("options")
require("myoptions").setup({ highlights = false, options = true })
require("lsp").setup({ ensure_installing = false })
require("autocmds")
require("custom")
require("custom.mynotes")
require("sessions").enable({ autocommands = true, usercmds = true, keymaps = true })
require("usrcmds")
vim.schedule(function()
  require("mappings").setup()
end)

-- ===================================================================================
-- Start a predictable RPC server at startup on Windows (named pipe).
-- This allows `nvr --server \\.\pipe\nvim-<USERNAME>` to always target this instance.
-- ===================================================================================
-- require("system.rpc_pipe").setup({ debug = false })

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

require("debugging").setup({
  all = false,        -- optional: aktiviert alle Module
  autocmds = nil,     -- Dbg.Autocmds.Modules|nil
  markdown = nil,     -- Dbg.Markdown.Modules|nil
  terminals = nil,    -- Dbg.Terminals.Modules|nil
  views = { all = true },        -- Dbg.Views.Setup|nil
  usercmds = false,    -- boolean|nil
  tools = nil,        -- Dbg.Tools.Modules|nil
  performance = true,
})
