---@module 'config.neotree.commands.add'
--- Custom file/directory creation with clipboard integration and types support
---
--- Dependencies:
--- - lib.lua_ls.insert.module_w_path (for @module annotation insertion)
--- - lib.lua_ls.get_module_path (for module path calculation)
--- - lib.buffer.insert_lines (for content insertion)

local notify = require("lib.nvim.notify").create("[config.neotree.commands.add]")
local notify_clean = require("lib.nvim.notify").create("")

local M = {}

local api, fn = vim.api, vim.fn

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

--- Get file extension
---@param path string
---@return string|nil extension (without dot)
local function get_extension(path)
  return path:match("%.([^%.]+)$")
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
  local template_path = fn.stdpath("config")
    .. "/lua/config/neotree/commands/add/types_template.lua"

  local lines = {}
  local file = io.open(template_path, "r")
  if not file then
    return nil, "Could not open types template file"
  end

  for line in file:lines() do
    table.insert(lines, line)
  end
  file:close()

  return lines, nil
end

--- Save the current buffer
---@param bufnr number
local function save_buffer(bufnr)
  local ok, err = pcall(api.nvim_buf_call, bufnr, function()
    vim.cmd("silent! write")
  end)

  if not ok then
    notify.error(("Failed to save buffer: %s"):format(err))
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

--- Insert @module annotation using library module
---@param file_path string Absolute path to the file
---@return boolean success
local function insert_module_annotation(file_path)
  local bufnr = api.nvim_get_current_buf()

  -- Verify we're in the correct buffer
  if api.nvim_buf_get_name(bufnr) ~= file_path then
    notify.error("Buffer mismatch, cannot insert module annotation")
    return false
  end

  -- Use library module to insert @module annotation
  local ok, insert_mod = pcall(require, "lib.nvim.lua_ls.insert.module_annnotation")
  if not ok then
    notify.error("Failed to load module annotation library")
    return false
  end

  return insert_mod({ bufnr = bufnr, row = 1, col = 0 }) or false
end

--- Handle types file creation for Lua
---@param file_path string Absolute path to the created file
---@param state table Neo-tree state
---@param options Cfg.NeoTree.Commands.AddOptions
---@diagnostic disable-next-line: unused-local
local function handle_lua_types_file(file_path, state, options)
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
          notify.info("Buffer is not empty, skipping template insertion")
          return
        end
      end

      -- Get and insert template content
      local lines, err = get_types_template_content(file_path)
      if not lines then
        notify.error(err or "Failed to load types template")
        return
      end

      insert_content_into_buffer(lines)

      -- Insert @module annotation using library
      local success = insert_module_annotation(file_path)
      if not success then
        notify.warn("Warning: Failed to insert @module annotation")
      end

      -- Save the buffer
      save_buffer(bufnr)

      -- Ensure cursor focus is in this buffer
      api.nvim_set_current_buf(bufnr)

      notify(
        ("Types file created: %s"):format(fn.fnamemodify(file_path, ":t")),
        vim.log.levels.INFO
      )
    end)
  end)
end

--- Ask user if they want to insert clipboard content
---@param callback fun(should_insert: boolean)
local function ask_insert_clipboard(callback)
  local inputs = require("neo-tree.ui.inputs")

  inputs.confirm("Insert clipboard content?", function(confirmed)
    callback(confirmed == true)
  end)
end

--- Handle regular file creation with optional clipboard content
---@param file_path string Absolute path to the created file
---@param options Cfg.NeoTree.Commands.AddOptions
local function handle_regular_file(file_path, options)
  -- Determine if we should insert clipboard
  local function proceed_with_clipboard(should_insert)
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

        if should_insert then
          -- Get clipboard content
          local clipboard_content, err = get_clipboard_content()
          if not clipboard_content then
            notify.warn(err or "No clipboard content available")
            return
          end

          -- Split content into lines and insert
          local lines = vim.split(clipboard_content, "\n", { plain = true })
          insert_content_into_buffer(lines)

          -- Save the buffer
          save_buffer(bufnr)

          notify(
            ("File created with clipboard content: %s"):format(fn.fnamemodify(file_path, ":t")),
            vim.log.levels.INFO
          )
        else
          notify_clean.info(("File created: %s"):format(fn.fnamemodify(file_path, ":t")))
        end
      end)
    end)
  end

  -- Check options to determine behavior
  if options.insert_clipb then
    -- Automatically insert clipboard
    proceed_with_clipboard(true)
  elseif options.ask_insert_clipb then
    -- Ask user first
    ask_insert_clipboard(proceed_with_clipboard)
  else
    -- Don't insert clipboard by default
    proceed_with_clipboard(false)
  end
end

--- Handle directory creation with init file
---@param dir_path string Path to the directory to create
---@param state table Neo-tree state
---@param options Cfg.NeoTree.Commands.AddOptions
local function handle_directory_creation(dir_path, state, options)
  -- Create the directory
  local ok, err = pcall(fn.mkdir, dir_path, "p")
  if not ok then
    notify.error(("Failed to create directory: %s"):format(err))
    return
  end

  -- Check if this is a types directory (Lua-specific)
  local is_types = is_types_target(dir_path)

  -- Create init.lua path (Lua-specific for now)
  local init_path = fn.resolve(dir_path .. "/init.lua")

  if is_types then
    -- Use types template (Lua-specific)
    handle_lua_types_file(init_path, state, options)
  else
    -- Use regular clipboard content
    handle_regular_file(init_path, options)
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
---@param options? Cfg.NeoTree.Commands.AddOptions Options for clipboard insertion
function M.custom_add(state, options)
  -- Default options
  options = vim.tbl_extend("force", {
    insert_clipb = false,
    ask_insert_clipb = false,
  }, options or {})

  -- Use Neo-tree's input for getting the path
  local inputs = require("neo-tree.ui.inputs")

  -- Get the parent node
  local node = state.tree:get_node()
  if not node then
    notify.warn("[cfg.neotree.commands].add node is nil")
    return nil
  end
  local parent_path = node.type == "directory" and node.path or node:get_parent_id()

  inputs.input("File or Folder/ name:", "", function(input_path)
    if not input_path or input_path == "" then
      return
    end

    -- Get absolute path
    local full_path = fn.resolve(parent_path .. "/" .. input_path)

    -- Determine if this is a directory or file
    if ends_with_separator(input_path) then
      -- Directory creation with init file
      handle_directory_creation(full_path:gsub("[/\\]$", ""), state, options)
    else
      -- File creation
      -- Check if file already exists
      if fn.filereadable(full_path) == 1 then
        notify.warn("File already exists")
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
        notify.error("Failed to create file")
        return
      end

      -- Check file extension
      local ext = get_extension(full_path)

      if ext == "lua" then
        -- Check if this is a types file
        if is_types_target(full_path) then
          handle_lua_types_file(full_path, state, options)
        else
          handle_regular_file(full_path, options)
        end
      else
        -- Non-Lua files - handle regularly
        -- (Can be extended for other languages here)
        handle_regular_file(full_path, options)
      end

      -- Refresh Neo-tree after a delay
      vim.schedule(function()
        if state and state.commands and state.commands.refresh then
          state.commands.refresh(state)
        end
      end)
    end
  end, {}, {
    show_path = "relative",
  })
end

return M
