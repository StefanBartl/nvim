# Analyse: User-Dialoge in allen Plugins

## Das Dialog-Modul
- Das Modul aus filetree.nvim `d` ist `ui.kit` (ui.nvim, `lua/ui/kit/`). Es ist kein filetree-Code.
  filetree kapselt es nur in `util/confirm.lua` (Ja/Nein plus Info-Body) und `util/confirm_choice.lua` (bis 4 Buttons).
- Das kit hat Buttons per Tastatur (h/l, Tab, CR, Esc/q) und per Maus (Klick = fokussieren und bestätigen), ein Theme/Preset-System
  und weitere Komponenten: `confirm`, `ask` (Warteschlange), `input`, `form`, `select`, `prompt`, `menu`, `picker`, `chooser`, `toast`.
- **Zwei divergierende Kopien:** `ui.nvim/lua/ui/kit` und `lib.nvim/lua/lib/nvim/ui/kit` (diff ca. 2000 Zeilen).
  Die lib-README erklärt `ui.kit` zur Quelle; `kit_drift_spec` in ui.nvim prüft die Abweichung.

## Bereits umgestellt (Referenz)
filetree, fileops, gopath, casedesk (`kit.ask`), tasks.nvim `ui/confirm.lua` und nvim `plugin_repos/confirm.lua` (beide mit
`vim.ui.select`-Fallback ohne ui.nvim).

## Noch nativ (ohne ui.kit): ca. 100 Stellen
Zählung außerhalb TESTS. Aufwand: S = Einzeiler tauschen, M = Logik umbauen, L = größerer Umbau.

### A. Ja/Nein und Mehrfach-Buttons -> `kit.confirm` / `kit.ask`
| Repo | Stelle | Nativ | Aufw. |
|---|---|---|---|
| images | `init.lua:625` Delete?, `calibrate.lua:271` Save/Just show | confirm / select | S |
| markdown | `core/heading_gaps.lua:113` | fn.confirm | S |
| color_my_ascii | `commands/fence/export.lua:82` | fn.confirm | S |
| buffer-ctx | `format/table_fmt.lua:153` | fn.confirm | S |
| sessions | `marks/menu.lua:142`, `bindings/usercmds/init.lua:287` | fn.confirm | S |
| ui | `tabufline/init.lua:180`, `tabufline/state.lua:481` (Discard changes) | fn.confirm | S |
| lib | `progress/styles/float.lua:110`, `kit.lua:149` (Abort?), `deps/view.lua:299`, `deps/install/init.lua:159`, `deps/project/init.lua:791` | fn.confirm | S-M (lib darf ui.nvim nur weich verwenden) |
| nvim | `usrcmds/execute/init.lua:85` | fn.confirm (n Optionen) | S |
| docmap | `ask.lua:32` | ui.select "No/Yes, x" | S |
| gitsuite | `conflict/init.lua:243`, `plugins/init.lua:455` | ui.select Ja/Nein | S |
| testing | `bindings/usrcmds.lua:420` | ui.select Ja/Nein | S |
| insights | `bindings/usrcmds.lua:502` | ui.select Build/Skip | S |
| data | `preview.lua:189` Apply/Discard | ui.select | S |
| pickers | `browse/init.lua:259` Delete? | ui.select yes/no | S |
| gopath | `create.lua:200` | ui.select | S |
| tasks | `ui/confirm.lua:48,79` (hat kit, nur Fallback) | ok | - |
| casedesk | `ai/confirm.lua:34` (nur Fallback) | ok | - |

### B. Texteingabe -> `kit.input` / `kit.form` / `kit.prompt`
images (`paste.lua:498,623,676`, `zen.lua:1911`), cmdlog (`ui/mappings.lua:132` Tag), pdfport (`util/page_range.lua:67`),
color_my_ascii (`export.lua:109`), buffer-ctx (`column_align.lua:236`), gitsuite (`dashboard/view.lua:1614`),
tasks (`ui/dash.lua:594,646,792`, `vault_cmd.lua:587`, `cmd.lua:1094` Feldweise = `kit.form`), rules (`vault_cmd.lua:602`, `report/review.lua:155`),
runtime-analysis (`telemetry/command.lua:210`), pickers (`dir_nav_picker.lua:72`, `browse/init.lua:118`, `refine/init.lua:237`),
gopath (`create.lua:216`), lib (`keymap/modifier/init.lua:297`).
Hinweis: `vim.fn.input` in images/paste ist blockierend und liefert synchron. Der Umbau macht den Aufrufer asynchron (M).

### C. Auswahllisten -> `kit.select` / `kit.menu` / `kit.picker`
Dies sind keine Dialoge im engeren Sinn, aber dasselbe Design wäre nötig: data, media (dashboard), images (init, browse, paste),
pdfport (picker), markdown (util/picker), buffer-ctx (commands), gitsuite (branch, plugins, conflict), diff (pickers_bridge),
open (picker), tasks (dash.lua, cmd.lua: rund 10), gopath (tailsearch, task_id, alternate/ui), pickers (6 Stellen),
cascade (word_cycle), testing, emojis (2), lsp (peek), nvim (sync_dash), ui (git_clickable, variant, usrcmds), rules,
runtime-analysis (2), lib (harvest/sink, keymap/modifier).
Das sind ca. 55 Stellen. Viele davon sind echte Picker (lange Listen, Suche). Dort `kit.select` bzw. `kit.picker` und kein Button-Dialog.

### D. Kein Handlungsbedarf
debugging (`keylogger.lua`) nutzt getcharstr bewusst. ui `windowpicker` (`getchar(1)`) und ui `screenkey` sind Tastaturlogik, keine Dialoge.
testing `guard/prompt.lua` fängt fremde Prompts ab (Test-Guard). Dokumentation und Beispiele (`lib.nvim/docs/EXAMPLES`) bleiben.

## Befunde und Risiken
1. **Zwei kit-Kopien.** Vor der Migration entscheiden: Alle Plugins (und lib) nutzen `require("ui.kit")`. Neue Features nur dort.
2. **Single-Instance:** `kit.confirm` schließt einen offenen Dialog ohne Antwort. Für Dialoge, die zu unvorhersehbaren Zeiten
   erscheinen (Callbacks, Streams, Autocmds), `kit.ask` verwenden (casedesk-Muster).
3. **Plugins ohne ui.nvim-Abhängigkeit** (lib.nvim, ggf. images, pdfport): weiche Abhängigkeit mit Fallback (Muster `tasks_nvim.ui.confirm`).
   Dieses Fallback-Muster ist 3x dupliziert (tasks, nvim, casedesk) und gehört als `ui.kit.confirm_soft` oder in lib.nvim.
4. **Sync -> async:** `vim.fn.confirm`/`input` liefern synchron, `kit.*` per Callback. Es gibt `kit.sync(open_fn, opts, timeout_ms)` als Brücke.
   Besser ist es, die Aufrufer auf Callbacks umzubauen.
5. **Konsistenz:** Standardbuttons uneinheitlich ("Yes/No", "Ja/Nein", "yes/no", "Apply/Discard"). Destruktive Aktion nie als Erstes (CR-Fehlbedienung).
   Konvention: "No" zuerst, Beschriftung "Yes, <aktion>".
6. **Breite:** Zu lange Fragezeilen schieben die Buttons aus dem Fenster (`shorten` in tasks). Das gehört ins kit.

## Vorschlag Umsetzung
- Stufe 0: kit-Entscheidung (Kopien) und `ui.kit.confirm_soft`-Helfer mit Fallback, Breitenbegrenzung, Standardlabels.
- Stufe 1 (je Repo S, 1 Task/Repo): Gruppe A, ca. 25 Stellen.
- Stufe 2: Gruppe B (`kit.input`/`kit.form`), pro Repo eine Task.
- Stufe 3: Gruppe C, nur wo der Dialog Auswahl mit wenigen Optionen ist, sonst `kit.select`.
- Je Stufe: Spec pro Repo, die den Aufruf ohne `vim.fn.confirm`/`vim.ui.*` prüft. Zusätzlich ein Lint/Grep-Check in der CI (verbietet die nativen Aufrufe außerhalb der Fallbacks).
