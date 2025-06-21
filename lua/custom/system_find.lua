---@module 'custom.system_find'
---@brief Systemweite Datei-Suche über fd + Telescope
---@description
--- Führt eine systemweite Datei-Suche mit optionalem Filter (Name, Endung, Pfad) aus.
--- Nutzt `fd` oder `fdfind` in Kombination mit Telescope.
---
--- Eingabe kann z. B. sein:
---   `init.lua`
---   `/etc/init.lua`
---   `/home/*nvim.lua`
---   `log /var/log`
---   `rc .conf /etc`
---
--- Alles wird in einen fd-Befehl übersetzt und mit Telescope angezeigt.

local M = {}

---Startet eine systemweite Datei-Suche mit fd
---@return nil
function M.system_find()
  local builtin = require("telescope.builtin")
  local input_opts = { prompt = "Suchbegriff(e) (Name .ext Pfad...): " }

  vim.ui.input(input_opts, function(input)
    if not input or input == "" then return end

    -- Prüfe auf verfügbares fd
    local fd_exec = vim.fn.executable("fd") == 1 and "fd"
        or (vim.fn.executable("fdfind") == 1 and "fdfind" or nil)
    if not fd_exec then
      vim.notify("Weder 'fd' noch 'fdfind' gefunden", vim.log.levels.ERROR)
      return
    end

    -- Eingabe in Tokens splitten
    local args = {}
    for word in input:gmatch("%S+") do
      table.insert(args, word)
    end

    local name = nil
    local extension = nil
    local paths = {}

    for _, token in ipairs(args) do
      if token:match("^%.[%w]+$") then
        extension = token:sub(2)
      elseif token:match("^/") then
        table.insert(paths, token)
      elseif not name then
        name = token
      end
    end

    -- Fallback: wenn keine Pfade → Standardpfade
    if #paths == 0 then
      paths = { "/etc", "/usr", "/home", "/media/steve" }
    end

    -- fd-Befehl aufbauen
    local fd_cmd = { fd_exec }
    if name then
      table.insert(fd_cmd, name)
    end
    vim.list_extend(fd_cmd, paths)

    if extension then
      table.insert(fd_cmd, "--extension")
      table.insert(fd_cmd, extension)
    end

    builtin.find_files({
      prompt_title = "Systemweite Dateisuche",
      find_command = fd_cmd,
    })
  end)
end

vim.api.nvim_create_user_command("FindOnSystem", function()
  require("custom.system_find").system_find()
end, {
  desc = "Systemweite Dateisuche (fd + telescope)",
  nargs = "*", -- Verhindert "Trailing characters"-Fehler
})

return M
