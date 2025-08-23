---@module 'lib.require_dir'
--- Load all Lua modules in a given `lua/<dir>` directory and, if a module
--- returns a table with a `setup` function, call `setup({})`.
--- Exported value is the function itself (not a table), for easy re-export.
--- Linux/macOS only; uses POSIX-style separators.

---@param dir string  -- Relative to `lua/`, e.g. "autocmds" or "plugins/local"
---@return nil
return function(dir)
  -- Normalize `dir` (strip leading/trailing slashes and trailing dots)
  dir = tostring(dir):gsub("^/*", ""):gsub("/*$", ""):gsub("%.+$", "")

  -- Resolve absolute path to the directory under the user's config `lua/`.
  local full_dir = vim.fn.stdpath("config") .. "/lua/" .. dir

  -- Find all .lua files within that directory (non-recursive).
  -- Using Vimscript glob for broad compatibility.
  ---@type string[]
  local files = vim.fn.glob(full_dir .. "/*.lua", true, true)

  if #files == 0 then
    vim.notify("[lib.require_dir] No files found in " .. full_dir, vim.log.levels.WARN)
    return
  end

  for _, file in ipairs(files) do
    -- Derive module name: "<dir>.<basename_without_ext>"
    local name = vim.fn.fnamemodify(file, ":t:r")

    -- Skip "init.lua" by default to avoid double-loading aggregators.
    if name ~= "init" then
      local module_name = dir .. "." .. name

      -- Attempt to require the module.
      local ok, mod = pcall(require, module_name)
      if not ok then
        vim.notify("[lib.require_dir] Failed to require " .. module_name .. ": " .. tostring(mod), vim.log.levels.ERROR)
      else
        -- If module returns a table with `setup`, call it defensively.
        if type(mod) == "table" and type(mod.setup) == "function" then
          local ok_setup, err = pcall(mod.setup, {})
          if not ok_setup then
            vim.notify("[lib.require_dir] Setup error in " .. module_name .. ": " .. tostring(err), vim.log.levels.ERROR)
          end
        end
      end
    end
  end
end
