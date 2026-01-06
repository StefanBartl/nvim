---@module 'usercmds.reload'
---@brief Enhanced module reloading with dependency tracking
---@description
--- Development helper: reload Lua modules with smart dependency handling.
---
--- Features:
--- - Single module reload (`:ReloadCurrentModule`)
--- - Deep reload (`:ReloadCurrentModuleDeep`) - reloads all submodules
--- - Pattern reload (`:ReloadModulePattern <pattern>`) - reload all matching modules
--- - Reverse reload (`:ReloadCurrentModuleReverse`) - reload parent modules
--- - Shows what was reloaded with detailed feedback
---
--- Use Cases:
--- - Edit `testmodul/keymaps.lua`, reload it and `testmodul` (parent)
--- - Edit any submodule, reload entire namespace with deep reload
--- - Development workflow without Neovim restarts
---
--- Notes:
--- - Deep reload helps when child modules changed but parent cached old version
--- - Reverse reload helps when current module changed but needs parent refresh
--- - Pattern reload useful for namespace-wide changes
---
local M = {}

local uv = vim.loop or vim.uv
local notify = vim.notify
local levels = vim.log.levels

--- Get absolute path of current buffer
---@return string|nil
local function get_buf_realpath()
  local bufpath = vim.fn.expand("%:p")
  if bufpath == "" then return nil end

  local ok, real = pcall(function()
    return uv.fs_realpath(bufpath)
  end)

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

  local mod = module_from_package_path(filepath)
  if not mod then
    mod = module_from_lua_dir(filepath)
  end

  return mod
end

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

--- Get all submodules of a module (e.g., testmodul.* for testmodul)
---@param base_module string
---@return string[]
local function get_submodules(base_module)
  local pattern = "^" .. base_module:gsub("%.", "%%.") .. "%."
  return get_loaded_modules_matching(pattern)
end

--- Get all parent modules (e.g., [testmodul, testmodul.foo] from testmodul.foo.bar)
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

--- Unload a single module
---@param modname string
---@return boolean success, string|nil error
local function unload_module(modname)
  package.loaded[modname] = nil

  local ok, res = pcall(require, modname)
  if ok then
    return true, nil
  else
    return false, tostring(res)
  end
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
      local ok, err = unload_module(modname)
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

  local level = levels.INFO
  if not vim.tbl_isempty(result.failed) then
    level = levels.ERROR
    table.insert(lines, string.format("✗ Failed to reload %d module(s):", vim.tbl_count(result.failed)))
    for mod, err in pairs(result.failed) do
      table.insert(lines, string.format("  • %s: %s", mod, err))
    end
  end

  return table.concat(lines, "\n"), level
end

--- Reload current module
---@param opts UsrCmds.Reload.Opts|nil
---@return UsrCmds.Reload.Result|nil
function M.reload_current(opts)
  opts = vim.tbl_extend("force", {
    deep = false,
    reverse = false,
    notify = true,
    force = false,
  }, opts or {})

  local modname = get_current_module_name()
  if not modname then
    if opts.notify then
      notify("Could not determine module name from current buffer", levels.WARN)
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
    notify(msg, level)
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
  }, opts or {})

  local modules = get_loaded_modules_matching(pattern)

  if #modules == 0 then
    if opts.notify then
      notify(string.format("No loaded modules match pattern: %s", pattern), levels.WARN)
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
    notify(string.format("Pattern: %s\n%s", pattern, msg), level)
  end

  return result
end

--- Create user commands
function M.enable()
  -- Simple reload
  vim.api.nvim_create_user_command("ReloadCurrentModule", function()
    M.reload_current({ deep = false, reverse = false })
  end, {
    desc = "[usrcmds.reload] Reload current module only",
  })

  -- Deep reload (includes submodules)
  vim.api.nvim_create_user_command("ReloadCurrentModuleDeep", function()
    M.reload_current({ deep = true, reverse = false })
  end, {
    desc = "[usrcmds.reload] Reload current module and all submodules",
  })

  -- Reverse reload (includes parents)
  vim.api.nvim_create_user_command("ReloadCurrentModuleReverse", function()
    M.reload_current({ deep = false, reverse = true })
  end, {
    desc = "[usrcmds.reload] Reload current module and parent modules",
  })

  -- Full reload (deep + reverse)
  vim.api.nvim_create_user_command("ReloadCurrentModuleFull", function()
    M.reload_current({ deep = true, reverse = true })
  end, {
    desc = "[usrcmds.reload] Reload current module, parents, and submodules",
  })

  -- Pattern reload
  vim.api.nvim_create_user_command("ReloadModulePattern", function(opts)
    if not opts.args or opts.args == "" then
      notify("Usage: :ReloadModulePattern <pattern>", levels.ERROR)
      return
    end
    M.reload_pattern(opts.args)
  end, {
    nargs = 1,
    desc = "[usrcmds.reload] Reload all modules matching pattern",
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
  vim.api.nvim_create_user_command("ReloadListLoaded", function(opts)
    local pattern = opts.args ~= "" and opts.args or ".*"
    local modules = get_loaded_modules_matching(pattern)

    if #modules == 0 then
      notify("No modules loaded" .. (pattern ~= ".*" and " matching: " .. pattern or ""), levels.INFO)
      return
    end

    notify(
      string.format("Loaded modules%s (%d):\n%s",
        pattern ~= ".*" and " matching '" .. pattern .. "'" or "",
        #modules,
        "  • " .. table.concat(modules, "\n  • ")
      ),
      levels.INFO
    )
  end, {
    nargs = "?",
    desc = "[usrcmds.reload] List loaded modules (optionally filter by pattern)",
  })
end

return M
