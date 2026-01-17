---@module 'config.neotree.actions.grep_picker'
---@brief Unified grep picker interface for Neo-tree (supports telescope and fzf-lua)
---@description
--- Provides a picker-agnostic interface for live grep functionality in Neo-tree.
--- Automatically detects available pickers and falls back gracefully.
---
--- Supported Pickers:
---   - telescope.nvim (default)
---   - fzf-lua (fallback)
---
--- Features:
---   - Automatic picker detection
---   - Graceful fallback chain
---   - Cross-platform path handling (Windows/WSL/macOS/Linux)
---   - Directory-based grep from Neo-tree nodes

local M = {}

local notify = require("lib.notify").create("[neotree.grep_picker]")
local node_utils = require("config.neotree.utils.node")
local fn = vim.fn

---Check if a picker is available
---@param picker_name string Module name to check
---@return boolean available
local function is_picker_available(picker_name)
  local ok = pcall(require, picker_name)
  return ok
end

---Detect available pickers in priority order
---@return Cfg.NeoTree.Actions.PickerType|nil picker, string|nil reason
local function detect_available_picker()
  -- Priority 1: Telescope (default)
  if is_picker_available("telescope.builtin") then
    return "telescope", nil
  end

  -- Priority 2: fzf-lua (fallback)
  if is_picker_available("fzf-lua") then
    return "fzf", nil
  end

  return nil, "No picker available (install telescope.nvim or fzf-lua)"
end

---Get directory from Neo-tree node
---@param state Cfg.NeoTree.State
---@return string|nil dir, string|nil error_msg
local function get_node_directory(state)
  local node = node_utils.get_current(state)
  if not node then
    return nil, "No node under cursor"
  end

  local path, is_dir = node_utils.get_path(node)
  if path == "" then
    return nil, "No path under cursor"
  end

  -- If it's a file, use parent directory
  local dir = is_dir and path or fn.fnamemodify(path, ":h")

  -- Validate directory exists
  if fn.isdirectory(dir) == 0 then
    return nil, "Directory does not exist: " .. dir
  end

  return dir, nil
end

---Live grep using Telescope
---@param dir string Directory to search in
---@return boolean success
local function grep_with_telescope(dir)
  local ok, builtin = pcall(require, "telescope.builtin")
  if not ok then
    return false
  end

  builtin.live_grep({
    cwd = dir,
    prompt_title = "Live Grep: " .. fn.fnamemodify(dir, ":t"),
  })

  return true
end

---Live grep using fzf-lua
---@param dir string Directory to search in
---@return boolean success
local function grep_with_fzf(dir)
  local ok, fzf = pcall(require, "fzf-lua")
  if not ok then
    return false
  end

  fzf.live_grep({
    cwd = dir,
    prompt = "Live Grep: " .. fn.fnamemodify(dir, ":t") .. "> ",
    rg_opts = "--hidden --glob !.git",
  })

  return true
end

---Execute live grep with specified picker
---@param dir string Directory to search in
---@param picker Cfg.NeoTree.Actions.PickerType Picker to use
---@return boolean success
local function execute_grep(dir, picker)
  if picker == "telescope" then
    return grep_with_telescope(dir)
  elseif picker == "fzf" then
    return grep_with_fzf(dir)
  end

  return false
end

---Main function: Live grep in node directory
---@param state Cfg.NeoTree.State Neo-tree state
---@param picker? Cfg.NeoTree.Actions.PickerType Picker to use ("telescope"|"fzf"|"auto"), default: "auto"
---@return boolean success
function M.live_grep(state, picker)
  picker = picker or "auto"

  -- Get directory from node
  local dir, err = get_node_directory(state)
  if not dir then
    notify.warn(err or "Failed to get directory")
    return false
  end

  -- Determine which picker to use
  local selected_picker = picker

  if picker == "auto" then
    local detected, reason = detect_available_picker()
    if not detected then
      notify.error(reason or "No picker available")
      return false
    end
    selected_picker = detected
  end

  -- Validate picker is available
  if selected_picker == "telescope" and not is_picker_available("telescope.builtin") then
    notify.warn("Telescope not available, trying fzf-lua...")
    selected_picker = "fzf"
  end

  if selected_picker == "fzf" and not is_picker_available("fzf-lua") then
    notify.warn("fzf-lua not available, trying Telescope...")
    selected_picker = "telescope"
  end

  -- Final validation
  local module_name = selected_picker == "telescope" and "telescope.builtin" or "fzf-lua"
  if not is_picker_available(module_name) then
    notify.error("Selected picker not available: " .. selected_picker)
    return false
  end

  -- Execute grep
  local success = execute_grep(dir, selected_picker)

  if not success then
    notify.error("Failed to execute grep with: " .. selected_picker)
    return false
  end

  return true
end

---Get current picker status
---@return table status {telescope: boolean, fzf: boolean, default: Cfg.NeoTree.Actions.PickerType|nil}
function M.get_picker_status()
  return {
    telescope = is_picker_available("telescope.builtin"),
    fzf = is_picker_available("fzf-lua"),
    default = detect_available_picker(),
  }
end

---Health check for pickers
---@return boolean healthy, string|nil message
function M.health_check()
  local telescope_ok = is_picker_available("telescope.builtin")
  local fzf_ok = is_picker_available("fzf-lua")

  if telescope_ok or fzf_ok then
    local available = {}
    if telescope_ok then table.insert(available, "telescope") end
    if fzf_ok then table.insert(available, "fzf-lua") end

    return true, "Available pickers: " .. table.concat(available, ", ")
  end

  return false, "No pickers available (install telescope.nvim or fzf-lua)"
end

return M
