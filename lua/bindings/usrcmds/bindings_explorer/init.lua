---@module 'bindings.usrcmds.bindings_explorer'
--- `:Bindings` — Picker über die BINDINGS-Cheatsheets (docs/NOTES/
--- PersonelPlugins/BINDINGS + docs/NOTES/ExternPlugins/Bindings). Konzept:
--- docs/ROADMAP/personal/bindings-explorer.nvim.md.
---
--- Phase 1 (diese Datei): `:Bindings search [query]`, Volltextsuche. Phase 2
--- (Tabellenzeilen als Datensätze) und Phase 3 (Drift-Erkennung gegen
--- `nvim_get_keymap`/`nvim_get_commands`) sind im Konzept skizziert, noch
--- nicht gebaut.

local composer = require("lib.nvim.usercmd.composer")
local search = require("bindings.usrcmds.bindings_explorer.search")
local ui = require("bindings.usrcmds.bindings_explorer.ui")

local M = {}

--- Suche ausführen; ohne `query` wird interaktiv gefragt (`kit.input`,
--- nicht-blockierend).
---@param query string|nil
---@return nil
function M.search(query)
  if query and query ~= "" then
    ui.pick(search.search(query))
    return
  end

  require("lib.nvim.ui.kit.input").open({
    title = "Bindings durchsuchen",
    on_submit = function(line)
      if line == "" then return end
      ui.pick(search.search(line))
    end,
  })
end

---@return nil
function M.enable()
  composer.verb("Bindings", {
    desc = "Cheatsheets in docs/NOTES/{PersonelPlugins/BINDINGS,ExternPlugins/Bindings} durchsuchen",
    default = function()
      M.search(nil)
    end,
    routes = {
      {
        path = { "search" },
        args = { { name = "query", type = "STRING", optional = true } },
        desc = "Volltextsuche über beide BINDINGS-Bäume",
        run = function(ctx)
          M.search(ctx.args.query)
        end,
      },
    },
  })
end

return M
