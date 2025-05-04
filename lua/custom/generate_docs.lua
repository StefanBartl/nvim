--[[
generate_docs.lua
Hilfsskript zur Generierung einer API-Dokumentation mit ldoc für Lua-Projekte.
Funktionen:
- Erstellt ldoc_config.ld, falls nicht vorhanden
- Führt ldoc aus (Markdown oder HTML)
- Zeigt HTML-Doku automatisch im Browser
- Bietet Clean-Funktion zum Löschen generierter Dokumentation
]]

local M = {}

--- Öffnet die HTML-Dokumentation im Standardbrowser, wenn sie existiert.
-- Unterstützt `xdg-open` (Linux) und `open` (macOS).
-- Wird nur verwendet, wenn `format = "html"` angegeben wurde.
local function open_in_browser()
  local html_path = "docs/api/index.html"
  if vim.fn.filereadable(html_path) == 1 then
    if vim.fn.executable("xdg-open") == 1 then
      os.execute("xdg-open " .. html_path)
    elseif vim.fn.executable("open") == 1 then
      os.execute("open " .. html_path) -- macOS
    else
      print("Kein unterstützter Befehl zum Öffnen eines Browsers gefunden.")
    end
  else
    print("HTML-Dokumentation nicht gefunden unter: " .. html_path)
  end
end

--- Hauptfunktion zur Initialisierung und Dokumentationserstellung
-- @param fargs string[] Argumente über Neovim-Command
--   - [1] Format: "markdown" (Standard) oder "html"
--   - [2] Projektpfad: wird zur Erkennung des Projektnamens verwendet
function M.init(fargs)
  local config_filename = "ldoc_config.ld"
  local config_file = io.open(config_filename, "r")

  local format = fargs[1] or "markdown"
  local project_dir = fargs[2] or vim.fn.getcwd()
  local project_name = project_dir:gsub("/+$", ""):match("([^/]+)$")

  -- Konfigurationsinhalt vorbereiten
  local default_config = string.format([[
project = "%s"
title = "%s – API Dokumentation"
description = "Dokumentation der internen Lua-API des Neovim-Plugins '%s'"
file = "README.md"
format = "%s"
dir = "docs/api"
all = true
examples = {
  "lua/%s",
}
boilerplate = false
]], project_name, project_name, project_name, format, project_name)

  -- Konfigurationsdatei erzeugen, falls sie fehlt
  if not config_file then
    print("Keine ldoc_config.ld gefunden. Erstelle Standardkonfiguration...")
    local f = io.open(config_filename, "w")
    if f then
      f:write(default_config)
      f:close()
      print("ldoc_config.ld wurde erstellt.")
    else
      print("Fehler: Konnte ldoc_config.ld nicht schreiben.")
      return
    end
  else
    config_file:close()
    print("ldoc_config.ld bereits vorhanden.")
  end

  -- ldoc ausführen
  print("Führe ldoc aus...")
  local success = os.execute("ldoc . --config ldoc_config.ld")
  if success == true or success == 0 then
    print("Dokumentation erfolgreich erstellt.")
    if format == "html" then
      open_in_browser()
    end
  else
    print("Fehler beim Erzeugen der Dokumentation.")
  end
end

--- Führt nur ldoc aus, ohne ldoc_config.ld zu erzeugen
-- Erwartet, dass die Datei `ldoc_config.ld` bereits existiert.
function M.generate()
  print("Führe ldoc aus...")
  local success = os.execute("ldoc . --config ldoc_config.ld")
  if success == true or success == 0 then
    print("Dokumentation erfolgreich erstellt.")
    open_in_browser()
  else
    print("Fehler beim Erzeugen der Dokumentation.")
  end
end

--- Löscht die generierte Dokumentation im Ordner `docs/api`
-- Dies betrifft nur den Ausgabeordner, nicht die Konfiguration.
function M.clean()
  print("Lösche Dokumentation: docs/api ...")
  os.execute("rm -rf docs/api")
  print("Dokumentation gelöscht.")
end

vim.api.nvim_create_user_command("DocBuild", function(opts)
  require("custom.generate_docs").init(opts.fargs)
end, {
  nargs = "*",
  desc = "Generiert ldoc_config.ld, baut Doku und öffnet sie im Browser (falls HTML)",
})

vim.api.nvim_create_user_command("DocGenerate", function()
  require("custom.generate_docs").generate()
end, {
  desc = "Baut ldoc-Doku basierend auf existierender Konfiguration",
})

vim.api.nvim_create_user_command("DocClean", function()
  require("custom.generate_docs").clean()
end, {
  desc = "Löscht die generierte API-Dokumentation (docs/api)",
})

return M

