---@module 'custom.repo_pickers.actions'
--- High-level actions: select repo using the configured selector-routing, then run fzf/Telescope.

local fs       = require("custom.repo_pickers.fs")
local dispatch = require("custom.repo_pickers.dispatch")

local M = {}

--- Ask for a repo and then open a file picker.
---@param cfg RepoPickersConfig
---@param selector fun(cfg:RepoPickersConfig, repos:RepoDir[], on_choice:fun(dir:RepoDir))
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
---@param cfg RepoPickersConfig
---@param selector fun(cfg:RepoPickersConfig, repos:RepoDir[], on_choice:fun(dir:RepoDir))
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

return M
