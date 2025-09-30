---@module 'custom.repo_pickers.config'
--- Default options, validation and merge utilities for repo_pickers.

local M = {}

--- Internal hard defaults; userland may override via enable(cfg, ...)
---@type RepoPickersConfig
local DEFAULTS = {
  repos_dir = vim.env.REPOS_DIR or nil,
  only_git = true,
  selector = "auto",
  engine = "auto",
  show_relative = true,
  usercmd_names = {
    find_files_telescope = "RepoFilesTelescope",
    grep_telescope       = "RepoGrepTelescope",
    find_files_fzf       = "RepoFilesFzf",
    grep_fzf             = "RepoGrepFzf",
  },
  keymaps_lhs = {
    repo_files = nil,
    repo_grep  = nil,
  },
}

--- Return a deep-copied config with defaults applied and sanitized.
--- This function never throws; invalid fields are ignored conservatively.
--- @param user RepoPickersConfig|nil
--- @return RepoPickersConfig
function M.merge(user)
  local u = type(user) == "table" and user or {}
  local out = vim.tbl_deep_extend("force", {}, DEFAULTS, u)

  -- Sanitize selector
  local sel = out.selector
  if sel ~= "auto" and sel ~= "telescope" and sel ~= "fzf" and sel ~= "vim_select" then
    out.selector = "auto"
  end

  -- Sanitize engine
  local eng = out.engine
  if eng ~= "auto" and eng ~= "telescope" and eng ~= "fzf" then
    out.engine = "auto"
  end

  -- Sanitize keymaps: keep nil or non-empty strings
  if out.keymaps_lhs then
    local k = out.keymaps_lhs
    if k.repo_files ~= nil and type(k.repo_files) ~= "string" then k.repo_files = nil end
    if k.repo_grep  ~= nil and type(k.repo_grep)  ~= "string" then k.repo_grep  = nil end
    if k.repo_files == "" then k.repo_files = nil end
    if k.repo_grep  == "" then k.repo_grep  = nil end
  end

  return out
end

return M

