---@module 'wkdoptions.hl_config.features.terminal_palette'
--- Terminal window harmonization: applies TermNormal/TermCursorLine via winhighlight.
--- Ensures consistent theme integration for :terminal buffers.

local lazy = require("lib.lazy")
local State = lazy.reequire("wkdoptions.hl_config.core.state")
local Winhl = lazy.require("wkdoptions.hl_config.utils.winhighlight")

local M = {}

--- Apply terminal-specific palette to current window
---@return nil
function M.apply()
  local win = vim.api.nvim_get_current_win()
  if not vim.api.nvim_win_is_valid(win) then
    return
  end

  local bufnr = vim.api.nvim_win_get_buf(win)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  -- Check if terminal buffer
  local ok, bt = pcall(vim.api.nvim_get_option_value, "buftype", { buf = bufnr })
  if not ok or bt ~= "terminal" then
    return
  end

  -- Build terminal-specific winhighlight
  local pairs = {
    Normal = "TermNormal",
    CursorLine = "TermCursorLine",
    CursorLineNr = "CursorLineNr",
    LineNr = "LineNr",
  }

  local wh = Winhl.merge(nil, pairs)
  Winhl.apply_to_window(win, wh)

  -- Enable cursorline for terminal (helps with prompt visibility)
  vim.wo[win].cursorline = true
  vim.wo[win].cursorlineopt = "line"
end

--- Install autocmds
---@param _cfg WKDOptions.HL_CFG
---@return nil
function M.enable(_cfg)
  local aug = State.get_augroup("TermPalette", true)

  if not State.is_enabled("terminal_palette") then
    return
  end

  vim.api.nvim_create_autocmd("TermOpen", {
    group = aug,
    callback = M.apply,
    desc = "Apply terminal-specific palette",
  })
end

return M
