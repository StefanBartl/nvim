# `test.nvim` — Konzept

Prüfung, ob eine Auslagerung von `nvim/lua/config/neotest/**` +
`nvim/lua/plugins/neotest.lua` in ein eigenständiges Plugin Sinn macht,
analog zu den bereits extrahierten `*.nvim`-Repos (`dap.nvim`, `filetree.nvim`,
...) und den Konzepten [lsp.md](./lsp.md) und
[NEW_PLUGIN.md](./NEW_PLUGIN.md). Aus [00_MISC.md](./00_MISC.md) übernommene
Ausgangsfrage: "Checken ob das sinn macht".

**Ergebnis vorab: Ja, es macht Sinn** — gleiche Begründung wie bei `dap.nvim`
(stateful Subsystem mit eigener Registry/State, kein deklaratives Options-Bündel)
— aber die Analyse hat unterwegs vier konkrete, unabhängig vom
Auslagerungs-Thema bestehende Inkonsistenzen im heutigen Code aufgedeckt
(§2), die bei der Migration mit-bereinigt werden sollten.

---

## Table of Content

- [1. Ist-Zustand](#1-ist-zustand)
- [2. Gefundene Inkonsistenzen im Ist-Zustand](#2-gefundene-inkonsistenzen-im-ist-zustand)
- [3. Lohnt sich die Auslagerung?](#3-lohnt-sich-die-auslagerung)
- [4. Architektur / Modul-Mapping](#4-architektur--modul-mapping)
- [5. lib.nvim-Integration](#5-libnvim-integration)
- [6. Öffentliche API](#6-öffentliche-api)
- [7. Dokumentationspflichten](#7-dokumentationspflichten)
- [8. Migrationsplan](#8-migrationsplan)
- [9. Brainstorm: fehlende / neue Features](#9-brainstorm-fehlende--neue-features)
- [10. Offene Fragen / Risiken](#10-offene-fragen--risiken)

---

## 1. Ist-Zustand

| Bereich | Pfad | Verantwortung |
|---|---|---|
| Plugin-Spec | `lua/plugins/neotest.lua` | Lazy-Spec für `nvim-neotest/neotest`, baut `opts` inline, ruft nach `neotest.setup()` sechs weitere Setup-Funktionen auf |
| Adapter (aktiv) | `opts.adapters` in `plugins/neotest.lua` | Hartcodiert: `neotest-plenary`, `neotest-vitest`, `neotest-go` — **ignoriert** `config.neotest.adapters.factory` komplett |
| Adapter (Registry, unbenutzt) | `adapters/factory.lua` | Singleton-Cache-Registry mit eigenen `ADAPTER_BUILDERS` für lua/go/python/rust (inline) + typescript (delegiert an `adapters/typescript.lua`) — wird nirgends aufgerufen |
| Adapter (Einzeldateien, unbenutzt) | `adapters/{lua,go,python,rust}.lua` | Eigenständige, dritte Implementierung derselben vier Adapter — weder von `factory.lua` noch von `plugins/neotest.lua` referenziert |
| Adapter (Einzeldateien, nie verdrahtet) | `adapters/{bash,assembly,c_ccp,wasm,zig}.lua` | Vollständig implementiert (Framework-Erkennung, Test-Pattern-Matching), aber in keiner Dependency-Liste, keinem Factory-Eintrag und keinem Setup-Aufruf referenziert |
| Adapter (smart, teilweise unbenutzt) | `adapters/typescript.lua` | CWD-gesperrte Root-Erkennung + Vitest/Jest-Autodetektion — wird nur über `factory.lua` erreicht, das selbst unbenutzt ist; die aktive Config in `plugins/neotest.lua` nutzt stattdessen ein rohes `require("neotest-vitest")` ohne jede Optionen |
| Core | `core/init.lua` | Auto-Attach an Testdateien per Dateinamen-Pattern, Auto-Open des Output-Fensters bei Fehlschlag — per `Autocmd`, optional aufgerufen (`pcall(require, "config.neotest.core")`) |
| Actions | `actions/init.lua` | Zentrale, saubere Fassade (`run_nearest`, `run_file`, `run_all`, `debug_nearest`, `toggle_summary`, `open_output`, `toggle_output_panel`, `stop`, `toggle_watch`) — von Keymaps, Commands, Telescope und Which-Key gleichermaßen konsumiert |
| Commands | `commands/init.lua` | 10 `:Neotest*`-Usercmds, direkt auf `actions` gemappt |
| Keymaps | `keymaps/init.lua` | `<leader>nt*`-Mappings über `lib.nvim.bindings.keymap`; **zusätzlich** zwei Mappings (`<leader>ntr`/`<leader>ntD`) bereits beim `require()` selbst gesetzt (Modul-Top-Level-Code, nicht in `setup()`) |
| Which-Key | `whichkey/init.lua` | Dieselben 9 `<leader>nt*`-Mappings noch einmal, über `which-key`s `wk.add()` |
| Debug | `debug/init.lua` | Fünf `:NeotestDebug*`-Usercmds (Adapter-Status, State, File, Root, Framework) **plus** eine dritte Definition von `<leader>ntr`/`<leader>ntD` |
| Highlights | `highlights/init.lua` | 8 statische `NeotestPassed/Failed/Running/...`-Highlight-Gruppen |
| Telescope | `telescope/init.lua` | Picker über dieselben `actions`-Funktionen |
| Neo-tree-Bridge (aktiv) | `neotree/init.lua` | `commands()`/`keymaps()` für die `tests`-Source in Neo-tree — **wird tatsächlich verwendet**, von `lua/plugins/neotree.lua:4` (`local NEOTEST = require("config.neotest.neotree")`) |
| Neo-tree-Consumer (aktiv) | `consumers/neotree_wrapper.lua` | Deferred-Wrapper um `neotest.consumers.neotree` (aus `TimCreasman/neo-tree-tests-source.nvim`), verhindert Race Condition beim Initialisieren |
| Validierung | `utils/validate_consumer.lua` | `:NeotestValidateConsumer` — prüft Consumer-Initialisierung und ob Neo-tree die `tests`-Source kennt |
| Auto-Discovery | `autocmds/auto_discovery.lua` | `VimEnter`-Trigger für initialen Scan + Neo-tree-Refresh — **auskommentiert** in `plugins/neotest.lua`, also inaktiv |
| Icons | `init/icons.lua` | Icon-Set-Auflösung (`"devicons"`-Variante wird aktiv genutzt) |
| Dependencies | `init/dependencies.lua` | Lazy-Deps-Liste: 5 Plugin-Deps, 1 Consumer-Plugin, 7 Adapter-Plugins (inkl. `neotest-python`, `rouge8/neotest-rust`, `neotest-jest` — installiert, aber s. §2 nie tatsächlich aktiviert) |
| Doku | `docs/COMMANDS.md` | Deutsche Kurzreferenz für Commands/Keymaps/Autocmds — bereits vorhanden, gut wiederverwendbar |

Gesamtumfang: ~2.500 Zeilen über 27 Dateien — deutlich kleiner als `lsp.nvim`
(~11.600) oder das kombinierte `wkdnvchad`/`wkdoptions` (~11.800), vergleichbar
mit `dap.nvim`s ursprünglichem `lua/wkddap`-Umfang.

---

## 2. Gefundene Inkonsistenzen im Ist-Zustand

Diese vier Punkte sind unabhängig von der Auslagerungsfrage bereits heute
bestehende Bugs bzw. totes Gewicht im Host — analog zum in
[lsp.md §1](./lsp.md#1-ist-zustand) dokumentierten Fund, dass
`lsp/debug_adapters/init.lua` nur auskommentierte `require`s enthält.

1. **Adapter-Split-Brain (drei parallele Implementierungen, eine davon aktiv):**
   `plugins/neotest.lua` setzt `opts.adapters` hartcodiert auf drei Einträge
   (`neotest-plenary`, `neotest-vitest`, `neotest-go`), jeweils ohne Optionen.
   Parallel existieren (a) `adapters/factory.lua` mit einer eigenen,
   Singleton-gecachten `ADAPTER_BUILDERS`-Registry für lua/go/python/rust/
   typescript und (b) fünf weitere eigenständige `adapters/{lua,go,python,
   rust}.lua`-Dateien, die *keine* der beiden anderen Stellen referenziert.
   **Konsequenz:** `neotest-python`, `rouge8/neotest-rust` und
   `neotest-jest` werden laut `init/dependencies.lua` als Lazy-Deps
   installiert, aber nie als Adapter aktiviert — Python-, Rust- und
   Jest-Projekte bekommen aktuell keine Testerkennung, obwohl die Plugins
   vorhanden sind. Die sorgfältig gebaute CWD-Sperre + Framework-Erkennung in
   `adapters/typescript.lua` (verhindert Multi-Root-Discovery, erkennt Vitest
   vs. Jest über Config-Dateien/`package.json`) wird ebenfalls nie erreicht,
   weil sie nur über das unbenutzte `factory.lua` verdrahtet ist — die aktive
   Config nutzt stattdessen ein Vitest-Adapter ohne jede Option.

2. **Fünf komplett unverdrahtete Adapter-Dateien:**
   `adapters/{bash,assembly,c_ccp,wasm,zig}.lua` sind vollständig
   implementiert (inkl. Framework-Erkennung wie `bats`/`shunit2` für Bash),
   aber in keiner Dependency-Liste, keinem Factory-Eintrag und keinem
   Setup-Pfad referenziert. Reines totes Gewicht — vermutlich Ausbaustufen,
   die nie angeschlossen wurden.

3. **Dreifache Keymap-Registrierung für `<leader>ntr`/`<leader>ntD`:**
   Dieselben zwei Tastenkombinationen werden an drei Stellen definiert:
   einmal als Modul-Top-Level-Code in `keymaps/init.lua` (läuft bereits beim
   `require()`, nicht erst bei `setup()`), einmal identisch-benannt (aber mit
   abweichender, elaborierterer Implementierung inkl. Test-Zähler) in
   `debug/init.lua:M.keymaps()`, aufgerufen über `debug.setup_all()` in
   `plugins/neotest.lua`. Wer zuletzt lädt, gewinnt (`vim.keymap.set`
   überschreibt kommentarlos) — nicht offensichtlich, welche Variante aktiv
   ist, ohne die Load-Reihenfolge nachzuvollziehen.

4. **Doppelte Registrierung der übrigen neun `<leader>nt*`-Keymaps:**
   `plugins/neotest.lua` ruft sowohl `require("config.neotest.keymaps").setup()`
   (bindet über `lib.nvim.bindings.keymap`/`vim.keymap.set`) als auch
   `require("config.neotest.whichkey").setup()` (bindet dieselben LHS über
   `which-key`s `wk.add()`) auf. Funktional vermutlich unschädlich (letzter
   Bind gewinnt, which-key registriert vermutlich nach dem nativen Mapping),
   aber unklar, ob die which-key-Beschreibungen tatsächlich die sind, die
   angezeigt werden, oder ob sie vom nativen `desc` überschrieben werden —
   ungetestet, sollte vor der Migration einmal manuell verifiziert werden.

**Auto-Discovery ist zusätzlich bewusst deaktiviert** (auskommentiert in
`plugins/neotest.lua`) — kein Bug, aber beim Umzug zu entscheiden, ob das
Feature reaktiviert oder als offiziell-abgeschaltet in die neue README
übernommen wird.

---

## 3. Lohnt sich die Auslagerung?

Ja — aus denselben Gründen wie bei `dap.nvim`/`lsp.nvim`
([nvim.md](./nvim.md#lsp-nvim-vs-optionsnvim)): `config/neotest/**` ist ein
**stateful Subsystem** (Adapter-Registry, Discovery-State, Consumer-Wiring)
mit eigenen Commands und Keymaps, keine deklarativen Settings — gehört damit
strukturell zur selben Kategorie wie `lsp.nvim`/`dap.nvim`, nicht zu
`options.nvim`.

Zusätzliches Argument: Die Extraktion ist der **richtige Zeitpunkt**, die vier
in [§2](#2-gefundene-inkonsistenzen-im-ist-zustand) gefundenen Inkonsistenzen
zu bereinigen — ein 1:1-Copy ins neue Repo würde die Bugs sonst nur
mitverschieben, wie es analog bei `lsp.nvim`s `debug_adapters`-Fund der Fall
gewesen wäre.

Anders als bei `wkdnvchad`/`wkdoptions` ([NEW_PLUGIN.md](./NEW_PLUGIN.md))
gibt es hier **keine NvChad-Kopplung** (0 Treffer beim Grep nach `nvchad` im
gesamten `config/neotest`-Baum) — die Frage "eigenständig lauffähig ohne
NvChad" stellt sich also gar nicht, `test.nvim` wäre von Anfang an NvChad-frei.

Es gibt aber eine **echte Neo-tree-Kopplung** (`neotree/init.lua`,
`consumers/neotree_wrapper.lua`, `utils/validate_consumer.lua`), die beim
Zuschnitt berücksichtigt werden muss — anders als die reine
Optionale-Adapter-Beziehung bei `lsp.nvim` zu `dap.nvim` ist diese Kopplung
für den Testrunner *funktional relevant* (die "tests"-Quelle in Neo-tree
existiert nur durch dieses Zusammenspiel), s. [§4](#4-architektur--modul-mapping)
und [§10](#10-offene-fragen--risiken).

---

## 4. Architektur / Modul-Mapping

```
test.nvim/
├── lua/test/                    -- oder wkdtest/ o.ä., s. §10 (Namenskollision)
│   ├── init.lua                 -- M.setup(opts) — Orchestrierung
│   ├── @types/
│   ├── adapters/
│   │   ├── init.lua             -- EINE Registry statt drei parallelen
│   │   │                           Implementierungen (factory.lua + Einzeldateien
│   │   │                           + Hardcode in plugins/neotest.lua verschmelzen)
│   │   ├── lua.lua / go.lua / python.lua / rust.lua / typescript.lua
│   │   └── bash.lua / assembly.lua / c_ccp.lua / wasm.lua / zig.lua
│   │                             -- entweder anschließen (opt.adapters aus opts.servers-
│   │                                artigem Array bauen) oder bewusst als "vorbereitet,
│   │                                nicht aktiv" markiert lassen — s. §10
│   ├── core/                    -- Auto-Attach, Auto-Open-on-Fail
│   ├── actions/                 -- unverändert, bereits die richtige Fassade
│   ├── commands/
│   ├── keymaps/                 -- EINE Quelle statt drei (s. §2 Punkt 3/4)
│   ├── highlights/
│   ├── telescope/               -- optional, pcall-guarded (Soft-Dep)
│   ├── neotree/                 -- Bridge: commands()/keymaps() für die "tests"-Source,
│   │                                bleibt öffentliche API, vom Host konsumiert
│   ├── consumers/                -- neotree_wrapper (Deferred-Consumer)
│   ├── utils/validate_consumer.lua
│   └── autocmds/auto_discovery.lua -- Default-Zustand (an/aus) explizit in setup(),
│                                       nicht mehr stumm auskommentiert
├── plugin/health.lua (oder lua/test/health.lua)  -- :checkhealth test
├── README.md
├── doc/test.txt
└── docs/
    ├── COMMANDS.md               -- bereits vorhanden, 1:1 übernehmen
    └── ROADMAP.md
```

Die interne Struktur (Actions als zentrale Fassade, von Keymaps/Commands/
Telescope/Which-Key gleichermaßen konsumiert) ist bereits gut nach SRP
organisiert und muss nicht neu entworfen werden — die Bereinigung betrifft
gezielt die Adapter- und Keymap-Redundanzen aus §2, nicht die Gesamtarchitektur.

---

## 5. lib.nvim-Integration

| Aktuell | Status |
|---|---|
| `lib.nvim.notify` (`actions`, `debug`, `consumers/neotree_wrapper`, `utils/validate_consumer`) | bereits verwendet ✅ |
| `lib.nvim.bindings.keymap` (`keymaps/init.lua`, `debug/init.lua`) | bereits verwendet ✅ — aber s. §2 Punkt 3/4 zur Redundanz |
| `lib.nvim.bindings.usercmd` (`debug/init.lua`, `utils/validate_consumer.lua`) | bereits verwendet ✅ |
| `lib.nvim.bindings.autocmd` (`core/init.lua`, `autocmds/auto_discovery.lua`) | bereits verwendet ✅ |
| `vim.api.nvim_create_user_command` direkt statt `lib.nvim.bindings.usercmd` (`commands/init.lua`) | uneinheitlich — `commands/init.lua` nutzt die native API, `debug/init.lua` im selben Plugin nutzt `lib.nvim.bindings.usercmd`. Beim Umzug vereinheitlichen |
| Adapter-Singleton-Cache (`adapters/factory.lua`, `_G._neotest_adapter_cache`) | globaler State über `_G` statt `lib.lua.memo` — sollte bei der Konsolidierung aus §4 durch `lib.lua.memo`/`lib.lua.memo.lru` ersetzt werden, kein `_G`-Zugriff nötig |
| Framework-Detection-Caching (`adapters/typescript.lua` liest bei jedem Aufruf `package.json` neu) | Kandidat für `lib.lua.memo` (pro Root-Pfad einmalig cachen) |

---

## 6. Öffentliche API

```lua
require("test").setup({
  adapters = {
    lua = true, go = true, python = true, rust = true, typescript = true,
    -- bash/assembly/c_ccp/wasm/zig: bewusst standardmäßig aus, s. §10
  },
  neotree_bridge = true,        -- entspricht heutigem neotree/init.lua + consumers/neotree_wrapper
  auto_discovery = false,       -- expliziter Default statt stiller Auskommentierung
  core = {
    auto_attach_on_test_file = true,
    show_output_on_fail = true,
  },
  keymaps = { enable = true, which_key = "auto" }, -- "auto" = nutzt which-key falls vorhanden,
                                                     -- sonst native Keymaps — NICHT beides
  telescope = true,             -- optional, nur falls telescope installiert
})
```

Commands (bereits vorhanden, bleiben stabil): `:NeotestRunNearest`,
`:NeotestRunFile`, `:NeotestRunAll`, `:NeotestDebugNearest`,
`:NeotestSummaryToggle`, `:NeotestOutput`, `:NeotestOutputPanelToggle`,
`:NeotestStop`, `:NeotestWatchToggle`, `:NeotestActions`,
`:NeotestDebugAdapters`, `:NeotestDebugState`, `:NeotestDebugFile`,
`:NeotestDebugRoot`, `:NeotestDebugFramework`, `:NeotestValidateConsumer`,
`:NeotestClearAll`.

---

## 7. Dokumentationspflichten

Wie in [NEW_Project.md](./MATERIALS/NEW_Project.md) festgelegt:

- `README.md` (deutsch) — ASCII-Art + Badges + Table of Content (nur H2)
- `/doc/test.txt` (englisch, `:h`-fähig)
- `/docs/ROADMAP.md` — künftige Features (§9)
- `/docs/COMMANDS.md` — **bereits vorhanden und gut**, 1:1 übernehmen, nur
  Pfade/Modulnamen nach dem Umzug aktualisieren
- **`:checkhealth test`** — prüft `lib.nvim`-Verfügbarkeit, ob `nvim-neotest/
  neotest` geladen ist, welche Adapter tatsächlich aktiv sind (direkte
  Antwort auf den in §2 Punkt 1 gefundenen Split-Brain — die Health-Ausgabe
  sollte explizit auflisten: "installiert, aber nicht aktiviert" vs. "aktiv"),
  und ob die Neo-tree-Bridge (`tests`-Source) korrekt registriert ist —
  letzteres im Kern eine Wiederverwendung von `utils/validate_consumer.lua`,
  analog zum in [lsp.md §6](./lsp.md#6-dokumentationspflichten) beschriebenen
  Muster ("kein Code-Duplikat, nur eine zweite dünne Schnittstelle").

---

## 8. Migrationsplan

1. Repo `test.nvim` unter `$REPOS_DIR\test.nvim` anlegen (Grundgerüst: README,
   doc, ROADMAP, `:checkhealth`, `.luarc.json`, `stylua.toml` — Vorlage:
   `dap.nvim`).
2. `lua/config/neotest/**` 1:1 kopieren.
3. **Adapter-Konsolidierung** (Kernarbeit dieser Migration, nicht nur
   Verschieben): eine einzige `adapters/init.lua`-Registry bauen, die
   entweder die `factory.lua`-Logik (Singleton-Cache, `M.get`/`M.get_all`)
   oder die Einzeldateien als Quelle nimmt — nicht beide parallel behalten.
   `plugins/neotest.lua`s künftiges Äquivalent (`nvchad`/Host-Spec) muss
   `adapters.get_all()` tatsächlich aufrufen statt eine Hardcode-Liste zu
   pflegen, sonst wiederholt sich der Fund aus §2 Punkt 1 im neuen Repo.
4. **Keymap-Konsolidierung**: `keymaps/init.lua`s Top-Level-Code in
   `setup()` verschieben (kein Side-Effect bei `require()`), `debug/init.lua`s
   `<leader>ntr`/`<leader>ntD`-Duplikate entfernen (eine Implementierung
   behalten — die elaboriertere aus `debug/init.lua` mit Test-Zähler wirkt
   ausgereifter). Which-Key vs. native Keymaps: **eines von beiden**, per
   `opts.keymaps.which_key` steuerbar (s. [§6](#6-öffentliche-api)), nicht
   beides gleichzeitig binden.
5. Fünf unverdrahtete Adapter (`bash`, `assembly`, `c_ccp`, `wasm`, `zig`)
   entweder anschließen (`opts.adapters.bash = true` etc.) oder explizit in
   `docs/ROADMAP.md` als "vorbereitet, aber nicht standardmäßig aktiv"
   vermerken — nicht stillschweigend als totes Gewicht mitschleppen.
6. Neo-tree-Bridge (`neotree/init.lua`, `consumers/neotree_wrapper.lua`)
   als öffentliche API belassen — der Host (`lua/plugins/neotree.lua`)
   konsumiert sie weiterhin per `require("test.neotree")` (oder
   `require("test").neotree`), analog zum heutigen
   `require("config.neotest.neotree")`. Keine Änderung an der Kopplungsrichtung
   nötig, nur am Modul-Pfad.
7. `:checkhealth`-Brücke ergänzen (s. [§7](#7-dokumentationspflichten)).
8. Host-Wiring in `lua/plugins/personal/init.lua` analog zum bestehenden
   `dap.nvim`-Eintrag ergänzen; `lua/plugins/neotest.lua` und
   `lua/config/neotest/**` entfernen, `lua/plugins/neotree.lua:4`
   (`require("config.neotest.neotree")`) auf `require("test.neotree")`
   umstellen.
9. Manuell verifizieren: Testerkennung für mindestens Lua/Go (aktueller
   Stand) UND Python/Rust/TS (bisher nie aktiviert, s. §2), Neo-tree
   `tests`-Source funktioniert weiterhin, keine doppelten Keymap-Meldungen
   mehr in `:verbose map <leader>ntr`.
10. Diesen Roadmap-Eintrag nach Abschluss aktualisieren, analog zur
    Memory-Notiz `lib-nvim-extraction.md`.

---

## 9. Brainstorm: fehlende / neue Features

| Feature | Nutzen | Aufwand |
|---|---|---|
| **Adapter-Status in `:checkhealth`** | Direkte Antwort auf §2 Punkt 1 — sichtbar machen, welche Sprache tatsächlich Testerkennung hat, statt es stillschweigend nicht zu tun | klein (Kern der Migration ohnehin) |
| **Coverage-Anzeige** (z. B. über `neotest`s eigene Coverage-Konsumenten oder externe Tools) | Aktuell nirgends in `config/neotest/**` referenziert | mittel-groß |
| **Test-Historie/letzter-Lauf-Zusammenfassung** (`:NeotestHistory` o. ä.) | `actions.lua` hat keinen Zugriff auf vergangene Läufe über die aktuelle Session hinaus | mittel |
| **Watch-Mode-Statusanzeige in der Statusline** | `toggle_watch()` existiert (Action + Keymap + Command), aber kein sichtbarer Indikator, ob Watch gerade aktiv ist — leicht mit `wkdnvchad`/`nvchad-ui.nvim`s Statusline-Modulen kombinierbar (s. [NEW_PLUGIN.md](./NEW_PLUGIN.md)) | klein-mittel |
| **Per-Projekt-Adapter-Override** (`.neotest.json` o. ä. im Repo-Root) | Analog zum in [lsp.md §8](./lsp.md#8-brainstorm-fehlende--neue-features) vorgeschlagenen Per-Projekt-Override für Server — hier für Adapter/Frameworks (z. B. Vitest erzwingen statt Auto-Detect) | mittel |
| **DAP-Integration verifizieren** | `actions.debug_nearest()` setzt `strategy = "dap"` voraus — ob das mit dem parallel geplanten `dap.nvim` (s. [lsp.md](./lsp.md)) tatsächlich zusammenspielt, ist unverifiziert; sollte beim Umzug einmal end-to-end getestet werden | klein (Audit) |
| **Assembly/Bash/Wasm/Zig-Adapter tatsächlich anschließen** | Code existiert bereits fertig (s. §2 Punkt 2), reine Verdrahtungsarbeit | klein |

---

## 10. Offene Fragen / Risiken

- **Modulname `test`:** `require("test")` ist ein sehr generischer,
  kollisionsanfälliger Name (andere Plugins/Projekte könnten eigene
  `lua/test/`-Verzeichnisse für ihre eigenen Testsuiten haben, die versehentlich
  auf dem `runtimepath` landen). Analog zu `dap.nvim`, dessen Lua-Modul
  bewusst `wkddap` statt `dap` heißt (Kollision mit `nvim-dap`s eigenem
  `dap`-Modul), empfiehlt sich hier ein spezifischerer Modulname wie
  `wkdtest` oder `testing` statt `test` — Repo-Name `test.nvim` kann davon
  unabhängig bleiben (Präzedenzfall: `dap.nvim` → `wkddap`).
- **Which-Key vs. native Keymaps:** aktuell laufen beide parallel (s. §2
  Punkt 4) und es ist unklar, ob das je zu sichtbaren Problemen geführt hat
  (falsche Beschreibung in `:WhichKey`, doppelte `<leader>nt`-Einträge in
  Popup-Menüs). Vor der endgültigen Entscheidung "which_key = auto"
  (s. §6) einmal interaktiv mit `:WhichKey <leader>nt` gegenprüfen.
- **Neo-tree-Kopplungsrichtung:** wie in [nvim.md](./nvim.md) vermerkt, besitzt
  der Host aktuell noch direkt `lua/config/neotree/**` (die
  neo-tree→filetree.nvim-Migration "Liste 1" ist offen). Die
  Neotest-Neotree-Bridge sollte deshalb bewusst als **von `test.nvim` nach
  außen exportierte** Funktion (`commands()`/`keymaps()`) gebaut werden, die
  der Host konsumiert — nicht als Config, die `test.nvim` selbst gegen ein
  bestimmtes Neo-tree-Setup fest verdrahtet. Falls/wenn "Liste 1" abgeschlossen
  wird, übernimmt `filetree.nvim` diesen Konsum-Punkt, ohne dass `test.nvim`
  selbst geändert werden muss.
- **`TimCreasman/neo-tree-tests-source.nvim`** ist eine Third-Party-Abhängigkeit
  außerhalb der eigenen `*.nvim`-Familie — als externe Dependency in
  `test.nvim`s eigenem `dependencies`-Feld deklarieren, nicht implizit über
  den Host erwarten.
- **Auto-Discovery-Reaktivierung:** aktuell bewusst auskommentiert. Vor der
  Migration entscheiden, ob das Feature (2s+1s verzögerter VimEnter-Scan)
  tatsächlich gewollt ist oder ob die Auskommentierung ein bewusster,
  dauerhafter Zustand war (z. B. wegen Startup-Performance) — dann gehört
  der Code nicht referenzlos ins neue Repo, sondern klar als "deaktiviert,
  weil X" dokumentiert, analog zur Sorgfalt bei den anderen Startup-Phasen
  in `init.lua` (s. [NEW_PLUGIN.md §8](./NEW_PLUGIN.md#8-offene-fragen--risiken)
  zur Startup-Reihenfolge-Disziplin).
