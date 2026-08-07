---@module 'bindings.usrcmds.bindings_explorer.search'
--- Volltextsuche über beide BINDINGS-Bäume — Phase 1 aus
--- docs/ROADMAP/personal/bindings-explorer.nvim.md. Liest Dateien direkt
--- und matched in reinem Lua, wie casedesks `case.query.M.grep` — kein
--- ripgrep-Aufruf, keine externe Abhängigkeit nur für die Suche.

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

--- Jede `.md`-Datei unter beiden BINDINGS-Wurzeln nach `pattern` durchsuchen
--- (case-insensitiver Substring, wie `case.query.M.grep`s Default).
---@param pattern string
---@return Bindings.Hit[]
function M.search(pattern)
  local hits = {}
  if not pattern or pattern == "" then return hits end

  for _, root in ipairs(config.roots()) do
    if vim.fn.isdirectory(root) == 1 then
      for _, f in ipairs(collect_recursive.files(root)) do
        if f:match("%.md$") then
          local content = read(f)
          if content then
            local lineno = 0
            for line in (content:gsub("\r", "") .. "\n"):gmatch("([^\n]*)\n") do
              lineno = lineno + 1
              if matches(line, pattern) then
                hits[#hits + 1] = { root = root, path = f, line = lineno, text = vim.trim(line) }
              end
            end
          end
        end
      end
    end
  end

  return hits
end

return M
