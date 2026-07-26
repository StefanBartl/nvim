# lib.nvim.ui.kit — Migrations-Audit (native Prompts → kit)

Ziel: native `vim.ui.*`/`vim.fn.confirm`/`vim.fn.input`-Aufrufe sowie
Eigenbau-Floats in allen `C:\repos\*.nvim`-Plugins (nicht lib.nvim selbst) und
der nvim-Config durch `lib.nvim.ui.kit` ersetzen. Ja/Nein bzw. ≤4-Optionen
Prompts → `kit.confirm` (Buttons). Mehr/dynamische Optionen → `kit.select`.
Freitext → `kit.input`.

Hinweis zur Zählweise: Datei:Zeile bezieht sich auf den Stand beim Audit
(2026-07-25, Nachtrag 2026-07-26) — kann sich bei künftigen Edits verschieben.
Audit deckt jedes `E:\repos\*.nvim`-Repo plus die nvim-Config ab.

Alles bereits abgeschlossene ist aus diesem Dokument entfernt — nur noch
offene Punkte unten. Fertiggestellte Migrationen inkl. Commit-Hashes stehen
in der Git-Historie dieser Datei.

## 1. Ja/Nein & ≤4-Optionen-Prompts → `kit.confirm` (Buttons)

### fileops.nvim
- `lua/fileops/ops/cycle.lua:182` — `vim.ui.select` mit 3 Optionen ("Save and
  open" / "Discard changes and open" / "Cancel") beim Reload einer modifizierten
  Buffer.
- `lua/fileops/bindings/usrcmds.lua:288` — `vim.ui.select` mit 2 Optionen
  (Confirm-Choice-String / "Cancel") für `:File bulk rename` Bestätigung.

### nvim-Config
- `lua/config/lazygit/actions/replace.lua:9` (Kommentar) — **kein
  Migrationskandidat, bewusst so gebaut**: Codekommentar begründet explizit,
  warum hier kein `vim.fn.confirm` (und damit auch kein `kit.confirm`) genutzt
  wird — ein LazyGit-Terminal-Float besitzt den Screen, ein blockierender
  Prompt wäre unsichtbar und sein Input würde von LazyGit verschluckt.
  Stattdessen No-Op-Fallback (`:badd` statt Save-Prompt). Gleiche Kategorie wie
  die Sonderfälle bei `replacer.nvim`/`diff.nvim` unten — nicht anfassen ohne
  das Terminal-Float-Problem zu lösen.

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

Fast vollständig migriert — verbleibend nur die folgenden bewusst nicht
migrierten Sonderfälle (dokumentiert im jeweiligen Code):

- `diff.nvim/lua/diff/core/init.lua:197` (`prompt_file`) — braucht
  `completion = "file"` (Cmdline-Tab-Completion), für die `kit.input` (reiner
  Insert-Mode-Buffer) noch kein Äquivalent hat.
- `dap.nvim/lua/wkddap/languages/{zig,rust,c,assembly}.lua`s "Path to
  executable"-Prompts — gleiche `completion="file"`-Einschränkung wie bei
  diff.nvim, plus nvim-dap-Coroutine-Kontext (`coroutine.wrap()`).
- `color_my_ascii.nvim/lua/color_my_ascii/commands/fence/export.lua:178`
  (No-Path-Prompt in `M.run`) — gleicher Grund (`completion = 'file'`).
- nvim-Config `lsp/debug_adapters/dotnet.lua:24` (DLL-Pfad) — gleicher Grund
  wie dap.nvim/diff.nvim (`completion="file"` + nvim-dap-Coroutine-Kontext).
- `buffer_ctx.nvim/ops/boilerplate/templates/utils.lua:18` (`M.prompt_user`/
  `process_prompts`, von `guard.lua`s `guard_interactive` genutzt) — 4-Ebenen-
  synchrone Kette (`:Insert`/`:Copy`-Dispatch → `boiler.get()` →
  `guard_interactive()` → `process_prompts()` → `prompt_user()`), nur für
  einen einzigen 2-Felder-Call-Site. `kit.form` (siehe Abschnitt 5) existiert
  jetzt und wäre eine Option — noch nicht umgesetzt.

## 4. Eigenbau-Floats (Menü/Picker) → `kit.menu`/`kit.select`/`kit.layout`

- `filetree.nvim/lua/filetree/features/system/open_with/init.lua:110` — siehe
  Abschnitt 2.
- `filetree.nvim/lua/filetree/features/paths/path_copy/init.lua:152` — siehe
  Abschnitt 2.
- `filetree.nvim/lua/filetree/features/fileops/create_from_template/init.lua:146`
  — siehe Abschnitt 2, plus Nummern-Shortcut-Feature das kit ggf. nicht bietet.
- `markdown.nvim/lua/markdown/tableview/views/table_selector.lua` — siehe
  Abschnitt 2.
- `recommender.nvim/lua/recommender/float/rendering.lua` — siehe Abschnitt 2,
  niedrige Priorität wegen Custom-Highlighting.

## 5. Fehlende UI-Bausteine in lib.nvim.ui.kit

Zwei der drei ursprünglich fehlenden Bausteine sind inzwischen gebaut
(`kit.viewer`, `kit.form`) — offen ist jeweils noch, ihre Call-Sites in den
Consumer-Plugins tatsächlich zu migrieren:

1. **`kit.viewer`-Migration** — Baustein existiert (`kit.viewer(opts)` /
   `kit.popup({type="viewer"})`: zentrierter, auto-sized Rounded-Float,
   `q`/`<Esc>` schließt, schließt zusätzlich bei `WinLeave`/`BufLeave`,
   Opt-out via `close_on_focus_lost = false`). Migrationskandidaten:
   `filetree.nvim/features/ui/node_info/init.lua`,
   `filetree.nvim/features/ui/cheatsheet/init.lua`,
   `filetree.nvim/features/org/marks/init.lua:141` (`M.show`),
   `filetree.nvim/features/fileops/trash/undo.lua:186` (`show_history`),
   `filetree.nvim/features/paths/path_copy/init.lua` (teils),
   `learn-cli.nvim/lua/learn_cli/ui/info_reader.lua`,
   nvim-Config `lsp/usercmds/info.lua`.

2. **`kit.form`-Migration** — Baustein existiert (`kit.form(opts)` /
   `kit.popup({type="form"})`: verkettet `kit.input`-Aufrufe pro Feld in eine
   gemeinsame `values`-Tabelle; `<Esc>` auf einem optionalen Feld überspringt
   es, auf einem `required`-Feld bricht es die ganze Form ab).
   Migrationskandidaten: `sandbox.nvim/bindings/usrcmds/container_commands.lua:380`
   (`M.run`, 5 verkettete Prompts: Image/Name/Ports/Volumes/Env — Image als
   `required`), `buffer_ctx.nvim/ops/boilerplate/templates/utils.lua:18`
   (`process_prompts`, siehe auch Abschnitt 3).

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

## 6. Priorisierung / Reihenfolge-Vorschlag (verbleibend)

1. **`kit.select`-Migrationen der Eigenbau-Picker** (open_with, path_copy,
   create_from_template, table_selector) — funktional unkritisch, aber
   entfernt viel duplizierten `nvim_open_win`-Code.
2. **replacer.nvim `perfile.lua`** und **diff.nvim `pick_specifier`** —
   beide brauchen Rücksicht auf bestehende Architektur (synchrone Schleife
   bzw. pluggable select_fn), kein Quick-Win.
3. **`kit.viewer`/`kit.form`-Call-Site-Migrationen** (Abschnitt 5) — die
   kit-Bausteine existieren bereits, nur die eigentliche Migration in den
   Consumer-Plugins steht noch aus.
4. **`kit.live_input`** (Abschnitt 5) — neuer kit-Baustein, am aufwendigsten,
   nur 2-3 Call-Sites, unabhängig einplanen sobald du eh an `ui/kit` arbeitest.
