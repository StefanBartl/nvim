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

require "system.env".compute_env()
require "options"
require("myoptions").setup { highlights = true, options = true }
require("lsp").setup { ensure_installing = false }
require "custom"
require "mynotes"
require "autocmds"
require "usrcmds"
require("sessions").enable { autocommands = true, usercmds = true, keymaps = true }
require("utils.help_sync").setup()
vim.schedule(function()
  require("mappings").setup()
end)
require("utils.column_align").setup()


-- ===================================================================================
-- Start a predictable RPC server at startup on Windows (named pipe).
-- This allows `nvr --server \\.\pipe\nvim-<USERNAME>` to always target this instance.
-- ===================================================================================

local uname = os.getenv("USERNAME") or "user"
local pipe  = ([[\\.\pipe\nvim-%s]]):format(uname)

-- If server is not already running, start it. Errors are ignored if the name is taken.
pcall(function()
  if vim.fn.exists("*serverstart") == 1 then
    -- serverstart returns 0 on error, or the address on success
    local ok = vim.fn.serverstart(pipe)
    if ok == 0 then
      -- fall back silently; nvr can still use $NVIM_LISTEN_ADDRESS if set externally
    end
  end
end)

-- Optionally export NVIM_LISTEN_ADDRESS for child processes
vim.env.NVIM_LISTEN_ADDRESS = pipe

