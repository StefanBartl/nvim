---@module 'config.telescope.actions.create_file'
---@description Create file/folder in current entry's directory using hover_select

local M = {}

local action_state = require("telescope.actions.state")
local fn = vim.fn
local notify = vim.notify

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
      notify(("Failed to create directory: %s"):format(err), vim.log.levels.ERROR)
      return false
    end
    notify(("Directory created: %s"):format(fn.fnamemodify(dir_path, ":t")), vim.log.levels.INFO)
    return true
  else
    -- File creation
    if fn.filereadable(full_path) == 1 then
      notify("File already exists", vim.log.levels.WARN)
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
      notify(("File created: %s"):format(fn.fnamemodify(full_path, ":t")), vim.log.levels.INFO)

      -- Open file in buffer
      vim.schedule(function()
        vim.cmd("edit " .. fn.fnameescape(full_path))
      end)

      return true
    else
      notify("Failed to create file", vim.log.levels.ERROR)
      return false
    end
  end
end

---Create file/folder action for Telescope
---@param prompt_bufnr integer Telescope prompt buffer number
function M.create_file(prompt_bufnr)
  local entry = action_state.get_selected_entry()

  if not entry then
    notify("No entry selected", vim.log.levels.WARN)
    return
  end

  -- Extract path from entry
  local path = entry.path or entry.filename
  if not path and type(entry.value) == "string" then
    path = entry.value
  end

  if not path or path == "" then
    notify("No valid path found", vim.log.levels.WARN)
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
    notify("Could not determine parent directory", vim.log.levels.ERROR)
    return
  end

  -- Close Telescope picker
  require("telescope.actions").close(prompt_bufnr)

  -- Directly show input prompt (skip hover_select intermediary)
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

---Get mappings for Telescope
---@return table mappings
function M.get_mappings()
  return {
    i = {
      ["<C-a>"] = M.create_file,
    },
    n = {
      ["<C-a>"] = M.create_file,
    },
  }
end

return M
