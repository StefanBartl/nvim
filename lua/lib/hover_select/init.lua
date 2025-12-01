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

  -- Create floating window
  local winid = window.create(bufnr, win_config, merged_win_opts)
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

  -- Setup navigation keymaps
  navigation.setup(bufnr, function()
    M._handle_selection()
  end)

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
