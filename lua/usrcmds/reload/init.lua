---@module 'usrcmds.reload'
---@brief Enhanced module reloading with resource cleanup
---@description
--- Smart Lua module reloading with automatic cleanup of:
--- - Keymaps (buffer-local and global)
--- - User commands
--- - Autocommands (via augroup deletion)
--- - Optional setup/enable function invocation
---
--- Features:
--- - Deep reload (submodules)
--- - Reverse reload (parents)
--- - Pattern reload
--- - Resource cleanup before re-registration
--- - Safe error handling with pcall
--- - Detailed feedback via notifications
---
--- Usage:
---   :ReloadCurrentModule         -- Simple reload
---   :ReloadCurrentModuleDeep     -- + submodules
---   :ReloadCurrentModuleReverse  -- + parents
---   :ReloadCurrentModuleFull     -- Everything
---   :ReloadModulePattern <pat>   -- Pattern-based
---
--- API:
---   local reload = require("usrcmds.reload")
---   reload.reload_current({ deep = true, cleanup = true, setup_fn = "setup" })

local M = {}

-- Dependencies
local uv = vim.uv or vim.loop
local api = vim.api
local notify_lib = require("lib.notify")
local safe_call = require("lib.safe_call").safe_call

-- Create prefixed notifier
local notify = notify_lib.create("[reload]")

-- Module state tracking
---@class ReloadState
---@field registered_augroups table<string, string[]> Module -> augroup names
---@field registered_commands table<string, string[]> Module -> command names
---@field registered_keymaps table<string, table[]> Module -> keymap specs
local state = {
  registered_augroups = {},
  registered_commands = {},
  registered_keymaps = {},
}

-- ============================================================================
-- Path and Module Name Resolution
-- ============================================================================

--- Get absolute path of current buffer
---@return string|uv.uv_fs_t|nil
local function get_buf_realpath()
  local bufpath = vim.fn.expand("%:p")
  if bufpath == "" then return nil end

  local ok, real = pcall(uv.fs_realpath, bufpath)
  if ok and real and real ~= vim.NIL then
    return real
  end
  return bufpath
end

--- Compute module name from file path using package.path patterns
---@param filepath string
---@return string|nil
local function module_from_package_path(filepath)
  for pattern in string.gmatch(package.path, "[^;]+") do
    local prefix = pattern:match("^(.-)%?")
    if prefix then
      local norm_prefix = prefix:gsub("\\", "/")
      local norm_path = filepath:gsub("\\", "/")

      if norm_path:sub(1, #norm_prefix) == norm_prefix then
        local rel = norm_path:sub(#norm_prefix + 1)
        if rel:sub(1, 1) == "/" then
          rel = rel:sub(2)
        end

        rel = rel:gsub("%.lua$", "")
        rel = rel:gsub("/init$", "")
        local mod = rel:gsub("/", ".")

        if mod ~= "" then
          return mod
        end
      end
    end
  end
  return nil
end

--- Fallback: compute module name from lua/ directory
---@param filepath string
---@return string|nil
local function module_from_lua_dir(filepath)
  local norm = filepath:gsub("\\", "/")
  local idx = norm:find("/lua/")

  if not idx then
    idx = norm:find("^lua/")
  end

  if not idx then return nil end

  local start = idx + (norm:sub(idx, idx + 3) == "/lua" and 5 or 4)
  local rel = norm:sub(start)

  if rel == "" then return nil end

  rel = rel:gsub("%.lua$", "")
  rel = rel:gsub("/init$", "")
  local mod = rel:gsub("/", ".")

  if mod ~= "" then
    return mod
  end
  return nil
end

--- Get module name from current buffer
---@return string|nil
local function get_current_module_name()
  local filepath = get_buf_realpath()
  if not filepath then return nil end

  local mod = module_from_package_path(tostring(filepath))
  if not mod then
    mod = module_from_lua_dir(tostring(filepath))
  end

  return mod
end

-- ============================================================================
-- Module Dependency Resolution
-- ============================================================================

--- Get all loaded modules matching a pattern
---@param pattern string Lua pattern
---@return string[]
local function get_loaded_modules_matching(pattern)
  local matches = {}
  for modname, _ in pairs(package.loaded) do
    if type(modname) == "string" and modname:match(pattern) then
      table.insert(matches, modname)
    end
  end
  table.sort(matches)
  return matches
end

--- Get all submodules of a module
---@param base_module string
---@return string[]
local function get_submodules(base_module)
  local pattern = "^" .. base_module:gsub("%.", "%%.") .. "%."
  return get_loaded_modules_matching(pattern)
end

--- Get all parent modules
---@param modname string
---@return string[]
local function get_parent_modules(modname)
  local parents = {}
  local parts = vim.split(modname, ".", { plain = true })

  for i = 1, #parts - 1 do
    local parent = table.concat(vim.list_slice(parts, 1, i), ".")
    table.insert(parents, parent)
  end

  return parents
end

-- ============================================================================
-- Resource Cleanup
-- ============================================================================

--- Delete all autocommands in augroups registered by module
---@param modname string
local function cleanup_augroups(modname)
  local augroups = state.registered_augroups[modname] or {}

  for _, augroup in ipairs(augroups) do
    pcall(api.nvim_del_augroup_by_name, augroup)
  end

  state.registered_augroups[modname] = nil
end

--- Delete all user commands registered by module
---@param modname string
local function cleanup_commands(modname)
  local commands = state.registered_commands[modname] or {}

  for _, cmd in ipairs(commands) do
    pcall(api.nvim_del_user_command, cmd)
  end
  state.registered_commands[modname] = nil
end

--- Delete all keymaps registered by module
---@param modname string
local function cleanup_keymaps(modname)
  local keymaps = state.registered_keymaps[modname] or {}

  for _, km in ipairs(keymaps) do
    for _, mode in ipairs(km.modes) do
      pcall(vim.keymap.del, mode, km.lhs, { buffer = km.buffer })
    end
  end

  state.registered_keymaps[modname] = nil
end

--- Cleanup all resources for a module
---@param modname string
local function cleanup_module_resources(modname)
  cleanup_augroups(modname)
  cleanup_commands(modname)
  cleanup_keymaps(modname)
end

-- ============================================================================
-- Module Reloading
-- ============================================================================

--- Unload and reload a single module
---@param modname string
---@param opts table
---@return boolean success, string|nil error
local function unload_module(modname, opts)
  -- Cleanup resources if requested
  if opts.cleanup then
    cleanup_module_resources(modname)
  end

  -- Unload from package.loaded
  package.loaded[modname] = nil

  -- Reload module
  local result = safe_call(require, modname)

  if not result.ok then
    return false, tostring(result.err)
  end

  local mod = result.result

  -- Call setup function if requested and not "_"
  if opts.setup_fn and opts.setup_fn ~= "_" and type(mod) == "table" then
    local setup_fn = mod[opts.setup_fn]

    if type(setup_fn) == "function" then
      local setup_result = safe_call(setup_fn, mod, opts.setup_args or {})

      if not setup_result.ok then
        return false, string.format("Setup failed: %s", setup_result.err)
      end
    end
  end

  return true, nil
end

--- Reload multiple modules
---@param modules string[]
---@param opts UsrCmds.Reload.Opts
---@return UsrCmds.Reload.Result
local function reload_modules(modules, opts)
  local result = {
    success = true,
    reloaded = {},
    failed = {},
    skipped = {},
  }

  for _, modname in ipairs(modules) do
    if not opts.force and not package.loaded[modname] then
      table.insert(result.skipped, modname)
    else
      local ok, err = unload_module(modname, opts)

      if ok then
        table.insert(result.reloaded, modname)
      else
        result.failed[modname] = err
        result.success = false
      end
    end
  end

  return result
end

-- ============================================================================
-- Result Formatting
-- ============================================================================

--- Format reload result for notification
---@param result UsrCmds.Reload.Result
---@return string message, integer level
local function format_result(result)
  local lines = {}

  if #result.reloaded > 0 then
    table.insert(lines, string.format("✓ Reloaded %d module(s):", #result.reloaded))
    for _, mod in ipairs(result.reloaded) do
      table.insert(lines, "  • " .. mod)
    end
  end

  if #result.skipped > 0 then
    table.insert(lines, string.format("⊘ Skipped %d module(s) (not loaded):", #result.skipped))
    for _, mod in ipairs(result.skipped) do
      table.insert(lines, "  • " .. mod)
    end
  end

  local level = vim.log.levels.INFO

  if not vim.tbl_isempty(result.failed) then
    level = vim.log.levels.ERROR
    table.insert(lines, string.format("✗ Failed to reload %d module(s):", vim.tbl_count(result.failed)))
    for mod, err in pairs(result.failed) do
      table.insert(lines, string.format("  • %s: %s", mod, err))
    end
  end

  return table.concat(lines, "\n"), level
end

-- ============================================================================
-- Public API
-- ============================================================================

--- Reload current module
---@param opts UsrCmds.Reload.Opts|nil
---@return UsrCmds.Reload.Result|nil
function M.reload_current(opts)
  opts = vim.tbl_extend("force", {
    deep = false,
    reverse = false,
    notify = true,
    force = false,
    cleanup = true,
    setup_fn = nil, -- Auto-detect: "setup", "enable", "init", or nil/"_" for none
  }, opts or {})

  local modname = get_current_module_name()

  if not modname then
    if opts.notify then
      notify.warn("Could not determine module name from current buffer")
    end
    return nil
  end

  local modules = { modname }

  -- Add submodules if deep reload
  if opts.deep then
    local subs = get_submodules(modname)
    vim.list_extend(modules, subs)
  end

  -- Add parent modules if reverse reload
  if opts.reverse then
    local parents = get_parent_modules(modname)
    -- Reload parents in reverse order (top-level first)
    for i = #parents, 1, -1 do
      table.insert(modules, 1, parents[i])
    end
  end

  local result = reload_modules(modules, opts)

  if opts.notify then
    local msg, level = format_result(result)
    vim.notify(msg, level)
  end

  return result
end

--- Reload modules matching pattern
---@param pattern string
---@param opts UsrCmds.Reload.Opts|nil
---@return UsrCmds.Reload.Result
function M.reload_pattern(pattern, opts)
  opts = vim.tbl_extend("force", {
    notify = true,
    force = false,
    cleanup = true,
    setup_fn = nil,
  }, opts or {})

  local modules = get_loaded_modules_matching(pattern)

  if #modules == 0 then
    if opts.notify then
      notify.warn(string.format("No loaded modules match pattern: %s", pattern))
    end
    return {
      success = false,
      reloaded = {},
      failed = {},
      skipped = {},
    }
  end

  local result = reload_modules(modules, opts)

  if opts.notify then
    local msg, level = format_result(result)
    vim.notify(string.format("Pattern: %s\n%s", pattern, msg), level)
  end

  return result
end

-- ============================================================================
-- Resource Registration Tracking (for modules to use)
-- ============================================================================

--- Register an augroup for cleanup tracking
---@param modname string
---@param augroup string
function M.track_augroup(modname, augroup)
  if not state.registered_augroups[modname] then
    state.registered_augroups[modname] = {}
  end
  table.insert(state.registered_augroups[modname], augroup)
end

--- Register a user command for cleanup tracking
---@param modname string
---@param command string
function M.track_command(modname, command)
  if not state.registered_commands[modname] then
    state.registered_commands[modname] = {}
  end
  table.insert(state.registered_commands[modname], command)
end

--- Register a keymap for cleanup tracking
---@param modname string
---@param modes string|string[]
---@param lhs string
---@param buffer integer|nil
function M.track_keymap(modname, modes, lhs, buffer)
  if not state.registered_keymaps[modname] then
    state.registered_keymaps[modname] = {}
  end

  if type(modes) == "string" then
    modes = { modes }
  end

  table.insert(state.registered_keymaps[modname], {
    modes = modes,
    lhs = lhs,
    buffer = buffer,
  })
end

--- Helper to create tracked augroup with autocmds
---@param modname string Module name for tracking
---@param augroup string Augroup name
---@param autocmds table[] Array of autocmd specs: {event, opts}
function M.create_tracked_augroup(modname, augroup, autocmds)
  -- Create augroup
  local id = api.nvim_create_augroup(augroup, { clear = true })

  -- Track it
  M.track_augroup(modname, augroup)

  -- Create autocmds
  for _, ac in ipairs(autocmds) do
    api.nvim_create_autocmd(ac.event, vim.tbl_extend("force", ac.opts or {}, {
      group = id,
    }))
  end

  return id
end

--- Helper to create tracked user command
---@param modname string Module name for tracking
---@param name string Command name
---@param command function|string Command implementation
---@param opts table|nil Command options
function M.create_tracked_command(modname, name, command, opts)
  -- Track it
  M.track_command(modname, name)

  -- Create command
  api.nvim_create_user_command(name, command, opts or {})
end

--- Helper to create tracked keymap
---@param modname string Module name for tracking
---@param modes string|string[] Mode(s)
---@param lhs string Left-hand side
---@param rhs string|function Right-hand side
---@param opts table|nil Keymap options
function M.create_tracked_keymap(modname, modes, lhs, rhs, opts)
  opts = opts or {}
  local buffer = opts.buffer

  -- Track it
  M.track_keymap(modname, modes, lhs, buffer)

  -- Create keymap
  vim.keymap.set(modes, lhs, rhs, opts)
end

-- ============================================================================
-- User Commands
-- ============================================================================

--- Create user commands
function M.enable()
  -- Simple reload
  api.nvim_create_user_command("ReloadCurrentModule", function()
    M.reload_current({ deep = false, reverse = false })
  end, {
    desc = "[reload] Reload current module only",
  })

  -- Deep reload
  api.nvim_create_user_command("ReloadCurrentModuleDeep", function()
    M.reload_current({ deep = true, reverse = false })
  end, {
    desc = "[reload] Reload current module and all submodules",
  })

  -- Reverse reload
  api.nvim_create_user_command("ReloadCurrentModuleReverse", function()
    M.reload_current({ deep = false, reverse = true })
  end, {
    desc = "[reload] Reload current module and parent modules",
  })

  -- Full reload
  api.nvim_create_user_command("ReloadCurrentModuleFull", function()
    M.reload_current({ deep = true, reverse = true })
  end, {
    desc = "[reload] Reload current module, parents, and submodules",
  })

  -- Pattern reload
  api.nvim_create_user_command("ReloadModulePattern", function(opts)
    if not opts.args or opts.args == "" then
      notify.error("Usage: :ReloadModulePattern <pattern>")
      return
    end
    M.reload_pattern(opts.args)
  end, {
    nargs = 1,
    desc = "[reload] Reload all modules matching pattern",
    complete = function(_, _, _)
      local modules = {}
      for modname, _ in pairs(package.loaded) do
        if type(modname) == "string" then
          table.insert(modules, modname)
        end
      end
      table.sort(modules)
      return modules
    end,
  })

  -- List loaded modules
  api.nvim_create_user_command("ReloadListLoaded", function(opts)
    local pattern = opts.args ~= "" and opts.args or ".*"
    local modules = get_loaded_modules_matching(pattern)

    if #modules == 0 then
      notify.info("No modules loaded" .. (pattern ~= ".*" and " matching: " .. pattern or ""))
      return
    end

    notify.info(
      string.format("Loaded modules%s (%d):\n%s",
        pattern ~= ".*" and " matching '" .. pattern .. "'" or "",
        #modules,
        "  • " .. table.concat(modules, "\n  • ")
      )
    )
  end, {
    nargs = "?",
    desc = "[reload] List loaded modules (optionally filter by pattern)",
  })
end

return M
