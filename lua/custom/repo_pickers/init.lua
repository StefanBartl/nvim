---@module 'custom.repo_pickers'
--- Repository chooser + action launcher (files/grep) that delegates to existing usr_pickers commands.
--- Modules are split for single responsibility, safety and testability.

local cfgmod = require("custom.repo_pickers.config")
local reg     = require("custom.repo_pickers.register")
local sel_vim = require("custom.repo_pickers.select.vim_select")
local sel_tel = require("custom.repo_pickers.select.telescope")
local sel_fzf = require("custom.repo_pickers.select.fzf")
local actions = require("custom.repo_pickers.actions")

local M = {}

-- Selector dispatcher kept small and side-effect free.
-- It chooses a concrete selection adapter based on cfg.selector with graceful fallbacks.
--- @param cfg RepoPickersConfig
--- @return fun(cfg:RepoPickersConfig, repos:RepoDir[], on_choice:fun(dir:RepoDir))
local function resolve_selector(cfg)
  local sel = cfg.selector or "auto"
  if sel == "telescope" then
    return function(c, r, cb)
      if not sel_tel.select(c, r, cb) then sel_vim.select(c, r, cb) end
    end
  elseif sel == "fzf" then
    return function(c, r, cb)
      if not sel_fzf.select(c, r, cb) then sel_vim.select(c, r, cb) end
    end
  elseif sel == "vim_select" then
    return function(c, r, cb) sel_vim.select(c, r, cb) end
  else
    -- auto: prefer Telescope, then fzf, else vim.ui.select
    return function(c, r, cb)
      if sel_tel.select(c, r, cb) then return end
      if sel_fzf.select(c, r, cb) then return end
      sel_vim.select(c, r, cb)
    end
  end
end

-- Public tiny entry wrappers used by keymaps to avoid capturing cfg in closures.
function M._entry_files()
  local C = M._active_cfg
  if not C then
    vim.notify("repo_pickers: not enabled yet", vim.log.levels.WARN)
    return
  end
  actions.repo_files(C, resolve_selector(C))
end

function M._entry_grep()
  local C = M._active_cfg
  if not C then
    vim.notify("repo_pickers: not enabled yet", vim.log.levels.WARN)
    return
  end
  actions.repo_grep(C, resolve_selector(C))
end

--- Enable repo pickers; registers user-commands and keymaps based on enable flags.
--- Example:
---   require("custom.repo_pickers").enable({}, { usercmds = true, keymaps = true })
--- @param user_cfg? RepoPickersConfig
--- @param enable_opts? RepoPickersEnable
--- @return nil
function M.enable(user_cfg, enable_opts)
  local C = cfgmod.merge(user_cfg)

  -- Early guard per guidelines: inform user if base dir is missing; do not abort.
  if not (C.repos_dir or vim.env.REPOS_DIR) then
    vim.notify("repo_pickers: please set $REPOS_DIR or pass config.repos_dir", vim.log.levels.WARN)
  end

  M._active_cfg = C

  local selector = resolve_selector(C)

  if enable_opts and enable_opts.usercmds then
    reg.usercmds(C, selector)
  end
  if enable_opts and enable_opts.keymaps then
    reg.keymaps(C)
  end
end

return M
