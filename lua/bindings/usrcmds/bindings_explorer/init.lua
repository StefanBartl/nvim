---@module 'bindings.usrcmds.bindings_explorer'
--- `:Bindings` — Picker über die BINDINGS-Cheatsheets (docs/NOTES/
--- PersonelPlugins/BINDINGS + docs/NOTES/ExternPlugins/Bindings). Doku:
--- docs/FEATURES.md (dieses Moduls), `:help bindings_explorer`. Der
--- ursprüngliche Konzept-Entwurf unter docs/ROADMAP/personal/
--- bindings-explorer.nvim.md wurde beim Aufräumen der Roadmap gelöscht
--- (Feature ist längst umgesetzt) — docs/FEATURES.md ist die aktuelle
--- Quelle, nicht dieser Pfad.
---
--- Phase 1 (diese Datei): `:Bindings search [query]`, Live-Grep-in-Picker
--- über `pickers.nvim`s Engine-Schicht (`live.lua`), mit einer statischen
--- Prompt+Liste-Suche als Fallback ohne Engine (`search.lua`/`ui.lua`).
--- `:Bindings search keymaps|usercmds|autocmds [query]` scopen dieselbe
--- Suche auf eine der drei Unterkategorien statt aller drei.
--- `:Bindings path [personal|extern]` kopiert die BINDINGS-Wurzel(n) in die
--- Zwischenablage — derselbe Zweck wie das bestehende `:BindingsPath`
--- (`lua/bindings/usrcmds/init.lua`), hier aber mit den tatsächlichen zwei
--- Wurzeln statt dessen einzelnem, nicht existierenden `docs/NOTES/
--- BINDINGS`-Pfad.
---
--- Phase 2 (diese Datei + `records.lua`/`browse.lua`): `:Bindings browse
--- [keymaps|usercmds|autocmds] [personal|extern]` — Picker über geparste
--- Tabellenzeilen statt Volltext, siehe `records.lua`s Scraper.
---
--- Phase 3 (diese Datei + `drift.lua`): `:Bindings check [plugin]` —
--- Drift-Bericht (dokumentiert-aber-nicht-live / live-aber-undokumentiert)
--- gegen `nvim_get_keymap`/`nvim_get_commands`, siehe `drift.lua`s
--- Moduldoc für den genauen (bewusst eingeschränkten) Scope.

local composer = require("lib.nvim.bindings.usercmd.composer")
local config = require("bindings.usrcmds.bindings_explorer.config")
local search = require("bindings.usrcmds.bindings_explorer.search")
local live = require("bindings.usrcmds.bindings_explorer.live")
local ui = require("bindings.usrcmds.bindings_explorer.ui")
local browse = require("bindings.usrcmds.bindings_explorer.browse")
local drift = require("bindings.usrcmds.bindings_explorer.drift")

local M = {}

---@return table notify-Handle aus lib.nvim
local function notify()
  return require("lib.nvim.notify").create("[bindings]")
end

--- Suche über `roots` ausführen. Versucht zuerst Live-Grep (`live.lua`);
--- nur ohne verfügbare Picker-Engine fällt es auf die statische
--- Prompt+Liste-Suche zurück (mit `kit.input`, wenn `query` fehlt).
---@param roots string[]
---@param query string|nil
---@param prompt string
---@return nil
local function search_scoped(roots, query, prompt)
  if live.open(roots, { query = query, prompt = prompt }) then
    return
  end

  if query and query ~= "" then
    ui.pick(search.search(query, roots))
    return
  end

  require("lib.nvim.ui.kit.input").open({
    title = prompt,
    on_submit = function(line)
      if line == "" then
        return
      end
      ui.pick(search.search(line, roots))
    end,
  })
end

--- Über beide BINDINGS-Bäume suchen.
---@param query string|nil
---@return nil
function M.search(query)
  search_scoped(config.roots(), query, "Bindings durchsuchen")
end

--- Auf eine Unterkategorie gescopte Suche.
---@param folder "Keymaps"|"Usercmds"|"Autocmds"
---@param query string|nil
---@return nil
function M.search_category(folder, query)
  search_scoped(config.roots_for(folder), query, "Bindings: " .. folder)
end

--- BINDINGS-Wurzel(n) in die Zwischenablage kopieren.
---@param scope "personal"|"extern"|nil nil = beide, newline-getrennt
---@return nil
function M.path(scope)
  local roots = config.roots()
  local text
  if scope == "personal" then
    text = roots[1]
  elseif scope == "extern" then
    text = roots[2]
  else
    text = table.concat(roots, "\n")
  end
  vim.fn.setreg("+", text)
  notify().info("Pfad(e) kopiert: " .. text)
end

--- Picker über geparste Tabellenzeilen (`records.lua`) statt Volltext.
---@param category ("Keymaps"|"Usercmds"|"Autocmds")|nil nil = alle drei
---@param scope ("personal"|"extern")|nil nil = beide
---@return nil
function M.browse(category, scope)
  browse.open(category, scope)
end

--- Drift-Bericht (`drift.lua`) in einem read-only Viewer anzeigen.
---@param plugin string|nil
---@return nil
function M.check(plugin)
  local findings, skipped, source_reason = drift.check(plugin)
  require("lib.nvim.ui.kit.viewer").open({
    title = ("Bindings — check (%d)"):format(#findings),
    lines = drift.describe(findings, skipped, source_reason),
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
        desc = "Live-Grep über beide BINDINGS-Bäume (Picker-Engine, sonst Prompt+Liste)",
        run = function(ctx)
          M.search(ctx.args.query)
        end,
      },
      {
        path = { "search", "keymaps" },
        args = { { name = "query", type = "STRING", optional = true } },
        desc = "Live-Grep, nur Keymaps-Cheatsheets",
        run = function(ctx)
          M.search_category("Keymaps", ctx.args.query)
        end,
      },
      {
        path = { "search", "usercmds" },
        args = { { name = "query", type = "STRING", optional = true } },
        desc = "Live-Grep, nur Usercmds-Cheatsheets",
        run = function(ctx)
          M.search_category("Usercmds", ctx.args.query)
        end,
      },
      {
        path = { "search", "autocmds" },
        args = { { name = "query", type = "STRING", optional = true } },
        desc = "Live-Grep, nur Autocmds-Cheatsheets",
        run = function(ctx)
          M.search_category("Autocmds", ctx.args.query)
        end,
      },
      {
        path = { "path" },
        args = {
          { name = "scope", type = "STRING", enum = { "personal", "extern" }, optional = true },
        },
        desc = "BINDINGS-Wurzel(n) in die Zwischenablage kopieren",
        run = function(ctx)
          M.path(ctx.args.scope)
        end,
      },
      {
        path = { "browse" },
        args = {
          { name = "scope", type = "STRING", enum = { "personal", "extern" }, optional = true },
        },
        desc = "Picker über alle Tabellenzeilen (Keymaps+Usercmds+Autocmds)",
        run = function(ctx)
          M.browse(nil, ctx.args.scope)
        end,
      },
      {
        path = { "browse", "keymaps" },
        args = {
          { name = "scope", type = "STRING", enum = { "personal", "extern" }, optional = true },
        },
        desc = "Picker über Keymaps-Tabellenzeilen",
        run = function(ctx)
          M.browse("Keymaps", ctx.args.scope)
        end,
      },
      {
        path = { "browse", "usercmds" },
        args = {
          { name = "scope", type = "STRING", enum = { "personal", "extern" }, optional = true },
        },
        desc = "Picker über Usercmds-Tabellenzeilen",
        run = function(ctx)
          M.browse("Usercmds", ctx.args.scope)
        end,
      },
      {
        path = { "browse", "autocmds" },
        args = {
          { name = "scope", type = "STRING", enum = { "personal", "extern" }, optional = true },
        },
        desc = "Picker über Autocmds-Tabellenzeilen",
        run = function(ctx)
          M.browse("Autocmds", ctx.args.scope)
        end,
      },
      {
        path = { "check" },
        args = { { name = "plugin", type = "STRING", optional = true } },
        desc = "Drift-Bericht: dokumentiert-aber-nicht-live / live-aber-undokumentiert (Personal, read-only)",
        run = function(ctx)
          M.check(ctx.args.plugin)
        end,
      },
    },
  })
end

return M
