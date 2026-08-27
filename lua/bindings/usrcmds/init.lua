---@module 'bindings.usrcmds'
-- Initialize module for 'bindings.usrcmds'

local usercmd = require("lib.nvim.bindings.usercmd")
local notify = require("lib.nvim.notify").create("[bindings.usrcmds]")

require("bindings.usrcmds.case").enable()
require("bindings.usrcmds.bindings_explorer").enable()
require("bindings.usrcmds.context_open").enable()
require("bindings.usrcmds.telemetry_nvim_config").enable()
require("bindings.usrcmds.autocmd_docs").enable()

usercmd.create('CopyLocation', function()
  -- Absoluter Pfad der aktuellen Datei
  local path = vim.fn.expand('%:p')

  -- Falls der Buffer noch nicht auf der Festplatte gespeichert ist
  if path == '' then
    notify.warn('Keine Datei geladen / kein Pfad vorhanden')
    return
  end

  -- Cursorposition holen (Zeile ist 1-basiert, Spalte ist 0-basiert)
  local cursor = vim.api.nvim_win_get_cursor(0)
  local line = cursor[1]
  local col = cursor[2] + 1 -- 1-basiert machen

  -- Text formatieren (Pfad:Zeile:Spalte)
  local result = string.format('%s:%d:%d', path, line, col)

  -- In das "+ Register (System-Zwischenablage) kopieren
  vim.fn.setreg('+', result)

  -- Rückmeldung anzeigen
  notify.info('Kopiert: ' .. result)
end, {
  desc = 'Kopiert absoluten Pfad, Zeile und Spalte in die Zwischenablage',
})


--TEMP: nur temporär (wahrscheinlich
local bindings_path = vim.fs.joinpath(vim.fn.stdpath("config"), "docs", "NOTES", "BINDINGS")
usercmd.create('BindingsPath', function()
  -- Kopiert den Pfad in das System-Register (+)
  vim.fn.setreg('+', bindings_path)
  notify.info('Bindings-Pfad in Zwischenablage kopiert!')
end, {
  desc = 'Kopiert den spezifischen Bindings-Pfad in die Zwischenablage',
})

-- 2. Keymap <leader>BI erstellen
-- Not vim.g.__map_helper: that global is only valid transiently, while
-- bindings.mappings' own setup() is running (it gets set to nil at the end
-- of that function) -- not a stable API for other modules to call into at
-- arbitrary load order. lib.nvim.bindings.keymap directly, like everywhere else.
require("lib.nvim.bindings.keymap")('n', '<leader>BI', '<cmd>BindingsPath<CR>', nil, 'Bindings-Pfad kopieren')

--FIX: Funktoinert, aber einen neotree/nvimtree/netrw reload muss ausgelöst werden damit dieser aktualisert das neue cwd in ihm.
usercmd.create("CwdHere", function()
  local bufname = vim.api.nvim_buf_get_name(0)
  if bufname ~= "" then
    local dir = vim.fn.fnamemodify(bufname, ":p:h")
    vim.cmd("lcd " .. vim.fn.fnameescape(dir))
  end
end, { force = true })

usercmd.create('PowershellProfile', function()
    if vim.fn.executable("powershell") ~= 1 then
        notify.error("Fehler: powershell ist auf diesem System nicht verfügbar.")
        return
    end
    -- argv array instead of io.popen with an embedded shell string
    local res = vim.system(
        { "powershell", "-NoProfile", "-Command", "[Console]::Write($PROFILE)" },
        { text = true }
    ):wait()
    local profile_path = res.code == 0 and res.stdout or nil

    if profile_path and profile_path ~= "" then
        vim.cmd('edit ' .. vim.fn.fnameescape(profile_path))
        return
    end
    notify.error("Fehler: Der PowerShell Profil-Pfad konnte nicht ermittelt werden.")
end, { desc = 'Öffnet das aktuelle PowerShell-Profil', force = true })
