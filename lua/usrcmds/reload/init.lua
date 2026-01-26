---@module 'usrcmds.reload'
-- User Command zum Neuladen des aktuellen Lua-Moduls
-- Fügen Sie dies zu Ihrer init.lua oder einem separaten Modul hinzu

local notify = require("lib.notify").create("[usrcmds.reload]")

local M = {}

-- Hilfsfunktion: Konvertiert Dateipfad zu Modulnamen
local function path_to_module(filepath)
  -- Normalisiere den Pfad
  filepath = vim.fn.fnamemodify(filepath, ':p')

  -- Finde alle möglichen Lua-Verzeichnisse im runtimepath
  local lua_paths = {}
  for _, path in ipairs(vim.api.nvim_list_runtime_paths()) do
    table.insert(lua_paths, path .. '/lua/')
  end

  -- Versuche, das lua/ Verzeichnis im Pfad zu finden
  local module_path = nil
  for _, lua_path in ipairs(lua_paths) do
    if filepath:sub(1, #lua_path) == lua_path then
      module_path = filepath:sub(#lua_path + 1)
      break
    end
  end

  -- Falls nicht in einem lua/ Verzeichnis, versuche andere Strategien
  if not module_path then
    -- Versuche, 'lua/' im Pfad zu finden
    local lua_index = filepath:find('/lua/')
    if lua_index then
      module_path = filepath:sub(lua_index + 5)
    else
      return nil, "Datei ist nicht in einem 'lua/' Verzeichnis"
    end
  end

  -- Entferne .lua Endung
  if module_path:match('%.lua$') then
    module_path = module_path:gsub('%.lua$', '')
  end

  -- Konvertiere Pfad zu Modulnotation (/ zu .)
  local module_name = module_path:gsub('/', '.')

  -- Behandle init.lua Dateien
  if module_name:match('%.init$') then
    module_name = module_name:gsub('%.init$', '')
  end

  return module_name
end

-- Hilfsfunktion: Reload eines Moduls
local function reload_module(module_name)
  -- Cache zurücksetzen
  package.loaded[module_name] = nil

  -- Vim.loader Cache für diese Datei zurücksetzen
  if vim.loader then
    local filepath = vim.api.nvim_buf_get_name(0)
    pcall(vim.loader.reset, filepath)
  end

  -- Modul neu laden
  local ok, result = pcall(require, module_name)

  return ok, result
end

-- Hauptfunktion für den User Command
local function reload_current_module()
  local filepath = vim.api.nvim_buf_get_name(0)

  -- Überprüfe, ob es eine Lua-Datei ist
  if not filepath:match('%.lua$') then
    notify.warn('Current buffer is not a Lua file')
    return
  end

  -- Konvertiere Pfad zu Modulnamen
  local module_name, err = path_to_module(filepath)

  if not module_name then
    notify.error('Could not determine module name: ' .. (err or 'unknown error'))
    return
  end

  -- Zeige, welches Modul geladen wird
  vim.notify('Reloading module: ' .. module_name, vim.log.levels.INFO)

  -- Reload das Modul
  local ok, result = reload_module(module_name)

  if ok then
    notify.info('✓ Module reloaded successfully: ' .. module_name)
    return result
  else
    notify.error('✗ Error reloading module: ' .. tostring(result))
  end
end


function M.enable()
vim.api.nvim_create_user_command('ReloadCurrentModule', reload_current_module, {
  desc = 'Reload the Lua module of the current buffer',
})
end

-- Optional: Keymap für schnellen Zugriff

-- vim.keymap.set('n', '<leader>lm', ':ReloadCurrentModule<CR>', {
  -- desc = 'Reload current Lua module',
  -- silent = true,
-- })

-- Optional: AutoCommand zum automatischen Reload beim Speichern
-- Kommentieren Sie dies aus, wenn Sie es nutzen möchten
--[[
vim.api.nvim_create_autocmd('BufWritePost', {
  pattern = '*.lua',
  callback = function()
    -- Nur für Dateien in lua/ Verzeichnissen
    local filepath = vim.api.nvim_buf_get_name(0)
    if filepath:match('/lua/') then
      reload_current_module()
    end
  end,
  desc = 'Auto-reload Lua modules on save',
})
--]]

return M
