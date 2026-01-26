---@module 'usrcmds.gather.lua.ui'
---@description UI utilities for displaying gather results in scratch buffers

local notify = require("lib.notify").create("[usrcmds.gather.lua.ui]")

local api = vim.api

local M = {}

--- Create and open scratch buffer with results
---@param lines string[] Content lines to display
---@param title string|nil Optional title for the buffer
function M.open_scratch(lines, title)
  -- Validate input
  if not lines or #lines == 0 then
    notify.warn("No content to display")
    return
  end

  -- Create unlisted scratch buffer
  local ok, bufnr = pcall(api.nvim_create_buf, false, true)
  if not ok or bufnr == 0 then
    notify.error("Failed to create scratch buffer")
    return
  end

  -- Set buffer content (requires modifiable temporarily)
  local set_lines_ok = pcall(api.nvim_buf_set_lines, bufnr, 0, -1, false, lines)
  if not set_lines_ok then
    notify.error("Failed to set buffer content")
    pcall(api.nvim_buf_delete, bufnr, { force = true })
    return
  end

  -- Apply buffer options using current API
  local buf_opts = {
    buftype = "nofile",
    bufhidden = "wipe",
    swapfile = false,
    modifiable = false,
    filetype = "lua",
  }

  for option, value in pairs(buf_opts) do
    -- CRITICAL: nvim_set_option_value requires 3 arguments (option, value, opts)
    pcall(api.nvim_set_option_value, option, value, { buf = bufnr })
  end

  -- Set buffer name if title provided
  if title then
    pcall(api.nvim_buf_set_name, bufnr, "gather://" .. title)
  end

  -- Switch to buffer
  api.nvim_set_current_buf(bufnr)

  -- Set keymaps for closing
  local keymap_opts = { noremap = true, silent = true, buffer = bufnr }

  vim.keymap.set("n", "q", "<cmd>bd!<cr>", keymap_opts)
  vim.keymap.set("n", "<Esc>", "<cmd>bd!<cr>", keymap_opts)
end

return M
