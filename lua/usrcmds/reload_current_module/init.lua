---@module 'usercmds.reload_current_module'
--- Development helper: create a Neovim user command to reload the Lua module
--- corresponding to the file currently open in the active buffer.
---
--- Behavior:
--- 1. Resolve absolute path of the current buffer.
--- 2. Attempt to map the file path to a Lua module name by matching against
---    entries in package.path (patterns containing '?'), and as a fallback by
---    locating a "lua/" segment in the path.
--- 3. If a module name is found, set package.loaded[module_name] = nil and
---    attempt to require(module_name) again.
--- 4. Notify the user about success or error.
---
--- Notes:
--- - This helper uses a best-effort heuristic to compute the module name. It
---   covers common layouts like: "$X/.../lua/foo/bar.lua" -> "foo.bar"
---   and patterns from package.path like "/some/dir/?.lua".
--- - The command created is :ReloadCurrentModule
--- - The module implements safe checks and reports helpful messages via
---   notify so it is straightforward to use during plugin development.
--- - To make plugin setups idempotent, ensure plugin exposes a `setup()` that
---   can be re-run or that side-effects are cleaned up before re-registering.
---
local M = {}

local uv = vim.loop
local notify = vim.notify

-- Determine directory separator (platform-agnostic).
-- package.config first line contains directory separator (Lua convention).
-- local DIR_SEP = package.config:sub(1, 1)

--- Helper: get real absolute path for the current buffer
--- @return string|nil absolute path or nil if none
local function get_buf_realpath()
  -- Use expand('%:p') to get the buffer's absolute path (works across platforms).
  local bufpath = vim.fn.expand("%:p")
  if bufpath == "" then
    return nil
  end
  -- Prefer uv.fs_realpath to resolve symlinks; fall back to the expand result.
  local ok, real = pcall(function()
    ---@diagnostic disable-next-line lib.uv
    return uv.fs_realpath(bufpath)
  end)
  if ok and real and real ~= vim.NIL then
    return real
  end
  return bufpath
end

--- Try to compute a module name from a file path using package.path entries.
--- This handles entries like "/home/user/.local/share/nvim/site/pack/packer/start/?/init.lua"
--- or "/home/user/.config/nvim/lua/?.lua".
--- @param filepath string absolute filesystem path
--- @return string|nil module name or nil if not found
local function module_from_package_path(filepath)
  -- Iterate possible patterns from package.path (split by ';').
  for pattern in string.gmatch(package.path, "[^;]+") do
    -- Find the prefix up to the question mark.
    local prefix = pattern:match("^(.-)%?")
    if prefix then
      -- Normalize prefix: remove trailing pattern parts like "?.lua" but keep directories.
      -- Compare prefix with start of filepath.
      -- On Windows, package.path may contain backslashes; normalize both to forward slashes for comparison.
      local norm_prefix = prefix:gsub("\\", "/")
      local norm_path = filepath:gsub("\\", "/")
      if norm_path:sub(1, #norm_prefix) == norm_prefix then
        -- Relative path after the prefix
        local rel = norm_path:sub(#norm_prefix + 1)
        -- Remove leading slash if present
        if rel:sub(1, 1) == "/" then
          rel = rel:sub(2)
        end
        -- Remove trailing ".lua" if present
        rel = rel:gsub("%.lua$", "")
        -- Handle "init" modules: "foo/init" -> "foo"
        rel = rel:gsub("/init$", "")
        -- Replace directory separators with dots to form module name
        local mod = rel:gsub("/", ".")
        if mod ~= "" then
          return mod
        end
      end
    end
  end
  return nil
end

--- Fallback: attempt to compute module name by finding a "lua/" segment in the path.
--- E.g. "/home/user/.config/nvim/lua/my/plugin/init.lua" -> "my.plugin"
--- @param filepath string absolute filesystem path
--- @return string|nil module name or nil if not found
local function module_from_lua_dir(filepath)
  local norm = filepath:gsub("\\", "/")
  local idx = norm:find("/lua/")
  if not idx then
    -- Also allow paths that end with "/lua" (rare) or start with "lua/"
    idx = norm:find("^lua/")
  end
  if not idx then
    return nil
  end
  -- take substring after the "lua/" part
  local start = idx + (norm:sub(idx, idx + 3) == "/lua" and 5 or 4) -- handle "/lua/" vs "lua/"
  local rel = norm:sub(start)
  if rel == "" then
    return nil
  end
  rel = rel:gsub("%.lua$", "")
  rel = rel:gsub("/init$", "")
  local mod = rel:gsub("/", ".")
  if mod ~= "" then
    return mod
  end
  return nil
end

--- Unload and require a module, reporting status with notify.
--- @param modname string module name to reload
local function unload_and_require(modname)
  -- Clear the cache entry so require re-evaluates the module.
  package.loaded[modname] = nil

  -- Use pcall to avoid breaking the user's session on error.
  local ok, res = pcall(require, modname)
  if ok then
    notify(string.format("Reloaded module: %s", modname), vim.log.levels.INFO)
    return true, res
  else
    notify(string.format("Error reloading module '%s': %s", modname, res), vim.log.levels.ERROR)
    return false, res
  end
end

--- Core command implementation: derive module name for current buffer and reload it.
local function reload_current_buffer_module()
  local filepath = get_buf_realpath()
  if not filepath then
    notify("No file in current buffer to reload as module.", vim.log.levels.WARN)
    return
  end

  -- Attempt to compute module name via package.path heuristics.
  local mod = module_from_package_path(filepath)

  -- Fallback: search for "lua/" directory in the path.
  if not mod then
    mod = module_from_lua_dir(filepath)
  end

  if not mod or mod == "" then
    -- Last resort: attempt to transform the file path rootless (best-effort).
    -- Replace non-alphanumeric path chars with dots and strip ".lua"
    local attempt = filepath:gsub("\\", "/")
    -- try to find first occurrence of "/lua/" again with a more forgiving search
    local s = attempt:match(".*/lua/(.*)")
    if s then
      s = s:gsub("%.lua$", ""):gsub("/init$", ""):gsub("/+", ".")
      if s ~= "" then
        mod = s
      end
    end
  end

  if not mod or mod == "" then
    notify("Could not infer module name from path: " .. filepath, vim.log.levels.ERROR)
    return
  end

  -- Unload + require the module, reporting the outcome.
  unload_and_require(mod)
end

--- Create the user command :ReloadCurrentModule
--- The command is created if the module is required (so require('dev.reload_current') runs this).
function M.enable()
  vim.api.nvim_create_user_command("ReloadCurrentModule", function()
    reload_current_buffer_module()
  end, {
    desc = "[usrcmds] Reload the Lua module corresponding to the file in the current buffer (best-effort).",
  })
end

return M
