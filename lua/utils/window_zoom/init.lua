---@module 'utils.window_zoom'
-- Toggle maximize current window and restore previous layout sizes.
-- Uses Vim's winrestcmd() to capture/restore the full layout.
-- Stores per tabpage to avoid cross-tab interference.

local M = {}

---@return string # Returns a string of Ex-commands that can restore window sizes
local function capture_layout()
  return vim.fn.winrestcmd()
end

---@param cmd string
local function restore_layout(cmd)
  if cmd and #cmd > 0 then
    vim.cmd(cmd) -- re-apply saved sizes/positions
  end
end

---@return boolean
function M.is_zoomed()
  -- Heuristic: if current window already full width and height compared to screen, consider it "zoomed".
  return vim.fn.winwidth(0) == vim.o.columns or vim.fn.winheight(0) == vim.o.lines
end

function M.zoom_toggle()
  -- Tab-local storage for the saved layout
  vim.t._zoom_restore = vim.t._zoom_restore or nil

  if vim.t._zoom_restore == nil then
    -- Save current layout and maximize the active window
    vim.t._zoom_restore = capture_layout()
    vim.cmd("wincmd |")  -- full width
    vim.cmd("wincmd _")  -- full height
  else
    -- Restore previous layout and clear marker
    restore_layout(vim.t._zoom_restore)
    vim.t._zoom_restore = nil
  end
end

return M
