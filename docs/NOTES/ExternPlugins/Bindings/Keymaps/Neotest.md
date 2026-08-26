# nvim-neotest/neotest — Keymaps

`neotest` selbst ist eine reine API-Bibliothek ohne eigene Default-Keymaps.
Alle folgenden Mappings sind daher **[custom]**, gesetzt über zentrale Actions
in [lua/config/neotest/actions/init.lua](../../../../../lua/config/neotest/actions/init.lua)
(gemeinsame Basis für Keymaps, Usercmds und Menüs — siehe Modul-Kommentar
"Centralized Neotest actions usable by keymaps, usercommands and menus").

Registriert im `config`-Block des `nvim-neotest/neotest`-Specs
([lua/plugins/neotest.lua](../../../../../lua/plugins/neotest.lua)):
`require("config.neotest.keymaps").setup()`, danach zusätzlich
`require("config.neotest.debug").setup_all()`.

## Gruppe `<leader>nt` — "Tests"

Aus [lua/config/neotest/keymaps/init.lua](../../../../../lua/config/neotest/keymaps/init.lua)
(`M.keymaps`-Tabelle, per `lib.nvim.bindings.keymap` gesetzt):

| Mapping | Aktion | Action-Funktion |
|---|---|---|
| `<leader>ntt` | Nächstliegenden Test ausführen | `actions.run_nearest` |
| `<leader>ntf` | Alle Tests der aktuellen Datei ausführen | `actions.run_file` |
| `<leader>nta` | Alle Tests im Projekt ausführen | `actions.run_all` |
| `<leader>ntd` | Nächstliegenden Test debuggen (DAP) | `actions.debug_nearest` |
| `<leader>nts` | Summary-Fenster togglen | `actions.toggle_summary` |
| `<leader>nto` | Output anzeigen | `actions.open_output` |
| `<leader>ntO` | Output-Panel togglen | `actions.toggle_output_panel` |
| `<leader>ntS` | Laufende Tests stoppen | `actions.stop` |
| `<leader>ntw` | Watch-Modus togglen | `actions.toggle_watch` |

Zusätzlich direkt in derselben Datei (nicht über `actions`, sondern inline):

| Mapping | Aktion |
|---|---|
| `<leader>ntr` | Test-State löschen und Discovery erzwingen (`neotest.state.clear` + verzögerte `neotest.state.positions()`-Abfrage) |
| `<leader>ntD` | Liste der geladenen Adapter anzeigen (`neotest.state.adapter_ids()`) |

## Überschreibung durch das Debug-Modul

[lua/config/neotest/debug/init.lua](../../../../../lua/config/neotest/debug/init.lua)
(`M.keymaps`, aufgerufen über `M.setup_all()` **nach** dem obigen Setup) setzt
`<leader>ntr` und `<leader>ntD` **erneut** — letzter `vim.keymap.set`-Aufruf
gewinnt, die Debug-Variante ist also die tatsächlich aktive:

| Mapping | Aktion | Unterschied zur ersten Definition |
|---|---|---|
| `<leader>ntr` | Discovery erzwingen | Zählt zusätzlich rekursiv die gefundenen Tests (`count_tests`) und meldet die Zahl statt nur "gefunden/nicht gefunden". |
| `<leader>ntD` | Adapter-Liste anzeigen | Funktional identisch zur ersten Definition. |

Dieselbe Duplikation existiert auch für die zugehörigen Consumer/Command-Ebenen
nicht — nur die beiden Keymaps sind betroffen.

## which-key-Anbindung

[lua/config/neotest/whichkey/init.lua](../../../../../lua/config/neotest/whichkey/init.lua)
registriert **zusätzlich** eigene, redundante `wk.add`-Einträge für dieselben
neun `<leader>nt*`-Chords aus der Actions-Tabelle (inkl. Gruppen-Label
`<leader>nt` = "Tests"), jeweils mit eigenem `function() require(...) end`-
Wrapper statt der bereits gesetzten `vim.keymap.set`-Callbacks. which-key
zeigt dadurch für diese neun Keys **zwei** überlappende Quellen (eigenes
`vim.keymap.set` + `wk.add`-Callback) — anders als bei Harpoon/DAP, wo
which-key nur ein Gruppen-Label ohne eigene Callbacks anlegt. Funktional macht
das keinen Unterschied (beide rufen dieselbe `actions`-Funktion), ist aber
eine Abweichung vom sonst in dieser Config üblichen Single-Source-Muster.
