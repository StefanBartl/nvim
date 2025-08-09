---@module 'utils.require_dir'

--- Windows version
--- Loads all Lua modules in a directory and calls .setup() if present
--- @param dir string Relative to `lua/`, e.g. "autocmds"
return function(dir)
  local stdpath = vim.fn.stdpath("config")
  local full_dir = stdpath .. "/lua/" .. dir
  local files = vim.fn.glob(full_dir .. "/*.lua", true, true)

  if #files == 0 then
    vim.notify("No files found in " .. full_dir, vim.log.levels.WARN)
  end

  for _, file in ipairs(files) do
    -- Strip directory and extension to get module name
    local name = vim.fn.fnamemodify(file, ":t:r")
    local module_name = dir .. "." .. name

    local ok, mod = pcall(require, module_name)
    if not ok then
      vim.notify("Failed to require " .. module_name .. ": " .. mod, vim.log.levels.ERROR)
    elseif type(mod) == "table" and type(mod.setup) == "function" then
      local ok_setup, err = pcall(mod.setup, {})
      if not ok_setup then
        vim.notify("Setup error in " .. module_name .. ": " .. err, vim.log.levels.ERROR)
      end
    end
  end
end
