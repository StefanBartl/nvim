---@module 'lib.require_dir'
--- Load all Lua modules in a given `lua/<dir>` directory.
--- Supports selective function invocation per module and safely skips
--- the calling module itself to avoid recursive self-loading.
---
--- Linux/macOS only; uses POSIX-style separators.

--[[
This utility loads all Lua modules located directly inside a given directory
under `lua/<dir>` and optionally invokes well-defined lifecycle functions
on each loaded module.

Key features:

1. Directory-based module loading
   All `*.lua` files inside `lua/<dir>` are required non-recursively.
   The module name is derived as `<dir>.<filename_without_extension>`.

2. Self-skip protection
   The module that calls `require_dir` is automatically skipped.
   This prevents infinite recursion in setups like:
     lua/lib/func.lua  -> require_dir("lib")
   where `lib.func` would otherwise re-require itself.

3. Optional function dispatch
   A second argument controls which functions are invoked on each module:
     - nil:
         Calls `setup({})` if present (default behavior).
     - string:
         Calls exactly that function name, e.g. "apply".
     - string[]:
         Calls all listed function names in order.
     - empty string (""):
         Calls nothing at all; modules are only required.

   Only functions that exist and are callable are invoked.
   Errors during require or function execution are reported via `vim.notify`.

4. Defensive execution
   All requires and function calls are wrapped in `pcall` to ensure
   robustness during startup and partial failures.

The function itself is exported directly (not wrapped in a table) to allow
simple re-export patterns.
]]--

local notify, levels = vim.notify, vim.log.levels

---@param dir string                       -- Relative to `lua/`, e.g. "autocmds" or "plugins/local"
---@param calls string|string[]|nil        -- Optional function(s) to call per module
---@return nil
return function(dir, calls)
  -- Normalize `dir` (strip leading/trailing slashes and trailing dots)
  dir = tostring(dir):gsub("^/*", ""):gsub("/*$", ""):gsub("%.+$", "")

  -- Resolve absolute path to the directory under the user's config `lua/`.
  local full_dir = vim.fn.stdpath("config") .. "/lua/" .. dir

  -- Determine the calling module to avoid self-require recursion.
  -- debug.getinfo(2) points to the direct caller of this function.
  local caller_src = debug.getinfo(2, "S")
  local caller_module = nil
  if caller_src and type(caller_src.source) == "string" then
    local src = caller_src.source:gsub("^@", "")
    if src:find("/lua/") then
      local rel = src:match("/lua/(.+)%.lua$")
      if rel then
        caller_module = rel:gsub("/", ".")
      end
    end
  end

  -- Normalize `calls` argument.
  ---@type string[]|nil
  local call_list = nil
  if type(calls) == "string" then
    if calls ~= "" then
      call_list = { calls }
    else
      call_list = {}
    end
  elseif type(calls) == "table" then
    call_list = calls
  end

  -- Find all .lua files within that directory (non-recursive).
  ---@type string[]
  local files = vim.fn.glob(full_dir .. "/*.lua", true, true)

  if #files == 0 then
    notify("[lib.require_dir] No files found in " .. full_dir, vim.log.levels.WARN)
    return
  end

  for _, file in ipairs(files) do
    local name = vim.fn.fnamemodify(file, ":t:r")

    -- Skip "init.lua" to avoid double-loading aggregators.
    if name ~= "init" then
      local module_name = dir .. "." .. name

      -- Skip the calling module itself to prevent recursion.
      if module_name ~= caller_module then
        local ok, mod = pcall(require, module_name)
        if not ok then
          notify(
            "[lib.require_dir] Failed to require " .. module_name .. ": " .. tostring(mod),
            levels.ERROR
          )
        else
          -- Function dispatch logic.
          if type(mod) == "table" then
            if call_list == nil then
              -- Default behavior: call setup({})
              if type(mod.setup) == "function" then
                local ok_setup, err = pcall(mod.setup, {})
                if not ok_setup then
                  notify(
                    "[lib.require_dir] Setup error in " .. module_name .. ": " .. tostring(err),
                    levels.ERROR
                  )
                end
              end
            else
              -- Explicit function list (possibly empty)
              for _, fn in ipairs(call_list) do
                if type(mod[fn]) == "function" then
                  local ok_call, err = pcall(mod[fn], mod)
                  if not ok_call then
                    notify(
                      "[lib.require_dir] Error calling " .. fn .. " in " .. module_name .. ": " .. tostring(err),
                      levels.ERROR
                    )
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end

