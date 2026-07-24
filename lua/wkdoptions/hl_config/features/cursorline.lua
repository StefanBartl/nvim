---@module 'wkdoptions.hl_config.features.cursorline'
--- CursorLine and CursorColumn activation with safe guards and config checks.

local lazy = require("lib.lua.lazy")
local State = lazy.require("wkdoptions.hl_config.core.state")
local Winhl = lazy.require("wkdoptions.hl_config.utils.winhighlight")
local LargeFile = lazy.require("wkdoptions.hl_config.utils.large_file")
local is_ui = lazy.require("wkdoptions.hl_config.utils.skip").std_skip

local M = {}

--- Check if cursorcolumn should be enabled for current buffer
---@nodiscard
---@param cfg WKDOptions.HL_CFG
---@return boolean
local function should_enable_column(cfg)
  if not State.is_enabled("column") then
    return false
  end

  if is_ui(0) then
    return false
  end

  if LargeFile.exceeds(0, cfg.min_colored_file_kb or 4096) then
    return false
  end

  return true
end

--- Activate CursorLine and optionally CursorColumn for active window
---@param cfg WKDOptions.HL_CFG
---@param mode string|nil -- current mode for tinting (optional)
---@return nil
function M.activate(cfg, mode)
  local win = vim.api.nvim_get_current_win()

  if not vim.api.nvim_win_is_valid(win) then
    return
  end

  if is_ui(0) then
    M.deactivate()
    return
  end

  -- Set cursorline/column options
  local enable_col = should_enable_column(cfg)
  vim.wo[win].cursorline = State.is_enabled("line")
  vim.wo[win].cursorlineopt = "both"
  vim.wo[win].cursorcolumn = enable_col

  -- Build winhighlight mapping
  local hl_line = mode and M.resolve_line_hl(mode, cfg) or "CursorLine"
  local pairs = {
    CursorLine = hl_line,
    CursorLineNr = "CursorLineNr",
  }

  if enable_col then
    pairs.CursorColumn = "CursorColumn"
  else
    pairs.CursorColumn = "Normal" -- neutralize
  end

  local wh = Winhl.merge(vim.wo[win].winhighlight, pairs)
  Winhl.apply_to_window(win, wh)
end

--- Deactivate for inactive windows
---@return nil
function M.deactivate()
  local win = vim.api.nvim_get_current_win()

  if not vim.api.nvim_win_is_valid(win) then
    return
  end

  vim.wo[win].cursorline = false
  vim.wo[win].cursorcolumn = false

  local pairs = {
    CursorLine = "Normal",
    CursorLineNr = "LineNr",
    CursorColumn = "Normal",
  }

  local wh = Winhl.merge(vim.wo[win].winhighlight, pairs)
  Winhl.apply_to_window(win, wh)
end

--- Resolve which CursorLine HL group to use based on mode
---@nodiscard
---@param mode string -- normalized mode char
---@param cfg WKDOptions.HL_CFG
---@return string
---@diagnostic disable-next-line: unused-local
function M.resolve_line_hl(mode, cfg)
  if not State.is_enabled("mode_colors") then
    return "CursorLine"
  end

  local map = {
    n = "CursorLineN",
    v = "CursorLineV",
    V = "CursorLineV",
    ["\22"] = "CursorLineV", -- CTRL-V
    i = "CursorLineI",
    R = "CursorLineR",
    r = "CursorLineR",
    c = "CursorLineN",
  }

  return map[mode] or "CursorLineN"
end

return M
