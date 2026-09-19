# nvim-neotest/neotest — User-Commands

Die `:Neotest*`-Commands dieser Config sind **[custom]**, größtenteils dünne
Wrapper um dieselben zentralen Actions wie die Keymaps (siehe
[Keymaps/Neotest.md](../Keymaps/Neotest.md) und
[lua/config/neotest/actions/init.lua](../../../../../lua/config/neotest/actions/init.lua)).

Dazu kommen zwei **[default]**-Sätze, die das Blatt bis 2026-09-02 verschwieg:
neotests eigenes `:Neotest` und die sechs `:Test*`-Commands von `vim-test`,
das als Dependency mitkommt. Beide unten.

> **Korrektur, 2026-09-02.** Hier stand: „`neotest` selbst bringt keine
> Usercmds mit (reine API-Lib)". Falsch — `:Neotest` existiert. Dieselbe
> Behauptung stand auch in `Usercmds/Conform.md`, `Usercmds/Treesitter.md`
> und `Usercmds/Dap.md`, und war jedes Mal falsch: „reine API-Lib" galt für
> die Bibliothek und nicht für ihr `plugin/`-Verzeichnis. Gefunden hat es
> `:Bindings check`, nachdem die Stamm-Auflösung die Blätter überhaupt erst
> mit geladenen Plugins verglich.

## [default] `:Neotest`

| Command | Wirkung |
|---|---|
| `:Neotest {subcommand} [args]` | Neotests eigener Dispatcher über die Lua-API — `:Neotest run`, `:Neotest summary`, `:Neotest output`, `:Neotest stop` und die weiteren Consumer. Die `:Neotest*`-Commands dieser Config unten sind die benannten Abkürzungen dafür. |

## [default] Die `:Test*`-Commands von vim-test

`vim-test/vim-test` steht in
[lua/config/neotest/init/dependencies.lua](../../../../../lua/config/neotest/init/dependencies.lua)
als `dependency` — es ist das Backend des Adapters
`nvim-neotest/neotest-vim-test` (aktiv für `vim`, `lua`, `sh`, `bash`, `zsh`,
`asm`). Es kommt also nicht als eigenständiges Werkzeug mit, sondern damit
neotest auch für Sprachen ohne eigenen Adapter etwas anzubieten hat.

Seine sechs Commands funktionieren trotzdem und sind live, sobald neotest
geladen ist. **Der Weg dieser Config führt aber über neotest**, nicht über
sie — sie sind hier dokumentiert, weil sie existieren, nicht weil sie
empfohlen wären.

| Command | Wirkung |
|---|---|
| `:TestNearest` | Den Test unter dem Cursor ausführen. |
| `:TestFile` | Alle Tests der aktuellen Datei. |
| `:TestSuite` | Die ganze Suite. |
| `:TestLast` | Den zuletzt ausgeführten Lauf wiederholen. |
| `:TestVisit` | Zur zuletzt getesteten Datei springen. |
| `:TestClass` | Die umgebende Test-Klasse — nur für Sprachen, deren vim-test-Runner das Konzept kennt. |

Die `[custom]`-Entsprechungen sind `:NeotestRunNearest`, `:NeotestRunFile`
und `:NeotestRunAll`; sie gehen über neotests Adapter-Auswahl und liefern
dessen Ausgabe-Oberfläche, nicht vim-tests Terminal-Strategie.

## Kern-Commands

Registriert in [lua/config/neotest/commands/init.lua](../../../../../lua/config/neotest/commands/init.lua)
(`M.setup`, `vim.api.nvim_create_user_command`), aufgerufen aus dem
`config`-Block in [lua/plugins/neotest.lua](../../../../../lua/plugins/neotest.lua).

| Command | Aktion | Action-Funktion |
|---|---|---|
| `:NeotestActions` | Öffnet einen Telescope-Picker über alle Aktionen (`config.neotest.telescope`) | — |
| `:NeotestRunNearest` | Nächstliegenden Test ausführen | `actions.run_nearest` |
| `:NeotestRunFile` | Alle Tests der aktuellen Datei ausführen | `actions.run_file` |
| `:NeotestRunAll` | Alle Tests im Projekt ausführen | `actions.run_all` |
| `:NeotestDebugNearest` | Nächstliegenden Test debuggen (DAP) | `actions.debug_nearest` |
| `:NeotestSummaryToggle` | Summary-Fenster togglen | `actions.toggle_summary` |
| `:NeotestOutput` | Output anzeigen | `actions.open_output` |
| `:NeotestOutputPanelToggle` | Output-Panel togglen | `actions.toggle_output_panel` |
| `:NeotestStop` | Laufende Tests stoppen | `actions.stop` |
| `:NeotestWatchToggle` | Watch-Modus togglen | `actions.toggle_watch` |
| `:NeotestClearAll` | Tests stoppen und alle Neotest-Fenster (Output, Summary) schließen | inline (`neotest.run.stop()`, `neotest.output.close()`, `neotest.summary.close()`) |

## Debug-Commands

Seit 2026-09-19 nicht mehr in dieser Config: die fünf `:NeotestDebug*`-Commands
aus `config/neotest/debug/init.lua` sind debugging.nvims
`:Debug neotest {adapters|state|file|root|framework|discover}` (Kategorie
`neotest`, `features.neotest = true` im Plugin-Default). Der Unterschied zur
alten Fassung: `file` und `root` fragen die Adapter-Tabellen aus
`neotest.setup()` selbst (`is_test_file(path)`, `root(dir)`) statt
Adapter-IDs gegen den Dateinamen zu matchen bzw. nur den TypeScript-Adapter
zu kennen — damit ist auch der geparkte Bug erledigt, dass `NeotestDebugRoot`
nie einen Root fand.

| Command | Zweck | Vorher |
|---|---|---|
| `:Debug neotest adapters` | Konfigurierte (`neotest.setup`) neben registrierten Adaptern (`state.adapter_ids()`); Hinweis, wenn nichts registriert ist | `:NeotestDebugAdapters` |
| `:Debug neotest state` | Adapter, aktueller Buffer (Pfad/Filetype), Positions-Tree für den Buffer inkl. Root-Name und Zählung nach Typ | `:NeotestDebugState` |
| `:Debug neotest file` | `is_test_file(path)` jedes konfigurierten Adapters für die aktuelle Datei | `:NeotestDebugFile` |
| `:Debug neotest root` | `root(dir)` jedes Adapters für die aktuelle Datei, Marker-Dateien im gefundenen Root | `:NeotestDebugRoot` |
| `:Debug neotest framework` | Marker-Dateien im CWD, Test-Frameworks laut `package.json` | `:NeotestDebugFramework` |
| `:Debug neotest discover` | Positionen je registriertem Adapter nach Typ, Test-Summe | `<leader>ntr` |

Keys: `<leader>ntr` → `discover`, `<leader>ntD` → `adapters`
([Keymaps/Neotest.md](../Keymaps/Neotest.md)).

## Consumer-Validierung

Registriert in [lua/config/neotest/utils/validate_consumer.lua](../../../../../lua/config/neotest/utils/validate_consumer.lua)
(`M.setup_command`), separat aufgerufen aus `plugins/neotest.lua`
(`require("config.neotest.utils.validate_consumer").setup_command()`).

| Command | Zweck |
|---|---|
| `:NeotestValidateConsumer` | Diagnostiziert, ob der Neo-tree-"tests"-Consumer korrekt initialisiert wurde (Modul geladen, in `neotest.config.consumers` registriert, als Table statt Factory-Function, Neo-tree-Source `"tests"` vorhanden). Meldet Ergebnis über `notify.info`/`notify.error`. |

## Nicht aktiv: Auto-Discovery

`require("config.neotest.autocmds.auto_discovery").attach()` ist im
`config`-Block von `plugins/neotest.lua` **auskommentiert** — siehe
[Keymaps/Neotest.md](../Keymaps/Neotest.md) sowie die Anmerkung unten in
diesem Ordner: kein `Autocmds/Neotest.md`, da der einzige Autocmd
(`VimEnter once` → verzögerte Discovery + Neo-tree-"tests"-Refresh in
[lua/config/neotest/autocmds/auto_discovery.lua](../../../../../lua/config/neotest/autocmds/auto_discovery.lua))
derzeit nicht registriert wird.
