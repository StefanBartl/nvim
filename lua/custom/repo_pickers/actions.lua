---@module 'custom.repo_pickers.actions'
--- High-level actions: select repo using the configured selector-routing, then run fzf/Telescope.
require("custom.repo_pickers.@types.types")

local fs = require("custom.repo_pickers.fs")
local dispatch = require("custom.repo_pickers.dispatch")

local M = {}

--- Ask for a repo and then open a file picker.
---@param cfg RepoPickers.Config
---@param selector fun(cfg:RepoPickers.Config, repos:RepoPickers.RepoDir[], on_choice:fun(dir:RepoPickers.RepoDir))
---@return nil
function M.repo_files(cfg, selector)
  local base = (cfg.repos_dir or vim.env.REPOS_DIR or "")
  local repos, err = fs.scan_repos(base, cfg.only_git ~= false)
  if not repos then
    vim.notify(err or "repo_pickers: failed to list repositories", vim.log.levels.WARN)
    return
  end
  if #repos == 0 then
    vim.notify("repo_pickers: no repositories found in repos_dir", vim.log.levels.INFO)
    return
  end

  local engine = dispatch.resolve_engine_for_files(cfg)
  selector(cfg, repos, function(dir)
    dispatch.run_files_by_engine(engine, dir)
  end)
end

--- Ask for a repo and then open a live_grep picker.
---@param cfg RepoPickers.Config
---@param selector fun(cfg:RepoPickers.Config, repos:RepoPickers.RepoDir[], on_choice:fun(dir:RepoPickers.RepoDir))
---@return nil
function M.repo_grep(cfg, selector)
  local base = (cfg.repos_dir or vim.env.REPOS_DIR or "")
  local repos, err = fs.scan_repos(base, cfg.only_git ~= false)
  if not repos then
    vim.notify(err or "repo_pickers: failed to list repositories", vim.log.levels.WARN)
    return
  end
  if #repos == 0 then
    vim.notify("repo_pickers: no repositories found in repos_dir", vim.log.levels.INFO)
    return
  end

  local engine = dispatch.resolve_engine_for_grep(cfg)
  selector(cfg, repos, function(dir)
    dispatch.run_grep_by_engine(engine, dir)
  end)
end

--- Ask for a wkdbook and then open a file picker.
---@param cfg RepoPickers.Config
---@param selector fun(cfg:RepoPickers.Config, repos:RepoPickers.RepoDir[], on_choice:fun(dir:RepoPickers.RepoDir))
---@return nil
function M.wkdbook_find(cfg, selector)
  local base = cfg.wkdbooks_dir or ""
  local prefix = cfg.wkdbook_prefix or "wkdbook-"

  local wkdbooks, err = fs.scan_wkdbooks(base, prefix)
  if not wkdbooks then
    vim.notify(err or "repo_pickers: failed to list wkdbooks", vim.log.levels.WARN)
    return
  end
  if #wkdbooks == 0 then
    vim.notify(
      ("repo_pickers: no directories with prefix '%s' found in %s"):format(prefix, base),
      vim.log.levels.INFO
    )
    return
  end

  local engine = dispatch.resolve_engine_for_files(cfg)
  selector(cfg, wkdbooks, function(dir)
    dispatch.run_files_by_engine(engine, dir)
  end)
end

--- Ask for a wkdbook and then open a live_grep picker.
---@param cfg RepoPickers.Config
---@param selector fun(cfg:RepoPickers.Config, repos:RepoPickers.RepoDir[], on_choice:fun(dir:RepoPickers.RepoDir))
---@return nil
function M.wkdbook_grep(cfg, selector)
  local base = cfg.wkdbooks_dir or ""
  local prefix = cfg.wkdbook_prefix or "wkdbook-"

  local wkdbooks, err = fs.scan_wkdbooks(base, prefix)
  if not wkdbooks then
    vim.notify(err or "repo_pickers: failed to list wkdbooks", vim.log.levels.WARN)
    return
  end
  if #wkdbooks == 0 then
    vim.notify(
      ("repo_pickers: no directories with prefix '%s' found in %s"):format(prefix, base),
      vim.log.levels.INFO
    )
    return
  end

  local engine = dispatch.resolve_engine_for_grep(cfg)
  selector(cfg, wkdbooks, function(dir)
    dispatch.run_grep_by_engine(engine, dir)
  end)
end
return M
