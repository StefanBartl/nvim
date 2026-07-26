# lib.nvim.ui.kit — Migrations-Audit (native Prompts → kit)

Ziel: native `vim.ui.*`/`vim.fn.confirm`/`vim.fn.input`-Aufrufe sowie
Eigenbau-Floats in allen `C:\repos\*.nvim`-Plugins (nicht lib.nvim selbst) und
der nvim-Config durch `lib.nvim.ui.kit` ersetzen. Ja/Nein bzw. ≤4-Optionen
Prompts → `kit.confirm` (Buttons). Mehr/dynamische Optionen → `kit.select`.
Freitext → `kit.input`.

Hinweis zur Zählweise: Datei:Zeile bezieht sich auf den Stand beim Audit
(2026-07-25, Nachtrag 2026-07-26) — kann sich bei künftigen Edits verschieben.

Nachtrag 2026-07-26: Audit war beim ersten Durchlauf nicht vollständig —
`cmdlog.nvim`, `debugging.nvim`, `insights.nvim`, `learn-cli.nvim`, `lsp.nvim`,
`mdview.nvim`, `migrate.nvim` und `neotree-fs-refactor.nvim` fehlten noch.
Jetzt nachgeholt (Ergebnisse unten eingearbeitet); `insights.nvim`, `lsp.nvim`,
`mdview.nvim`, `migrate.nvim` und `neotree-fs-refactor.nvim` haben **keine**
Treffer (kein `vim.ui.select`/`vim.ui.input`/`vim.fn.confirm`/`vim.fn.input`/
`vim.fn.inputsecret`, kein Eigenbau-`nvim_open_win`-Prompt). Damit ist jetzt
jedes `E:\repos\*.nvim`-Repo plus die nvim-Config abgedeckt.

## 1. Ja/Nein & ≤4-Optionen-Prompts → `kit.confirm` (Buttons)

Das ist die für dich wichtigste Kategorie. Sortiert grob nach Impact.

### sandbox.nvim — ~~ein Fix behebt alles~~ ✅ erledigt (2026-07-26)
- ~~`lua/sandbox/util/confirm.lua:16`~~ — `M.destructive` läuft jetzt über
  `kit.confirm({question=prompt, on_answer=...})`; wirkt in allen 7
  Call-Sites (`ui/list_actions.lua`, `bindings/usrcmds/{container,image,
  volume,network,wsl}_commands.lua`, `container_commands_buffer.lua`) ohne
  weitere Änderung dort. Test: neue `tests/sandbox/util/confirm_spec.lua`
  + `list_actions_spec.lua`s `bulk_confirm_then`-Mock auf `kit.confirm`
  umgestellt. Commit `66ca7b5`, gepusht auf `main`.

### filetree.nvim — Chooser-Konsolidierung ✅ erledigt (2026-07-26)
- ~~`lua/filetree/util/confirm.lua` (ganzes Modul)~~ — Eigenbau-Float ersetzt,
  läuft jetzt über `kit.confirm` (Body-Zeilen werden als zusätzliche
  Message-Zeilen in `question` gefaltet). Weiter genutzt von
  `features/fileops/trash/init.lua:159` (`confirm_popup`).
- Neues Modul `lua/filetree/util/confirm_choice.lua` — dünner
  `kit.confirm`-Wrapper mit `choices`-Array für die wiederkehrenden
  ≤4-Options-Chooser (ersetzt `filetree.util.select` an diesen Stellen).
- ~~`lua/filetree/features/fileops/trash/init.lua:176`~~ (4 Optionen) und
  ~~`:331`~~ (3 Optionen, Batch-Menü) — beide auf `confirm_choice` (Buttons)
  umgestellt.
- ~~`lua/filetree/features/fileops/smart_rename/init.lua:429`~~ (3 Optionen)
  und ~~`:554`~~ (Overwrite/Cancel) — auf `confirm_choice` umgestellt.
- ~~`lua/filetree/features/fileops/smart_create/init.lua:200`~~
  (Empty/Paste clipboard) — auf `confirm_choice` umgestellt.
- ~~`lua/filetree/features/fileops/copy_move/init.lua:261`~~ und
  ~~`lua/filetree/features/fileops/rename_batch/init.lua:97`~~ (je 3 Optionen)
  — auf `confirm_choice` umgestellt.
- **Bewusst NICHT migriert** (Sonderfall, dokumentiert im Code):
  `lua/filetree/features/fileops/trash/init.lua:69` — lokale `confirm(path)`
  bleibt auf rohem `vim.fn.confirm`, weil sie die einzige Confirm-Stelle im
  synchronen `M.delete(path)`-Pfad ist (dokumentierte Sync-API für
  direkte/programmatische Aufrufer). `kit.confirm` ist callback-basiert —
  eine Migration hier würde `M.delete` stillschweigend asynchron machen und
  den Rückgabewert-Vertrag brechen. Gleiche Kategorie wie die
  `replacer.nvim`/`diff.nvim`-Sonderfälle unten.
- Tests: `test/units.lua` — alle `filetree.util.select`-Stubs für die
  migrierten Choosers auf `filetree.util.confirm_choice` umgestellt, der
  y/n-Test treibt jetzt `<CR>`/`l<CR>` statt roher y/n-Tasten, plus neue
  Regressionstests für die vorher ungetesteten smart_rename-Overwrite- und
  smart_create-Paste-Chooser. Commit `fd14fe4`, gepusht auf `main`.
  (Nebenbefund: ein vorbestehender, unabhängiger Buffer-Keymap-Testflake in
  `units.lua` — als separate Task ausgelagert, nicht Teil dieser Migration.)
- ~~`lua/filetree/features/fileops/rename_batch/init.lua:169`~~ — war
  `vim.fn.input("Rename %d item(s)? [y/N] ")` (Yes/No als **Freitext**,
  `answer:lower() ~= "y"`) ✅ auf `util.confirm` (`kit.confirm`) umgestellt.
  Da der alte Rückgabewert synchron im `BufWriteCmd`-Handler konsumiert wurde,
  wurde `execute_renames` dafür auf einen `on_done(ok)`-Callback umgebaut
  (Rename-Ausführung selbst in neues `run_plan(plan)` extrahiert).
- ~~`lua/filetree/features/fileops/copy_move/init.lua:310`~~ — gleiches
  Pattern beim Paste-Confirm, ✅ ebenfalls auf `util.confirm` umgestellt;
  `M.paste()`s Post-Confirm-Body dafür in neues `do_paste_impl(dst_dir)`
  extrahiert.
- ~~`lua/filetree/features/fileops/create_from_template/init.lua:213`~~ —
  `vim.fn.input("File exists. Overwrite? [y/N] ")`, ✅ auf `util.confirm`
  umgestellt (war schon in einem async Callback, keine Restrukturierung
  nötig).
  Alle drei: 2026-07-26, Commit `bac28eb`, gepusht auf `main`, inkl. neuer
  Regressionstests für den vorher ungetesteten `confirm=true`-Pfad.

  (Die 5 "Update all refs / Inspect / Leave as-is"-Chooser in trash,
  smart_rename, copy_move und rename_batch — siehe oben, bereits als
  `confirm_choice`-Helper konsolidiert.)

### sessions.nvim ✅ erledigt (2026-07-26)
- ~~`lua/sessions/bindings/autocmds/init.lua:33` — `float_confirm(question, cb)`~~:
  Eigenbau-Yes/No-Float war exakt die im Kommentar selbst beschriebene
  `kit.confirm`-Anforderung. `float_confirm` nutzt jetzt `kit.confirm` wenn
  lib.nvim da ist; der alte Eigenbau-Float bleibt (umbenannt zu
  `hand_rolled_confirm`) als Fallback erhalten — lib.nvim ist in dieser Datei
  bewusst Soft-Dependency (siehe Datei-Kommentar, konsistent mit autocmd/
  notify dort). Manuell verifiziert (kein Testsetup im Repo): beide Pfade
  (kit vorhanden / lib.nvim fehlt) durchlaufen. Commit `84ce371`, gepusht auf
  `main`.

### fileops.nvim
- `lua/fileops/ops/cycle.lua:182` — `vim.ui.select` mit 3 Optionen ("Save and
  open" / "Discard changes and open" / "Cancel") beim Reload einer modifizierten
  Buffer.
- `lua/fileops/bindings/usrcmds.lua:288` — `vim.ui.select` mit 2 Optionen
  (Confirm-Choice-String / "Cancel") für `:File bulk rename` Bestätigung.

### color_my_ascii.nvim ✅ erledigt (2026-07-26)
- ~~`lua/color_my_ascii/commands/fence/export.lua:75`~~ — war
  `vim.fn.confirm(..., "&Yes\n&No", 2)` beim Overwrite-Check von
  `:Fence export`. Neuer `confirm()`-Helper: `kit.confirm` als Soft-Dep
  (gleiche Konvention wie `lib.nvim.fs.write.to_file` direkt daneben),
  Fallback auf `vim.fn.confirm` falls lib.nvim fehlt. Write-Logik nach dem
  Confirm-Punkt dafür in `write_content()` extrahiert (kit.confirm ist
  Callback-basiert). Neuer Regressionstest für den vorher ungetesteten
  Overwrite-Pfad. Commit `3609192`, gepusht auf `main`.

### cmdlog.nvim ✅ erledigt (2026-07-26)
- ~~`lua/cmdlog/core/shell.lua:351`~~ — war `vim.fn.confirm("Delete %d
  occurrence(s) ... from shell history file?", "&Yes\n&No", 2)`, jetzt
  `kit.confirm`. `opts.skip_confirm`-Guard unverändert erhalten. Da der alte
  Rückgabewert 3 Ebenen höher synchron konsumiert wurde (Telescope
  Delete-Keymap → `delete_from_any_history` → `shell.delete_entry`), wurden
  alle drei auf einen `on_done(ok, err)`-Callback umgebaut
  (`shell.lua`, `all_picker.lua`/`all_unique_picker.lua`, `mappings.lua`).
  Manuell verifiziert (kein Testsetup im Repo). **Hinweis:** Repo war auf
  Branch `feature-notes` (nicht `main`) ausgecheckt — Commit `1d3af41` ging
  dorthin, gepusht auf `origin/feature-notes`, nicht auf `main`.

### learn-cli.nvim ✅ erledigt (2026-07-26)
- ~~`lua/learn_cli/user_actions/commands.lua:94` (`:LearnCLIReset`)~~ — war
  `vim.ui.input({prompt = "Reset all progress? (yes/no): "}, ...)` mit
  `input:lower() == "yes"`-Check, jetzt `require("lib.nvim.ui.kit").confirm(...)`.
  lib.nvim war hier schon Hard-Dependency. Commit `3bbb748`, gepusht auf `main`.

### nvim-Config ✅ erledigt (2026-07-26)
- ~~`lua/config/menu/custom_menu/init.lua:242`~~ — war `vim.fn.confirm("Delete
  all content in buffer?", "&Yes\n&No", 2)`, jetzt `kit.confirm`.
- ~~`lua/config/menu/custom_menu/init.lua:267`~~ — war `vim.fn.confirm('Delete
  file "%s"?', "&Yes\n&No", 2)`, jetzt `kit.confirm`. Commit `c8766c8c`,
  gepusht auf `main`. Manuell verifiziert (kein Testsetup für dieses Modul).
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

## 3. Freitext-Eingaben → `kit.input` ✅ erledigt (2026-07-26)

Alles bis auf drei dokumentierte Ausnahmen (File-Completion, nvim-dap-Coroutine,
Multi-Field-Form) migriert. Sync→Callback-Umbauten waren nötig, wo der alte
Rückgabewert synchron weiterverarbeitet wurde (markiert unten).

- ~~`pdfport.nvim/lua/pdfport/util/page_range.lua:45`~~ — Seitenbereich-Prompt,
  jetzt `kit.input`. Erster Test für `M.prompt` ergänzt. Commit `dfeb83d`.
- ~~`reposcope.nvim/lua/reposcope/ui/actions/filter_prompt.lua`~~ (ganzes Modul)
  — Eigenbau-`nvim_open_win`+`buftype=prompt` (~35 Zeilen) durch `kit.input`
  ersetzt. Commit `fa45e8f`.
- ~~`replacer.nvim/lua/replacer/surround.lua:244`~~ — Delimiter-Prompt für
  `:Surround`, jetzt `kit.input` inkl. `on_cancel` (kit.input feuert
  `on_submit` nicht bei Esc, anders als `vim.ui.input`s `callback(nil)` —
  musste explizit nachgebildet werden, um die "surround_cancelled"-Message
  bei Esc zu erhalten). Neuer Regressionstest. Commit `6811497`.
- ~~`pickers.nvim/lua/pickers/sources/system.lua:80`~~,
  ~~`pickers.nvim/lua/pickers/entry_actions/create_file.lua:70`~~,
  ~~`pickers.nvim/lua/pickers/ui/dir_nav_picker.lua:50`~~ — alle drei auf
  `kit.input` umgestellt (`dir_nav_picker.lua` folgt dem Datei-eigenen
  kit.select-Soft-Dep-Muster: `pcall` + `vim.ui.input`-Fallback statt Hard-
  Require). Erste Tests für alle drei. Commit `3bb4573`.
- ~~`sandbox.nvim`~~ — `ui/list_view.lua:56` (Container umbenennen),
  `ui/image_list_view_{podman,docker}.lua` (Image taggen),
  `bindings/usrcmds/registry_commands.lua:24` (Registry-Username; Passwort
  bleibt bewusst auf `vim.fn.inputsecret` — kein kit-Äquivalent für maskierte
  Eingabe) — alle auf `kit.input` umgestellt.
  ~~`bindings/usrcmds/container_commands.lua:365` (`M.run`)~~ — die 5
  verketteten Image/Name/Ports/Volumes/Env-Prompts ebenfalls: jedes optionale
  Feld bekam zusätzlich `on_cancel`, das mit einem leeren Wert weiterläuft
  (Esc = "Feld überspringen", nicht "ganzen Flow abbrechen" — nur beim
  Pflichtfeld Image bricht Esc wirklich ab). Neuer
  `tests/sandbox/bindings/usrcmds/container_commands_spec.lua` (3 Fälle: alle
  Felder ausgefüllt / Esc auf optionalem Feld / Esc auf Image). Commit
  `f6ff0a2`.
- ~~`filetree.nvim`~~ — `features/system/shell_run/init.lua:89`,
  `features/fileops/smart_rename/init.lua:540`,
  `features/fileops/smart_create/init.lua:155`,
  `features/fileops/create_from_template/init.lua:207` — alle auf `kit.input`
  umgestellt. `features/search/grep_in_dir/init.lua:97`: `via_builtin` in
  `run_builtin_search` (der eigentliche rg/grep-Lauf) + einen async
  `kit.input`-Wrapper gesplittet — der alte Rückgabewert war ohnehin nie von
  Aufrufern konsumiert (`via_builtin` ist immer der letzte, unbeobachtete
  Fallback in `M.grep`s Backend-Kette), also risikolos machbar. Commit
  `8ce7c8e` (siehe auch Abschnitt 1 für die dabei aktualisierten
  `units.lua`-Stubs).
- ~~`fileops.nvim/lua/fileops/bindings/usrcmds.lua:218` (`prompt_dest`)~~ ✅
  erledigt (2026-07-26) — war `vim.ui.input`, jetzt `kit.input`. Zentraler
  Helper für new/write/saveas/writeto/touch/rename/move/duplicate/copy (9
  Subcommands), ein Fix deckt alle ab. Neuer `docs/TESTS/usrcmds_spec.lua`
  (erster Test für diesen Dispatcher). Commit `1ad83c9`, gepusht auf `main`.
- `diff.nvim/lua/diff/core/init.lua:197` (`prompt_file`) — **bewusst NICHT
  migriert**: braucht `completion = "file"` (Cmdline-Tab-Completion), für die
  `kit.input` (reiner Insert-Mode-Buffer) noch kein Äquivalent hat. Code-
  Kommentar ergänzt. ~~`:205` (`prompt_buffer`)~~ — keine Completion nötig,
  auf `kit.input` umgestellt. Commit `70d6bd4`.
- ~~`dap.nvim/lua/wkddap/bindings/keymaps/init.lua`~~ — Breakpoint-Condition /
  Log-Message-Prompts, jetzt `kit.input` (reine Keymap-Callbacks, kein
  Sonderfall). ~~`lua/wkddap/languages/lua.lua:46,49`~~ (nach der zwischen-
  zeitlichen `configurations/`→`languages/`-Umstrukturierung durch den
  Autor) — Host/Port-Prompts fürs Attach: nvim-dap löst Config-Funktionen
  innerhalb von `coroutine.wrap()` auf, also nutzt die Migration dasselbe
  yield/resume-Idiom, das nvim-daps eigene Async-Picker verwenden (`kit.input`
  anstoßen, `on_submit` weckt die suspendierte Coroutine mit dem Wert,
  `coroutine.yield()`). Gegen das echte nvim-dap-Plugin verifiziert, inkl.
  einer echten Async-Lücke via `vim.schedule`. Commit `51feb40`.
  `languages/{zig,rust,c,assembly}.lua`s "Path to executable"-Prompts sind
  **bewusst NICHT migriert**: gleiche `completion="file"`-Einschränkung wie
  bei diff.nvim, plus derselbe Coroutine-Kontext.
- `color_my_ascii.nvim/lua/color_my_ascii/commands/fence/export.lua:178`
  (No-Path-Prompt in `M.run`) — **bewusst NICHT migriert**, gleicher Grund
  (`completion = 'file'`). Code-Kommentar ergänzt, Commit `8fde040`.
- ~~`buffer_ctx.nvim/lua/buffer_ctx/format/column_align.lua:173,183`~~ —
  Zielspalte + Fill-Char, jetzt zwei verkettete `kit.input`-Aufrufe. Neuer
  Regressionstest für `align_interactive` (vorher nur `align_to_column`
  direkt getestet). Commit `3ed2290`.
  `ops/boilerplate/templates/utils.lua:18` (`M.prompt_user`/
  `process_prompts`, von `guard.lua`s `guard_interactive` genutzt) — **bewusst
  NICHT migriert**: 4-Ebenen-synchrone Kette (`:Insert`/`:Copy`-Dispatch →
  `boiler.get()` → `guard_interactive()` → `process_prompts()` →
  `prompt_user()`), nur für einen einzigen 2-Felder-Call-Site. Genau der
  Fall, für den Abschnitt 6 ein zukünftiges `kit.form`-Primitiv statt einer
  Ad-hoc-Migration vorschlägt.
- ~~nvim-Config~~ — `bindings/mappings/telescope.lua:21` (Grep-Query),
  `bindings/mappings/nvchad.lua:44` (WhichKey-Query),
  `lsp/languages/webdev/astro/{usercmds,keymaps}.lua` (Component-/Page-Name,
  4 Stellen — `usercmds.lua`s zwei Stellen um eine gemeinsame
  `create()`-Continuation herum restrukturiert, damit der Explicit-Arg-Pfad
  ohne Prompt weiterhin funktioniert) — alle auf `kit.input` umgestellt.
  Commit `0ddb6156`. `lsp/debug_adapters/dotnet.lua:24` (DLL-Pfad) — **bewusst
  NICHT migriert**, gleicher Grund wie dap.nvim/diff.nvim
  (`completion="file"` + nvim-dap-Coroutine-Kontext).

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
- `filetree.nvim/util/select.lua` — der zentrale kit.select-Wrapper. ✅ Der
  vorgeschlagene Buttons-Wrapper existiert jetzt separat als
  `filetree.nvim/util/confirm_choice.lua`; smart_rename/smart_create/trash/
  rename_batch/copy_move nutzen ihn für ihre ≤4-Options-Chooser, `util/select`
  bleibt nur noch für dynamische/>4-Options-Listen (z.B. `find_files`) im Einsatz.
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
   title})` (o.ä.) würde das bündeln. Weiterer Beleg (Nachtrag 2026-07-26):
   `learn-cli.nvim/lua/learn_cli/ui/info_reader.lua` — 1:1 dasselbe Pattern
   (fullscreen statt zentriert, aber gleiche q/CR/Esc-Keymaps + manuelles
   Zentrieren), macht die Wiederverwendungs-Argumentation für `kit.viewer`
   noch stärker.

   Zur Einordnung: `debugging.nvim` hat sein Scratch/Float-UI laut eigenem
   `docs/ROADMAP.md` bereits nach `lib.nvim.window.make_scratch` /
   `open_scratch_split` migriert — das ist aber `lib.nvim.window`, nicht
   `ui.kit`, und deckt reine Scratch-Buffer ab, kein interaktives
   Confirm/Select. Kein Handlungsbedarf hier, nur als Präzedenzfall für
   "gemeinsamer Helper lohnt sich" erwähnenswert.
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
2. ✅ **filetree.nvim: `util/confirm.lua` konsolidieren.** Erledigt
   (2026-07-26, Commit `fd14fe4`) — Eigenbau-Float durch `kit.confirm`
   ersetzt, alle 7 ≤4-Options-Chooser (trash x2, smart_rename x2,
   smart_create, copy_move, rename_batch) auf den neuen gemeinsamen
   `util/confirm_choice.lua`-Helper + Buttons gezogen. `trash.lua`s
   synchroner `M.delete`-Pfad bleibt bewusst auf `vim.fn.confirm` (Sync-API-
   Vertrag, siehe Abschnitt 1).
3. ✅ **Die vier `vim.fn.input`/`vim.ui.input("...[y/N]/yes-no...")`-Stellen**
   (filetree rename_batch/copy_move/create_from_template, learn-cli.nvim
   `:LearnCLIReset`) — erledigt (2026-07-26, Commits `bac28eb` filetree.nvim,
   `3bbb748` learn-cli.nvim). rename_batch/copy_move brauchten dafür einen
   Sync→Callback-Umbau (`execute_renames`/`M.paste` liefen vorher synchron).
4. ✅ **sessions.nvim `float_confirm`** — erledigt (2026-07-26, Commit `84ce371`).
5. ✅ **nvim-Config (`custom_menu`) + color_my_ascii.nvim + cmdlog.nvim** —
   erledigt (2026-07-26, Commits `c8766c8c` nvim-Config, `3609192`
   color_my_ascii.nvim, `1d3af41` cmdlog.nvim auf `feature-notes`).
   cmdlog.nvim brauchte einen 3-Ebenen Sync→Callback-Umbau (Guard auf
   `opts.skip_confirm` blieb erhalten).
6. ✅ **Freitext-Aufräumen (Abschnitt 3)** — erledigt (2026-07-26). Alle Stellen
   über pdfport.nvim, reposcope.nvim, replacer.nvim, pickers.nvim, sandbox.nvim,
   filetree.nvim, fileops.nvim, dap.nvim, buffer_ctx.nvim und nvim-Config auf
   `kit.input` umgestellt — siehe Abschnitt 3 für Commit-Hashes je Repo. Drei
   bewusste Ausnahmen bleiben auf `vim.fn.input`/`vim.ui.input` (dokumentiert
   im Code): diff.nvim `prompt_file`, dap.nvim `languages/{zig,rust,c,
   assembly}.lua`, color_my_ascii.nvim `export.lua`, nvim-Config
   `dotnet.lua` (alle brauchen `completion="file"`, das `kit.input` nicht
   bietet) sowie buffer_ctx.nvim `boilerplate/templates/utils.lua`
   (4-Ebenen-Sync-Kette für einen einzigen 2-Felder-Call-Site, siehe
   Abschnitt 6 unten für das fehlende `kit.form`-Primitiv).
7. **`kit.select`-Migrationen der Eigenbau-Picker** (open_with, path_copy,
   create_from_template, table_selector) — funktional unkritisch, aber
   entfernt viel duplizierten `nvim_open_win`-Code.
8. **replacer.nvim `perfile.lua`** und **diff.nvim pick_specifier** zuletzt —
   beide brauchen Rücksicht auf bestehende Architektur (synchrone Schleife
   bzw. pluggable select_fn), kein Quick-Win.
9. **Neue kit-Bausteine (Abschnitt 6)** unabhängig einplanen, sobald du eh an
   `ui/kit` arbeitest — Info-Panel zuerst (höchste Wiederverwendung), dann
   Multi-Field-Form, Live-Input zuletzt (am aufwendigsten, nur 2-3 Call-Sites).
