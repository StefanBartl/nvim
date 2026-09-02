# Gitsigns — User-Commands

Ein einziges Command, **[default]**, und es ist ein Dispatcher: `:Gitsigns`
mit `nargs = "*"` und `range = true`, registriert von `gitsigns.nvim` selbst
in `lua/gitsigns.lua` (`setup_cli`). Diese Config registriert **keinen**
eigenen Gitsigns-Command; was sie ergänzt, sind zwei Keymaps, siehe
[Keymaps/Gitsigns.md](../Keymaps/Gitsigns.md).

Registriert wird es, sobald `require("gitsigns").setup()` läuft — der
Plugin-Spec ist `event = { "BufReadPre", "BufNewFile" }` mit `config = true`
([lua/plugins/git.lua](../../../../../lua/plugins/git.lua)). In einer Session
ohne geöffnete Datei gibt es `:Gitsigns` also nicht.

## `:Gitsigns <subcommand> [args]`

Der Subcommand ist ein Funktionsname aus einem von drei Modulen; die
Argumente werden nach Lua-Werten geparst (`false`/`true`/`nil`/Zahlen, sonst
String). Tab-Completion listet die Subcommands und, wo das Plugin eine
Argument-Completion hinterlegt hat, auch deren Argumente.

### Aus `gitsigns.actions`

| Gruppe | Subcommands |
|---|---|
| Navigation | `nav_hunk` `next_hunk` `prev_hunk` |
| Hunk-Ansicht | `preview_hunk` `preview_hunk_inline` `select_hunk` `get_hunks` |
| Stage / Reset | `stage_hunk` `undo_stage_hunk` `stage_buffer` `reset_hunk` `reset_buffer` `reset_buffer_index` |
| Blame | `blame` `blame_line` `toggle_current_line_blame` |
| Anzeige-Toggles | `toggle_signs` `toggle_numhl` `toggle_linehl` `toggle_word_diff` `toggle_deleted` |
| Diff | `diffthis` `show` `show_commit` `change_base` `reset_base` |
| Listen | `setqflist` `setloclist` |
| Sonstiges | `refresh` `get_actions` |

### Aus `gitsigns.attach`

`attach` `detach` `detach_all` — dieselben drei tauchen auch in `actions` auf.

### Aus `gitsigns.debug`

`debug_messages` `clear_debug` `dump_cache`

## Was diese Config davon tatsächlich benutzt

Nichts über `:Gitsigns`. Die beiden gebundenen Wege rufen die Lua-API direkt
auf:

| Mapping | API-Aufruf | Entspräche |
|---|---|---|
| `<leader>di` | `toggle_word_diff()` + `toggle_linehl()`, dann `preview_hunk_inline()` | drei `:Gitsigns`-Aufrufe |
| `gh` | `preview_hunk_inline()` (Fallback `preview_hunk()`) | `:Gitsigns preview_hunk_inline` |

Das ist kein Versehen: beide Maps prüfen die Verfügbarkeit der Funktion in der
installierten Version und fallen weich zurück, was über die Command-Zeile
nicht geht. Siehe [Keymaps/Gitsigns.md](../Keymaps/Gitsigns.md).
