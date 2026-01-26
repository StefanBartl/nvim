---@module 'config.fzf.actions.create_file'
---@description Create file/folder in current entry's directory using hover_select

local notify = require("lib.notify").create("[config.fzf.actions.create_file]")

local M = {}

local fn = vim.fn

---Check if path ends with directory separator
---@param path string
---@return boolean
local function ends_with_separator(path)
  return path:match("[/\\]$") ~= nil
end

---Create file or directory
---@param parent_dir string Parent directory path
---@param name string Name of file/folder to create
---@return boolean success
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

---Extract file path from fzf-lua entry
---@param selected table|string fzf-lua selected entry
---@return string|nil path Absolute file path
local function get_path_from_entry(selected)
  -- Handle different fzf-lua entry formats
  local path

  if type(selected) == "string" then
    -- Raw string entry (files picker)
    path = selected
  elseif type(selected) == "table" then
    -- Structured entry
    path = selected.path or selected.filename or selected[1]
  end

  if not path or path == "" then
    return nil
  end

  -- Remove fzf formatting (colors, icons, etc.)
  -- Match pattern: optional ANSI codes, optional icon, then path
  path = path:gsub("^%s*\27%[[%d;]*m*", "")  -- Remove leading ANSI codes
  path = path:gsub("^%s*[^ ]*%s+", "")        -- Remove icon/prefix
  path = path:gsub("\27%[[%d;]*m", "")        -- Remove all ANSI codes
  path = path:gsub("^%s+", ""):gsub("%s+$", "")  -- Trim whitespace

  -- Expand to absolute path
  path = fn.fnamemodify(path, ":p")

  return path
end

---Create file/folder action for fzf-lua
---@param selected table|string fzf-lua selected entry
---@param opts table fzf-lua options
---@return boolean continue Continue fzf-lua picker
---@diagnostic disable-next-line: unused-local
function M.create_file(selected, opts)
  -- Debug output
  notify.info("[DEBUG] create_file triggered")
  notify.info("[DEBUG] selected type: " .. type(selected))

  local path = get_path_from_entry(selected)

  if not path then
    notify.warn("No valid path found")
    return false  -- Close picker
  end

  notify.info("[DEBUG] path: " .. path)

  -- Get parent directory
  local parent_dir
  if fn.isdirectory(path) == 1 then
    parent_dir = path
  else
    parent_dir = fn.fnamemodify(path, ":h")
  end

  if not parent_dir or parent_dir == "" then
    notify.error("Could not determine parent directory")
    return false  -- Close picker
  end

  notify.info("[DEBUG] parent_dir: " .. parent_dir)

  -- Schedule input to avoid conflicts
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

  return false  -- Close fzf picker
end

return M
