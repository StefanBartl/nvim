---@module 'hover-select.window'
---@description Window creation and configuration for hover-select

local M = {}

local config = require("hover-select.config")
local notify = vim.notify
local api = vim.api

---Calculate optimal window dimensions based on content
---@param items_count integer Number of items to display
---@param width integer|nil User-specified width
---@param height integer|nil User-specified height
---@return integer width Calculated width
---@return integer height Calculated height
local function calculate_dimensions(items_count, width, height)
  local dims = config.dimensions

  -- Calculate height
  local calc_height = height or items_count
  calc_height = math.max(dims.min_height, math.min(calc_height, dims.max_height))

  -- Calculate width (auto-size if not specified)
  local calc_width = width or (dims.min_width + dims.padding)
  calc_width = math.max(dims.min_width, math.min(calc_width, dims.max_width))

  return calc_width, calc_height
end

---Create floating window with the given configuration
---@param bufnr integer Buffer to display in window
---@param win_config table Window configuration options
---@param win_options table<string, any> Window-local options to apply
---@return integer|nil winid Window ID, or nil on failure
function M.create(bufnr, win_config, win_options)
  -- Calculate dimensions
  local width, height = calculate_dimensions(
    win_config.items_count or 0,
    win_config.width,
    win_config.height
  )

  -- Build window configuration
  local float_config = vim.tbl_deep_extend("force", config.default_win_config, {
    relative = win_config.relative or "cursor",
    width = width,
    height = height,
    row = win_config.row or 1,
    col = win_config.col or 0,
    title = win_config.title,
  })

  -- Create floating window
  local winid = api.nvim_open_win(bufnr, true, float_config)
  if winid == 0 then
    notify("hover-select: failed to create window", vim.log.levels.ERROR)
    return nil
  end

  -- Apply window-local options
  for option, value in pairs(win_options) do
    local success, err = pcall(api.nvim_set_option_value, option, value, { win = winid } )
    if not success then
      notify(
        string.format("hover-select: failed to set window option '%s': %s", option, err),
        vim.log.levels.WARN
      )
    end
  end

  -- Setup autocommands for cleanup
  M._setup_autocommands(bufnr, winid)

  return winid
end

---Setup autocommands for automatic window cleanup
---@param bufnr integer Buffer number
---@param winid integer Window ID
---@private
function M._setup_autocommands(bufnr, winid)
  local augroup = api.nvim_create_augroup("HoverSelectWindow_" .. winid, { clear = true })

  -- Close window when leaving buffer
  api.nvim_create_autocmd({ "BufLeave", "BufWipeout" }, {
    group = augroup,
    buffer = bufnr,
    callback = function()
      if api.nvim_win_is_valid(winid) then
        api.nvim_win_close(winid, true)
      end
    end,
  })

  -- Handle window closure
  api.nvim_create_autocmd("WinClosed", {
    group = augroup,
    pattern = tostring(winid),
    callback = function()
      if api.nvim_buf_is_valid(bufnr) then
        api.nvim_buf_delete(bufnr, { force = true })
      end
    end,
  })
end

return M
