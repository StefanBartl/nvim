---@module 'custom.reload'
--- Utility to reload Lua modules from within a running Neovim session.
--- Provides the `:ReloadConfig` user-command which accepts zero or more module names.
--- Examples:
---   :ReloadConfig                      -- reloads 'custom' (the whole custom tree)
---   :ReloadConfig utils.help_sync      -- reloads only utils.help_sync
---   :ReloadConfig utils                -- reloads all package.loaded keys starting with "utils"

---@alias ReloadOpts table|nil

---@async
---@class ReloadModule
---@field reload fun(modname:string): (boolean, string|table) reload single module, returns ok, result_or_error
---@field reload_pattern fun(prefix:string): table reload multiple modules by prefix
---@field create_user_command fun(): nil create the :ReloadConfig command

local M = {}

--- Normalize a module name (trim and ensure string)
---@param name string
---@return string
local function normalize(name)
  return vim.trim(tostring(name or ""))
end

--- Reload a single module: clear cache and require it again.
--- Does NOT attempt to call any lifecycle functions (enable/setup/disable) on the module.
--- This is intentional to avoid guessing required arguments or side-effect semantics.
--- Returns boolean ok, and either the loaded module (on success) or error message (on failure).
---@param modname string
---@return boolean, table|string
function M.reload(modname)
  local name = normalize(modname)
  if name == "" then
    return false, "empty module name"
  end

  -- Remove cached module so require() reads the file again.
  package.loaded[name] = nil

  -- Protected require to catch errors during module execution.
  local ok, res = pcall(require, name)
  if not ok then
    return false, res
  end

  -- Return success and the module (no enable() invocation).
  return true, res
end

--- Reload all loaded modules whose package name starts with `prefix`.
--- Collects matching package.loaded keys first to avoid mutation-while-iterating issues.
--- Returns a list of tables { name = <module>, ok = <bool>, result = <module|error> }.
---@param prefix string
---@return table
function M.reload_pattern(prefix)
  local p = normalize(prefix)
  if p == "" then
    return {}
  end
  local results = {}

  -- Collect keys first
  local keys = {}
  for k, _ in pairs(package.loaded) do
    if type(k) == "string" and k:sub(1, #p) == p then
      table.insert(keys, k)
    end
  end

  -- Reload each collected key
  for _, k in ipairs(keys) do
    local ok, res = M.reload(k)
    table.insert(results, { name = k, ok = ok, result = res })
  end

  -- Attempt to reload the prefix itself (e.g. require("utils"))
  if not vim.tbl_isempty(keys) then
    local ok_root, res_root = M.reload(p)
    table.insert(results, { name = p, ok = ok_root, result = res_root })
  end

  return results
end

--- Create the user command :ReloadConfig
--- Usage:
---  :ReloadConfig                 -- reloads 'custom' (full)
---  :ReloadConfig utils.help_sync -- reloads that module
---  :ReloadConfig utils           -- reloads all package.loaded keys starting with "utils"
---@return nil
function M.create_user_command()
  vim.api.nvim_create_user_command("ReloadConfig", function(opts)
    local args = normalize(opts.args)

    -- No args: reload top-level 'custom'
    if args == "" then
      package.loaded["custom"] = nil
      local ok, res = pcall(require, "custom")
      if not ok then
        vim.notify("Failed to reload 'custom': " .. tostring(res), vim.log.levels.ERROR)
      else
        vim.notify("Reloaded 'custom' successfully", vim.log.levels.INFO)
      end
      return
    end

    -- Support multiple module names separated by whitespace
    local modules = {}
    for token in args:gmatch("%S+") do
      table.insert(modules, token)
    end

    for _, mod in ipairs(modules) do
      -- Decide whether to treat the token as a prefix (reload multiple) or single module
      local is_prefix = false
      local p = mod
      for k, _ in pairs(package.loaded) do
        if type(k) == "string" then
          if k == p or k:sub(1, #p + 1) == (p .. ".") then
            is_prefix = true
            break
          end
        end
      end

      if is_prefix then
        local results = M.reload_pattern(mod)
        for _, r in ipairs(results) do
          if r.ok then
            vim.notify(string.format("Reloaded %s", r.name), vim.log.levels.INFO)
          else
            vim.notify(string.format("Failed to reload %s: %s", r.name, tostring(r.result)), vim.log.levels.ERROR)
          end
        end
      else
        local ok, res = M.reload(mod)
        if ok then
          vim.notify(string.format("Reloaded %s", mod), vim.log.levels.INFO)
        else
          vim.notify(string.format("Failed to reload %s: %s", mod, tostring(res)), vim.log.levels.ERROR)
        end
      end
    end
  end, {
    nargs = "*",
    complete = function(ArgLead, _, _)
      local completions = {}
      local seen = {}
      for k, _ in pairs(package.loaded) do
        if type(k) == "string" and k:match("^" .. vim.pesc(ArgLead)) then
          if not seen[k] then
            table.insert(completions, k)
            seen[k] = true
          end
        end
      end
      table.sort(completions)
      return completions
    end,
    desc = "Reload specified Lua module(s) from the running Neovim session (no args => reload 'custom')",
  })
end

---@return nil
function M.enable()
  M.create_user_command()
end

---@package
---@type ReloadModule
return M
