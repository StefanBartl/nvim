---@module 'custom.repo_pickers.actions'
--- High-level actions: ask for repo, then open files or grep via configured engine.

local fs = require("custom.repo_pickers.fs")
local dispatch = require("custom.repo_pickers.dispatch")

local M = {}

--- Ask for a repository and then open a file picker (files).
--- @param cfg RepoPickersConfig
--- @param selector fun(cfg:RepoPickersConfig, repos:RepoDir[], on_choice:fun(dir:RepoDir))  -- injected selector
--- @return nil
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

  selector(cfg, repos, function(dir)
    dispatch.run_usr_picker(dispatch.resolve_cmd_files(cfg), dir)
  end)
end

--- Ask for a repository and then open a live_grep picker.
--- @param cfg RepoPickersConfig
--- @param selector fun(cfg:RepoPickersConfig, repos:RepoDir[], on_choice:fun(dir:RepoDir))  -- injected selector
--- @return nil
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

  selector(cfg, repos, function(dir)
    dispatch.run_usr_picker(dispatch.resolve_cmd_grep(cfg), dir)
  end)
end

return M
