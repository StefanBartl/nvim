---@module 'custom.repo_pickers.config'
--- Defaults + merge/sanitize for repo_pickers.

local M = {}

---@type RepoPickersConfig
local DEFAULTS = {
  repos_dir = vim.env.REPOS_DIR or nil,
  only_git = true,
  selector = "auto",
  engine = "auto",
  show_relative = true,
  expose_engine_cmds = false, -- new: do not expose engine-specific commands by default
  usercmd_names = {
    find_files_telescope = "RepoFindFilesTelescope",
    grep_telescope = "RepoGrepTelescope",
    find_files_fzf = "RepoFindFilesFzf",
    grep_fzf = "RepoGrepFzf",
  },
  keymaps_lhs = {
    repo_files = nil,
    repo_grep = nil,
  },
}

--- Merge user config into defaults and sanitize values.
---@param user RepoPickersConfig|nil
---@return RepoPickersConfig
function M.merge(user)
  local u = type(user) == "table" and user or {}
  local out = vim.tbl_deep_extend("force", {}, DEFAULTS, u)

  local sel = out.selector
  if sel ~= "auto" and sel ~= "telescope" and sel ~= "fzf" and sel ~= "vim_select" then
    out.selector = "auto"
  end
  local eng = out.engine
  if eng ~= "auto" and eng ~= "telescope" and eng ~= "fzf" then
    out.engine = "auto"
  end
  if out.keymaps_lhs then
    local k = out.keymaps_lhs
    if k.repo_files ~= nil and type(k.repo_files) ~= "string" then
      k.repo_files = nil
    end
    if k.repo_grep ~= nil and type(k.repo_grep) ~= "string" then
      k.repo_grep = nil
    end
    if k.repo_files == "" then
      k.repo_files = nil
    end
    if k.repo_grep == "" then
      k.repo_grep = nil
    end
  end

  out.expose_engine_cmds = not not out.expose_engine_cmds
  return out
end

return M
