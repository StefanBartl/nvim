---@module 'custom.find_config.engines.telescope'
---@description Telescope engine implementation for find_config

local notify = require("lib.nvim.notify").create("[find_config:telescope]")
local core = require("custom.find_config.core")

local M = {}

--- Open Telescope file picker rooted at config directory.
--- Uses find_files with case-insensitive matching.
---@param opts table|nil Extra options passed to telescope.builtin.find_files
---@return nil
function M.find_in_config(opts)
  local ok, builtin = pcall(require, "telescope.builtin")
  if not ok or not builtin or type(builtin.find_files) ~= "function" then
    notify.error("Telescope not found or missing 'find_files' function")
    return
  end

  local cwd = core.get_nvim_config_dir()

  -- Default Telescope options
  local merged = vim.tbl_extend("force", {
    cwd = cwd,
    prompt_title = "Config Files",
    -- Telescope uses case-insensitive search by default in find_files
    -- Additional ripgrep args can be added via find_command if needed
  }, opts or {})

  -- Execute telescope.builtin.find_files with defensive error handling
  local ok_call, err = pcall(function()
    builtin.find_files(merged)
  end)
  if not ok_call then
    notify.error("telescope.builtin.find_files failed: " .. tostring(err))
  end
end

--- Run live grep rooted at config directory.
--- Uses Telescope's live_grep for interactive search.
---@param opts table|nil Extra options passed to telescope.builtin.live_grep
---@return nil
function M.grep_in_config(opts)
  local ok, builtin = pcall(require, "telescope.builtin")
  if not ok or not builtin or type(builtin.live_grep) ~= "function" then
    notify.error("Telescope not found or missing 'live_grep' function")
    return
  end

  local cwd = core.get_nvim_config_dir()

  -- Default Telescope options
  local merged = vim.tbl_extend("force", {
    cwd = cwd,
    prompt_title = "Grep Config",
    -- Telescope uses ripgrep by default which is case-insensitive
    -- Can be customized via additional_args = { "--case-sensitive" } if needed
  }, opts or {})

  -- Execute telescope.builtin.live_grep with defensive error handling
  local ok_call, err = pcall(function()
    builtin.live_grep(merged)
  end)
  if not ok_call then
    notify.error("telescope.builtin.live_grep failed: " .. tostring(err))
  end
end

return M
