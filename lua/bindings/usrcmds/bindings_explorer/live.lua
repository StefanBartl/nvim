---@module 'bindings.usrcmds.bindings_explorer.live'
--- Live-Grep-in-Picker über `pickers.nvim`s **Engine**-Schicht
--- (`pickers.engines`, `M.live_grep(opts)`), nicht die `sources/*`-Schicht.
--- `sources/*` ist an konkrete Dateisystem-Quellen gebunden (cwd/folder/
--- repos/drives) und hat keinen generischen "Picker über diese
--- Verzeichnisliste"-Einstieg — genau die Einschränkung, die casedesks
--- eigene Prüfung von `pickers.nvim` schon für `actions/files.lua` notierte
--- (siehe dieses Moduls docs/FEATURES.md). Die
--- Engine-Schicht darunter ist dagegen bewusst generisch: `live_grep(opts)`
--- nimmt `opts.roots` als beliebige Verzeichnisliste, einheitlich über
--- telescope/fzf-lua/snacks hinweg — genau der fehlende Baustein.
---
--- Kein harter Fallback hier: wenn keine Engine (oder kein `ripgrep`)
--- verfügbar ist, meldet `M.open` das über den Rückgabewert, und der
--- Aufrufer (`init.lua`) wechselt auf die statische Phase-1-Suche
--- (`search.lua` + `ui.lua`s `kit.select`).

local M = {}

--- Live-Grep über `roots` öffnen.
---@param roots string[]
---@param opts { query: string|nil, prompt: string|nil }|nil
---@return boolean ok true, wenn eine Picker-Engine übernommen hat
function M.open(roots, opts)
  opts = opts or {}

  local ok, engines = pcall(require, "pickers.engines")
  if not ok then
    return false
  end

  local engine = engines.load()
  if not engine or type(engine.live_grep) ~= "function" then
    return false
  end

  engine.live_grep({
    roots = roots,
    prompt = opts.prompt or "Bindings",
    query = opts.query,
  })
  return true
end

return M
