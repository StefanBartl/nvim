---@module 'bindings.mappings.window_orientation'
--- Module for quickly changing split orientation in Neovim.
--- Provides:
---   - Lua functions for vertical/horizontal layout changes
---   - Mappings (normal mode)
---   - User commands :WinVertical and :WinHorizontal

local usercmd = require("lib.nvim.bindings.usercmd")

local M = {}

--- Move current window into a vertical layout, left side.
--- Equivalent to :wincmd H
function M.to_vertical_left()
  vim.cmd("wincmd H")
end

--- Move current window into a vertical layout, right side.
--- Equivalent to :wincmd L
function M.to_vertical_right()
  vim.cmd("wincmd L")
end

--- Move current window into a horizontal layout (top).
--- Equivalent to :wincmd K
function M.to_horizontal_top()
  vim.cmd("wincmd K")
end

--- Move current window into a horizontal layout (bottom).
--- Equivalent to :wincmd J
function M.to_horizontal_bottom()
  vim.cmd("wincmd J")
end

--- Rotate all windows.
--- Equivalent to :wincmd R
function M.rotate()
  vim.cmd("wincmd R")
end

--- Set up keymaps and user commands.
function M.setup()
  local map = require("lib.nvim.bindings.keymap")

  -- vertical
  map("n", "<leader>wl", M.to_vertical_left, { desc = "Move window to vertical split (left)" })
  map("n", "<leader>wr", M.to_vertical_right, { desc = "Move window to vertical split (right)" })

  -- horizontal
  map("n", "<leader>wh", M.to_horizontal_top, { desc = "Move window to horizontal split (top)" })
  map("n", "<leader>wj", M.to_horizontal_bottom, { desc = "Move window to horizontal split (bottom)" })

  -- rotate entire layout
  map("n", "<leader>wo", M.rotate, { desc = "Rotate window layout" })

  -- user commands
  usercmd.create("WinVertical", function()
    M.to_vertical_left()
  end, { desc = "Move current window to vertical split" })

  usercmd.create("WinHorizontal", function()
    M.to_horizontal_top()
  end, { desc = "Move current window to horizontal split" })
end

return M
