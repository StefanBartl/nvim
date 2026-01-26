---@module 'usercmds.copy'
---@description
--- Flexible path copy command for Neovim.
--- Supports relative/absolute paths, parent levels, custom bases, targets, and separators.

local notify = require("lib.notify").create("[usrcmds.copy]")

local M = {}

local api = vim.api
local fn = vim.fn
local uv = vim.uv or vim.loop

-- ============================================================================
-- Helper Functions
-- ============================================================================

--- Get parent directory N levels up
---@param path string
---@param levels integer
---@return string
local function parent_dir(path, levels)
  local p = uv.fs_realpath(path) or path
  for _ = 1, levels do
    p = fn.fnamemodify(p, ":h")
  end
  return p
end

--- Normalize path separators
---@param path string
---@param separator? string Custom separator (default: "/")
---@return string
local function normalize(path, separator)
  separator = separator or "/"
  return (path:gsub("[/\\]", separator))
end

--- Copy text to clipboard
---@param str string
local function copy(str)
  vim.fn.setreg("+", str)
  print("Copied: " .. str)
end

--- Check if path is inside Neovim config directory
---@param path string
---@return boolean
local function is_inside_nvim_config(path)
  local config = fn.stdpath("config")
  local real_path = uv.fs_realpath(path) or path
  local real_config = uv.fs_realpath(config) or config

  -- Normalize both paths for comparison
  real_path = normalize(real_path, "/")
  real_config = normalize(real_config, "/")

  return real_path:sub(1, #real_config) == real_config
end

--- Convert file path to Lua module path
---@param filepath string Absolute path to file
---@return string|nil module_path
local function to_lua_module(filepath)
  local normalized = normalize(filepath, "/")
  local lua_idx = normalized:find("/lua/")

  if not lua_idx then
    return nil
  end

  local after_lua = normalized:sub(lua_idx + 5)
  local without_ext = after_lua:gsub("%.lua$", "")
  without_ext = without_ext:gsub("/init$", "")
  local module_path = without_ext:gsub("/", ".")

  return module_path
end

-- ============================================================================
-- Main Copy Function
-- ============================================================================

--- Parse and process copy path command
---@param args table Command arguments
local function copy_path(args)
  -- Default values
  local mode = "relative"
  local base = nil
  local target_type = "file"
  local target_path = fn.expand("%:p")
  local separator = "/"
  local special_mode = nil

  -- Parse arguments
  local i = 1
  while i <= #args do
    local arg = args[i]

    -- Mode
    if arg == "absolute" or arg == "relative" then
      mode = arg

    -- Special modes
    elseif arg == "nvim" then
      special_mode = "nvim"
    elseif arg == "nvim_module" then
      special_mode = "nvim_module"

    -- Separator
    elseif arg == "sep" or arg == "separator" then
      i = i + 1
      if i <= #args then
        separator = args[i]
      end

    -- Target type
    elseif arg == "file" or arg == "dir" then
      target_type = arg

    -- Numeric parent level
    elseif arg:match("^%d+$") then
      base = arg

    -- Explicit base or target path
    else
      -- If we haven't set a base yet and mode is relative, this is the base
      if mode == "relative" and not base then
        base = arg
      else
        -- Otherwise it's the target path
        target_path = arg
      end
    end

    i = i + 1
  end

  -- Handle special modes
  if special_mode == "nvim" then
    if not is_inside_nvim_config(target_path) then
      notify.warn("File is not inside Neovim config directory")
      return
    end
    base = fn.stdpath("config")
    mode = "relative"
  elseif special_mode == "nvim_module" then
    local module_path = to_lua_module(target_path)
    if not module_path then
      notify.warn("File is not in a lua/ directory")
      return
    end
    copy(module_path)
    return
  end

  -- Determine final target path
  if target_type == "dir" then
    target_path = fn.fnamemodify(target_path, ":h")
  end

  -- Process based on mode
  if mode == "absolute" then
    copy(normalize(target_path, separator))
    return
  end

  -- RELATIVE MODE
  local base_path

  if not base then
    -- Default: relative to cwd
    base_path = fn.getcwd()
  elseif base:match("^%d+$") then
    -- Numeric parent level
    local levels = tonumber(base)
    ---@cast levels integer
    if levels == 0 then
      base_path = fn.fnamemodify(target_path, ":h")
    else
      base_path = parent_dir(target_path, levels)
    end
  else
    -- Explicit base path
    base_path = uv.fs_realpath(base) or base
  end

  -- Calculate relative path
  local rel = fn.fnamemodify(target_path, ":." .. base_path)
  copy(normalize(rel, separator))
end

-- ============================================================================
-- Command Setup
-- ============================================================================

--- Setup user command
function M.enable()
  api.nvim_create_user_command("Copy", function(opts)
    local args = vim.split(opts.args, "%s+")

    if #args == 0 or args[1] ~= "path" then
      notify.error("Usage: :Copy path [options]")
      return
    end

    -- Remove "path" from args
    table.remove(args, 1)

    copy_path(args)
  end, {
    nargs = "*",
    ---@diagnostic disable-next-line: unused-local
    complete = function(arg_lead, cmd_line, _)
      -- Base completions
      local completions = {
        "path",
        "absolute",
        "relative",
        "nvim",
        "nvim_module",
        "file",
        "dir",
        "sep",
        "separator",
        "0",
        "1",
        "2",
        "3",
        "4",
        "5",
      }

      -- Filter based on what's already typed
      local filtered = {}
      for _, comp in ipairs(completions) do
        if comp:sub(1, #arg_lead) == arg_lead then
          table.insert(filtered, comp)
        end
      end

      return filtered
    end,
    desc = "[Copy] Copy paths to clipboard with flexible options",
  })
end

return M
