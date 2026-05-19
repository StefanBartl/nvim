---@module 'custom.picker_fd_depth.core'
---@brief Core logic for flexible multi-engine file searching with dynamic depth calculation.

local notify = require("lib.notify").create("[picker_fd_depth.core]")

local M = {}

--- Resolves the absolute target path based on the given depth above current CWD.
---@param depth integer The number of directory levels to go upwards.
---@return string The normalized, absolute path string.
local function resolve_path_with_depth(depth)
  local cwd = vim.uv.cwd() or vim.fn.getcwd()
  if depth <= 0 then
    return vim.fs.normalize(cwd)
  end

  -- Highly performant string replication avoiding costly OS-specific shell spawning
  local up_modifiers = string.rep("/..", depth)
  return vim.fs.normalize(cwd .. up_modifiers)
end

--- Launches fzf-lua within the specified path.
---@param search_path string
local function launch_fzf(search_path)
  local ok, fzf = pcall(require, "fzf-lua")
  if not ok then
    notify.error("fzf-lua is not installed or could not be loaded.")
    return
  end
  fzf.files({ cwd = search_path })
end

--- Launches telescope built-in find_files within the specified path.
---@param search_path string
local function launch_telescope(search_path)
  local ok, builtin = pcall(require, "telescope.builtin")
  if not ok then
    notify.error("telescope.builtin could not be loaded.")
    return
  end
  builtin.find_files({ cwd = search_path })
end

--- Validates arguments and dispatches the search to the requested picker engine.
---@param depth_arg any The desired directory depth levels upwards (number or string).
---@param engine_arg string|nil The picker engine to use ("telescope" or "fzf").
---@return nil
function M.find_files(depth_arg, engine_arg)
  -- Guard and normalize input arguments
  local depth = tonumber(depth_arg) or 0
  local engine = tostring(engine_arg or "telescope"):lower()

  if depth < 0 then
    notify.warn("Invalid depth specified. Falling back to current directory (0).")
    depth = 0
  end

  -- Safe, cross-platform path resolution
  local target_path = resolve_path_with_depth(depth)

  if vim.fn.isdirectory(target_path) == 0 then
    notify.error("Resolved path does not exist: " .. target_path)
    return
  end

  -- Route to appropriate picker engine
  if engine == "telescope" then
    launch_telescope(target_path)
  elseif engine == "fzf" or engine == "fzf-lua" or engine == "fzf_lua" then
    launch_fzf(target_path)
  else
    notify.warn("Unknown engine '" .. engine_arg .. "'. Defaulting to Telescope.")
    launch_telescope(target_path)
  end
end

return M
