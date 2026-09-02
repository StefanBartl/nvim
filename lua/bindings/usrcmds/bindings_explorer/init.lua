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
--- `:Bindings check repo [plugin]` bzw. `:Bindings check <plugin> repo`
--- schaltet zusätzlich die Checkout-Achse zu (`repo.lua`): dokumentierte
--- Bindings von Plugins, die diese Session nie geladen hat und die die
--- Live-Achse deshalb nur als „skipped" durchwinkt, werden im lokalen
--- Quellbaum des Plugins gesucht. Opt-in, weil sie als einzige Achse von
--- der Platte liest statt eine laufende Session zu befragen.
---
--- Phase 4 (diese Datei + `status.lua`/`report.lua`): `:Bindings status` —
--- eine Seite Korpus-, Live- und Plugin-Zahlen plus die Routenliste, nach dem
--- Vorbild von `:Reposcope status`; und `:Bindings report [...]
--- [out=<pfad>]` — derselbe Drift-Lauf wie `check`, als Markdown-Datei statt
--- als Viewer. Beide entstanden aus dem Driftreport vom 2026-09-02: der
--- wurde von Hand aus einem headless-Lauf zusammengesetzt, und `report`
--- macht genau diesen Teil.

local composer = require("lib.nvim.bindings.usercmd.composer")
local config = require("bindings.usrcmds.bindings_explorer.config")
local search = require("bindings.usrcmds.bindings_explorer.search")
local live = require("bindings.usrcmds.bindings_explorer.live")
local ui = require("bindings.usrcmds.bindings_explorer.ui")
local browse = require("bindings.usrcmds.bindings_explorer.browse")
local drift = require("bindings.usrcmds.bindings_explorer.drift")
local status = require("bindings.usrcmds.bindings_explorer.status")

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
---@param opts { repo?: boolean, repo_root?: string, scope?: "personal"|"extern"|"all" }|nil
---`repo` schaltet die Checkout-Achse zu (siehe `drift.lua`s Moduldoc, "The
---repo axis") — bewusst opt-in, weil sie als einzige Achse ~20 Repos von der
---Platte liest statt eine laufende Session zu befragen. `repo_root` richtet
---dieselbe Achse auf ein Sammelverzeichnis mit mehreren Lua-Projekten statt
---auf die Lazy-Spec-Auflösung und impliziert `repo`. `scope` trennt eigene
---von fremden Live-Commands, Default `"personal"` — siehe `drift.check`.
---@return nil
function M.check(plugin, opts)
  local findings, skipped, source_reason, repo_info, scope_info, autocmd_info =
    drift.check(plugin, opts)
  -- Der Scope steht im Titel, nicht nur im Bericht: der Unterschied
  -- zwischen 53 und 107 Befunden ist sonst nicht erklärbar, ohne bis zur
  -- Scope-Notiz zu scrollen.
  local label = (scope_info and scope_info.scope ~= "personal")
      and (" [" .. scope_info.scope .. "]")
    or ""
  require("lib.nvim.ui.kit.viewer").open({
    title = ("Bindings — check%s (%d)"):format(label, #findings),
    lines = drift.describe(findings, skipped, source_reason, repo_info, scope_info, autocmd_info),
  })
end

--- Denselben Bericht als Markdown-Datei schreiben (`report.lua`).
---@param plugin string|nil
---@param opts { repo?: boolean, repo_root?: string, out?: string, scope?: "personal"|"extern"|"all" }|nil
---`out` darf ein Verzeichnis oder ein Dateiname sein; ohne `out` landet der
---Bericht als `BINDINGS-DRIFT-<datum>.md` in `config.report_dir()`. `scope`
---wie bei `M.check`.
---@return nil
function M.report(plugin, opts)
  opts = opts or {}
  local path, err, count = require("bindings.usrcmds.bindings_explorer.report").write({
    plugin = plugin,
    repo = opts.repo,
    repo_root = opts.repo_root,
    out = opts.out,
    scope = opts.scope,
  })
  if not path then
    notify().error("Bericht nicht geschrieben: " .. (err or "unbekannter Fehler"))
    return
  end
  notify().info(("%d Befunde -> %s"):format(count or 0, path))
end

--- Dashboard: eine Seite Zahlen plus die Routenliste (`status.lua`).
---@return nil
function M.status()
  status.open()
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
        args = {
          { name = "plugin", type = "STRING", optional = true },
          { name = "axis", type = "STRING", enum = { "repo", "extern", "all" }, optional = true },
        },
        -- `root=` als kv, nicht als dritter Positionswert: ein Pfad und ein
        -- Plugin-Name sind beide freie Strings, und der Composer bindet
        -- Positionen der Reihe nach — `:Bindings check C:/repos` würde den
        -- Pfad still als Plugin-Namen binden. Mit dem Schlüssel davor ist die
        -- Zuordnung unabhängig von der Stellung, und `<Tab>` nach `root=`
        -- vervollständigt Verzeichnisse (`type = "DIR"`).
        kv = { { key = "root", type = "DIR" } },
        desc = "Drift-Bericht: dokumentiert-aber-nicht-live / live-aber-undokumentiert (Personal, read-only)",
        run = function(ctx)
          M.check(ctx.args.plugin, {
            repo = ctx.args.axis == "repo",
            repo_root = ctx.kv.root,
            scope = (ctx.args.axis == "extern" or ctx.args.axis == "all") and ctx.args.axis or nil,
          })
        end,
      },
      -- Dieselbe Achse ohne Plugin-Argument. Nötig als eigene Route, nicht
      -- als bloßer zweiter Positionswert: `:Bindings check repo` würde sonst
      -- „repo" als Plugin-Namen binden und stillschweigend einen leeren
      -- Bericht liefern. Als literales Kind von `check` gewinnt der
      -- Baum-Walk (siehe composer `tree.walk`), und `<Tab>` schlägt es vor.
      {
        path = { "check", "repo" },
        args = { { name = "plugin", type = "STRING", optional = true } },
        kv = { { key = "root", type = "DIR" } },
        desc = "Drift-Bericht mit der Checkout-Achse: dokumentierte Bindings ungeladener Plugins gegen deren lokalen Quellbaum; `root=<dir>` nimmt jedes Lua-Projekt unter einem Sammelverzeichnis statt der Lazy-Spec-Auflösung",
        run = function(ctx)
          M.check(ctx.args.plugin, { repo = true, repo_root = ctx.kv.root })
        end,
      },
      -- `extern`/`all` brauchen dieselbe literale Kind-Route wie `repo`, und
      -- aus demselben Grund: `:Bindings check extern` bände „extern" sonst
      -- als Plugin-Namen und lieferte still einen leeren Bericht.
      {
        path = { "check", "extern" },
        args = { { name = "plugin", type = "STRING", optional = true } },
        kv = { { key = "root", type = "DIR" } },
        desc = "Nur die fremden: live registrierte Commands ohne Cheatsheet, deren Plugin dieser Korpus nicht abdeckt",
        run = function(ctx)
          M.check(ctx.args.plugin, { repo_root = ctx.kv.root, scope = "extern" })
        end,
      },
      {
        path = { "check", "all" },
        args = { { name = "plugin", type = "STRING", optional = true } },
        kv = { { key = "root", type = "DIR" } },
        desc = "Eigene und fremde zusammen — das Verhalten vor der Scope-Trennung",
        run = function(ctx)
          M.check(ctx.args.plugin, { repo_root = ctx.kv.root, scope = "all" })
        end,
      },
      -- `report` spiegelt `check` inklusive der zweiten Route für `repo`,
      -- aus demselben Grund: ohne literales Kind bände `:Bindings report
      -- repo` „repo" als Plugin-Namen. `out` ist `PATH`, nicht `FILE` —
      -- `FILE` verlangt eine lesbare Datei, und eine Ausgabedatei gibt es
      -- vor dem Lauf per Definition noch nicht.
      {
        path = { "report" },
        args = {
          { name = "plugin", type = "STRING", optional = true },
          { name = "axis", type = "STRING", enum = { "repo", "extern", "all" }, optional = true },
        },
        kv = { { key = "root", type = "DIR" }, { key = "out", type = "PATH" } },
        desc = "Drift-Bericht als Markdown-Datei; ohne `out=` nach docs/ROADMAP/personal/All/BINDINGS-DRIFT-<datum>.md",
        run = function(ctx)
          M.report(ctx.args.plugin, {
            repo = ctx.args.axis == "repo",
            repo_root = ctx.kv.root,
            out = ctx.kv.out,
            scope = (ctx.args.axis == "extern" or ctx.args.axis == "all") and ctx.args.axis or nil,
          })
        end,
      },
      -- Dieselben literalen Kinder wie bei `check`, aus demselben Grund.
      {
        path = { "report", "extern" },
        args = { { name = "plugin", type = "STRING", optional = true } },
        kv = { { key = "root", type = "DIR" }, { key = "out", type = "PATH" } },
        desc = "Nur die fremden, als Markdown-Datei",
        run = function(ctx)
          M.report(ctx.args.plugin, { repo_root = ctx.kv.root, out = ctx.kv.out, scope = "extern" })
        end,
      },
      {
        path = { "report", "all" },
        args = { { name = "plugin", type = "STRING", optional = true } },
        kv = { { key = "root", type = "DIR" }, { key = "out", type = "PATH" } },
        desc = "Eigene und fremde zusammen, als Markdown-Datei",
        run = function(ctx)
          M.report(ctx.args.plugin, { repo_root = ctx.kv.root, out = ctx.kv.out, scope = "all" })
        end,
      },
      {
        path = { "report", "repo" },
        args = { { name = "plugin", type = "STRING", optional = true } },
        kv = { { key = "root", type = "DIR" }, { key = "out", type = "PATH" } },
        desc = "Drift-Bericht mit der Checkout-Achse, als Markdown-Datei",
        run = function(ctx)
          M.report(ctx.args.plugin, { repo = true, repo_root = ctx.kv.root, out = ctx.kv.out })
        end,
      },
      {
        path = { "status" },
        desc = "Dashboard: Korpus-, Live- und Plugin-Zahlen plus die Routenliste",
        run = function()
          M.status()
        end,
      },
    },
  })
end

return M
