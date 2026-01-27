---@module 'autocmds.git'
--- Orchestrates all Git-related autocommands by delegating to submodules.
--- Public entrypoint: require('autocmds.git').enable(cfg)
--- Each submodule implements exactly one feature and exposes `enable(cfg)`.

local M = {}

local api = vim.api

--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

local lazy = require("lib.lazy")
local augroup_lib = lazy.require("lib.autocmd.augroup")
local augroup = augroup_lib.create.clear
local autocmd_lib = lazy.require("lib.autocmd")
local norm_events = autocmd_lib.norm_events
local in_git_repo = lazy.require("lib.git").in_git_repo
local NS_LINE_DIFF = api.nvim_create_namespace("git_line_diff_preview") -- Namespace for inline virtual text previews (line_diff_on_hold).
local clear_line_diff = require("lib.git").clear_line_diff(NS_LINE_DIFF)

---Return true if the current buffer is a "normal" file buffer (not special/ignored).
---@param ignore_buftypes string[]|nil
---@return boolean
local function normal_buf_allowed(ignore_buftypes) -- CHECK: Wird dies irgendwo verwendet außer das es im shared buffer eingebaut wird?
  local bt = vim.bo.buftype or ""
  if ignore_buftypes and vim.tbl_contains(ignore_buftypes, bt) then
    return false
  end
  return bt == "" or bt == "acwrite"
end

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
    augroup = augroup,  -- CHECK: Wird dies irgendwo verwendet ?
    norm_events = norm_events,  -- CHECK: Wird dies irgendwo verwendet ?
    in_git_repo = in_git_repo,  -- CHECK: Wird dies irgendwo verwendet ?
    normal_buf_allowed = normal_buf_allowed, -- CHECK: Wird dies irgendwo verwendet ?
    NS_LINE_DIFF = NS_LINE_DIFF,  -- CHECK: Wird dies irgendwo verwendet ?
    clear_line_diff = clear_line_diff,  -- CHECK: Wird dies irgendwo verwendet ?
  }

  -- Delegate to submodules (each may register its own autocmds)
  require("autocmds.git.conflicts_qf").enable(cfg.conflicts_qf, shared)
  require("autocmds.git.commit_ft").enable(cfg.commit_ft, shared)
  require("autocmds.git.conflict_marks").enable(cfg.conflict_marks, shared)
  require("autocmds.git.gitsigns_refresh").enable(cfg.gitsigns_refresh, shared)
  require("autocmds.git.blame_on_hold").enable(cfg.blame_on_hold, shared)
  if cfg.line_diff_on_hold ~= false then
    require("autocmds.git.line_diff_on_hold").enable(cfg.line_diff_on_hold, shared)
    vim.o.updatetime = 100
  end
end

---@type AutoCmds.Git
return M
