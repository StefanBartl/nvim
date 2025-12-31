---@module 'lib.hover_select.navigation'
---@description Navigation and keymap setup for lib.hover_select buffer

local M = {}

local api = vim.api
local set_km = vim.keymap.set

---Setup navigation keymaps for the given buffer
---@param bufnr integer Buffer number
---@param on_select function Callback to execute on selection
---@param use_tab_navigation boolean Enable Tab/Shift-Tab navigation
function M.setup(bufnr, on_select, use_tab_navigation)
  local opts = { noremap = true, silent = true, buffer = bufnr }

  -- Block horizontal movement in all modes
  M._block_horizontal_movement(bufnr)

  -- Vertical movement (keep default behavior)
  -- j/k, <Up>/<Down>, etc. work normally

  -- Optional Tab/Shift-Tab navigation
  -- Buffer-local mappings override global mappings automatically
  if use_tab_navigation then
    -- IMPORTANT: These buffer-local mappings take precedence over
    -- any global Tab/Shift-Tab mappings (e.g., for buffer navigation)
    -- while this hover_select window is focused

    -- Move to next line (with wrapping)
    set_km("n", "<Tab>", function()
      local ok, err = pcall(function()
        local winid = api.nvim_get_current_win()
        if not api.nvim_win_is_valid(winid) then
          return
        end

        local buf = api.nvim_win_get_buf(winid)
        local cursor = api.nvim_win_get_cursor(winid)
        local line_count = api.nvim_buf_line_count(buf)

        local next_line = cursor[1] + 1
        if next_line > line_count then
          next_line = 1  -- Wrap to first line
        end

        api.nvim_win_set_cursor(winid, { next_line, 0 })
      end)

      if not ok then
        vim.notify("Tab navigation error: " .. tostring(err), vim.log.levels.ERROR)
      end
    end, opts)

    -- Move to previous line (with wrapping)
    set_km("n", "<S-Tab>", function()
      local ok, err = pcall(function()
        local winid = api.nvim_get_current_win()
        if not api.nvim_win_is_valid(winid) then
          return
        end

        local buf = api.nvim_win_get_buf(winid)
        local cursor = api.nvim_win_get_cursor(winid)
        local line_count = api.nvim_buf_line_count(buf)

        local prev_line = cursor[1] - 1
        if prev_line < 1 then
          prev_line = line_count  -- Wrap to last line
        end

        api.nvim_win_set_cursor(winid, { prev_line, 0 })
      end)

      if not ok then
        vim.notify("Shift-Tab navigation error: " .. tostring(err), vim.log.levels.ERROR)
      end
    end, opts)

    -- Also map in insert mode to be safe
    set_km("i", "<Tab>", function()
      -- Switch to normal mode first, then move
      vim.cmd("stopinsert")
      vim.defer_fn(function()
        local winid = api.nvim_get_current_win()
        if not api.nvim_win_is_valid(winid) then return end

        local buf = api.nvim_win_get_buf(winid)
        local cursor = api.nvim_win_get_cursor(winid)
        local line_count = api.nvim_buf_line_count(buf)

        local next_line = cursor[1] + 1
        if next_line > line_count then
          next_line = 1
        end

        api.nvim_win_set_cursor(winid, { next_line, 0 })
      end, 10)
    end, opts)

    set_km("i", "<S-Tab>", function()
      vim.cmd("stopinsert")
      vim.defer_fn(function()
        local winid = api.nvim_get_current_win()
        if not api.nvim_win_is_valid(winid) then return end

        local buf = api.nvim_win_get_buf(winid)
        local cursor = api.nvim_win_get_cursor(winid)
        local line_count = api.nvim_buf_line_count(buf)

        local prev_line = cursor[1] - 1
        if prev_line < 1 then
          prev_line = line_count
        end

        api.nvim_win_set_cursor(winid, { prev_line, 0 })
      end, 10)
    end, opts)
  else
    -- If Tab navigation is disabled, explicitly disable Tab/Shift-Tab
    -- to prevent accidental buffer switches while in hover_select
    local noop = function() end
    set_km("n", "<Tab>", noop, opts)
    set_km("n", "<S-Tab>", noop, opts)
    set_km("i", "<Tab>", noop, opts)
    set_km("i", "<S-Tab>", noop, opts)
  end

  -- Selection with Enter
  set_km("n", "<CR>", on_select, opts)
  set_km("n", "<2-LeftMouse>", on_select, opts)

  -- Close with Escape or q
  set_km("n", "<Esc>", function()
    local hover_select = require("lib.hover_select")
    hover_select.close()
  end, opts)

  set_km("n", "q", function()
    local hover_select = require("lib.hover_select")
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
