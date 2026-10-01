# nvim-neotest/neotest — Keymaps

`neotest` selbst ist eine reine API-Bibliothek ohne eigene Default-Keymaps.
Alle folgenden Mappings sind daher **[custom]**, gesetzt über zentrale Actions
in [lua/config/neotest/actions/init.lua](../../../../../lua/config/neotest/actions/init.lua)
(gemeinsame Basis für Keymaps, Usercmds und Menüs — siehe Modul-Kommentar
"Centralized Neotest actions usable by keymaps, usercommands and menus").

Bis neotest geladen ist, sind die Chords Lazy-Stubs (`keys` in
[lua/plugins/neotest.lua](../../../../../lua/plugins/neotest.lua), aus
derselben `config.neotest.keymaps.keymaps`-Liste gebaut): der erste Druck lädt
neotest und spielt die Taste in die echte Belegung nach. Die echten Mappings
setzt der `config`-Block des `nvim-neotest/neotest`-Specs:
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
registriert nur das Gruppen-Label `<leader>nt` = "Tests", über
`which_key.add_group` aus lib.nvim. Das lädt which-key nie: ist es schon da,
gilt das Label sofort, sonst wartet es in der Warteschlange bis zum Laden. Der
Aufruf steht in `bindings.mappings.setup()`
([lua/bindings/mappings/init.lua](../../../../../lua/bindings/mappings/init.lua)),
nicht im `config`-Block von neotest: das Label muss vor dem ersten Druck
existieren, solange neotest noch nicht geladen ist.

Die einzelnen Keys brauchen kein `wk.add`: which-key nimmt ihre Beschriftung
aus dem `desc` des Mappings (zuerst der des Lazy-Stubs, danach der des echten
Mappings). Es gibt also genau eine Quelle pro Key, wie bei DAP. Das Modul hat
früher alle neun Keys zusätzlich per `wk.add` angelegt; das ist mit 59de4d68
entfallen.
