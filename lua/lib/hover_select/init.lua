---@module 'lib.hover_select'
---@description Main module for creating interactive hover selection windows
---with line-wise navigation and custom selection callbacks

local M = {}

local config = require("lib.hover_select.config")
local buffer = require("lib.hover_select.buffer")
local window = require("lib.hover_select.window")
local navigation = require("lib.hover_select.navigation")
local highlight = require("lib.hover_select.highlight")
local notify = vim.notify
local api = vim.api

local state = {
  bufnr = nil,
  winid = nil,
  items = {},
  on_select = nil,
}

---Open a new hover selection window with the given items
---@param opts HoverSelectOptions Configuration options
---@return integer|nil bufnr Buffer number, or nil on failure
---@return integer|nil winid Window ID, or nil on failure
function M.open(opts)
  -- Validate required parameters
  if not opts or not opts.items or #opts.items == 0 then
    notify("lib.hover_select: items list is required and must not be empty", vim.log.levels.ERROR)
    return nil, nil
  end

  if not opts.on_select or type(opts.on_select) ~= "function" then
    notify("lib.hover_select: on_select callback is required", vim.log.levels.ERROR)
    return nil, nil
  end

  -- Close any existing instance
  M.close()


-- Debug helper to check if Tab mappings are working
-- Run this after opening hover_select

local function debug_hover_select_mappings()
  local bufnr = vim.api.nvim_get_current_buf()
  local bufname = vim.api.nvim_buf_get_name(bufnr)

  print("=== Hover Select Debug ===")
  print("Buffer number:", bufnr)
  print("Buffer name:", bufname)
  print("Buffer valid:", vim.api.nvim_buf_is_valid(bufnr))
  print("Window ID:", vim.api.nvim_get_current_win())

  -- Check normal mode mappings
  print("\n=== Normal Mode Mappings ===")
  local n_maps = vim.api.nvim_buf_get_keymap(bufnr, 'n')

  for _, map in ipairs(n_maps) do
    if map.lhs == "<Tab>" or map.lhs == "<S-Tab>" then
      print(string.format("%s -> %s (buffer: %s)",
        map.lhs,
        map.rhs or "function",
        map.buffer and "yes" or "no"
      ))
    end
  end

  -- Test Tab mapping directly
  print("\n=== Direct Test ===")
  local ok, result = pcall(function()
    local winid = vim.api.nvim_get_current_win()
    local cursor_before = vim.api.nvim_win_get_cursor(winid)
    print("Cursor before:", vim.inspect(cursor_before))

    -- Simulate Tab press
    vim.api.nvim_feedkeys(
      vim.api.nvim_replace_termcodes("<Tab>", true, false, true),
      'n',
      false
    )

    vim.defer_fn(function()
      local cursor_after = vim.api.nvim_win_get_cursor(winid)
      print("Cursor after:", vim.inspect(cursor_after))
    end, 100)
  end)

  if not ok then
    print("Error:", result)
  end
end

-- Create user command for easy debugging
vim.api.nvim_create_user_command('HoverSelectDebug', debug_hover_select_mappings, {})

print("Debug helper loaded. Open hover_select and run :HoverSelectDebug")

  -- Extract configuration options
  local use_tab_navigation = opts.use_tab_navigation or false
  local auto_width = opts.auto_width  -- Can be true, "wrap", or nil/false

  -- Merge user options with defaults
  local merged_buf_opts = vim.tbl_deep_extend("force", config.default_buf_options, opts.buf_options or {})
  local merged_win_opts = vim.tbl_deep_extend("force", config.default_win_options, opts.win_options or {})

  -- Create buffer with items
  local bufnr = buffer.create(opts.items, merged_buf_opts)
  if not bufnr then
    return nil, nil
  end

  -- Calculate dimensions
  local win_config = {
    relative = opts.relative or "cursor",
    width = opts.width,
    height = opts.height,
    title = opts.title,
    items_count = #opts.items,
  }

  -- Create floating window (pass items for auto-width calculation)
  local winid = window.create(bufnr, win_config, merged_win_opts, opts.items, auto_width)
  if not winid then
    api.nvim_buf_delete(bufnr, { force = true })
    return nil, nil
  end

  -- Store state
  state.bufnr = bufnr
  state.winid = winid
  state.items = opts.items
  state.on_select = opts.on_select

  -- Setup highlight for current line
  highlight.setup(winid)

  -- Setup navigation keymaps (with optional Tab navigation)
  navigation.setup(bufnr, function()
    M._handle_selection()
  end, use_tab_navigation)

  -- Set cursor to first line
  api.nvim_win_set_cursor(winid, { 1, 0 })

  return bufnr, winid
end

---Close the hover selection window and clean up resources
function M.close()
  if state.winid and api.nvim_win_is_valid(state.winid) then
    api.nvim_win_close(state.winid, true)
  end

  if state.bufnr and api.nvim_buf_is_valid(state.bufnr) then
    api.nvim_buf_delete(state.bufnr, { force = true })
  end

  -- Clear state
  state.bufnr = nil
  state.winid = nil
  state.items = {}
  state.on_select = nil
end

---Handle selection of current line
---@private
function M._handle_selection()
  if not state.winid or not api.nvim_win_is_valid(state.winid) then
    return
  end

  -- Get current cursor position
  local cursor = api.nvim_win_get_cursor(state.winid)
  local line_idx = cursor[1]

  -- Get selected item
  local selected_item = state.items[line_idx]
  if not selected_item then
    notify("lib.hover_select: invalid selection", vim.log.levels.WARN)
    M.close()
    return
  end

  -- Store callback before closing (window close might clear state)
  local callback = state.on_select

  -- Close window and buffer
  M.close()

  -- Execute callback
  if callback then
    callback(selected_item, line_idx)
  end
end

---Check if hover selection window is currently open
---@return boolean is_open True if window is open and valid
function M.is_open()
  return state.winid ~= nil and api.nvim_win_is_valid(state.winid)
end



return M
