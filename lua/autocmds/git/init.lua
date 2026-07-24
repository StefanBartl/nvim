---@module 'autocmds.git'
--- Orchestrates all Git-related autocommands by delegating to submodules.
--- Public entrypoint: require('autocmds.git').enable(cfg)
--- Each submodule implements exactly one feature and exposes `enable(cfg)`.

local M = {}

--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

local lazy = require("lib.lua.lazy")
local augroup_lib = lazy.require("lib.nvim.autocmd.augroup")
local augroup = augroup_lib.create.clear
local autocmd_lib = lazy.require("lib.nvim.autocmd")
local norm_events = autocmd_lib.norm_events
local in_git_repo = lazy.require("lib.nvim.git").in_git_repo

--------------------------------------------------------------------------------
-- Defaults
--------------------------------------------------------------------------------

---@type AutoCmds.Git.Cfg
local Defaults = require("autocmds.git.defaults").get_defaults()

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------

---Enable git-related autocommands per feature.
---@param cfg AutoCmds.Git.Cfg|boolean|nil
---@return nil
function M.enable(cfg)
  if not cfg or cfg == false then
    return
  end
  if cfg == true then
    cfg = {} -- FIX: 'Missing required field' der submodule, eventuell hier besser struktuireren, damit diese branches so nicht notwednig sind
  end
  ---@type AutoCmds.Git.Cfg
  cfg = vim.tbl_deep_extend("force", vim.deepcopy(Defaults), cfg or {})

  -- Shared context passed to submodules (no globals)
  local shared = {
    augroup = augroup,
    norm_events = norm_events,
    in_git_repo = in_git_repo,
  }

  -- Delegate to submodules (each may register its own autocmds)
  -- Unresolved-conflict quickfix population lives in insights.nvim now
  -- (`conflicts` — :Insights conflicts, VimEnter autocmd).
  require("autocmds.git.commit_ft").enable(cfg.commit_ft, shared)
  require("autocmds.git.gitsigns_refresh").enable(cfg.gitsigns_refresh, shared)
  require("autocmds.git.blame_on_hold").enable(cfg.blame_on_hold, shared)
end

---@type AutoCmds.Git
return M
