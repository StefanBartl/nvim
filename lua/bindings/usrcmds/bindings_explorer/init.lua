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
--- Zwischenablage. Es hat am 2026-09-04 das ältere `:BindingsPath`
--- (`lua/bindings/usrcmds/init.lua`) abgelöst, das einen einzelnen, nie
--- existierenden `docs/NOTES/BINDINGS`-Pfad kopierte; `<leader>BI` läuft
--- seither hierher.
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
--- Plugin-Scope (diese Datei + `plugin_scope.lua`): überall dort, wo eine Route
--- über den Korpus geht, darf ein Cheatsheet-Stamm als Scope stehen —
--- `:Bindings search keymaps hover.nvim` durchsucht nur hover.nvims
--- Keymaps-Sheet, `:Bindings browse usercmds gitsigns` nur dessen
--- Tabellenzeilen. Bei `search` teilt sich der Scope den Platz mit der Query
--- (`:Bindings search keymaps redact` war und bleibt eine Textsuche), deshalb
--- zählt dort nur ein Token als Scope, das ein Sheet wirklich benennt; die
--- Präfix-Auflösung (`doc` → `documentation.nvim`) gibt es nur in der
--- ausgeschriebenen Form `plugin=doc`. Die volle Begründung steht in
--- `plugin_scope.lua`s Moduldoc. `check`/`report` hatten ihr Plugin-Argument von
--- Anfang an; neu ist auch dort nur, dass es nicht mehr exakt getippt sein
--- muss.
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
local plugin_scope = require("bindings.usrcmds.bindings_explorer.plugin_scope")

--- Der Argumenttyp der Plugin-Scope-Slots. Eigener Name statt `STRING`, weil
--- `<Tab>` dort die Cheatsheet-Stämme der bereits getippten Kategorie anbieten
--- soll (`plugin_scope.argtype`); das Typregister des Composers ist
--- prozessweit, daher der Präfix — dieselbe Konvention wie `GH_REPO`,
--- `IMAGE_TARGET` und die anderen Plugin-Typen dieser Config.
local PLUGIN_ARG = "BINDINGS_PLUGIN"

--- Die zwei Korpus-Hälften, als Positionswert von `browse` erlaubt. Bewusst
--- kein `enum` auf dem Slot: dort steht wahlweise dieser Wert ODER ein
--- Plugin-Stamm, und ein `enum` würde jeden Stamm als Tippfehler abweisen,
--- bevor der Handler ihn überhaupt sieht.
local SCOPE_VALUES = { "personal", "extern" }

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

---@class Bindings.Selection
---@field plugin Bindings.PluginMatch|nil aufgelöster Plugin-Scope
---@field query string|nil Suchtext (nur `search`)
---@field scope ("personal"|"extern")|nil Korpus-Hälfte (nur `browse`)

--- Den Plugin-Scope einer `search`-Route aus ihren zwei Positionswerten und
--- dem optionalen `plugin=` lesen.
---
--- Der erste Positionswert trägt Scope ODER Query, deshalb entscheidet nicht
--- die Stellung, sondern ob das Token ein Sheet benennt: `hover.nvim` ist ein
--- Scope, `redact` ist eine Query, und `hover.nvim redact` wie
--- `redact hover.nvim` heißen beide „redact, im Scope hover.nvim". Zwei
--- Tokens, von denen keines ein Sheet benennt, sind dagegen ein Tippfehler und
--- keine zweiwortige Query — gesucht wird mit einem Muster, nicht mit zweien.
---@param ctx table Composer-Ctx
---@param category ("Keymaps"|"Usercmds"|"Autocmds")|nil
---@return Bindings.Selection|nil sel
---@return string|nil err fertige Meldung für `notify`
local function search_selection(ctx, category)
  local opts = { category = category }
  local a, b = ctx.args.plugin, ctx.args.query
  local explicit = ctx.kv and ctx.kv.plugin or nil

  -- `plugin=` ist die ausgeschriebene Form: sie darf per Präfix auflösen, und
  -- der Positionswert ist dann eindeutig die Query.
  if explicit then
    local match, err = plugin_scope.resolve(explicit, { category = category, fuzzy = true })
    if not match then
      return nil, err or plugin_scope.unknown_message(explicit, opts)
    end
    if b then
      return nil, ("zu viele Argumente: '%s' — mit plugin= ist '%s' die Query"):format(b, a)
    end
    return { plugin = match, query = a }
  end

  if not a then
    return {}
  end

  local match = plugin_scope.resolve(a, opts)
  if match then
    return { plugin = match, query = b }
  end
  if not b then
    return { query = a }
  end
  local swapped = plugin_scope.resolve(b, opts)
  if swapped then
    return { plugin = swapped, query = a }
  end
  return nil, plugin_scope.unknown_message(a, opts)
end

--- Dasselbe für `browse`, wo derselbe Slot Plugin ODER Korpushälfte trägt.
---
--- Hier gibt es keine Query, mit der ein Token verwechselt werden könnte,
--- deshalb löst dieser Slot auch per Präfix auf (`doc` → `documentation.nvim`)
--- und meldet ein unbekanntes Token als Fehler statt es stillschweigend
--- anders zu deuten. Die Reihenfolge ist frei: `keymaps hover.nvim personal`
--- und `keymaps personal hover.nvim` sind dasselbe.
---@param ctx table Composer-Ctx
---@param category ("Keymaps"|"Usercmds"|"Autocmds")|nil
---@return Bindings.Selection|nil sel
---@return string|nil err
local function browse_selection(ctx, category)
  ---@type Bindings.Selection
  local sel = {}
  local token = ctx.kv and ctx.kv.plugin or nil

  for _, raw in ipairs(ctx.pos or {}) do
    local lower = raw:lower()
    if lower == "personal" or lower == "extern" then
      if sel.scope then
        return nil, ("Korpushälfte doppelt: '%s'"):format(raw)
      end
      sel.scope = lower
    elseif token then
      return nil, ("zu viele Argumente: '%s' — ein Plugin-Scope reicht"):format(raw)
    else
      token = raw
    end
  end

  if token then
    local opts = { category = category, scope = sel.scope, fuzzy = true }
    local match, err = plugin_scope.resolve(token, opts)
    if not match then
      return nil, err or plugin_scope.unknown_message(token, opts)
    end
    sel.plugin = match
  end

  return sel
end

--- Ein `check`/`report`-Plugin-Token auf GENAU einen Cheatsheet-Stamm bringen.
---
--- Beide Achsen filtern über `rec.plugin == plugin` (siehe `drift.check`),
--- verarbeiten also genau einen Stamm; ein Token, das zwei Sheets benennt
--- (`dap` → `dap.nvim` und `Dap`), wird deshalb zurückgewiesen statt still auf
--- eines von beiden verengt zu werden. Ein exakt getippter Stamm gewinnt
--- dabei gegen seinen normalisierten Zwilling — sonst wäre `:Bindings check
--- Dap` mehrdeutig, obwohl es eine Datei genau so benennt.
---
--- Ein Token, das gar nichts benennt, geht unverändert durch wie vor dem
--- Plugin-Scope, nur mit einer Warnung: der Bericht bleibt leer, und das ist
--- ohne Hinweis nicht von „nichts gefunden" zu unterscheiden.
---@param token string|nil
---@return string|nil stem
---@return string|nil err
local function single_stem(token)
  if not token or token == "" then
    return nil, nil
  end

  local match = plugin_scope.resolve(token)
  if not match then
    notify().warn(plugin_scope.unknown_message(token))
    return token, nil
  end
  if #match.stems == 1 then
    return match.stems[1], nil
  end
  if #match.exact == 1 then
    return match.exact[1], nil
  end
  return nil,
    ("'%s' benennt mehrere Cheatsheets: %s — bitte den Stamm ausschreiben"):format(
      token,
      table.concat(match.stems, ", ")
    )
end

--- Suche über den Korpus, optional auf eine Kategorie und/oder ein Plugin
--- gescopt.
---
--- Der Plugin-Scope ersetzt die Wurzeln durch die Dateien des Plugins statt
--- zusätzlich zu filtern — beide Backends nehmen an derselben Stelle Dateien
--- wie Verzeichnisse (`live.lua` reicht sie an ripgrep durch, `search.lua`
--- liest sie direkt), also ist die gescopte Suche dieselbe Suche über weniger
--- Pfade.
---
--- **Ohne Plugin-Scope geht die Dateiliste durch `plugin_scope.all_files`,
--- nicht durch `config.roots()`.** Die zwei physischen Bäume allein sind seit
--- `BND-04` nicht mehr der ganze Korpus — jedes Personal-Plugin bringt seine
--- drei Kategorien jetzt aus seiner eigenen `docs/BINDINGS.md` mit, und
--- `config.roots()` sieht die nicht. Ein Plugin-Scope ist davon unberührt,
--- weil `plugin_scope.resolve` dieselbe dritte Quelle bereits seit jeher liest.
---@param category ("Keymaps"|"Usercmds"|"Autocmds")|nil nil = der ganze Korpus
---@param sel Bindings.Selection|nil
---@return nil
function M.search(category, sel)
  sel = sel or {}
  local label = sel.plugin and sel.plugin.label or nil

  local roots = sel.plugin and sel.plugin.files or plugin_scope.all_files(category)

  local prompt
  if category and label then
    prompt = ("Bindings: %s — %s"):format(category, label)
  elseif label then
    prompt = "Bindings: " .. label
  elseif category then
    prompt = "Bindings: " .. category
  else
    prompt = "Bindings durchsuchen"
  end

  search_scoped(roots, sel.query, prompt)
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
---@param sel Bindings.Selection|nil
---@return nil
function M.browse(category, sel)
  sel = sel or {}
  browse.open(category, sel.scope, sel.plugin)
end

--- Drift-Bericht (`drift.lua`) in einem read-only Viewer anzeigen.
---@param plugin string|nil Cheatsheet-Stamm; muss seit dem Plugin-Scope nicht
---mehr exakt getippt sein (`hover` → `hover.nvim`, siehe `single_stem`).
---@param opts { repo?: boolean, repo_root?: string, scope?: "personal"|"extern"|"all" }|nil
---`repo` schaltet die Checkout-Achse zu (siehe `drift.lua`s Moduldoc, "The
---repo axis") — bewusst opt-in, weil sie als einzige Achse ~20 Repos von der
---Platte liest statt eine laufende Session zu befragen. `repo_root` richtet
---dieselbe Achse auf ein Sammelverzeichnis mit mehreren Lua-Projekten statt
---auf die Lazy-Spec-Auflösung und impliziert `repo`. `scope` trennt eigene
---von fremden Live-Commands, Default `"personal"` — siehe `drift.check`.
---@return nil
function M.check(plugin, opts)
  local stem, stem_err = single_stem(plugin)
  if stem_err then
    notify().error(stem_err)
    return
  end

  local findings, skipped, source_reason, repo_info, scope_info, autocmd_info =
    drift.check(stem, opts)
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
  local stem, stem_err = single_stem(plugin)
  if stem_err then
    notify().error(stem_err)
    return
  end

  local path, err, count = require("bindings.usrcmds.bindings_explorer.report").write({
    plugin = stem,
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

--- Eine `search`-Route. Die vier unterscheiden sich nur in Pfad, Kategorie
--- und Beschreibung — das Argument-Schema (Plugin-Scope, Query, `plugin=`)
--- ist bei allen dasselbe, und eine Kopie davon je Route wäre vier Stellen,
--- an denen ein späterer Slot fehlen kann.
---@param path string[]
---@param category ("Keymaps"|"Usercmds"|"Autocmds")|nil
---@param desc string
---@return Lib.UserCmd.Composer.Route
local function search_route(path, category, desc)
  return {
    path = path,
    args = {
      { name = "plugin", type = PLUGIN_ARG, optional = true },
      { name = "query", type = "STRING", optional = true },
    },
    kv = { { key = "plugin", type = PLUGIN_ARG } },
    desc = desc,
    run = function(ctx)
      local sel, err = search_selection(ctx, category)
      if not sel then
        notify().error(err or "Argumente nicht verstanden")
        return
      end
      M.search(category, sel)
    end,
  }
end

--- Eine `browse`-Route, nach demselben Muster. Beide Positionswerte tragen
--- denselben Typ und dieselben `values`, weil beide wahlweise den
--- Plugin-Scope oder die Korpushälfte aufnehmen — `<Tab>` bietet damit in
--- jeder der zwei Stellungen das an, was dort erlaubt ist.
---@param path string[]
---@param category ("Keymaps"|"Usercmds"|"Autocmds")|nil
---@param desc string
---@return Lib.UserCmd.Composer.Route
local function browse_route(path, category, desc)
  return {
    path = path,
    args = {
      { name = "plugin", type = PLUGIN_ARG, values = SCOPE_VALUES, optional = true },
      { name = "scope", type = PLUGIN_ARG, values = SCOPE_VALUES, optional = true },
    },
    kv = { { key = "plugin", type = PLUGIN_ARG } },
    desc = desc,
    run = function(ctx)
      local sel, err = browse_selection(ctx, category)
      if not sel then
        notify().error(err or "Argumente nicht verstanden")
        return
      end
      M.browse(category, sel)
    end,
  }
end

---@return nil
function M.enable()
  -- Vor `composer.verb`, damit die Routen unten den Typ schon referenzieren
  -- dürfen: `argtypes.get` fällt für einen unbekannten Namen still auf STRING
  -- zurück, und der Slot hätte dann eine Completion ohne Cheatsheet-Stämme.
  composer.register_type(PLUGIN_ARG, plugin_scope.argtype())

  composer.verb("Bindings", {
    desc = "Cheatsheets in docs/NOTES/{PersonelPlugins/BINDINGS,ExternPlugins/Bindings} durchsuchen",
    default = function()
      M.search(nil, nil)
    end,
    routes = {
      search_route(
        { "search" },
        nil,
        "Live-Grep über beide BINDINGS-Bäume (Picker-Engine, sonst Prompt+Liste); ein Cheatsheet-Stamm als Argument scopt auf dessen Sheets"
      ),
      search_route(
        { "search", "keymaps" },
        "Keymaps",
        "Live-Grep, nur Keymaps-Cheatsheets; `hover.nvim` als Argument scopt auf dessen Sheet"
      ),
      search_route(
        { "search", "usercmds" },
        "Usercmds",
        "Live-Grep, nur Usercmds-Cheatsheets; `hover.nvim` als Argument scopt auf dessen Sheet"
      ),
      search_route(
        { "search", "autocmds" },
        "Autocmds",
        "Live-Grep, nur Autocmds-Cheatsheets; `hover.nvim` als Argument scopt auf dessen Sheet"
      ),
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
      browse_route(
        { "browse" },
        nil,
        "Picker über alle Tabellenzeilen (Keymaps+Usercmds+Autocmds); `personal`/`extern` oder ein Cheatsheet-Stamm scopen"
      ),
      browse_route(
        { "browse", "keymaps" },
        "Keymaps",
        "Picker über Keymaps-Tabellenzeilen; `personal`/`extern` oder ein Cheatsheet-Stamm scopen"
      ),
      browse_route(
        { "browse", "usercmds" },
        "Usercmds",
        "Picker über Usercmds-Tabellenzeilen; `personal`/`extern` oder ein Cheatsheet-Stamm scopen"
      ),
      browse_route(
        { "browse", "autocmds" },
        "Autocmds",
        "Picker über Autocmds-Tabellenzeilen; `personal`/`extern` oder ein Cheatsheet-Stamm scopen"
      ),
      {
        path = { "check" },
        args = {
          { name = "plugin", type = PLUGIN_ARG, optional = true },
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
        args = { { name = "plugin", type = PLUGIN_ARG, optional = true } },
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
        args = { { name = "plugin", type = PLUGIN_ARG, optional = true } },
        kv = { { key = "root", type = "DIR" } },
        desc = "Nur die fremden: live registrierte Commands ohne Cheatsheet, deren Plugin dieser Korpus nicht abdeckt",
        run = function(ctx)
          M.check(ctx.args.plugin, { repo_root = ctx.kv.root, scope = "extern" })
        end,
      },
      {
        path = { "check", "all" },
        args = { { name = "plugin", type = PLUGIN_ARG, optional = true } },
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
          { name = "plugin", type = PLUGIN_ARG, optional = true },
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
        args = { { name = "plugin", type = PLUGIN_ARG, optional = true } },
        kv = { { key = "root", type = "DIR" }, { key = "out", type = "PATH" } },
        desc = "Nur die fremden, als Markdown-Datei",
        run = function(ctx)
          M.report(ctx.args.plugin, { repo_root = ctx.kv.root, out = ctx.kv.out, scope = "extern" })
        end,
      },
      {
        path = { "report", "all" },
        args = { { name = "plugin", type = PLUGIN_ARG, optional = true } },
        kv = { { key = "root", type = "DIR" }, { key = "out", type = "PATH" } },
        desc = "Eigene und fremde zusammen, als Markdown-Datei",
        run = function(ctx)
          M.report(ctx.args.plugin, { repo_root = ctx.kv.root, out = ctx.kv.out, scope = "all" })
        end,
      },
      {
        path = { "report", "repo" },
        args = { { name = "plugin", type = PLUGIN_ARG, optional = true } },
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
