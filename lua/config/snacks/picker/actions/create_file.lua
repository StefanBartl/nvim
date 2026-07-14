---@module 'config.snacks.picker.actions.create_file'
---@brief Create file/folder action for snacks picker
---@description
--- Provides <C-a> action to create files and folders in the current entry's directory.
--- Adapted from config.telescope.actions.create_file

local notify = require("lib.nvim.notify").create("[config.snacks.picker.actions.create_file]")
local create_entry_core = require("lib.nvim.fs.create_entry")
local fn = vim.fn

local M = {}

---Create file or directory, notify, and open newly created files
---@param parent_dir string Parent directory path
---@param name string Name of file/folder to create
---@return boolean success
---@private
local function create_entry(parent_dir, name)
  local ok, kind, path_or_err = create_entry_core(parent_dir, name)
  if not ok then
    notify.error(path_or_err)
    return false
  end

  if kind == "directory" then
    notify.info(("Directory created: %s"):format(fn.fnamemodify(path_or_err, ":t")))
  else
    notify.info(("File created: %s"):format(fn.fnamemodify(path_or_err, ":t")))
    vim.schedule(function()
      vim.cmd("edit " .. fn.fnameescape(path_or_err))
    end)
  end

  return true
end

---Create file/folder action for snacks picker
---@param picker any Picker instance
---@param item? any Selected item
function M.create_file(picker, item)
  if not item then
    notify.warn("No item selected")
    return
  end

  -- Extract path from item
  ---@diagnostic disable-next-line: undefined-field
  local path = item.file or item.path or item.filename
  ---@diagnostic disable-next-line: undefined-field
  if not path and type(item.item) == "table" then
    ---@diagnostic disable-next-line: undefined-field
    path = item.item.path or item.item.filename
  end

  if not path or path == "" then
    notify.warn("No valid path found")
    return
  end

  -- Expand to absolute path
  path = fn.fnamemodify(path, ":p")

  -- Get parent directory
  local parent_dir
  if fn.isdirectory(path) == 1 then
    parent_dir = path
  else
    parent_dir = fn.fnamemodify(path, ":h")
  end

  if not parent_dir or parent_dir == "" then
    notify.error("Could not determine parent directory")
    return
  end

  -- Close picker
  ---@diagnostic disable-next-line: undefined-field
  picker:close()

  -- Show input prompt
  vim.schedule(function()
    vim.ui.input({
      prompt = "Create in " .. fn.fnamemodify(parent_dir, ":~:.") .. " (/ for folder): ",
      default = "",
    }, function(input)
      if not input or input == "" then
        return
      end

      create_entry(parent_dir, input)
    end)
  end)
end

return M
