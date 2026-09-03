---@module 'bindings.usrcmds.bindings_explorer.search'
--- Statische Volltextsuche über die BINDINGS-Wurzeln — der Fallback, wenn
--- keine Live-Grep-Picker-Engine verfügbar ist (siehe `live.lua`, die
--- eigentlich bevorzugte Suche). Liest Dateien direkt und matched in
--- reinem Lua, wie casedesks `case.query.M.grep` — kein ripgrep-Aufruf,
--- keine externe Abhängigkeit nur für diesen Fallback.

local collect_recursive = require("lib.nvim.fs.collect_recursive")
local read = require("lib.nvim.fs.read")
local config = require("bindings.usrcmds.bindings_explorer.config")

local M = {}

---@class Bindings.Hit
---@field root string BINDINGS-Wurzel, unter der die Datei liegt
---@field path string absoluter Pfad
---@field line integer 1-basierte Zeilennummer
---@field text string getrimmter Zeileninhalt

---@param value string
---@param pattern string
---@return boolean
local function matches(value, pattern)
  return value:lower():find(pattern:lower(), 1, true) ~= nil
end

--- Eine Datei Zeile für Zeile gegen `pattern` halten.
---@param root string Wurzel, unter der die Datei liegt (siehe `Bindings.Hit`)
---@param path string
---@param pattern string
---@param hits Bindings.Hit[] wird in-place gefüllt
---@return nil
local function scan_file(root, path, pattern, hits)
  local content = read(path)
  if not content then
    return
  end
  local lineno = 0
  for line in (content:gsub("\r", "") .. "\n"):gmatch("([^\n]*)\n") do
    lineno = lineno + 1
    if matches(line, pattern) then
      hits[#hits + 1] = { root = root, path = path, line = lineno, text = vim.trim(line) }
    end
  end
end

--- Jede `.md`-Datei unter `roots` nach `pattern` durchsuchen
--- (case-insensitiver Substring, wie `case.query.M.grep`s Default).
---
--- Ein Eintrag in `roots` darf auch eine einzelne Datei sein: der
--- Plugin-Scope (`:Bindings search keymaps hover.nvim`, siehe `plugin.lua`)
--- löst sich zu Cheatsheet-Pfaden auf, und die gehen hier durch dieselbe
--- Liste wie ein Verzeichnis — genau wie bei `live.lua`, wo ripgrep Dateien
--- und Verzeichnisse ebenfalls in derselben Position nimmt. Der `root` eines
--- solchen Treffers ist das Verzeichnis der Datei; das Feld beschreibt, wo
--- die Datei liegt, und nicht, was der Aufrufer übergeben hat.
---@param pattern string
---@param roots string[]|nil nil = beide vollen BINDINGS-Wurzeln
---@return Bindings.Hit[]
function M.search(pattern, roots)
  local hits = {}
  if not pattern or pattern == "" then
    return hits
  end

  for _, root in ipairs(roots or config.roots()) do
    if vim.fn.isdirectory(root) == 1 then
      for _, f in ipairs(collect_recursive.files(root)) do
        if f:match("%.md$") then
          scan_file(root, f, pattern, hits)
        end
      end
    elseif vim.fn.filereadable(root) == 1 then
      scan_file(vim.fs.dirname(root), root, pattern, hits)
    end
  end

  return hits
end

return M
