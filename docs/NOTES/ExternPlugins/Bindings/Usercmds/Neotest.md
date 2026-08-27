# nvim-neotest/neotest — User-Commands

`neotest` selbst bringt keine Usercmds mit (reine API-Lib). Alle folgenden
Commands sind **[custom]**, größtenteils dünne Wrapper um dieselben
zentralen Actions wie die Keymaps (siehe
[Keymaps/Neotest.md](../Keymaps/Neotest.md) und
[lua/config/neotest/actions/init.lua](../../../../../lua/config/neotest/actions/init.lua)).

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

Registriert in [lua/config/neotest/debug/init.lua](../../../../../lua/config/neotest/debug/init.lua)
(`M.usercommands`, via `lib.nvim.bindings.usercmd.create`), Teil desselben `M.setup_all()`-
Aufrufs, der auch die überschreibenden Keymaps setzt (siehe
[Keymaps/Neotest.md](../Keymaps/Neotest.md)).

| Command | Zweck |
|---|---|
| `:NeotestDebugAdapters` | Liste aller registrierten Adapter-IDs (`neotest.state.adapter_ids()`). |
| `:NeotestDebugState` | Kompletter Debug-Dump: Adapter, aktueller Buffer (Pfad/Filetype), ob ein Test-Tree für den Buffer gefunden wurde. |
| `:NeotestDebugFile` | Prüft, ob für die aktuelle Datei ein passender Adapter existiert (Pattern-Match des Adapter-IDs gegen den Dateinamen). |
| `:NeotestDebugRoot` | Root-Detection-Debug speziell für den TypeScript-Adapter (`config.neotest.adapters.typescript`), listet gefundene Marker-Dateien (`vitest.config.ts`, `package.json`, `tsconfig.json`). |
| `:NeotestDebugFramework` | Framework-Erkennung im CWD: listet Vitest-/Jest-Configs und prüft `package.json` auf `"vitest"`/`"jest"`-Einträge. |

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
