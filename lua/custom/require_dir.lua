--- Lädt alle Lua-Dateien in einem Verzeichnis und ruft `.setup()` auf, falls vorhanden.
-- @param dir string Pfad relativ zu `lua/`, z. B. "custom"
-- @return nil
return function(dir)
  local path = vim.fn.stdpath("config") .. "/lua/" .. dir
  local files = vim.fn.glob(path .. "/*.lua", true, true)

  for _, file in ipairs(files) do
    local name = vim.fn.fnamemodify(file, ":t:r")
    local module_name = dir .. "." .. name
    local ok, mod = pcall(require, module_name)

    if not ok then
      vim.notify("Fehler beim Laden von " .. module_name .. ": " .. mod, vim.log.levels.WARN)
    elseif type(mod) == "table" and type(mod.setup) == "function" then
      local ok_setup, err = pcall(mod.setup, {})
      if not ok_setup then
        vim.notify("Fehler beim Setup von " .. module_name .. ": " .. err, vim.log.levels.WARN)
      end
    end
  end
end
