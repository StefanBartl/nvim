---@module 'custom.repo_pickers'
--- Tiny facade: keeps active config, resolves selectors, exposes _entry_*.

local notify = require("lib.nvim.notify").create("[custom.repo_pickers]")

local cfgmod = require("custom.repo_pickers.config")
local reg = require("custom.repo_pickers.register")
local actions = require("custom.repo_pickers.actions")
local router = require("custom.repo_pickers.select.router")
local dispatch = require("custom.repo_pickers.dispatch")

local M = {}

--- Internal: build a selector that matches the effective engine unless "vim_select" is forced.
---@param cfg RepoPickers.Config
---@param kind "files"|"grep"
---@return fun(cfg:RepoPickers.Config, repos:RepoPickers.RepoDir[], on_choice:fun(dir:RepoPickers.RepoDir))
local function selector_for(cfg, kind)
  if cfg.selector == "vim_select" then
    return router.mk_selector(cfg, nil) -- always vim_select
  end
  local eng = (kind == "files") and dispatch.resolve_engine_for_files(cfg) or dispatch.resolve_engine_for_grep(cfg)
  return router.mk_selector(cfg, eng)
end

--- Internal: build a wkdbook selector that matches the effective engine unless "vim_select" is forced.
---@param cfg RepoPickers.Config
---@param kind "files"|"grep"
---@return fun(cfg:RepoPickers.Config, wkdbooks:RepoPickers.RepoDir[], on_choice:fun(dir:RepoPickers.RepoDir))
local function wkdbook_selector_for(cfg, kind)
  if cfg.selector == "vim_select" then
    return router.mk_wkdbook_selector(cfg, nil)
  end
  local eng = (kind == "files") and dispatch.resolve_engine_for_files(cfg) or dispatch.resolve_engine_for_grep(cfg)
  return router.mk_wkdbook_selector(cfg, eng)
end

function M._entry_files()
  local C = M._active_cfg
  if not C then
    notify.warn("repo_pickers: not enabled yet")
    return
  end
  actions.repo_files(C, selector_for(C, "files"))
end

function M._entry_grep()
  local C = M._active_cfg
  if not C then
    notify.warn("repo_pickers: not enabled yet")
    return
  end
  actions.repo_grep(C, selector_for(C, "grep"))
end

function M._entry_wkdbook_find()
  local C = M._active_cfg
  if not C then
    notify.warn("repo_pickers: not enabled yet")
    return
  end
  actions.wkdbook_find(C, wkdbook_selector_for(C, "files"))
end

function M._entry_wkdbook_grep()
  local C = M._active_cfg
  if not C then
    notify.warn("repo_pickers: not enabled yet")
    return
  end
  actions.wkdbook_grep(C, wkdbook_selector_for(C, "grep"))
end

--- Public enable: registers only RepoFiles/RepoGrep by default.
---@param user_cfg? RepoPickers.Config
---@param enable_opts? RepoPickers.Enable
---@return nil
function M.enable(user_cfg, enable_opts)
  local C = cfgmod.merge(user_cfg)
  if not (C.repos_dir or vim.env.REPOS_DIR) then
    notify.warn("repo_pickers: please set $REPOS_DIR or pass config.repos_dir")
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
