---@module 'hover-select.config'
---@description Default configuration values for hover-select plugin

local M = {}

---Default buffer options
---@type table<string, any>
M.default_buf_options = {
  buftype = "nofile",
  bufhidden = "wipe",
  swapfile = false,
  modifiable = false,
  filetype = "hover-select",
}

---Default window options
---@type table<string, any>
M.default_win_options = {
  cursorline = true,
  number = false,
  relativenumber = false,
  wrap = false,
  spell = false,
  foldenable = false,
  signcolumn = "no",
}

---Default window configuration
---@type table<string, any>
M.default_win_config = {
  relative = "cursor",
  row = 1,
  col = 0,
  style = "minimal",
  border = "rounded",
  focusable = true,
  zindex = 50,
}

---Minimum and maximum window dimensions
---@type table<string, integer>
M.dimensions = {
  min_width = 20,
  max_width = 80,
  min_height = 3,
  max_height = 20,
  padding = 2, -- Extra width padding for borders
}

---@type Lib.UI.HoverSelect.Config
return M
