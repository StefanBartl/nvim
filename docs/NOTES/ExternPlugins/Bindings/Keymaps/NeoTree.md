# Neo-tree — Keymaps

Betrifft `nvim-neo-tree/neo-tree.nvim` (Core) plus die beiden Source-Plugins
`mrbjarksen/neo-tree-diagnostics.nvim` und
`TimCreasman/neo-tree-tests-source.nvim`. `s1n7ax/nvim-window-picker` wird nur
an einem Punkt eingebunden (`W`, `<CR>`-Fallback) und wird deshalb unten als
Unterabschnitt statt als eigene Datei geführt.

Registriert über
[lua/plugins/neotree.lua](../../../../../lua/plugins/neotree.lua), das die
Mapping-Tabellen aus `config.neotree.keymaps.*` an `opts.window.mappings`
(global, gilt für alle Quellen) bzw. `opts.<source>.window.mappings`
(Quellen-spezifisch: `filesystem`, `buffers`, `git_status`,
`document_symbols`, `diagnostics`, `tests`) übergibt.

## Merge-Reihenfolge (wichtig zum Lesen der Tabellen)

Neo-tree merged pro Quelle in dieser Priorität (spätere Ebene überschreibt
frühere, Quelle: `neo-tree.nvim`s `setup/init.lua`, `merge_config`):

1. Neo-tree-eigene **globale** Defaults (`defaults.lua`, `window.mappings`)
2. Neo-tree-eigene **Quellen**-Defaults (z. B. `filesystem.window.mappings`,
   oder die Defaults, die `neo-tree-diagnostics.nvim`/
   `neo-tree-tests-source.nvim` als externe Source-Module mitbringen)
3. Diese Configs **globale** Custom-Mappings
   ([lua/config/neotree/keymaps/init.lua](../../../../../lua/config/neotree/keymaps/init.lua))
4. Diese Configs **Quellen**-spezifische Custom-Mappings
   (`keymaps/filesystem/*.lua`, `keymaps/buffers.lua`, `keymaps/git_status.lua`,
   `keymaps/document_symbols.lua`, `keymaps/diagnostics.lua`,
   `config.neotest.neotree.keymaps()` für `tests`)

`"[default]"` markiert unten Werte, die aus Ebene 1/2 stammen und von dieser
Config **nicht** angefasst werden. `"[custom]"` markiert alles, was diese
Config in Ebene 3/4 setzt — auch wenn der Wert zufällig mit dem Default
identisch ist (dann als *"= Default-Wert, explizit gesetzt"* vermerkt, weil es
den Key aktiv gegen Wegfall/Drift absichert).

Wichtiger Nebeneffekt, der in mehreren Quellen-Dateien per Kommentar
dokumentiert ist: **filetree.nvim** (ein anderes lokales Plugin dieser Config)
hängt für das `filesystem`-Fenster zusätzlich **buffer-lokale**
`FileType neo-tree`-Mappings ein (Trash, Window-Size-Cycler, Tree-Reset,
Reveal-Alt/Open-Variants, Clipboard, Create/Rename/Diff, Shell/Find/Grep/
Markdown-Links). Buffer-lokale Mappings gewinnen in Vim immer gegen die hier
gezeigten `window.mappings`-Tabellen von Neo-tree selbst — deshalb sind Keys
wie `d`, `w`, `<Esc>`, `B`, `<S-CR>`, `gb`, `sg`, `sv`, `st`, `c`/`x`/`p`/
`<C-c>`, `a`/`r`/`D`, `i`/`tf`/`tg`/`ML`/`MR`/`MM` in `filesystem` **de facto**
filetree.nvim-Verhalten, selbst wo die Tabellen unten `noop` oder einen
Neo-tree-Default zeigen. Das ist hier nur vermerkt, nicht im Detail
dokumentiert — siehe die filetree.nvim-eigene Doku für deren Bindings.

---

## Basis-Layer (gilt für alle Quellen, sofern nicht pro Quelle überschrieben)

Registriert in
[lua/config/neotree/keymaps/init.lua](../../../../../lua/config/neotree/keymaps/init.lua)
als `opts.window.mappings` (global).

| Taste | Aktion | Status |
|---|---|---|
| `<space>` | `toggle_node` | [default] |
| `<2-LeftMouse>` | `open` | [default] |
| `<cr>` | `open` | [default] (in `filesystem` durch eigenen Wrapper ersetzt, s. u.) |
| `<esc>` | `cancel` | [default] (in `filesystem` faktisch filetree.nvim's `tree_reset`, s. o.) |
| `P` | `toggle_preview` (float, snacks/image.nvim) | [default] |
| `<C-f>` | `scroll_preview` (−10) | [default] |
| `<C-b>` | `scroll_preview` (+10) | [default] |
| `l` | `focus_preview` | [default] |
| `S` | `open_split` | [default] |
| `s` | `noop` | [custom] (Default wäre `open_vsplit`; Splits laufen pro Quelle über eigene 2-Zeichen-Keys wie `sv`/`sg`/`st`) |
| `t` | `noop` | [custom] (Default wäre `open_tabnew`) |
| `w` | `open_with_window_picker` | [default], aber ungenutzt — bewusst **nicht** in dieser Config gemappt, weil filetree.nvim's `window_size_cycler` (buffer-lokal, `filesystem`) denselben Key belegt und immer gewinnt |
| `W` | `open_with_window_picker` | [custom] (neue Großbuchstaben-Taste als Fallback, siehe [window-picker](#nvim-window-picker-integration) unten) |
| `C` | `close_node` | [custom] (= Default-Wert, explizit gesetzt) |
| `z` | `close_all_nodes` | [custom] (= Default-Wert, explizit gesetzt) |
| `R` | `refresh` | [custom] (= Default-Wert, explizit gesetzt) |
| `a` | `add` | [default] |
| `A` | `add_directory` | [default] |
| `d` | `noop` | [custom] (Default wäre `delete`; in `filesystem` übernimmt filetree.nvim's Trash-Feature `d` buffer-lokal, s. o.) |
| `r` | `rename` | [default] |
| `y` | `copy_to_clipboard` | [default] |
| `x` | `cut_to_clipboard` | [default] |
| `p` | `paste_from_clipboard` | [default] |
| `<C-r>` | `clear_clipboard` | [default] |
| `c` | `copy` | [default] |
| `m` | `move` | [default] |
| `e` | `toggle_auto_expand_width` | [default] |
| `q` | `close_window` | [custom] (= Default-Wert, explizit gesetzt) |
| `?` | `show_help` | [custom] (= Default-Wert, explizit gesetzt) |
| `g?` | `noop` | [custom] (deaktiviert bewusst) |
| `>` | `next_source` | [default] |
| `<` | `noop` | [custom] (Default wäre `prev_source`) |
| `"` | `source_command.next_source()` | [custom] (neue Taste, funktional wie `>`, hält aber die aktuelle Fenster-Position bei) |
| `!` | `source_command.prev_source()` | [custom] (neue Taste, Ersatz für das deaktivierte `<`) |

Quelle für `"`/`!`:
[lua/config/neotree/commands/source/init.lua](../../../../../lua/config/neotree/commands/source/init.lua).

---

## Quelle: `filesystem`

Custom-Layer:
[lua/config/neotree/keymaps/filesystem/init.lua](../../../../../lua/config/neotree/keymaps/filesystem/init.lua)
(bündelt nur noch
[filesystem/files.lua](../../../../../lua/config/neotree/keymaps/filesystem/files.lua)
— alle anderen früheren Module (`filter`, `save`, `replace`, `mark`,
`navigation`, `path`, `info`, `search`, `preview`, `images`, `pdfport`,
`trash`, `clipboard`, `create`, `commands`) wurden entfernt, weil
filetree.nvim dieselben Keys buffer-lokal und default-on belegt — ein zweites
natives Neo-tree-Mapping war totes Gewicht, das mit demselben Key racete).

| Taste | Aktion | Status |
|---|---|---|
| `<CR>` | Custom-Wrapper: sicheres Expand/Collapse von Directories, sonst `open_with_window_picker` (Fallback `open`, falls `window-picker` fehlt). Von filetree.nvim's `preview`-Feature als `original_cr_cb` eingebunden. | [custom] |
| `<2-LeftMouse>` | `open` | [custom] (= Default-Wert, explizit gesetzt) |
| `H` | `toggle_hidden` | [default] |
| `/` | `fuzzy_finder` | [default] |
| `D` | `fuzzy_finder_directory` | [default] |
| `#` | `fuzzy_sorter` | [default] |
| `f` | `filter_on_submit` | [default] |
| `<C-x>` | `clear_filter` | [default] |
| `<bs>` | `navigate_up` | [default] |
| `.` | `set_root` | [default] |
| `[g` / `]g` | `prev_git_modified` / `next_git_modified` | [default] |
| `i` | `show_file_details` | [default] |
| `b` | `rename_basename` | [default] |
| `o`, `oc`, `od`, `og`, `om`, `on`, `os`, `ot` | Order-by-Untermenü (created/diagnostics/git_status/modified/name/size/type) | [default] |

Entfernte, jetzt von filetree.nvim gehaltene Keys (nur zur Einordnung, nicht
Teil dieser Config mehr): `d` (Trash), `w` (Window-Size-Cycler), `<Esc>`
(Tree-Reset), `B`/`<S-CR>`/`gb`/`sg`/`sv`/`st` (Reveal-Alt/Open-Variants),
`c`/`x`/`p`/`<C-c>` (Clipboard/Copy-Move), `a`/`r`/`D` (Smart-Create/-Rename/
Diff), `i`/`tf`/`tg`/`ML`/`MR`/`MM` (Shell-Run/Find-Files/Grep-in-Dir/
Markdown-Links).

### nvim-window-picker-Integration

`s1n7ax/nvim-window-picker` wird eigenständig konfiguriert in
[lua/plugins/ui.lua](../../../../../lua/plugins/ui.lua) (`filter_rules`:
Neo-tree-, Popup- und Notify-Fenster werden von der Auswahl ausgeschlossen,
`autoselect_one = true`). Es bringt selbst keine Keymaps mit — es wird nur an
zwei Stellen aufgerufen:

- `W` im Basis-Layer → `open_with_window_picker` (Neo-tree-Command, ruft
  intern `window-picker` auf).
- `<CR>` in `filesystem/files.lua` → versucht
  `state.commands.open_with_window_picker`, fällt bei fehlendem
  `window-picker` (`pcall(require, "window-picker")` schlägt fehl) auf
  `state.commands.open` zurück.

---

## Quelle: `buffers`

Custom-Layer:
[lua/config/neotree/keymaps/buffers.lua](../../../../../lua/config/neotree/keymaps/buffers.lua).
Basis-Defaults der Quelle selbst (aus `neo-tree.nvim`s `defaults.lua`):

| Taste | Aktion | Status |
|---|---|---|
| `<bs>` | `navigate_up` | [default] |
| `.` | `set_root` | [default] |
| `d`, `bd` | `buffer_delete` | [default] |
| `i` | `show_file_details` | [default] |
| `b` | `rename_basename` | [default] |
| `o`, `oc`, `od`, `om`, `on`, `os`, `ot` | Order-by-Untermenü | [default] |

Custom-Overrides/-Additions dieser Config:

| Taste | Aktion | Status |
|---|---|---|
| `dd` | `buffer_delete` | [custom] (zweite Taste zusätzlich zum Default `d`/`bd`) |

Zusätzlich deaktiviert (`noop`) — filesystem-spezifische Aktionen, die in
`buffers` keinen Sinn ergeben, teils Defaults, teils präventiv gegen sonst
leere/undefinierte Keys: `+`, `-`, `a`, `A`, `c`, `D`, `I`, `L`, `M`, `m`, `O`,
`p`, `r`, `U`, `x`, `Y`, `fm`, `gb`, `gr`, `rq`, `sm`, `[F`, `[f`, `[p`, `[r`,
`[t`, `]p`, `]r`, `]t`, `<C-s>`, `<M-s>`, `<S-CR>`. Alle `[custom]`.

---

## Quelle: `git_status`

Custom-Layer:
[lua/config/neotree/keymaps/git_status.lua](../../../../../lua/config/neotree/keymaps/git_status.lua).
Basis-Defaults der Quelle selbst:

| Taste | Aktion | Status |
|---|---|---|
| `A` | `git_add_all` | [default] |
| `gu` | `git_unstage_file` | [default] |
| `gU` | `git_undo_last_commit` | [default] |
| `ga` | `git_add_file` | [default] |
| `gt` | `git_toggle_file_stage` | [default] |
| `gr` | `git_revert_file` | [default] |
| `gc` | `git_commit` | [default] |
| `gp` | `git_push` | [default] |
| `gg` | `git_commit_and_push` | [default] |
| `i` | `show_file_details` | [default] |
| `b` | `rename_basename` | [default] |
| `o`, `oc`, `od`, `om`, `on`, `os`, `ot` | Order-by-Untermenü | [default] |

Custom-Overrides/-Additions dieser Config:

| Taste | Aktion | Status |
|---|---|---|
| `dd` | `delete` | [custom] (neue Taste zusätzlich zum Basis-`d`, das global auf `noop` steht) |

Zusätzlich deaktiviert (`noop`): `+`, `-`, `a`, `c`, `d`, `m`, `p`, `r`, `x`,
`A`, `D`, `I`, `L`, `M`, `O`, `U`, `Y`, `gb`, `rq`, `[f`, `[F`, `[p`, `[r`,
`[t`, `]p`, `]r`, `]t`, `<CR>`, `<S-CR>`, `<C-s>`, `<M-s>`. Alle `[custom]`.
`A` und `gr` sind darunter bewusst: Beide tauchen als neo-tree-eigener Default
auf (`git_add_all`, `git_revert_file`), werden hier aber gezielt auf `noop`
gelegt — Absicht laut Datei-Kommentar ("Disable filesystem operations"), keine
zufällige Kollision. Es handelt sich um zwei Layer (Basis-Default aus
`neo-tree.nvim`s `defaults.lua` vs. diese Custom-Override-Tabelle für die
`git_status`-Quelle), nicht um doppelte Keys im selben Lua-Literal.

---

## Quelle: `document_symbols`

Custom-Layer:
[lua/config/neotree/keymaps/document_symbols.lua](../../../../../lua/config/neotree/keymaps/document_symbols.lua).
Basis-Defaults der Quelle selbst:

| Taste | Aktion | Status |
|---|---|---|
| `<cr>` | `jump_to_symbol` | [default] |
| `o` | `jump_to_symbol` | [default] |
| `/` | `filter` | [default] |
| `f` | `filter_on_submit` | [default] |
| `A`, `d`, `y`, `x`, `p`, `c`, `m`, `a` | `noop` | [default] (Quelle deaktiviert diese Filesystem-Aktionen bereits selbst) |

Custom-Overrides/-Additions dieser Config:

| Taste | Aktion | Status |
|---|---|---|
| `l` | `jump_to_symbol` | [custom] (zusätzliche Taste neben `o`/`<CR>`) |
| `F` | `filter` | [custom] (Großbuchstaben-Variante zusätzlich zu `/`) |
| `f` | `filter_on_submit` | [custom] (= Default-Wert, explizit gesetzt) |

Zusätzlich deaktiviert (`noop`), über die Quellen-Defaults hinaus: `+`, `-`,
`c`\*, `d`\*, `m`\*, `p`\*, `r`, `x`\*, `A`\*, `D`, `I`, `L`, `M`, `O`, `U`,
`Y`, `dd`, `gb`, `gr`, `rl`, `st`, `sv`, `[f`, `[F`, `[p`, `[r`, `[t`, `]p`,
`]r`, `]t`, `<S-CR>`, `<C-b>`, `<C-c>`, `<C-f>`, `<C-s>`, `<M-s>`, `<Tab>`,
`<leader>mc`, `<leader>th`, `<PageDown>`, `<PageUp>`. Alle `[custom]` (\* =
bereits von der Quelle selbst als `noop` vordefiniert, hier redundant erneut
gesetzt).

---

## Quelle: `diagnostics`

Bereitgestellt von `mrbjarksen/neo-tree-diagnostics.nvim` als externe
Neo-tree-Source. Deren eigene `defaults.lua` liefert **keine**
Quellen-spezifischen `window.mappings` (`mappings = {}`) — die Quelle erbt
also ausschließlich den Basis-Layer von Neo-tree selbst (siehe oben).

Custom-Layer dieser Config:
[lua/config/neotree/keymaps/diagnostics.lua](../../../../../lua/config/neotree/keymaps/diagnostics.lua).

| Taste | Aktion | Status |
|---|---|---|
| `o` | `open` | [custom] (neue Taste) |
| `<CR>` | `open` | [custom] (überschreibt Basis-`open`, hier explizit gleich) |
| `<2-LeftMouse>` | `open` | [custom] (= Basis-Default, explizit gesetzt) |
| `sg` | `open_vsplit` | [custom] (neue Taste, da Basis-`s` global `noop` ist) |
| `st` | `open_tabnew` | [custom] (neue Taste, da Basis-`t` global `noop` ist) |
| `sv` | `open_split` | [custom] (neue Taste) |
| `<Tab>` | `toggle_preview` | [custom] (neue Taste) |
| `R` | `refresh` | [custom] (= Basis-Wert, explizit gesetzt) |

Zusätzlich deaktiviert (`noop`) — Filesystem-Aktionen ohne Bedeutung in
`diagnostics`: `+`, `-`, `a`, `c`, `d`, `m`, `p`, `r`, `x`, `A`, `D`, `I`, `L`,
`M`, `U`, `Y`, `dd`, `fm`, `gb`, `gr`, `rq`, `sm`, `[f`, `[F`, `[p`, `[r`,
`[t`, `]p`, `]r`, `]t`, `<S-CR>`, `<C-s>`, `<M-s>`, `<S-o>`, `<leader>mc`,
`<leader>th`. Alle `[custom]`.

---

## Quelle: `tests`

Bereitgestellt von `TimCreasman/neo-tree-tests-source.nvim` als externe
Neo-tree-Source, über `neotest` angebunden. Deren eigene `defaults.lua`
liefert Quellen-spezifische Defaults:

| Taste | Aktion | Status |
|---|---|---|
| `r` | `run_tests` | [default] |
| `u` | `stop_tests` | [default] |
| `d` | `debug_tests` | [default, aber unerreichbar — überschrieben, s. u.] |
| `R` | `run_all_tests` | [default, aber unerreichbar — überschrieben, s. u.] |
| `w` | `watch_tests` | [default] |
| `o` | `show_test_output` | [default, aber unerreichbar — überschrieben, s. u.] |
| `<cr>` | `open` (`expand_nested_files = true`) | [default, aber unerreichbar — überschrieben, s. u.] |

Diese Config bindet **keine** eigene Tabelle unter
`config/neotree/keymaps/` für `tests` ein (ein `config.neotree.keymaps.tests`-
Require ist in
[lua/plugins/neotree.lua](../../../../../lua/plugins/neotree.lua) auskommentiert).
Stattdessen liefert
[lua/config/neotest/neotree/init.lua](../../../../../lua/config/neotest/neotree/init.lua)
(`NEOTEST.keymaps()`) die komplette, source-eigene `window.mappings`-Tabelle:

| Taste | Aktion | Status |
|---|---|---|
| `T` | `neotest_run_nearest` | [custom] |
| `F` | `neotest_run_file` | [custom] |
| `A` | `neotest_run_all` | [custom] (überschreibt Basis-Default `add_directory`) |
| `D` | `neotest_debug` | [custom] (neue Großbuchstaben-Taste, kollidiert nicht mit Quellen-Default `d`) |
| `S` | `neotest_summary` | [custom] (überschreibt Basis-Default `open_split`) |
| `O` | `neotest_output` | [custom] |
| `R` | `neotest_refresh` | [custom] (überschreibt Quellen-Default `run_all_tests`, ruft `sources.tests.navigate` erneut auf) |

Effektiv im `tests`-Fenster erreichbar sind also: Basis-Layer (siehe oben,
inkl. `s`/`t` → `noop`, `q`/`?`/`C`/`z` etc.), überlagert von den
Quellen-Defaults `r`/`u`/`w`/`d`\*/`R`\*/`o`\*/`<cr>`\* (\* = durch
`NEOTEST.keymaps()` unten erneut überschrieben), überlagert von
`T`/`F`/`A`/`D`/`S`/`O`/`R` aus `NEOTEST.keymaps()`. Da `NEOTEST.keymaps()`
komplett anstelle einer weiteren Custom-Tabelle registriert wird, gibt es hier
— anders als bei den anderen Quellen — keine separate `noop`-Deaktivierungs-
Liste; nicht genannte Keys fallen einfach auf Basis-Layer/Quellen-Default
zurück.

Command-Registry für die obigen Aktionen:
[lua/config/neotest/neotree/init.lua](../../../../../lua/config/neotest/neotree/init.lua)
`M.commands()`, dünne Wrapper um
[lua/config/neotest/actions/](../../../../../lua/config/neotest/actions/).

---

## Außerhalb von Neo-tree-Fenstern (globale Keymaps)

Registriert in
[lua/config/neotree/window/open/keymaps/only_lhs.lua](../../../../../lua/config/neotree/window/open/keymaps/only_lhs.lua)
(aktiviert via `only_lhs = true` in `lua/plugins/neotree.lua`s `config`-Block)
und
[lua/config/neotree/keymaps/global.lua](../../../../../lua/config/neotree/keymaps/global.lua).
Beides `[custom]` — Neo-tree selbst definiert außerhalb seiner eigenen Fenster
keine Keymaps, nur das Usercmd `:Neotree` (siehe
[Usercmds/NeoTree.md](../Usercmds/NeoTree.md)).

| Mapping | Aktion | Status |
|---|---|---|
| `<M-c>` | Neo-tree togglen, Position `current` (ersetzt aktuelles Fenster), `reveal` + `reveal_force_cwd` | [custom] |
| `<M-f>` | Neo-tree togglen, Position `float` | [custom] |
| `<M-l>` | Neo-tree togglen, Position `left` | [custom] |
| `<M-r>` | Neo-tree togglen, Position `right` | [custom] |
| `<leader>ns` | Source-Switcher-Picker öffnen (`config.neotree.sources.switcher`) | [custom] |

Das alternative Modul `window/open/keymaps/reveal_current_file.lua` (per
`reveal_current_file = true` aktivierbar) existiert in dieser Config **nicht
mehr** — der `setup()`-Aufruf in `lua/plugins/neotree.lua` setzt
`reveal_current_file = false` und `only_lhs = true`, sodass ausschließlich die
obigen `<M-*>`-Mappings aktiv sind.
