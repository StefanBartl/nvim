---@module 'bindings.usrcmds.bindings_explorer.ui'
--- Picker-Verdrahtung für `:Bindings search` — `lib.nvim.ui.kit.select`,
--- nicht `pickers.nvim`: dessen `sources/*` sind Dateisystem-Source-Objekte
--- (cwd/folder/repos/drives), kein trivialer "Picker über diese Liste"-
--- Einstieg — siehe docs/ROADMAP/personal/bindings-explorer.nvim.md §3 für
--- die Begründung. `kit.select` ist derselbe Fallback, den images.nvim und
--- casedesk in genau dieser Lage auch nehmen.

local M = {}

---@return table notify-Handle aus lib.nvim
local function notify()
  return require("lib.nvim.notify").create("[bindings]")
end

--- Absoluten Pfad relativ zu `stdpath("config")` anzeigen — sonst wäre jede
--- Zeile im Picker mit dem immer gleichen langen Präfix überladen.
---@param path string
---@return string
local function display_path(path)
  local cfg = vim.fn.stdpath("config")
  if path:sub(1, #cfg) == cfg then return path:sub(#cfg + 2) end
  return path
end

--- Suchergebnisse als Picker anzeigen; `<CR>` öffnet die Datei an der
--- Fundstelle.
---@param hits Bindings.Hit[]
---@return nil
function M.pick(hits)
  if #hits == 0 then
    notify().warn("Keine Treffer")
    return
  end

  require("lib.nvim.ui.kit.select").open({
    items = hits,
    title = ("%d Treffer"):format(#hits),
    format_item = function(hit)
      return ("%s:%d: %s"):format(display_path(hit.path), hit.line, hit.text)
    end,
    on_select = function(hit)
      vim.cmd("edit " .. vim.fn.fnameescape(hit.path))
      vim.api.nvim_win_set_cursor(0, { hit.line, 0 })
      vim.cmd("normal! zz")
    end,
  })
end

return M
