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

--- Convert file path to Lua module path.
--- Shares the single source of truth with `:Insert module`.
---@param filepath string Absolute path to file
---@return string|nil module_path
local function to_lua_module(filepath)
  return require("lib.lua_ls.get_module_path")(filepath)
end

--- Derive a default module style from the current buffer's filetype.
---@return string style
local function style_from_filetype()
  local ft = vim.bo.filetype
  if ft == "lua" then
    return "lua"
  elseif ft == "javascript" or ft == "typescript"
      or ft == "javascriptreact" or ft == "typescriptreact" then
    return "js"
  elseif ft == "c" or ft == "cpp" then
    return "c"
  end
  return "generic"
end

--- Build a module path string for the given file in the requested style.
--- - lua/luals/lua_ls -> dotted Lua module (relative to the nearest `lua/` dir)
--- - any other style  -> path relative to cwd, extension stripped, `/`-separated
---@param filepath string Absolute path to file
---@param style string
---@return string|nil result
local function build_module_path(filepath, style)
  style = (style or ""):lower()
  if style == "lua" or style == "luals" or style == "lua_ls" then
    return to_lua_module(filepath)
  end
  -- Generic: project-relative path without extension (js/ts/c/... import style).
  local rel = normalize(fn.fnamemodify(filepath, ":."), "/")
  rel = rel:gsub("%.[^./]+$", "")
  return rel
end

--- :Copy module [style] — copy the current file path as a module path.
---@param args string[]
local function copy_module(args)
  local style = args[1]
  if not style or style == "" then
    style = style_from_filetype()
  end

  local filepath = fn.expand("%:p")
  if filepath == "" then
    notify.warn("No file in current buffer")
    return
  end

  local result = build_module_path(filepath, style)
  if not result or result == "" then
    notify.warn(string.format("Could not derive module path (style=%s)", tostring(style)))
    return
  end

  copy(result)
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

local function attach_keymap()
    require("lib.map")("n", "<leader>cnm", function()
    vim.cmd("Copy path nvim_module")
  end, { desc = "[usrcmds.copy] Copy module path relative to nvim config" })
end

--- Setup user command
function M.enable()
  api.nvim_create_user_command("Copy", function(opts)
    local args = vim.split(vim.trim(opts.args), "%s+", { trimempty = true })
    local sub = args[1]

    if sub == "path" then
      table.remove(args, 1)
      copy_path(args)
    elseif sub == "module" then
      table.remove(args, 1)
      copy_module(args)
    else
      notify.error("Usage: :Copy path|module [options]")
    end
  end, {
    nargs = "*",
    complete = function(arg_lead, cmd_line, cursor_pos)
      -- Subcommands and their option sets.
      local subcommands = { "path", "module" }
      local path_options = {
        "absolute", "relative", "nvim", "nvim_module",
        "file", "dir", "sep", "separator",
        "0", "1", "2", "3", "4", "5",
      }
      local module_styles = { "lua", "luals", "lua_ls", "js", "ts", "c", "cpp", "generic" }

      local function filter(cands)
        local out = {}
        for _, c in ipairs(cands) do
          if c:sub(1, #arg_lead) == arg_lead then
            out[#out + 1] = c
          end
        end
        return out
      end

      -- Determine which argument position we are completing.
      local before = cmd_line:sub(1, cursor_pos)
      local toks = vim.split(vim.trim(before), "%s+", { trimempty = true })
      -- toks[1] == "Copy". When arg_lead is non-empty, its partial is the last token.
      local completed = (arg_lead ~= "") and (#toks - 2) or (#toks - 1)
      local sub = toks[2]

      if completed <= 0 then
        -- Completing the subcommand itself.
        return filter(subcommands)
      end

      if sub == "path" then
        -- Path options may appear in any order/repetition.
        return filter(path_options)
      elseif sub == "module" then
        -- Only the first argument after `module` is the style.
        if completed == 1 then
          return filter(module_styles)
        end
        return {}
      end

      return {}
    end,
    desc = "[Copy] Copy paths/module paths to clipboard with flexible options",
  })

  attach_keymap()
end

return M
