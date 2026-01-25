---@module 'custom.recommender.keymaps'
---Navigation and actions

local notify = require("lib.notify").create("[custom.recommender.navigation]")

local M = {}

local api = vim.api
local rendering = require("custom.recommender.rendering")

---Check if a line is selectable (chain line, not alias line)
---@param line integer
---@return boolean
local function is_selectable(line)
  return line > 1 and (line - 2) % 3 == 0
end

---Move cursor to next/previous selectable line
---@param delta integer
local function move(delta)
  if not rendering.is_open() then
    return
  end

  local ok, cursor = pcall(api.nvim_win_get_cursor, rendering.float_win)
  if not ok then
    return
  end

  local line = cursor[1]
  local target = line + delta

  -- Get buffer line count
  local line_count = api.nvim_buf_line_count(rendering.float_buf)

  -- Find next selectable line
  while target >= 2 and target <= line_count do
    if is_selectable(target) then
      pcall(api.nvim_win_set_cursor, rendering.float_win, { target, 0 })
      rendering.cursor_index = target
      return
    end
    target = target + delta
  end
end

---@param bufnr integer
---@param state table
function M.attach(bufnr, state)
  if not bufnr or not api.nvim_buf_is_valid(bufnr) then
    return
  end

  local opts = { buffer = bufnr, silent = true, nowait = true }

  -- Navigation
  vim.keymap.set("n", "j", function()
    move(3)
  end, opts)

  vim.keymap.set("n", "k", function()
    move(-3)
  end, opts)

  vim.keymap.set("n", "<Down>", function()
    move(3)
  end, opts)

  vim.keymap.set("n", "<Up>", function()
    move(-3)
  end, opts)

  -- Close
  vim.keymap.set("n", "q", function()
    rendering.close()
  end, opts)

  vim.keymap.set("n", "<ESC>", function()
    rendering.close()
  end, opts)

  -- Select and insert
  vim.keymap.set("n", "<CR>", function()
    if not rendering.is_open() then
      return
    end

    -- Calculate index from cursor position
    local idx = math.floor((rendering.cursor_index - 2) / 3) + 1
    local item = state.visible[idx]

    if not item then
      return
    end

    -- Get the window we came from
    local prev_win = vim.fn.win_getid(vim.fn.winnr("#"))
    if not prev_win or prev_win == 0 or not api.nvim_win_is_valid(prev_win) then
      -- Fallback: find first normal window
      for _, win in ipairs(api.nvim_list_wins()) do
        local buf = api.nvim_win_get_buf(win)
        if api.nvim_buf_get_option(buf, "buftype") == "" then
          prev_win = win
          break
        end
      end
    end

    rendering.close()

    -- Insert the alias
    if prev_win and api.nvim_win_is_valid(prev_win) then
      api.nvim_set_current_win(prev_win)
      vim.schedule(function()
        api.nvim_put({ item.alias }, "l", true, true)
      end)
    end
  end, opts)

  -- Ignore entry
  vim.keymap.set("n", "<BS>", function()
    if not rendering.is_open() then
      return
    end

    local idx = math.floor((rendering.cursor_index - 2) / 3) + 1
    local item = state.visible[idx]

    if item then
      state.ignored[item.chain] = true
      state.refresh()
    end
  end, opts)

  -- Un-ignore all
  vim.keymap.set("n", "U", function()
    state.ignored = {}
    -- Update the reference in ignore_by_buf
    -- local bufnr_target = vim.api.nvim_get_current_buf()
    if type(require("custom.recommender")) == "table" then
      -- This is a bit hacky, but we need to update the main ignore list
      vim.notify("All ignored items cleared", vim.log.levels.INFO)
    end
    state.refresh()
  end, opts)

  -- Help
  vim.keymap.set("n", "?", function()
    local help_text = {
      "Recommender Help:",
      "",
      "j/k, ↓/↑  - Navigate",
      "Enter     - Insert alias",
      "Backspace - Ignore entry",
      "U         - Un-ignore all",
      "q/Esc     - Close",
    }
    notify.info(table.concat(help_text, "\n"))
  end, opts)
end

return M
