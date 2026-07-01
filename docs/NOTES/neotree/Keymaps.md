# Neo-tree Keymaps Übersicht

## Table of content

  - [init (global, außerhalb von Sources)](#init-global-auerhalb-von-sources)
  - [global](#global)
  - [buffers](#buffers)
  - [diagnostics](#diagnostics)
  - [document_symbols](#document_symbols)
  - [git_status](#git_status)
  - [tests](#tests)
  - [filesystem/filter](#filesystemfilter)
  - [filesystem/commands](#filesystemcommands)
  - [filesystem/files](#filesystemfiles)
  - [filesystem/save](#filesystemsave)
  - [filesystem/replace](#filesystemreplace)
  - [filesystem/clipboard](#filesystemclipboard)
  - [filesystem/create](#filesystemcreate)
  - [filesystem/trash](#filesystemtrash)
  - [filesystem/mark](#filesystemmark)
  - [filesystem/navigation](#filesystemnavigation)
  - [filesystem/path](#filesystempath)
  - [filesystem/info](#filesysteminfo)
  - [filesystem/search](#filesystemsearch)
  - [filesystem/preview](#filesystempreview)
  - [filesystem/images](#filesystemimages)
  - [filesystem/pdfport](#filesystempdfport)

---

## init (global, außerhalb von Sources)

| Mapping | Info |
| --- | --- |
| `d` | noop (Standard-Delete deaktiviert; wird von filesystem-Source mit custom Trash-Handler überschrieben) |
| `q` | close_window |
| `?` | show_help |
| `g?` | noop |
| `<Esc>` | Setzt Filesystem-Suche/Filter zurück, versteckt Preview-Fenster, löscht Suchhighlights (`nohlsearch`), verlässt Watcher-Quarantäne falls aktiv |
| `"` | Zur nächsten Source wechseln |
| `!` | Zur vorherigen Source wechseln |
| `<` | noop |
| `R` | refresh |
| `C` | close_node |
| `z` | close_all_nodes |
| `W` | open_with_window_picker |
| `w` | Fenstergröße zyklisch umschalten (normal → large → small → normal) |
| `s` | noop (wird pro Source aktiviert) |
| `t` | noop (wird pro Source aktiviert) |

---

## global

| Mapping | Info |
| --- | --- |
| `<leader>ns` | Öffnet Source-Switcher-Picker (außerhalb des Neo-tree-Fensters nutzbar) |

---

## buffers

| Mapping | Info |
| --- | --- |
| `dd` | buffer_delete |
| `+`, `-`, `a`, `A`, `c`, `D`, `I`, `L`, `M`, `m`, `O`, `p`, `r`, `U`, `x`, `Y` | noop (Filesystem-spezifische Operationen deaktiviert) |
| `fm`, `gb`, `gr`, `rq`, `sm` | noop |
| `[F`, `[f`, `[p`, `[r`, `[t`, `]p`, `]r`, `]t` | noop |
| `<C-s>`, `<M-s>`, `<S-CR>` | noop |

---

## diagnostics

| Mapping | Info |
| --- | --- |
| `o` | open |
| `<CR>` | open |
| `<2-LeftMouse>` | open |
| `sg` | open_vsplit |
| `st` | open_tabnew |
| `sv` | open_split |
| `<Tab>` | toggle_preview |
| `R` | refresh |
| `+`, `-`, `a`, `c`, `d`, `m`, `p`, `r`, `x`, `A`, `D`, `I`, `L`, `M`, `U`, `Y` | noop |
| `dd`, `fm`, `gb`, `gr`, `rq`, `sm` | noop |
| `[f`, `[F`, `[p`, `[r`, `[t`, `]p`, `]r`, `]t` | noop |
| `<S-CR>`, `<C-s>`, `<M-s>`, `<S-o>` | noop |
| `<leader>mc`, `<leader>th` | noop |

---

## document_symbols

| Mapping | Info |
| --- | --- |
| `l` | jump_to_symbol |
| `o` | jump_to_symbol |
| `<CR>` | jump_to_symbol |
| `<2-LeftMouse>` | jump_to_symbol |
| `F` | filter |
| `f` | filter_on_submit |
| `+`, `-`, `/`, `a`, `c`, `d`, `m`, `p`, `r`, `x` | noop |
| `A`, `D`, `I`, `L`, `M`, `O`, `U`, `Y` | noop |
| `dd`, `gb`, `gr`, `rl`, `st`, `sv` | noop |
| `[f`, `[F`, `[p`, `[r`, `[t`, `]p`, `]r`, `]t` | noop |
| `<S-CR>`, `<C-b>`, `<C-c>`, `<C-f>`, `<C-s>`, `<M-s>`, `<Tab>` | noop |
| `<leader>mc`, `<leader>th` | noop |
| `<PageDown>`, `<PageUp>` | noop |

---

## git_status

| Mapping | Info |
| --- | --- |
| `dd` | delete |
| `+`, `-`, `a`, `c`, `d`, `m`, `p`, `r`, `x` | noop |
| `A`, `D`, `I`, `L`, `M`, `O`, `U`, `Y` | noop |
| `gb`, `gr`, `rq` | noop |
| `[f`, `[F`, `[p`, `[r`, `[t`, `]p`, `]r`, `]t` | noop |
| `<CR>`, `<S-CR>`, `<C-s>`, `<M-s>` | noop |

---

## tests

Hinweis: laut Audit-Kommentar im Source derzeit nicht verwendet.

| Mapping | Info |
| --- | --- |
| `<cr>` | open |
| `<esc>` | cancel |
| `<2-LeftMouse>` | open |
| `t` | run_test (Test unter Cursor ausführen) |
| `T` | run_file (alle Tests in Datei) |
| `d` | debug_test |
| `w` | watch_test |
| `s` | stop_test |
| `o` | show_output |
| `r` | refresh |
| `q` | close_window |
| `?` | show_help |

---

## filesystem/filter

| Mapping | Info |
| --- | --- |
| `/` | noop |
| `f` | filter_on_submit |
| `F` | fuzzy_finder |
| `<C-c>` | clear_filter |

---

## filesystem/commands

| Mapping | Info |
| --- | --- |
| `i` | run_command |
| `tf` | telescope_find |
| `tg` | telescope_grep |
| `ML` | markdown_links |
| `MR` | markdown_links_recursive |
| `MM` | markdown_links_from_marked |

---

## filesystem/files

| Mapping | Info |
| --- | --- |
| `B` | Reveal des Alternate-Buffer-Pfads (Semantik analog zu `:e #`); normalisiert auf absoluten Pfad, fokussiert Neo-tree und passt cwd-Root bei Bedarf an |
| `<CR>` | Sicheres Expand/Collapse von Verzeichnissen bzw. Öffnen von Dateien; versteckt vorher die Preview, nutzt window-picker falls vorhanden |
| `<2-LeftMouse>` | open |
| `<S-CR>` | open_badd |
| `gb` | open_badd |
| `sg` | open_vsplit |
| `sv` | open_split |
| `st` | open_tabnew |

---

## filesystem/save

| Mapping | Info |
| --- | --- |
| `<C-s>` | Erzwingt Speichern (`w!`) des letzten normalen (adjazenten) Buffers |
| `<M-s>` | Erzwingt Speichern (`w!`) des Buffers, der dem Node unter dem Cursor entspricht |

---

## filesystem/replace

| Mapping | Info |
| --- | --- |
| `O` | Öffnet Datei unter Cursor und ersetzt den aktuellen Buffer (focus + auto_close) |

---

## filesystem/clipboard

| Mapping | Info |
| --- | --- |
| `c` | Kopiert markierte/aktuelle Nodes in die Zwischenablage |
| `x` | Schneidet markierte/aktuelle Nodes in die Zwischenablage aus |
| `p` | Fügt aus Zwischenablage in aktuelles Verzeichnis ein |
| `<C-c>` | Leert die Zwischenablage (`state.clipboard = nil`) |

---

## filesystem/create

| Mapping | Info |
| --- | --- |
| `a` | custom_add (mit `insert_clipb = true`, ohne Bestätigungsdialog) |
| `D` | diff_files (zwei Dateien markieren, dann auslösen) |
| `r` | rename |

---

## filesystem/trash

| Mapping | Info |
| --- | --- |
| `d` | Löscht markierte Dateien bzw. Datei unter Cursor (in den Papierkorb) |
| `U` | Macht letzten Trash-Vorgang rückgängig |
| `<leader>th` | Zeigt Trash-Verlauf an |

---

## filesystem/mark

| Mapping | Info |
| --- | --- |
| `m` | Markierung einer einzelnen Datei umschalten |
| `]m` | Alle Dateien im Verzeichnis markieren |
| `[m` | Alle Dateien im Verzeichnis demarkieren |
| `<C-m>` | Alle Markierungen löschen |
| `<leader>ms` | Markierte Nodes anzeigen |

---

## filesystem/navigation

| Mapping | Info |
| --- | --- |
| `+` | In Verzeichnis navigieren und als neue Root setzen |
| `-` | Eine Ebene nach oben navigieren |

---

## filesystem/path

| Mapping | Info |
| --- | --- |
| `[a` | Absoluten Pfad in Register `+` kopieren |
| `]a` | Absoluten Basis-Pfad (Verzeichnis) in Register `+` kopieren |
| `[f` | Absoluten Dateipfad (Datei-Node) bzw. rekursive Dateiliste (Verzeichnis-Node) in Register `+` kopieren |
| `]f` | Relativen Dateipfad (zu cwd) bzw. rekursive Dateiliste in Register `+` kopieren |
| `[F` | Absoluten Ordnerpfad (Datei-Node) bzw. rekursive Ordnerliste (Verzeichnis-Node) in Register `+` kopieren |
| `]F` | Relativen Ordnerpfad (zu cwd) bzw. rekursive Ordnerliste in Register `+` kopieren |

---

## filesystem/info

| Mapping | Info |
| --- | --- |
| `I` | Zeigt Datei-/Verzeichnisinformationen an (Hover inkl. Zeilenanzahl, lazy berechnet nur für Dateien) |
| `<leader>fm` | Öffnet Node im System-Dateimanager |
| `<leader>sm` | Öffnet Node mit Standard-Systemanwendung |
| `rq` | Kopiert Lua-`require()`-String(s) des Node (relativ, mit Vorschau) |

---

## filesystem/search

| Mapping | Info |
| --- | --- |
| `gr` | Live-Grep im Node-Verzeichnis (automatische Backend-Wahl) |
| `<leader>gt` | Live-Grep explizit über Telescope |
| `<leader>gf` | Live-Grep explizit über fzf-lua |

---

## filesystem/preview

| Mapping | Info |
| --- | --- |
| `<Tab>` | Schaltet das schwebende Preview-Fenster um (Fallback: manuelles `hide`, falls `toggle_preview` fehlschlägt); nur aktiv wenn Fokus im Neo-tree-Buffer liegt |
| `<C-b>` | scroll_preview (direction = 1) |
| `<C-f>` | scroll_preview (direction = -1) |
| `<PageUp>` | scroll_preview (direction = 10) |
| `<PageDown>` | scroll_preview (direction = -10) |

---

## filesystem/images

| Mapping | Info |
| --- | --- |
| `<Tab>` | Bild-Node: öffnet in Standard-Systemanwendung (`xdg-open`/`open`/`wslview`/`cmd.exe start`, plattformabhängig). Anderer Node: Fallback auf toggle_preview |
| `<CR>` | Bild-Node: öffnet in Standard-Systemanwendung. Anderer Node: Fallback auf Expand/Open-Verhalten wie in `files.lua` |

Hinweis: `images.lua` exportiert `is_image_path()` und `open_in_system_app()` zur Wiederverwendung durch `pdfport.lua`.

---

## filesystem/pdfport

| Mapping | Info |
| --- | --- |
| `<Tab>` | PDF-Node: pdfport Quick-Open (pdftotext-Buffer). Bild-Node: Standard-Systemanwendung. Anderer Node: Fallback auf toggle_preview |
| `<CR>` | PDF-Node: pdfport Quick-Open. Bild-Node: Standard-Systemanwendung. Anderer Node: Fallback auf Expand/Open-Verhalten wie in `files.lua` |

Merge-Reihenfolge für `<Tab>` und `<CR>` (laut `filesystem/init.lua`, letzter Eintrag gewinnt):

`preview.lua` → `images.lua` → `pdfport.lua`

Damit gilt für beide Tasten: PDF-Erkennung schlägt Bild-Erkennung, Bild-Erkennung schlägt das generische Preview-Toggle bzw. Expand/Open-Verhalten.

---

