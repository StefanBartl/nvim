# filetree.nvim

## Zweck
filetree.nvim (`E:\repos\filetree.nvim`) ist ein "adapter-agnostisches" Feature-Layer für Datei-Baum-Plugins: ~50 opt-out Features (Trash+Undo, Smart Create/Rename, Copy/Cut/Paste, Batch-Rename, Markdown-Link-Tracking, cwd/Root-Policies, Preview, Marks, Diff, Git-Status, LSP-Diagnostics, Suche, PDF/System-Open, Session, …) werden über ein gemeinsames `FiletreeAdapter`-Interface (`lua/filetree/adapter/init.lua`) auf neo-tree.nvim, nvim-tree.lua, netrw, oil.nvim oder mini.files gelegt. Laut README ist es als "in-tree actions"-Schicht gedacht, ergänzt durch ein Begleit-Plugin (`fileops.nvim`) für schwerere Fileops. Alle Features sind standardmäßig aktiv (`lua/filetree/init.lua:29-53`); Nutzer deaktivieren gezielt, außer einer kurzen, explizit begründeten `DEFAULT_DISABLED`-Liste (cwd_sync, current_hl, safety, auto_resize, handle_guard).

## Nicht-standard Patterns / Algorithmen

- **Locale-unabhängige Recycle-Bin-Wiederherstellung** — `lua/filetree/features/fileops/trash/undo.lua:49-128`. Der native Windows-COM-"Restore"-Verb ist lokalisiert (z.B. deutsch "Wiederherstellen") und `InvokeVerb('restore')` schlägt auf nicht-englischen Systemen still fehl (Exit-Code trotzdem 0). Fix: Direkter `Move-Item` der realen `$R…`-Datei, lokalisiert über die stabile `System.Recycle.DeletedFrom`-Property (Abgleich gegen den vollen Original-Pfad, nicht nur den Dateinamen, um Namenskollisionen zu vermeiden), mit dem Verb-Regex nur als Fallback. Vier unterscheidbare Exit-Codes (0-3) mappen auf konkrete Fehlermeldungen.
- **Watcher-Handle-Freigabe vor destruktiven Ops** — `lua/filetree/features/infra/handle_guard/init.lua`, genutzt aus `trash/init.lua:107-116` und `copy_move/init.lua:238-248`. neo-trees libuv-Verzeichnis-Watcher schließen ihre Handles auf Windows nie, wodurch Rename/Delete eines beobachteten Verzeichnisses sporadisch mit EPERM/ERROR_SHARING_VIOLATION fehlschlägt. Statt nur zu retryen, wird das konkrete Watcher-Handle über eine geteilte Registry (`lib.nvim.neotree.watch`) proaktiv freigegeben, danach `vim.wait(20)`, damit der asynchrone libuv-Close greift, bevor der externe Move/Trash-Call läuft. `copy_move.do_move` (Zeile 238-256) hängt dieselbe Freigabe als `on_retry`-Hook in einen gemeinsamen `lib.nvim.cross.fs.mutate`-Retry-Mechanismus, plus Fallback von `uv.fs_rename` auf `vim.fn.rename` bei `EXDEV` (Laufwerks-übergreifende Moves sind nicht retry-fähig).
- **EPERM-Quarantäne als zweite, unabhängige Gegenmaßnahme** — `lua/filetree/features/infra/watcher_quarantine/init.lua`. Anders als handle_guard wird hier nicht die Ursache behoben: `vim.notify` wird während eines debounced Zeitfensters gepatcht, um EPERM-Meldungen zu schlucken (`patch_notify`, Zeile 73-83), UND neo-trees `fs_watch.watch_folder`-Callbacks werden direkt an der Quelle gewrappt, um EPERM/EACCES nie zu propagieren (`wrap_callback`, Zeile 109-122). Der Moduldoc erklärt explizit, dass beide Layer dasselbe Windows-Problem aus verschiedenen Winkeln angehen.
- **cwd_mode als Zustandsautomat mit Guard** — `lua/filetree/features/nav/cwd_mode/init.lua`. Sechs Modi (follow/project/nearest/lock/manual/tree_leads) über eine `decide()`-Funktion (Zeile 250-317). "project" und "nearest" sind derselbe Walk-Algorithmus mit unterschiedlichen Marker-Sets, bewusst als zwei Modi statt einer Option belassen, weil man zur Laufzeit zwischen "Repo" und "Paket, das ich gerade editiere" wechseln will. Ein `dir_guard` macht fremde `:cd`-Aufrufe im `lock`-Modus aktiv rückgängig (`install_guard`, Zeile 332-355), mit einem `unguarded()`-Escape-Hatch, damit bewusste Re-Roots nicht gegen den eigenen Guard laufen.
- **Diff-basiertes Statusline-Update** — `cwd_mode.lua:706-841`. Der Modus-Indikator berechnet Text/Highlight, vergleicht gegen den zuletzt gerenderten Wert und feuert nur bei tatsächlicher Änderung ein `User FiletreeCwdModeChanged`-Autocmd + deferred `redrawstatus` — vermeidet Redraw-Stürme durch routinemäßige Window-Lifecycle-Events.
- **Trash-Confirm-Asymmetrie** — `trash/init.lua:43-57` setzt bewusst `confirm = true` als Default, während `copy_move`/`rename_batch` `confirm = false` default'en, mit Inline-Kommentar zur Begründung (Trash-Ziele werden leichter falsch getroffen und sind schwerer rückgängig zu machen als Move/Rename).
- **Markdown-Referenz-bewusste destruktive Ops** — `trash/init.lua:142-206`, `copy_move/init.lua:258-368`. Vor Trash/Move wird (soft dependency markdown.nvim) nach Markdown-Links auf die Datei gesucht und ein Chooser ("delete + remove refs" / "inspect first" / "delete keep refs" / "cancel") angeboten; bei Cut-Operationen wird der Referenz-Scan bereits beim Staging gestartet (nicht erst beim Paste), damit der Scan mit der Navigation zum Zielort überlappt.
- **mini.files Positional-Argument-Fallstricke** — `lua/filetree/adapter/mini_files.lua:48-61, 137-142, 165-181`. Kommentare dokumentieren zwei reale Bugs: `state.windows`-Einträge sind Tabellen `{win_id, path}`, kein rohes Window-Handle; `MiniFiles.get_fs_entry(buf, line)` nimmt positionale Argumente, kein Table — ein Table-Argument warf still innerhalb eines `pcall` und lieferte immer null Einträge. mini.files fügt außerdem auf Windows einen doppelten Slash nach dem Laufwerksbuchstaben ein, weshalb `normalize_key` `(%S)/+` → `%1/` kollabiert statt naiv Backslashes zu tauschen.
- **`nowait`-Mapping-Unblock-Trick** — `copy_move/init.lua:436-456`. neo-tree registriert eigene Single-Char-Keymaps mit `nowait = true`, wodurch eine Zwei-Zeichen-Sequenz wie `xx` nie zustande kommen kann. Fix: Der Präfix-Char wird ohne `nowait` auf `<Nop>` remappt, sodass Vims normales Warten-auf-weitere-Eingabe wieder greift.
- **Composer-abgeleiteter `:Filetree`-Befehlsbaum ohne Duplikation** — `lua/filetree/commands.lua:311-399, 457-478`. Eine handgeschriebene `TREE`-Tabelle ist gleichzeitig Dispatch-Tabelle und (via `walk_tree`/`build_routes`) Quelle für Ex-Command-Completion; `M.command_paths()` läuft dieselbe TREE für Doku/Health ab — Dispatch, Completion und Doku können nicht auseinanderlaufen.
- **Feature-Registry-Indirektion** — `lua/filetree/features/init.lua`. Alle Features werden über eine `FEATURES`-Name→Modulpfad-Tabelle geladen, kein Consumer hardcoded `require("filetree.features.<category>.<name>")`, explizit damit ein Feature den Kategorie-Ordner wechseln kann, ohne Aufrufer anzupassen.
- **neo-tree-Cheatsheet-Injection ohne User-Wiring** — `lua/filetree/attach.lua`. filetrees eigene Keymaps laufen über einen privaten zentralen Dispatcher (`util/tree_attach.lua`), der für neo-trees `?`-Popup unsichtbar ist (das nur aus `state.resolved_mappings`/`window.mappings` liest). `attach.lua` dupliziert dieselbe Keymap→Handler-Zuordnung zusätzlich in neo-trees Config/Live-State — eine bewusste Doppelregistrierung nur für den Cheatsheet-Sichtbarkeits-Seiteneffekt (Verhalten ist in beiden Fällen identisch).

## Abgeleitete Guidelines

1. Ein Feature = ein Ordner `features/<category>/<name>/init.lua`, registriert in genau einer `features/init.lua`-Tabelle (`FEATURES`). Nie einen Feature-Modulpfad hart verdrahten — immer über `require("filetree.features").load(name)`.
2. Jedes Feature-Modul hat dieselbe Form: lokales `_cfg`-Default, `M.setup(config, adapter)`, `M.teardown()`, öffentliche Action-Funktionen. `setup()` ist No-Op bei `config.enabled == false`; `teardown()` räumt Augroups/State auf, damit erneutes `setup()` idempotent ist.
3. Config ist opt-out, nicht opt-in. Neue Features sind standardmäßig aktiv; nur mit konkreter, inline dokumentierter Begründung in eine kleine `DEFAULT_DISABLED`-Liste aufnehmen.
4. Alle Notifications laufen über einen gescopten Notifier: `require("filetree.util.notify").create("[filetree.<feature>]")`, nie rohes `vim.notify` in Feature-Code.
5. Zentraler Dispatcher für Buffer-lokale Keymaps: Features erzeugen kein eigenes `FileType`-Autocmd, sondern registrieren sich per `tree_attach.on_attach(fn)`; ein einziges Autocmd fächert per `vim.schedule` (nach dem Adapter) an alle registrierten Callbacks auf.
6. Aller Adapter-Zugriff läuft über das `FiletreeAdapter`-Interface, nie über direktes `require("neo-tree...")` etc. aus Feature-Code — Ausnahmen (handle_guard, watcher_quarantine, attach.lua) sind explizit neo-tree-spezifisch, immer hinter `pcall` + Plattform/Adapter-Namens-Guard.
7. Destruktive Filesystem-Operationen: `pcall`-gewrappt, bestätigt über einen geteilten UI-Helfer (`util/confirm.lua`/`confirm_choice.lua`), geroutet über einen gemeinsamen retryenden Mutation-Chokepoint (`lib.nvim.cross.fs.mutate`) statt rohe `uv.fs_*`/Shell-Aufrufe an vielen Stellen.
8. Config-Doc-Kommentare dienen als Inline-Entscheidungs-Log — jeder nicht-offensichtliche Default wird mit "warum" begründet. Konsistent durchgehalten, kein Einzelfall.
9. Pfad-Handling zentral und pur (`util/path.lua`): keine Funktion hält State oder macht Root-Lookups; Forward-Slash ist die kanonische Anzeigeform, Backslash-Konvertierung nur unmittelbar vor nativen Shell/COM-Aufrufen.
10. Soft Dependencies (`lib.nvim`, which-key, markdown.nvim, mini.files, telescope) immer `pcall`-gesichert, Features degradieren dokumentiert graceful.
11. Single Source of Truth durch Konstruktion statt Disziplin erzwingen: `TREE`-Tabelle treibt Dispatch+Completion+Doku, `FEATURES`-Tabelle treibt Setup+Cheatsheet+Lookup.
12. Plattform-Verzweigung lebt an genau einer Stelle (`util/platform.lua`: `is_windows`, `is_wsl`, `is_mac`), nie pro Feature neu erkannt.

## Keybindings-Audit

Aus `lua/filetree/bindings/keymaps.lua` (alle Buffer-lokal im Tree-Fenster):

| lhs | Feature | Beschreibung |
|---|---|---|
| `-` / `+` | tree_traverse | Elternverzeichnis / als Root setzen |
| `B` | reveal_alt | Alternate-Buffer aufdecken |
| `L` | cwd_mode | cwd-Modus wechseln |
| `gp` | cwd_mode | cwd auf Node locken |
| `<Tab>`/`<CR>` | preview | Preview toggeln/öffnen |
| `I` | node_info | Node-Info-Float |
| `w` | window_size_cycler | Fenstergröße durchschalten |
| `<Esc>` | tree_reset | Preview/Filter/Search zurücksetzen |
| `?` | cheatsheet | Keymap-Cheatsheet |
| `<RightMouse>` | context_menu | Kontextmenü |
| `a` | smart_create | Datei/Verzeichnis erstellen |
| `c`/`x`/`p`/`P`/`<C-c>` | copy_move | Copy/Cut/Paste/Show/Clear Clipboard |
| `<leader>rb` | rename_batch | Batch-Rename |
| `r` | smart_rename | Rename mit LSP-Refs |
| `A` | create_from_template | Aus Template erstellen |
| `O` | open_replace | Öffnen (Buffer ersetzen) |
| `sg`/`sv`/`st`/`gb`/`<S-CR>` | open_variants | vsplit/split/tab/badd |
| `d`/`U`/`<leader>th` | trash | Trash / Undo / History |
| `<C-s>`/`<M-s>` | buffer_save | Adjacent-/Node-Buffer speichern |
| `/`/`<C-c>` | filter | Filter / Clear |
| `gs` | live_search | Live-Suche |
| `f`/`tf` | find_files | Find / Telescope-Find |
| `gr`/`tg` | grep_in_dir | Grep / Telescope-Grep |
| `[a`/`]a` | path_copy | Absoluter Pfad / Parent-Dir |
| `rq` | lua_require_copy | Als `require()` kopieren |
| `[f`/`]f`/`[F`/`]F` | copy_file_list | Datei/Dir-Listen abs/rel |
| `ML`/`MR`/`MM` | markdown_links | Link aktuell/rekursiv/marked |
| `m`/`]m`/`[m`/`<C-m>`/`<leader>ms` | marks | Toggle/Mark all/Unmark all/Clear/Show |
| `<leader>fm`/`<leader>sm`/`i` | system | Dateimanager/System-Open/Shell-Run |
| `D` | diff | Diff aktueller Node |

- **Count**: Kein einziges Keymap unterstützt sinnvoll einen Count-Prefix. Alle Handler sind Zero-Arg-Funktionen, `v:count`/`v:count1` wird nirgends in `keymaps.lua` gelesen. "N Items betreffen" läuft stattdessen über `marks` (erst markieren, dann agieren) — ein bewusst anderer UX-Ansatz statt Count-Prefix.
- **Zwei dokumentierte Key-Konflikte**: `<C-c>` ist doppelt belegt (copy_move: Clipboard leeren; filter: Filter leeren), im Code an beiden Stellen kommentiert (Zeile 45, 63). Kein Konfliktlösungsmechanismus — nur ein Kommentar; wer zuletzt via `tree_attach.on_attach` registriert, gewinnt.
- **Completion**: Nur auf `:Filetree`/`:Ft`-Ebene, nicht für In-Tree-Keymaps. `find [dir]` hat DIR-Completion, `cwd mode <name>` ein geschlossenes Enum, `cwd scope <name>` ebenso, `cwd lock [dir]` DIR-Completion — alles via `lib.nvim.usercmd.composer`. Andere Subcommands (`trash undo`, `git refresh`, `marks show`) haben nur Subcommand-Namen-Completion, keine Argument-Wert-Completion (`grep <pattern>`, `filter <query>` sind Freitext ohne Completion).
- **Fehlende Flags**: kein Keymap-Toggle für Dry-Run bei `copy_move`/`rename_batch` (nur `trash` hat `:Filetree trash dry-run`, nur als Ex-Command). Kein Keymap, um direkt zu einem bestimmten Mark zu springen oder zwei markierte Dateien gegeneinander zu diffen (nur `diff marked` gegen aktuellen Buffer). Keine Visual-Mode-Keymaps überhaupt — alles ist Normal-Mode-Single-Node oder marks-basiert.

## Ideen für andere Plugins

1. `lib.nvim.cross.fs.mutate` mit pluggable `on_retry`-Hooks als eigenständige Mini-Library für "retrying FS mutation" — jedes Plugin mit Windows-Fileops trifft dieselbe Watcher-Lock-Bugklasse.
2. Die `FiletreeAdapter`-Schnittstelle (get_current_node, get_visible_nodes, expand_node, highlight_node, …) als eigenständige "Filetree-Backend-Abstraktion"-Library, nutzbar auch für Git-Status-Overlays oder LSP-Diagnostics-in-Tree-Plugins.
3. `cwd_mode` (Root-Policy-Automat + dir_guard + diff-basiertes Statusline-Update) als eigenständiges "Project-Root-Policy"-Plugin, unabhängig von jedem Filetree.
4. Locale-unabhängige Windows-Recycle-Bin-Restore (`System.Recycle.DeletedFrom` + echter File-Move statt Verb-Caption) als eigene kleine Cross-Platform-Trash-Library.
5. Der markdown-referenz-bewusste Move/Delete-Flow (Scan → Prefetch beim Staging → Chooser → Retarget) verallgemeinert zu einem "Safe Refactor"-Modul für andere Linkformate (reST, AsciiDoc).
6. Der Composer-getriebene Ex-Command-Baum (`TREE` → Dispatch + Completion + Doku aus einer Quelle) ist bereits in `lib.nvim` — lohnt sich, als eigenständiges Mini-Framework zu dokumentieren/bewerben.
