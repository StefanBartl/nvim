---@module 'config.notify'
--- Unified configuration for nvim-notify with path separator normalization.
--- This module:
---   * Wraps vim.notify so that Windows-style backslashes (`\`) are normalized to forward slashes (`/`).
---   * Configures nvim-notify (colors, timeout, stages, etc.).
---   * Ensures notifications are non-focusable.
---   * Provides a convenient <Esc> mapping to dismiss popups.

-- ---------------------------------------------------------------------------
-- Path separator normalization for vim.notify
-- ---------------------------------------------------------------------------

--- Save reference to the original notify function
---@type fun(msg: string|any, ...: any): any
local original_notify = vim.notify

--- Override vim.notify to normalize path separators in messages.
--- Converts Windows-style backslashes (`\`) to forward slashes (`/`).
---@param msg string|any Message to display in the notification
---@param ... any Additional arguments passed to the original notify
---@return any Return value from the original notify function
---@diagnostic disable-next-line
vim.notify = function(msg, ...)
  if type(msg) == "string" then
    msg = msg:gsub("\\", "/")
  end
  return original_notify(msg, ...)
end

-- ---------------------------------------------------------------------------
-- nvim-notify setup
-- ---------------------------------------------------------------------------

local ok, notify = pcall(require, "notify")
if not ok then
  return
end

-- Highlight adjustments for notify icons
local notify_hl = vim.api.nvim_create_augroup("NotifyHighlights", { clear = true })
vim.api.nvim_create_autocmd("BufEnter", {
  group = notify_hl,
  desc = "Redefine notify icon highlight groups",
  callback = function()
    vim.api.nvim_set_hl(0, "NotifyINFOIcon", {})
    vim.api.nvim_set_hl(0, "NotifyINFOIcon", { link = "Character" })
  end,
})

--- Configure nvim-notify
notify.setup({
  background_colour = "#1a1a1a",
  timeout = 5000,
  render = "default",
  stages = "fade",
  merge_duplicates = true,
  on_open = function(win)
    -- Make notify windows unfocusable
    vim.api.nvim_win_set_config(win, { focusable = false })
  end,
})

-- ---------------------------------------------------------------------------
-- Keymaps
-- ---------------------------------------------------------------------------

--- Map <Esc> to dismiss notify popups and clear hlsearch
vim.keymap.set("n", "<Esc>", function()
  require("notify").dismiss()
  vim.cmd("nohlsearch")
end, { desc = "Dismiss notify popup and clear hlsearch" })
