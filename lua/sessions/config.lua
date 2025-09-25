---@module 'sessions/config'
---@brief Configuration for portable sessions stored under stdpath('config')/sessions.
---@description
--- Provides a single source of truth for all options the session modules rely on:
--- - Storage directory under stdpath('config') (per user request)
--- - Safe and minimal :set sessionoptions to maximize portability
--- - Blacklists for buffers/filetypes/paths to avoid serializing ephemeral state
--- All values are intentionally explicit to reduce surprises across machines.

---@class SessionsConfigModule
local M = {}

local fn = vim.fn

---@type SessionsCfg
M.cfg = {
  -- Store sessions alongside the user's Neovim config (portable, user-requested).
  root = fn.stdpath("config") .. "/lua/sessions/storage",
  -- Default file name (without .vim) used for autosave/autoload.
  default_name = "last",
  -- Keep options minimal and deterministic; exclude volatile per-window "localoptions".
  -- See coding rules: explicitness, reproducibility across devices.
  -- buffers,curdir,tabpages,winsize,help,folds are a proven minimal baseline.
  sessionoptions = table.concat({
    "buffers",
    "curdir",
    "tabpages",
    "winsize",
    "help",
    "folds",
    -- Consider dropping "terminal" for heterogeneous shells across devices.
    -- "globals" and "localoptions" are intentionally omitted for portability.
  }, ","),

  blacklist = {
    buftypes = { "quickfix", "nofile", "prompt" },  -- ephemeral / UI noise
    filetypes = { "gitcommit", "gitrebase" },       -- volatile across hosts
    paths = { "/tmp/", "/private/tmp/" },           -- Linux/macOS temp
  },
}

return M
