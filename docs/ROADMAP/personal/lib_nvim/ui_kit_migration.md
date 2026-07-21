- nvim.ui.kit^da gibt es ein selection/prompt mit "buttons" die ist cool, das würde ichgerne bei allen prompts haben, bei der man selection machen kann, alsoeigentlich alle select auf button variante umstellen, außer es gibt mehr als 4 selcts, denn dann würde se viele buttons geben

gehe alle nvim repos in e:\repos durch und auch meine nvim config und anaylsere und sammle ale estellen in de rein plugin etwsas verwendet, dass man mit lib.nvim/nvim/ui/ ersetzen könnte bzw wenn ein ui ist, die npoch nicht im ui modul abgeilder tist, dann auch notieren, was noch fehlen würde.

speziel wegen den selections bzw ja/nein/vielleicht ppronpts usw... die sepearat auflisten,

das ganze bitte in 

nvim/docs/ROADMAP/personal/lib_nvim/ 
in eine datei schreiben



NICHT FERTIG GEWESEN










# lib.nvim.ui.kit — Migrations-Audit (native Prompts → kit)

Ziel: native `vim.ui.*`/`vim.fn.confirm`/`vim.fn.input`-Aufrufe sowie
Eigenbau-Floats in allen `C:\repos\*.nvim`-Plugins (nicht lib.nvim selbst) und
der nvim-Config durch `lib.nvim.ui.kit` ersetzen. Ja/Nein bzw. ≤4-Optionen
Prompts → `kit.confirm` (Buttons). Mehr/dynamische Optionen → `kit.select`.
Freitext → `kit.input`.

Hinweis zur Zählweise: Datei:Zeile bezieht sich auf den Stand beim Audit
(2026-07-25) — kann sich bei künftigen Edits verschieben.

## 1. Ja/Nein & ≤4-Optionen-Prompts → `kit.confirm` (Buttons)

Das ist die für dich wichtigste Kategorie. Sortiert grob nach Impact.

### sandbox.nvim — **ein Fix behebt alles**
- `lua/sandbox/util/confirm.lua:16` — `M.destructive(prompt, on_confirm)` nutzt
  `vim.ui.select({"Yes","No"}, ...)`. Das ist der **zentrale Chokepoint**: wird
  laut Grep in **7 Dateien** aufgerufen (`ui/list_actions.lua`,
  `bindings/usrcmds/{container,image,volume,network,wsl}_commands.lua`,
  `container_commands_buffer.lua`) — Kill/Remove/Prune für Container, Images,
  Volumes, Networks, WSL-Distros läuft alles hier durch. Einmal auf
  `kit.confirm({question=prompt, on_answer=...})` umstellen (2 Choices: Yes/No)
  → sofort plugin-weiter Effekt.

### filetree.nvim
- `lua/filetree/util/confirm.lua` (ganzes Modul) — Eigenbau-Yes/No-Float mit
  optionalem Info-Body (`nvim_open_win`, y/n/CR/Esc/q-Keymaps, WinClosed-Guard).
  Baut exakt das nach, was `kit.confirm` schon kann (der Body-Text ließe sich
  als zusätzliche Message-Zeile mitgeben). Wird u.a. von
  `features/fileops/trash/init.lua:159` (`confirm_popup`) für den
  Single-Item-Trash-Confirm genutzt.
- `lua/filetree/features/fileops/trash/init.lua:69` — lokale `confirm(path)`
  nutzt rohes `vim.fn.confirm(..., "&Yes\n&No", 2)` für `M.delete()` (der
  nicht-interaktive/API-Pfad). Macht 3 verschiedene Confirm-Mechanismen im
  selben Feature (`vim.fn.confirm` hier, der Eigenbau-Float in
  `confirm_popup`, `ui_select` fürs Batch-Menü) — Konsolidierung auf
  `kit.confirm` würde das vereinheitlichen.
- `lua/filetree/features/fileops/trash/init.lua:176` — `ui_select` mit 4
  Optionen ("Delete + remove all refs" / "Inspect first" / "Delete, keep refs"
  / "Cancel") für die Markdown-Referenzen-Frage beim Trash. Läuft schon über
  `filetree.util.select` (kit-geroutet), aber als Liste statt Buttons.
- `lua/filetree/features/fileops/trash/init.lua:331` — `ui_select` mit 3
  Optionen ("Delete all at once" / "Confirm individually" / "Cancel") fürs
  Batch-Trash-Menü.
- `lua/filetree/features/fileops/smart_rename/init.lua:429` — `ui_select` mit 3
  Optionen (Update all refs / Inspect first / Leave as-is).
- `lua/filetree/features/fileops/smart_rename/init.lua:554` — `ui_select` mit 2
  Optionen ("Overwrite" / "Cancel") wenn Zieldatei beim Rename existiert.
- `lua/filetree/features/fileops/smart_create/init.lua:200` — `ui_select` mit 2
  Optionen ("Empty" / "Paste clipboard").
- `lua/filetree/features/fileops/copy_move/init.lua:261` — `ui_select` mit 3
  Optionen (Update all refs / Inspect / Leave as-is), gleiches Pattern wie oben.
- `lua/filetree/features/fileops/rename_batch/init.lua:97` — `ui_select` mit 3
  Optionen, gleiches Pattern.
- `lua/filetree/features/fileops/rename_batch/init.lua:169` — `vim.fn.input`
  mit `"Rename %d item(s)? [y/N] "` — Yes/No wird hier als **Freitext**
  abgefragt (`answer:lower() ~= "y"`). Schlechteste UX-Variante im ganzen
  Audit für ein Ja/Nein — klarer `kit.confirm`-Kandidat.
- `lua/filetree/features/fileops/copy_move/init.lua:310` — gleiches
  `vim.fn.input(...[y/N]...)`-Pattern beim Paste-Confirm.
- `lua/filetree/features/fileops/create_from_template/init.lua:213` —
  `vim.fn.input("File exists. Overwrite? [y/N] ")`, gleiches Pattern.

  (Die 5 "Update all refs / Inspect / Leave as-is"-Chooser in trash,
  smart_rename, copy_move und rename_batch sind praktisch derselbe Codeblock,
  4x dupliziert — bei der Migration auf `kit.confirm` lohnt sich vermutlich
  auch ein Shared-Helper statt 4x denselben String-Array + Handler.)

### sessions.nvim
- `lua/sessions/bindings/autocmds/init.lua:33` — `float_confirm(question, cb)`:
  kompletter Eigenbau-Yes/No-Float (eigene `nvim_open_win`, y/n/CR/Esc/q-Keys).
  Der Kommentar im Code sagt explizit *"Not a vim.ui.select ... the roadmap
  asks for an actual floating prompt"* — das ist wortwörtlich die
  `kit.confirm`-Beschreibung. Für `autoload = "ask"` beim Start.

### fileops.nvim
- `lua/fileops/ops/cycle.lua:182` — `vim.ui.select` mit 3 Optionen ("Save and
  open" / "Discard changes and open" / "Cancel") beim Reload einer modifizierten
  Buffer.
- `lua/fileops/bindings/usrcmds.lua:288` — `vim.ui.select` mit 2 Optionen
  (Confirm-Choice-String / "Cancel") für `:File bulk rename` Bestätigung.

### color_my_ascii.nvim
- `lua/color_my_ascii/commands/fence/export.lua:75` — `vim.fn.confirm(...,
  "&Yes\n&No", 2)` beim Overwrite-Check von `:Fence export`.

### nvim-Config
- `lua/config/menu/custom_menu/init.lua:242` — `vim.fn.confirm("Delete all
  content in buffer?", "&Yes\n&No", 2)`.
- `lua/config/menu/custom_menu/init.lua:267` — `vim.fn.confirm('Delete file
  "%s"?', "&Yes\n&No", 2)`.

### replacer.nvim (Sonderfall, siehe unten)
- `lua/replacer/rename_assist.lua:36` — `vim.fn.confirm(..., "&Yes\n&No", 2)`
  für `--also-rename-file`. Klarer 2-Options-Kandidat.
- `lua/replacer/perfile.lua:46` — `vim.fn.confirm(..., "&All\n&Skip\n&Only
  some\n&Quit", 1)`, exakt 4 Optionen — **aber**: der Code-Kommentar
  begründet explizit, warum hier bewusst `vim.fn.confirm` statt
  `kit.confirm` verwendet wird — es ist eine synchrone Schleife über Dateien,
  die den Rückgabewert blockierend braucht (wie `:confirm quit`). `kit.confirm`
  ist vermutlich async/callback-basiert; eine Migration bräuchte entweder eine
  synchrone kit-Variante oder einen Umbau der Schleife auf Callback-Rekursion.
  Nicht ignorieren, aber mit Vorsicht angehen — kein Quick-Win.

### diff.nvim (Sonderfall)
- `lua/diff/core/init.lua:238` (`pick_specifier`) — Quellen-Picker hat 4
  Optionen ("current buffer" / "clipboard" / "file path …" / "buffer number …"),
  Target/Base-Picker haben 3. Aber: `resolve_select_fn()` (Zeile 219) erlaubt
  explizit einen Custom-`select_fn` oder pickers.nvim als Backend, `vim.ui.select`
  ist nur der letzte Fallback. Migration auf `kit.confirm` würde nur den
  Default-Fallback-Pfad ändern — sauber machbar, aber die Pluggable-Architektur
  im Hinterkopf behalten.
- `lua/gopath.nvim/create.lua:169` (`ask()`) — bereits auf `kit.confirm`
  migriert (≤3 Choices: Create/Filetree/Cancel), `vim.ui.select`-Fallback nur
  wenn lib.nvim fehlt. **Vorbild für die anderen Fälle hier** — genau dieses
  Pattern (kit primär, vim.ui.select als Soft-Dep-Fallback) sollte überall
  repliziert werden.

## 2. Auswahllisten (>4 Optionen / dynamisch) → `kit.select`

- `dap.nvim/lua/wkddap/utils/validation.lua:15` — `vim.ui.select` über
  `ps -eo pid,comm`-Output (Prozessliste, dynamisch/lang) für Attach-Debugging.
- `replacer.nvim/lua/replacer/root.lua:99` — `vim.ui.select` über gefundene
  Projekt-Root-Kandidaten (meist 2-3, aber unbegrenzt).
- `replacer.nvim/lua/replacer/history.lua:77` — `vim.ui.select` über die
  letzten 50 Replace-Runs.
- `pickers.nvim/lua/pickers/sources/system.lua` — kein Select, aber siehe
  Abschnitt 3 (Freitext).
- `open.nvim/lua/open/picker.lua:20` — `vim.ui.select` über Handler-Kandidaten.
  **Vorsicht**: Kommentar sagt explizit, das ist bewusst so gebaut, damit
  `vim.ui.select`-Overrides (telescope-ui-select, fzf-lua, dressing.nvim) vom
  User respektiert werden. Migration würde dieses Verhalten ändern/entfernen —
  eher niedrige Priorität bzw. Rücksprache nötig.
- `gopath.nvim/lua/gopath/resolvers/common/tailsearch.lua:381` (`M.probe`) —
  `vim.ui.select` über mehrdeutige Tail-Search-Treffer, kein kit-Fallback.
- `gopath.nvim/lua/gopath/alternate/ui.lua:38` — `vim.ui.select` über
  ähnliche Dateien beim "File not found"-Fallback. Kommentar sagt ebenfalls
  bewusst: respektiert User-Backend (telescope/dressing). Gleiche Vorsicht wie
  bei open.nvim.
- `emojis.nvim/lua/emojis/picker.lua:97` (`select_fallback`) — reiner
  Fallback wenn weder Telescope noch fzf-lua verfügbar sind; ähnlich wie
  open.nvim bewusst multi-backend. Niedrige Priorität.
- `filetree.nvim/lua/filetree/features/system/open_with/init.lua:110`
  (`M.pick`) — **kompletter Eigenbau-`nvim_open_win`-Picker** über konfigurierte
  Apps (dynamische Länge), kein kit/`filetree.util.select` genutzt. Klarer
  Migrationskandidat.
- `filetree.nvim/lua/filetree/features/paths/path_copy/init.lua:152`
  (`M.pick`) — Eigenbau-`nvim_open_win`-Picker über 9 Pfad-Formate (>4, also
  Liste statt Buttons). Auch kein kit genutzt.
- `filetree.nvim/lua/filetree/features/fileops/create_from_template/init.lua:146`
  (`pick_template`) — Eigenbau-Liste mit Nummern-Shortcuts (1-9) fürs
  Template-Picking. `kit.select` deckt das Grundverhalten ab, Nummern-Shortcuts
  wären ein Feature-Verlust (siehe Abschnitt 4).
- `recommender.nvim/lua/recommender/float/rendering.lua` — Eigenbau-Picker mit
  Syntax-Highlighting pro Eintrag (chain/alias farblich abgesetzt). Funktional
  ein `kit.select`, aber mit Rendering, das kit vermutlich nicht abdeckt —
  niedrige Priorität, eher Kandidat für ein kit-Feature "custom highlight per
  item" als für eine 1:1-Migration.
- `markdown.nvim/lua/markdown/tableview/views/table_selector.lua` —
  Eigenbau-`nvim_open_win`-Liste zum Wählen einer von mehreren Markdown-Tabellen
  im Buffer. Simpler 1:1 `kit.select`-Kandidat.
- `buffer_ctx.nvim/lua/buffer_ctx/commands.lua:153` — `vim.ui.select` über
  Snippet-Keys (dynamisch, aus User-Config).
- `buffer_ctx.nvim/lua/buffer_ctx/commands.lua:226` — `vim.ui.select` über
  Boilerplate-Template-Keys (dynamisch).
- `diff.nvim/lua/diff/core/init.lua:433` (`run_buffers`) — `vim.ui.select`
  (via `resolve_select_fn()`) über alle offenen Buffer, dynamische Länge.
- `cascade.nvim/lua/cascade/cycle/word_cycle.lua:142` (`M.pick`) —
  `vim.ui.select` über eine Cycle-Gruppe (Länge variiert je nach User-Config,
  oft klein aber nicht garantiert ≤4).

## 3. Freitext-Eingaben → `kit.input`

Sehr viele Treffer, meist simple "prompt für einen Wert"-Aufrufe. Nur
auffällige/wiederkehrende Stellen einzeln gelistet, Rest gebündelt:

- `pdfport.nvim/lua/pdfport/util/page_range.lua:45` — Seitenbereich-Prompt.
- `reposcope.nvim/lua/reposcope/ui/actions/filter_prompt.lua` (ganzes Modul) —
  kompletter Eigenbau-`nvim_open_win` + `buftype=prompt`-Aufbau nur für einen
  einzeiligen Filter-Text. 1:1 `kit.input`-Kandidat (ersetzt ~35 Zeilen Boilerplate).
- `replacer.nvim/lua/replacer/surround.lua:244` — Delimiter-Prompt für
  `:Surround`.
- `pickers.nvim/lua/pickers/sources/system.lua:80` — fd-Suchstring-Prompt.
- `pickers.nvim/lua/pickers/entry_actions/create_file.lua:70` — Dateiname-Prompt.
- `pickers.nvim/lua/pickers/ui/dir_nav_picker.lua:50` — "path=…"-Prompt
  innerhalb eines ansonsten schon kit-migrierten Pickers.
- `sandbox.nvim` — mehrere `vim.ui.input`-Stellen: `ui/list_view.lua:56`
  (Container umbenennen), `ui/image_list_view_{podman,docker}.lua` (Image
  taggen), `bindings/usrcmds/registry_commands.lua:24` (Registry-Username;
  Passwort via `vim.fn.inputsecret`, siehe Abschnitt 6).
- `sandbox.nvim/lua/sandbox/bindings/usrcmds/container_commands.lua:365`
  (`M.run`) — **5 verkettete** `vim.ui.input`-Aufrufe (Image/Name/Ports/
  Volumes/Env) für `:Sandbox container run`. Siehe Abschnitt 6 (Multi-Field-Form).
- `filetree.nvim` — `features/system/shell_run/init.lua:89` (Shell-Kommando),
  `features/fileops/smart_rename/init.lua:540` (neuer Name),
  `features/fileops/smart_create/init.lua:155` (neuer Name/Ordner),
  `features/search/grep_in_dir/init.lua:97` (`vim.fn.input` für Grep-Pattern),
  `features/fileops/create_from_template/init.lua:207` (Dateiname).
- `fileops.nvim/lua/fileops/bindings/usrcmds.lua:218` (`prompt_dest`) —
  zentraler Helper, wird von new/write/saveas/writeto/touch/rename/move/
  duplicate/copy genutzt, sobald kein Pfad-Argument übergeben wurde. Einmaliger
  Fix hier hat großen Radius.
- `diff.nvim/lua/diff/core/init.lua:197,205` — File-Path- und
  Buffer-Number-Prompt innerhalb des Picker-Flows.
- `dap.nvim/lua/wkddap/languages/{zig,rust,c,assembly}.lua` — je ein
  `vim.fn.input("Path to executable: ...")`.
- `dap.nvim/lua/wkddap/languages/lua.lua:46,49` — Host/Port-Prompts fürs
  Attach.
- `dap.nvim/lua/wkddap/bindings/{usercmds,keymaps}/init.lua` —
  Breakpoint-Condition / Log-Message-Prompts (je 2x dupliziert zwischen
  Usercmd- und Keymap-Pfad).
- `color_my_ascii.nvim/lua/color_my_ascii/commands/fence/export.lua:147` —
  Export-Pfad mit Default + File-Completion.
- `buffer_ctx.nvim/lua/buffer_ctx/ops/boilerplate/templates/utils.lua:18`
  (`M.prompt_user`) — generischer Prompt-Helper, von `process_prompts` (Zeile
  34) mehrfach in Folge aufgerufen → auch ein Multi-Field-Form-Kandidat
  (Abschnitt 6).
- `buffer_ctx.nvim/lua/buffer_ctx/format/column_align.lua:173,183` — Zielspalte
  + Fill-Char, zwei verkettete `vim.fn.input`.
- nvim-Config: `lsp/debug_adapters/dotnet.lua:24` (DLL-Pfad),
  `bindings/mappings/telescope.lua:21` (Grep-Query),
  `lsp/languages/webdev/astro/{usercmds,keymaps}.lua` (Component-/Page-Name,
  mehrfach), `bindings/mappings/nvchad.lua:44` (WhichKey-Query).

## 4. Eigenbau-Floats (Menü/Picker) → `kit.menu`/`kit.select`/`kit.layout`

- `filetree.nvim/lua/filetree/util/confirm.lua` — siehe Abschnitt 1 (ist
  eigentlich ein Confirm-Duplikat, kein Menü).
- `filetree.nvim/lua/filetree/features/system/open_with/init.lua:110` — siehe
  Abschnitt 2.
- `filetree.nvim/lua/filetree/features/paths/path_copy/init.lua:152` — siehe
  Abschnitt 2.
- `filetree.nvim/lua/filetree/features/fileops/create_from_template/init.lua:146`
  — siehe Abschnitt 2, plus Nummern-Shortcut-Feature das kit ggf. nicht bietet.
- `markdown.nvim/lua/markdown/tableview/views/table_selector.lua` — siehe
  Abschnitt 2.
- `reposcope.nvim/lua/reposcope/ui/actions/filter_prompt.lua` — siehe
  Abschnitt 3 (ist eigentlich Input, kein Menü).
- `recommender.nvim/lua/recommender/float/rendering.lua` — siehe Abschnitt 2,
  niedrige Priorität wegen Custom-Highlighting.
- `sessions.nvim/lua/sessions/bindings/autocmds/init.lua` (`float_confirm`) —
  siehe Abschnitt 1.

## 5. Bereits migriert / kein Handlungsbedarf (zur Info)

Diese Stellen nutzen schon `kit.select`/`kit.confirm`/`kit.note` (meist mit
`vim.ui.select`-Fallback fürs Fehlen von lib.nvim) — nur zur Verifikation,
keine Aktion nötig. Ein paar davon haben aber ≤4 Optionen und könnten
optional noch von `kit.select` auf die Button-Variante `kit.confirm`
gehoben werden, wenn du das durchziehen willst:

- `pdfport.nvim/util/picker.lua` + `bindings/usrcmds.lua` — kit.select mit
  Fallback, 8-9 Optionen (>4, Buttons wären hier ohnehin unpassend).
- `pickers.nvim/ui/scope_picker.lua`, `dir_nav_picker.lua` — kit.select,
  dynamische/8+ Optionen.
- `pickers.nvim/ui/action_picker.lua` — kit.select mit genau 3 Optionen
  (`{"files","grep","smart"}`) → **Buttons-Kandidat** wenn du konsequent sein willst.
- `markdown.nvim/util/picker.lua` — generischer kit.select-Wrapper (Backend
  "hover_select"), sauber.
- `filetree.nvim/util/select.lua` — der zentrale kit.select-Wrapper, den
  smart_rename/smart_create/trash/rename_batch/copy_move alle nutzen. Guter
  Ankerpunkt: ließe sich um einen `ui_confirm2/ui_confirm_choices`-Wrapper
  ergänzen, der automatisch Buttons vs. Liste je nach Optionsanzahl wählt.
- `gopath.nvim/create.lua` (`ask()`) — kit.confirm mit Fallback, Vorbild-Pattern.
- `language.nvim/translate/window.lua` — kit.select fürs Sprachziel.
- `github_stats.nvim/bindings/usrcmds/utils.lua` — kit.note fürs Floating-Info.

## 6. Fehlende UI-Bausteine in lib.nvim.ui.kit

Drei wiederkehrende Muster, die über mehrere Plugins hinweg selbst gebaut
werden und noch keine kit-Komponente haben:

1. **Read-only Info-Panel** (zentrierter Rounded-Float, Titel, `q`/`<Esc>`
   schließt, kein Confirm/Select nötig). Belege: `filetree.nvim` allein hat das
   **6x** separat implementiert — `features/ui/node_info/init.lua`,
   `features/ui/cheatsheet/init.lua`, `features/org/marks/init.lua:141`
   (`M.show`), `features/fileops/trash/undo.lua:186` (`show_history`),
   `features/paths/path_copy/init.lua` (teils), plus
   `lsp/usercmds/info.lua` in der nvim-Config, `gopath` node_info-Analoga
   nicht mitgezählt. Jede Implementierung dupliziert: Buffer erstellen,
   Breite/Höhe aus Content berechnen, zentrieren, `border=rounded`,
   `q`/`<Esc>`-Keymap, Auto-Close bei `WinLeave`. Ein `kit.viewer({lines,
   title})` (o.ä.) würde das bündeln.
2. **Multi-Field-Form** (mehrere `vim.fn.input`/`vim.ui.input` nacheinander,
   jedes Feld optional mit Default). Belege:
   `sandbox.nvim/bindings/usrcmds/container_commands.lua:380` (`M.run`, 5
   Felder: Image/Name/Ports/Volumes/Env), `buffer_ctx.nvim/ops/boilerplate/
   templates/utils.lua:34` (`process_prompts`, generischer Form-Helper —
   zeigt, dass der Bedarf sogar plugin-intern schon erkannt wurde),
   `buffer_ctx.nvim/format/column_align.lua:172` (2 Felder: Zielspalte +
   Fill-Char), `filetree.nvim/features/fileops/smart_rename` +
   `create_from_template` (Name-Prompt + Overwrite-Nachfrage als zwei
   getrennte Schritte). Ein `kit.form({fields={...}})` mit sequenziellem
   Tab/Enter-Fluss und Defaults pro Feld wäre hier ein klarer Gewinn.
3. **Live-Incremental-Input** (Prompt-Buffer mit Debounce, der bei jedem
   Tastendruck einen Callback/Preview aktualisiert — kein einmaliges Submit
   wie `kit.input`). Belege: `filetree.nvim/features/search/live_search/init.lua`
   und `features/search/filter/init.lua` implementieren beide unabhängig
   voneinander einen floating Prompt-Buffer mit `TextChangedI`-Debounce +
   Overlay-Highlighting. `reposcope.nvim/ui/actions/filter_prompt.lua` ist ein
   einfacherer (nicht-live) Fall vom selben Grundbedürfnis. Kein 1:1-Ersatz für
   `kit.input`, aber ein potenzielles `kit.live_input({on_change=...})`-Primitiv
   würde 2 Implementierungen in filetree.nvim allein einsparen.

Kein neuer Baustein nötig, aber erwähnenswert: Sekret-/Passwort-Eingabe
(`sandbox.nvim/registry_commands.lua:30`, `vim.fn.inputsecret`) hat aktuell
keine kit-Entsprechung — falls `kit.input` maskierte Eingabe unterstützen
soll, wäre das der einzige Call-Site dafür im Audit.

## 7. Priorisierung / Reihenfolge-Vorschlag

1. **sandbox.nvim: `util/confirm.lua` → `kit.confirm`.** Ein einziger Fix,
   wirkt in 7 Dateien / de facto jeder destruktiven Aktion im Plugin. Bester
   Aufwand/Nutzen im ganzen Audit.
2. **filetree.nvim: `util/confirm.lua` konsolidieren.** Ersetzt den
   Eigenbau-Float durch `kit.confirm` und behebt gleichzeitig die
   Drei-Wege-Fragmentierung (vim.fn.confirm in trash.lua + Eigenbau-Float +
   ui_select fürs Batch-Menü). Danach die 5 duplizierten "Update refs /
   Inspect / Leave as-is"-Chooser (trash, smart_rename, copy_move,
   rename_batch) auf einen gemeinsamen Helper + `kit.confirm` ziehen.
3. **Die drei `vim.fn.input("...[y/N]...")`-Stellen** (filetree
   rename_batch/copy_move/create_from_template) — kleine, in sich
   geschlossene Fixes mit sofortigem UX-Gewinn (Buttons statt Text-y/n tippen).
4. **sessions.nvim `float_confirm`** — 1 Stelle, Code-Kommentar verrät
   selbst schon die Absicht.
5. **nvim-Config (`custom_menu`) + color_my_ascii.nvim** — beide je 1-2
   simple `vim.fn.confirm`-Stellen, schnell erledigt.
6. **Freitext-Aufräumen (Abschnitt 3)** — kein Quick-Win an einer Stelle,
   aber viele kleine mechanische Ersetzungen; am besten pro Repo im Rutsch
   erledigen, `fileops.nvim`s `prompt_dest`-Helper zuerst (deckt 9
   Subcommands ab).
7. **`kit.select`-Migrationen der Eigenbau-Picker** (open_with, path_copy,
   create_from_template, table_selector) — funktional unkritisch, aber
   entfernt viel duplizierten `nvim_open_win`-Code.
8. **replacer.nvim `perfile.lua`** und **diff.nvim pick_specifier** zuletzt —
   beide brauchen Rücksicht auf bestehende Architektur (synchrone Schleife
   bzw. pluggable select_fn), kein Quick-Win.
9. **Neue kit-Bausteine (Abschnitt 6)** unabhängig einplanen, sobald du eh an
   `ui/kit` arbeitest — Info-Panel zuerst (höchste Wiederverwendung), dann
   Multi-Field-Form, Live-Input zuletzt (am aufwendigsten, nur 2-3 Call-Sites).
