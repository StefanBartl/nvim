---@module 'config.snacks.picker.actions.create_file'
---@brief Create file/folder action for snacks picker
---@description
--- Provides <C-a> action to create files and folders in the current entry's directory.
--- Adapted from config.telescope.actions.create_file

local notify = require("lib.nvim.notify").create("[config.snacks.picker.actions.create_file]")
local fn = vim.fn

local M = {}

---Check if path ends with directory separator
---@param path string
---@return boolean
---@private
local function ends_with_separator(path)
  return path:match("[/\\]$") ~= nil
end

---Create file or directory
---@param parent_dir string Parent directory path
---@param name string Name of file/folder to create
---@return boolean success
---@private
local function create_entry(parent_dir, name)
  local full_path = fn.resolve(parent_dir .. "/" .. name)

  if ends_with_separator(name) then
    -- Directory creation
    local dir_path = full_path:gsub("[/\\]$", "")
    local ok, err = pcall(fn.mkdir, dir_path, "p")
    if not ok then
      notify.error(("Failed to create directory: %s"):format(err))
      return false
    end
    notify.info(("Directory created: %s"):format(fn.fnamemodify(dir_path, ":t")))
    return true
  else
    -- File creation
    if fn.filereadable(full_path) == 1 then
      notify.warn("File already exists")
      return false
    end

    -- Create parent directory if needed
    local parent = fn.fnamemodify(full_path, ":h")
    if fn.isdirectory(parent) == 0 then
      fn.mkdir(parent, "p")
    end

    -- Create empty file
    local file = io.open(full_path, "w")
    if file then
      file:close()
      notify.info(("File created: %s"):format(fn.fnamemodify(full_path, ":t")))

      -- Open file in buffer
      vim.schedule(function()
        vim.cmd("edit " .. fn.fnameescape(full_path))
      end)

      return true
    else
      notify.error("Failed to create file")
      return false
    end
  end
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
