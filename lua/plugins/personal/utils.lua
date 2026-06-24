---@module 'plugins.personal.utils'

local PERSONAL_UTILS = {}

local local_repos_path = nil
local using_remote_fallback = false

-- Perform the investigation once on the first request
if vim.env.REPOS_DIR and vim.fn.isdirectory(vim.env.REPOS_DIR) == 1 then
  local_repos_path = vim.env.REPOS_DIR
else
  local candidate_roots = { "/repos", "C:/repos", "D:/repos", "E:/repos" }
  for _, path in ipairs(candidate_roots) do
    if vim.fn.isdirectory(path) == 1 then
      local_repos_path = path
      break
    end
  end

  if local_repos_path then
    vim.notify(
      string.format(("[PLUGINS PERSONAL] 'REPOS_DIR' is missing. Local fallback: '%s'"):format(), local_repos_path),
      vim.log.levels.WARN
    )
  else
    using_remote_fallback = true
    vim.notify(
      "[PLUGINS PERSONAL] No local repository folder found. Switching to remote repositories.",
      vim.log.levels.INFO
    )
  end
end

-- Export the path (important for pickers.nvim)
PERSONAL_UTILS.repos_path = local_repos_path or ""

--- Helper function for determining the local development path
---@param plugin_name string Der Name des Ordners im Repos-Verzeichnis
---@return string|nil
function PERSONAL_UTILS.local_dev(plugin_name)
  if using_remote_fallback or not local_repos_path then
    return nil
  end
  return vim.fs.joinpath(local_repos_path, plugin_name)
end

return PERSONAL_UTILS

