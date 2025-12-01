---@module 'hover-select.navigation'
---@description Navigation and keymap setup for hover-select buffer

local M = {}

local set_km = vim.keymap.set

---Setup navigation keymaps for the given buffer
---@param bufnr integer Buffer number
---@param on_select function Callback to execute on selection
function M.setup(bufnr, on_select)
  local opts = { noremap = true, silent = true, buffer = bufnr }

  -- Block horizontal movement in all modes
  M._block_horizontal_movement(bufnr)

  -- Vertical movement (keep default behavior)
  -- j/k, <Up>/<Down>, etc. work normally

  -- Selection with Enter
  set_km("n", "<CR>", on_select, opts)
  set_km("n", "<2-LeftMouse>", on_select, opts)

  -- Close with Escape or q
  set_km("n", "<Esc>", function()
    local hover_select = require("hover-select")
    hover_select.close()
  end, opts)

  set_km("n", "q", function()
    local hover_select = require("hover-select")
    hover_select.close()
  end, opts)
end

---Block horizontal cursor movement in all modes
---@param bufnr integer Buffer number
---@private
function M._block_horizontal_movement(bufnr)
  local noop = function() end
  local modes = { "n", "v", "i" }
  local horizontal_keys = {
    "h",
    "l",
    "<Left>",
    "<Right>",
    "0",
    "^",
    "$",
    "w",
    "e",
    "b",
    "W",
    "E",
    "B",
  }

  for _, mode in ipairs(modes) do
    for _, key in ipairs(horizontal_keys) do
      set_km(mode, key, noop, {
        noremap = true,
        silent = true,
        buffer = bufnr,
      })
    end
  end
end

return M
