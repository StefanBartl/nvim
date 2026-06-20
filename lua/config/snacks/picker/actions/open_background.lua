---@module 'config.snacks.picker.actions.open_background'
---@brief Open file in background buffer action for snacks picker
---@description
--- Provides <S-CR> and <C-o> actions to open files in background without closing picker.
--- Adapted from config.telescope.actions.open_badd

local notify = require("lib.notify").create("[config.snacks.picker.actions.open_background]")
local fn = vim.fn

local M = {}

---Open selected entry as background buffer
---@param _picker any Picker instance
---@param item? any Selected item
function M.open_background(_picker, item)
  if not item then
    notify.warn("No item selected")
    return
  end

  -- Extract path from item (snacks picker structure)
  ---@diagnostic disable-next-line: undefined-field
  local path = item.file or item.path or item.filename
  ---@diagnostic disable-next-line: undefined-field
  if not path and type(item.item) == "table" then
    ---@diagnostic disable-next-line: undefined-field
    path = item.item.path or item.item.filename or item.item.file
  end
  ---@diagnostic disable-next-line: undefined-field
  if not path and type(item.text) == "string" then
    ---@diagnostic disable-next-line: undefined-field
    path = item.text
  end

  if not path or path == "" then
    notify.warn("No valid path found")
    return
  end

  -- Expand to absolute path
  path = fn.fnamemodify(path, ":p")

  -- Check if file exists and is readable
  if fn.filereadable(path) ~= 1 then
    notify.error("File not readable: " .. path)
    return
  end

  -- Add buffer to buffer list
  local bufnr = fn.bufadd(path)

  -- Load buffer content
  local ok = pcall(fn.bufload, bufnr)
  if not ok then
    notify.error("Failed to load buffer: " .. path)
    return
  end

  -- Ensure buffer is listed
  pcall(function()
    vim.bo[bufnr].buflisted = true
  end)

  -- Show confirmation
  local filename = fn.fnamemodify(path, ":t")
  notify.info("Buffered: " .. filename)

  -- Do NOT close picker - that's the point of background open
end

return M
