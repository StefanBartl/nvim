# nvim-neotest/neotest — Keymaps

`neotest` selbst ist eine reine API-Bibliothek ohne eigene Default-Keymaps.
Alle folgenden Mappings sind daher **[custom]**, gesetzt über zentrale Actions
in [lua/config/neotest/actions/init.lua](../../../../../lua/config/neotest/actions/init.lua)
(gemeinsame Basis für Keymaps, Usercmds und Menüs — siehe Modul-Kommentar
"Centralized Neotest actions usable by keymaps, usercommands and menus").

Registriert im `config`-Block des `nvim-neotest/neotest`-Specs
([lua/plugins/neotest.lua](../../../../../lua/plugins/neotest.lua)):
`require("config.neotest.keymaps").setup()`.

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

Zusätzlich in derselben Tabelle, als `<cmd>`-Mappings auf debugging.nvim
(seit 2026-09-19; vorher das eigene `config/neotest/debug/`-Modul, das
dieselben zwei Keys ein zweites Mal setzte):

| Mapping | Aktion |
|---|---|
| `<leader>ntr` | `:Debug neotest discover` — gefundene Positionen je registriertem Adapter, nach Typ, plus Test-Summe |
| `<leader>ntD` | `:Debug neotest adapters` — konfigurierte (`neotest.setup`) neben registrierten Adaptern (`state.adapter_ids()`) |

Die übrigen vier Diagnosen (`state`, `file`, `root`, `framework`) haben
keinen Key; siehe [Usercmds/Neotest.md](../Usercmds/Neotest.md#debug-commands).

## which-key-Anbindung

[lua/config/neotest/whichkey/init.lua](../../../../../lua/config/neotest/whichkey/init.lua)
registriert **zusätzlich** eigene, redundante `wk.add`-Einträge für dieselben
neun `<leader>nt*`-Chords aus der Actions-Tabelle (inkl. Gruppen-Label
`<leader>nt` = "Tests"), jeweils mit eigenem `function() require(...) end`-
Wrapper statt der bereits gesetzten `vim.keymap.set`-Callbacks. which-key
zeigt dadurch für diese neun Keys **zwei** überlappende Quellen (eigenes
`vim.keymap.set` + `wk.add`-Callback) — anders als bei DAP, wo
which-key nur ein Gruppen-Label ohne eigene Callbacks anlegt. Funktional macht
das keinen Unterschied (beide rufen dieselbe `actions`-Funktion), ist aber
eine Abweichung vom sonst in dieser Config üblichen Single-Source-Muster.
