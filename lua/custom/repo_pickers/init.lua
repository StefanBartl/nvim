---@module 'custom.repo_pickers'
--- Repository chooser + action launcher (files/grep) that delegates to existing usr_pickers commands.
--- Modules are split for single responsibility, safety and testability.

local cfgmod  = require("custom.repo_pickers.config")
local reg     = require("custom.repo_pickers.register")
local actions = require("custom.repo_pickers.actions")
local router  = require("custom.repo_pickers.select.router")
local dispatch= require("custom.repo_pickers.dispatch")

local M = {}

-- Keymap entry wrappers now pick the selector based on the resolved engine.
function M._entry_files()
  local C = M._active_cfg
  if not C then
    vim.notify("repo_pickers: not enabled yet", vim.log.levels.WARN)
    return
  end
  local eng = dispatch.resolve_engine_for_files(C)
  actions.repo_files(C, router.mk_selector(C, eng))
end

function M._entry_grep()
  local C = M._active_cfg
  if not C then
    vim.notify("repo_pickers: not enabled yet", vim.log.levels.WARN)
    return
  end
  local eng = dispatch.resolve_engine_for_grep(C)
  actions.repo_grep(C, router.mk_selector(C, eng))
end

function M.enable(user_cfg, enable_opts)
  local C = cfgmod.merge(user_cfg)
  if not (C.repos_dir or vim.env.REPOS_DIR) then
    vim.notify("repo_pickers: please set $REPOS_DIR or pass config.repos_dir", vim.log.levels.WARN)
  end
  M._active_cfg = C

  if enable_opts and enable_opts.usercmds then
    reg.usercmds(C)
  end
  if enable_opts and enable_opts.keymaps then
    reg.keymaps(C)
  end
end

return M
