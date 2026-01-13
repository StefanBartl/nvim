---@module 'config.neotree.commands.add'
--- Custom file/directory creation with clipboard integration and types support
---
--- Dependencies:
--- - User command `:InsertModule` must be available for @module annotation generation

local M = {}

local api, fn = vim.api, vim.fn
local notify = vim.notify

--- Check if a path ends with a directory separator
---@param path string
---@return boolean
local function ends_with_separator(path)
  return path:match("[/\\]$") ~= nil
end

--- Check if the path indicates a types definition file or folder
---@param path string
---@return boolean is_types_target
local function is_types_target(path)
  -- Check for @types/ or types/ directory
  if path:match("@types/?$") or path:match("types/?$") then
    return true
  end

  -- Check for @types.lua or types.lua file
  local basename = fn.fnamemodify(path, ":t")
  if basename == "@types.lua" or basename == "types.lua" then
    return true
  end

  return false
end

--- Get clipboard content
---@return string|nil content, string|nil error_msg
local function get_clipboard_content()
  local ok, content = pcall(fn.getreg, "+")
  if not ok or not content or content == "" then
    return nil, "Clipboard is empty or unavailable"
  end
  return content, nil
end

--- Insert content into the current buffer
---@param lines string[]
local function insert_content_into_buffer(lines)
  local bufnr = api.nvim_get_current_buf()

  -- Ensure buffer is modifiable
  vim.bo[bufnr].modifiable = true
  vim.bo[bufnr].readonly = false

  api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
end

--- Load and process the types template
---@param file_path string Absolute path to the file
---@return string[]|nil lines, string|nil error_msg
---@diagnostic disable-next-line: unused-local
local function get_types_template_content(file_path)
  local template_path = fn.stdpath("config") .. "/lua/config/neotree/commands/add/types_template.lua"

  local lines = {}
  local file = io.open(template_path, "r")
  if not file then
    return nil, "Could not open types template file"
  end

  for line in file:lines() do
    table.insert(lines, line)
  end
  file:close()

  -- Template contains {MODULEPATH} placeholder - will be replaced by :InsertModule
  return lines, nil
end

--- Save the current buffer
---@param bufnr number
local function save_buffer(bufnr)
  local ok, err = pcall(api.nvim_buf_call, bufnr, function()
    vim.cmd("silent! write")
  end)

  if not ok then
    notify(("Failed to save buffer: %s"):format(err), vim.log.levels.ERROR)
  end
end

--- Check if buffer is effectively empty (ignoring single empty line)
---@param bufnr number
---@return boolean
local function is_buffer_empty(bufnr)
  local line_count = api.nvim_buf_line_count(bufnr)

  -- Single line that is empty counts as empty
  if line_count == 1 then
    local first_line = api.nvim_buf_get_lines(bufnr, 0, 1, false)[1]
    return first_line == nil or first_line == ""
  end

  -- More than one line means not empty
  if line_count > 1 then
    return false
  end

  return true
end

--- Handle types file creation
---@param file_path string Absolute path to the created file
---@param state table Neo-tree state
---@diagnostic disable-next-line: unused-local
local function handle_types_file(file_path, state)
  -- Schedule to ensure file operations complete
  vim.schedule(function()
    -- Open the file in a buffer
    vim.cmd("edit " .. fn.fnameescape(file_path))

    -- Wait for buffer to be ready
    vim.schedule(function()
      local bufnr = api.nvim_get_current_buf()

      -- Ensure buffer is modifiable
      vim.bo[bufnr].modifiable = true
      vim.bo[bufnr].readonly = false

      -- Only insert template if buffer is effectively empty
      if not is_buffer_empty(bufnr) then
        -- Check if it's just the default empty line - clear it
        local lines = api.nvim_buf_get_lines(bufnr, 0, -1, false)
        if #lines == 1 and lines[1] == "" then
          -- Buffer has only one empty line, proceed
        else
          notify("Buffer is not empty, skipping template insertion", vim.log.levels.INFO)
          return
        end
      end

      -- Get and insert template content
      local lines, err = get_types_template_content(file_path)
      if not lines then
        notify(err or "Failed to load types template", vim.log.levels.ERROR)
        return
      end

      insert_content_into_buffer(lines)

      -- Call :InsertModule to replace {MODULEPATH} placeholder
      local has_insert_module = fn.exists(":InsertModule") > 0
      if has_insert_module then
        vim.cmd("InsertModule")
      else
        notify("Warning: :InsertModule command not found, module path not inserted", vim.log.levels.WARN)
      end

      -- Save the buffer
      save_buffer(bufnr)

      -- Ensure cursor focus is in this buffer
      api.nvim_set_current_buf(bufnr)

      notify(("Types file created: %s"):format(fn.fnamemodify(file_path, ":t")), vim.log.levels.INFO)
    end)
  end)
end

--- Handle regular file creation with clipboard content
---@param file_path string Absolute path to the created file
local function handle_regular_file(file_path)
  -- Schedule to ensure file operations complete
  vim.schedule(function()
    -- Open the file in a buffer
    vim.cmd("edit " .. fn.fnameescape(file_path))

    -- Wait for buffer to be ready
    vim.schedule(function()
      local bufnr = api.nvim_get_current_buf()

      -- Ensure buffer is modifiable
      vim.bo[bufnr].modifiable = true
      vim.bo[bufnr].readonly = false

      -- Get clipboard content
      local clipboard_content, err = get_clipboard_content()
      if not clipboard_content then
        notify(err or "No clipboard content available", vim.log.levels.WARN)
        return
      end

      -- Split content into lines and insert
      local lines = vim.split(clipboard_content, "\n", { plain = true })
      insert_content_into_buffer(lines)

      -- Save the buffer
      save_buffer(bufnr)

      notify(("File created with clipboard content: %s"):format(fn.fnamemodify(file_path, ":t")), vim.log.levels.INFO)
    end)
  end)
end

--- Handle directory creation with init.lua
---@param dir_path string Path to the directory to create
---@param state table Neo-tree state
local function handle_directory_creation(dir_path, state)
  -- Create the directory
  local ok, err = pcall(fn.mkdir, dir_path, "p")
  if not ok then
    notify(("Failed to create directory: %s"):format(err), vim.log.levels.ERROR)
    return
  end

  -- Check if this is a types directory
  local is_types = is_types_target(dir_path)

  -- Create init.lua path
  local init_path = fn.resolve(dir_path .. "/init.lua")

  if is_types then
    -- Use types template
    handle_types_file(init_path, state)
  else
    -- Use regular clipboard content
    handle_regular_file(init_path)
  end

  -- Refresh Neo-tree after a delay to allow file operations to complete
  vim.schedule(function()
    if state and state.commands and state.commands.refresh then
      state.commands.refresh(state)
    end
  end)
end

--- Main command handler for custom add
---@param state Cfg.NeoTree.State Neo-tree state
function M.custom_add(state)
  -- Use Neo-tree's input for getting the path
  local inputs = require("neo-tree.ui.inputs")

  -- Get the parent node
  local node = state.tree:get_node()
  local parent_path = node.type == "directory" and node.path or node:get_parent_id()

  inputs.input("File name:", "", function(input_path)
    if not input_path or input_path == "" then
      return
    end

    -- Get absolute path
    local full_path = fn.resolve(parent_path .. "/" .. input_path)

    -- Determine if this is a directory or file
    if ends_with_separator(input_path) then
      -- Directory creation with init.lua
      handle_directory_creation(full_path:gsub("[/\\]$", ""), state)
    else
      -- File creation
      -- Check if file already exists
      if fn.filereadable(full_path) == 1 then
        notify("File already exists", vim.log.levels.WARN)
        return
      end

      -- Create parent directory if needed
      local parent_dir = fn.fnamemodify(full_path, ":h")
      if fn.isdirectory(parent_dir) == 0 then
        fn.mkdir(parent_dir, "p")
      end

      -- Create empty file
      local file = io.open(full_path, "w")
      if file then
        file:close()
      else
        notify("Failed to create file", vim.log.levels.ERROR)
        return
      end

      -- Check if this is a types file
      if is_types_target(full_path) then
        handle_types_file(full_path, state)
      else
        handle_regular_file(full_path)
      end

      -- Refresh Neo-tree after a delay
      vim.schedule(function()
        if state and state.commands and state.commands.refresh then
          state.commands.refresh(state)
        end
      end)
    end
  end, {}, {
    show_path = "relative"
  })
end

return M
