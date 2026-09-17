# Test-Coverage-Kampagne über alle nvim-Plugins — Handover

## Table of content

  - [Restliche Plugins (Reihenfolge für die Fortsetzung)](#restliche-plugins-reihenfolge-fr-die-fortsetzung)
  - [Regeln für diese Session (aus CLAUDE.md / Nutzer-Vorgaben)](#regeln-fr-diese-session-aus-claudemd--nutzer-vorgaben)
  - [Ausgangslage (2026-09-15)](#ausgangslage-2026-09-15)
  - [Aktueller Stand (2026-09-16, nach zwei Wochenlimit-Unterbrechungen)](#aktueller-stand-2026-09-16-nach-zwei-wochenlimit-unterbrechungen)
  - [Fortschritt](#fortschritt)

---

## Restliche Plugins (Reihenfolge für die Fortsetzung)

11 von 36 Plugins sind fertig (siehe "Fortschritt" unten). 9 weitere (`images.nvim`,
`ai.nvim`, `hover.nvim`, `runtime-analysis.nvim`, `lib.nvim`, `markdown.nvim`,
`documentation.nvim`, `media.nvim`, `ui.nvim`) sind laut Survey bereits 🟢/✅ und bekommen
laut Kampagnenregel keine volle Runde, außer eine konkrete Prüfung findet doch eine Lücke.
Die verbleibenden 16 (🟠 dann 🟡, wie im Survey unten priorisiert) sind die Warteschlange,
in dieser Reihenfolge abzuarbeiten:

1. insights.nvim
2. sessions.nvim
3. pdfport.nvim
4. emojis.nvim
5. fileops.nvim
6. reposcope.nvim
7. gopath.nvim
8. color_my_ascii.nvim
9. diff.nvim
10. cascade.nvim
11. sandbox.nvim
12. data.nvim
13. spotlight.nvim
14. mdview.nvim
15. filetree.nvim
16. lsp.nvim

## Regeln für diese Session (aus CLAUDE.md / Nutzer-Vorgaben)

- Nie mehr als 1 Agent gleichzeitig; bei Bedarf mehrere Runden á 1 Agent, repo-für-repo.
- Antworten Deutsch, Quellcode (inkl. Kommentare) Englisch.
- Keine Co-Autorenschaft von Claude in Commits.
- Nach jedem fertigen Plugin: committen/pushen direkt auf `main` des jeweiligen Repos, sodass es sofort verfügbar ist.
- Code muss luacheck/stylua-grün sein.
- README.md je Plugin aktualisieren, sofern sinnvoll (z.B. Coverage-Hinweis, Testlauf-Doku).
- `TOOL-PLACEMENT.md` / `HEREDOC.md` beachten, falls Nebenbei-Tooling entsteht.
- Ziel: Testabdeckung je Plugin auf idealerweise 100% heben — reine UI/Rendering-Wrapper
  (Telescope/fzf/snacks-Adapter ohne echtes Backend) bewusst aussparen, analog zum
  Muster von `documentation.nvim`/`markdown.nvim` (eigener leichter Harness statt plenary,
  keine reinen Rendering-Pfade).

## Ausgangslage (2026-09-15)

Ursprünglicher Report `nvim/docs/ROADMAP/reports/TESTS-Abdeckung.md` deckte nur 3 Repos ab
(pickers.nvim, dap.nvim, cmdlog.nvim) und ist inzwischen veraltet (media.nvim z.B. fehlt dort,
obwohl in diesem media.nvim-Worktree bereits durchgetestet, Commit `f8498c0`).

Schneller Survey (Lua-Quelldateien in `lua/` vs. Testdateien) über alle 33 Plugins unter
`E:\repos`, um zu priorisieren (Datei-Ratio ist nur ein grober Proxy, keine echte %-Abdeckung):

| Plugin | lua_src | lua_test | Status |
|---|---:|---:|---|
| pickers.nvim | 73 | 2 | ✅ fertig (diese Session, Commit `fbaed4c`) |
| cmdlog.nvim | 40 | 1 | ✅ fertig (diese Session, Commit `a43edc9`) |
| dap.nvim | 41 | 5 | ✅ fertig (diese Session, Commit `5f2da6e`) |
| casedesk.nvim | 46 | 6 | 🔴 kaum getestet |
| buffer-ctx.nvim | 45 | 7 | 🔴 kaum getestet |
| debugging.nvim | 34 | 7 | 🔴 kaum getestet |
| recommender.nvim | 23 | 7 | 🔴 kaum getestet |
| language.nvim | 51 | 8 | 🔴 kaum getestet |
| open.nvim | 26 | 8 | 🔴 kaum getestet |
| replacer.nvim | 40 | 8 | 🔴 kaum getestet |
| github_stats.nvim | 44 | 9 | ✅ fertig (Runde 11, Commit `1b9b638`; 9 → 22 Spec-Dateien) |
| insights.nvim | 49 | 9 | 🟠 schwach |
| sessions.nvim | 17 | 9 | 🟠 schwach |
| pdfport.nvim | 50 | 10 | 🟠 schwach |
| emojis.nvim | 23 | 11 | 🟠 schwach |
| fileops.nvim | 18 | 11 | 🟠 schwach |
| reposcope.nvim | 113 | 12 | 🟠 schwach (großes Repo) |
| gopath.nvim | 77 | 16 | 🟠 schwach |
| color_my_ascii.nvim | 95 | 17 | 🟠 schwach |
| diff.nvim | 23 | 17 | 🟡 mittel |
| cascade.nvim | 48 | 18 | 🟡 mittel |
| sandbox.nvim | 270 | 19 | 🟡 mittel (sehr großes Repo) |
| data.nvim | 16 | 20 | 🟡 mittel |
| spotlight.nvim | 27 | 19 | 🟡 mittel |
| mdview.nvim | 78 | 24 | 🟡 mittel |
| filetree.nvim | 129 | 26 | 🟡 mittel |
| lsp.nvim | 176 | 29 | 🟡 mittel (großes Repo) |
| images.nvim | 37 | 29 | 🟢 gut |
| ai.nvim | 25 | 35 | 🟢 gut |
| hover.nvim | 40 | 38 | 🟢 gut |
| runtime-analysis.nvim | 43 | 54 | 🟢 gut |
| lib.nvim | 497 | 159 | 🟢 gut (Basis-Lib, sehr groß) |
| markdown.nvim | 81 | 102 | 🟢 gut |
| documentation.nvim | 139 | 104 | 🟢 gut |
| media.nvim | 31 | 98 | ✅ fertig (diese Session, Commits bc5adfe/f8498c0/4e33ad2/bc12c13) |
| ui.nvim | 93 | 232 | ✅ sehr gut |

**Reihenfolge:** pickers.nvim → cmdlog.nvim → dap.nvim (aus altem Report übernommen), danach
absteigend nach Ratio durch die 🔴/🟠 Liste, 🟡/🟢 nur falls noch Lücken bei konkreter Prüfung.

## Aktueller Stand (2026-09-17, nach zwei Wochenlimit-Unterbrechungen)

11 von ~35 Plugins fertig (pickers, cmdlog, dap, casedesk, buffer-ctx, debugging,
recommender, language, open, replacer, github_stats).

**Die 4 während der Kampagne gefundenen/gepinnten Bugs wurden in einer separaten Session
zwischenzeitlich gefixt** (jeweils eigener Commit, direkt auf `main` des jeweiligen Repos,
keine Claude-Co-Autorenschaft):
- `cmdlog.nvim` — `:history`'s `>`-Marker wird jetzt geparst. Commit `240ca1d`.
- `buffer-ctx.nvim` — `alpha_marker()`'s Off-by-one gefixt (Commit `79893f9`) **und** der
  zweite in dieser Runde gepinnte Bug, `format/text_width.lua`'s Marker-Duplizierung beim
  Reflow von Bullet-/Nummer-Zeilen, ebenfalls gefixt (Commit `3c99c3c`; dabei ein verwandter
  Folgefehler in `wrap_words()`'s Separator-Leerzeichen-Logik mitgefixt).
- `recommender.nvim` — Tree-sitter-Query-Knotennamen aktualisiert (`dot_index_expression`/
  `function_call`). Commit `cc338f6`. Dabei wurde zusätzlich ein zweiter, in der Coverage-Runde
  nicht entdeckter Folgebug gefunden und mitgefixt: `Query:iter_matches` liefert auf aktuellem
  Neovim pro Capture eine Liste von Knoten statt eines einzelnen `TSNode`, wodurch der Analyzer
  selbst nach der Namenskorrektur weiterhin nichts gefunden hätte.
- `debugging.nvim` — `inline_debug.lua`'s fehlender Pfadtrenner gefixt (nutzt jetzt
  `lib.nvim.fs.path.joinpath`, analog zu `views/capture/init.lua`). Commit `8ac567e`.

**Die 2 in Runde 10 (replacer.nvim) gefundenen Bugs sind ebenfalls gefixt**, Commit `7031f73`:
- `config.get()` gab verschachtelte Config-Tabellen per Referenz statt per Deep-Copy zurück
  (`vim.tbl_deep_extend("force", {}, state)` kopiert nur Keys, die auf *beiden* Merge-Seiten
  existieren). Jetzt `vim.deepcopy(state)`.
- `debug.lua`s `enable()`/`disable()`/`status()` lasen/schrieben ein nirgendwo existierendes
  Config-Feld (`require("replacer").options.ext_highlight_opts.debug`) — als toten Code
  entfernt (Nutzerentscheidung: kein neues Config-Feld einführen, siehe Chat). `M.test()`
  suchte die eigene Testsuite am falschen Runtimepath-Ort (`require("test.utf8_offsets")`
  statt der echten Datei unter `TESTS/utf8_offsets.lua`) — jetzt per Dateipfad geladen.

Alle 10 abgeschlossenen Coverage-Commits sowie alle 6 Bugfix-Commits sind per `git
merge-base --is-ancestor` gegen `origin/main` verifiziert; keine Repos mit uncommitteten
Änderungen gefunden (Stichprobe über alle ~35 Plugin-Repos anhand des jeweils letzten Commits).

**Nächste Schritte:** Runde 12 (insights.nvim) starten, danach der Reihe nach die
restliche 🟠/🟡-Liste unten (→ sessions.nvim → pdfport.nvim → emojis.nvim → fileops.nvim
→ reposcope.nvim → gopath.nvim → color_my_ascii.nvim, danach 🟡 nur bei konkreten Lücken).

**Offener Nebenauftrag:** die 2 in Runde 11 (github_stats.nvim) gepinnten Bugs sind noch
nicht gefixt (`usrcmds/utils.lua`s `split_lines()`-Trailing-Leerzeile → doppelt gesetzte
Floats; `export.lua`s `ensure_parent_dir()` außerhalb des pcall → rohes `E739`). Beide sind
sichtbare Verhaltensänderungen und daher bewusst als eigene Entscheidung offen gelassen,
Details im Fortschritts-Eintrag unten. Alle früheren Kampagnen-Bugs (7 insgesamt über 6
Repos, inkl. des in Runde 11 direkt gefixten `strptime`-Fehlers) sind erledigt.

## Fortschritt

- [x] **pickers.nvim** — fertig. 19 zuvor ungetestete Dateien mit echter Logik bekamen neue
  Suiten in `TESTS/pickers_spec.lua`: `error.lua` (typed Result), `config/DEFAULTS.lua`'s
  `depth_aliases`-Resolver (git/root, gegen echtes Temp-`.git`), `actions/grep.lua` +
  `actions/smart.lua` (find-Override-Merge, spiegelt `actions/files`), `actions/dir.lua`
  (nav-arg-Resolution end-to-end inkl. scheiterndem Alias-Resolver und interaktivem
  nil/nil-Fallback), `engines/when_loaded.lua` (3 Lade-Branches: sofort/vim.schedule/
  lazy.nvim-one-shot), `entry_actions/extract/{telescope,snacks}.lua`,
  `entry_actions/open_background.lua` (inkl. `open_background_show`-Fensterwechsel gegen
  echten Scratch-Buffer), `sources/folder.lua`, `sources/plugins_book.lua`,
  `sources/wkdbooks.lua`, `ui/action_picker.lua`, `smart/init.lua` (defaults/config-Merge +
  frecency-gated `query()`), sowie die komplette Bindings-Schicht: `bindings/collections.lua`,
  `bindings/usrcmds.lua`, `bindings/autocmds.lua`, `bindings/init.lua` und `pickers/init.lua`
  selbst (enable-Flag-Gating). Die bestehende `:Pickers`-Completion-Suite wurde zusätzlich um
  dir-nav-Completion und den Collection-Namenskollisions-Guard erweitert.
  Bewusst ausgelassen (kein Backend/keine Verzweigungslogik zum Testen): `pickers/health.lua`
  (reiner `:checkhealth`-Report, nur `vim.health.*`-Aufrufe ohne Rückgabewert),
  `sources/drives.lua` (shellt echtes `Get-PSDrive`/`df` via `vim.system`, keine stabile
  Mock-Fläche ohne die ganze Prozess-Schicht zu ersetzen), `sources/config.lua` und
  `sources/cwd.lua` (je eine Zeile, keine Verzweigung). `keys/adapters/*.lua` brauchten keine
  eigene Suite — `pickers.keys`' bestehende Suite treibt `fzf_keymap`/`telescope_mappings`/
  `snacks_win` schon direkt durch sie hindurch.
  Testlauf: 400 → 575 grüne Checks (0 Fails), `luacheck lua plugin TESTS` und
  `stylua --check lua plugin TESTS` beide grün. `TESTS/README.md` um einen Abschnitt zu den
  neuen Suiten sowie den bewusst ausgelassenen Dateien ergänzt; Top-Level-`README.md` hatte
  keinen Test-Abschnitt, daher unangetastet gelassen.
  Commit: `fbaed4c` (test: cover actions/dir/grep/smart, bindings layer, and leaf
  source/util gaps), direkt auf `main` gepusht.
- [x] **cmdlog.nvim** — fertig. `TESTS/smoke_spec.lua` hatte bereits ein paar echte Suiten
  (risky, shell's Custom-Parser-Escape-Hatch, preview_policy), aber der Großteil von `core/*`,
  `config/`, `bindings/*` und die Merge/Dedup-Logik in `ui.all_picker`/`ui.all_unique_picker`
  hatte nur den Load-Time-`require()`-Smoketest. Datei wurde (statt eine zweite Spec-Datei
  anzulegen, die die CI nicht ausgeführt hätte) weiter ausgebaut: `config.setup`'s
  Merge/Mappings-Fallback; `core/store.lua` (JSON-Persistenz); `core/favorites.lua` (Toggle,
  Undo, Reorder, Export/Import mit Merge-Dedup, project-scoped Storage gegen ein echtes
  Temp-`.git`); `core/shell.lua` in der Tiefe — Shell-Erkennung über `$SHELL`,
  `shell_history_path`-Override, jeder eingebaute Shell-Parser (zsh/bash/fish/nu/PSReadLine),
  Delete-Zeilen-Matching pro Shell, der Confirm-Dialog-Pfad über ein gestubtes `ui.kit.confirm`;
  `core/errors.lua`/`core/stats.lua`/`core/tags.lua`; `core/project_history.lua` gegen einen
  echten Temp-Git-Root; `core/extra_files.lua`; `core/history.lua` gegen Neovims echte
  `:`-History (`histadd`/`histdel`); `core/utils.lua`'s `process_list`; `bindings/usrcmds.lua`
  (Katalog-Form + echte `:Cmdlog`-Registrierung/-Completion), `bindings/keymaps.lua`,
  `bindings/picker_mappings.lua`, `bindings/init.lua`'s Aggregator (inkl. eines dokumentierten
  Quirks, bewusst gepinnt statt "gefixt"); `integrations/which_key.lua`; `ui/fzf-previewer.lua`'s
  pure `command_previewer()` (kein fzf-lua nötig); `ui/all_picker.lua`/`ui/all_unique_picker.lua`'s
  Cross-Source-Merge, Origin-Labelling und Delete-Adapter über ein monkey-gepatchtes
  `picker_utils.open_picker` (kein echtes Picker-Backend nötig); die Empty-State-Guards in
  `ui/favorites_picker.lua`/`ui/stats_picker.lua`/`ui/lua_picker.lua`/`ui/project_picker.lua`.
  Ein Bug in Neovims eigenem `:history`-Output wurde dabei entdeckt und umschifft: der zuletzt
  hinzugefügte Eintrag wird mit führendem `>` statt einem Index angezeigt, was
  `core.history.get_command_history()`'s Parser-Pattern nicht matcht und den Eintrag stillschweigend
  verschluckt — jede Suite, die einen `histadd()`-Marker sofort danach prüft, hängt jetzt einen
  Wegwerf-Eintrag an, damit der zu testende nicht in diesem blinden Fleck landet.
  **Mittlerweile gefixt** (separate Session, Commit `240ca1d`): Parser-Pattern akzeptiert jetzt
  auch den `>`-Marker; `TESTS/smoke_spec.lua` pinnt das mit einer eigenen Assertion.
  Bewusst ausgelassen (reines UI/Picker-Rendering mit echtem Backend oder Trivial-Datei ohne
  Verzweigung): `ui/cycle.lua` und `ui/mappings.lua` (Telescope-Glue ohne eigene Logik, sobald von
  einer echten Picker-Session getrennt — die Contracts, von denen sie abhängen, sind bereits
  direkt gegen `core.*` gepinnt), `ui/telescope-previewer.lua` (hard-requirt telescope.nvim, hier
  nicht verfügbar, schon vom Modul-Load-Loop übersprungen), `ui/history_picker.lua`,
  `ui/history_unique_picker.lua`, `ui/shell_picker.lua`, `ui/shell_unique_picker.lua` (Picker-
  Assembly + Ein-Zeilen-Adapter, dessen Ziel-Funktionen schon direkt getestet sind),
  `@types/init.lua` (reine Annotationen), `bindings/autocmds.lua` (statische Tabelle ohne
  Verzweigung).
  Testlauf: 35 statische `check()`-Aufrufstellen auf 183 (durch Schleifen z.B. über
  `usrcmds.catalog` mehrfach ausgeführt) → 257 grüne Checks, 0 Fails, 1 Skip (telescope-only
  Previewer-Modul, telescope.nvim hier nicht installiert). `luacheck lua` (genau der CI-Befehl)
  und `stylua --check lua TESTS` beide grün. `TESTS/README.md` neu angelegt (gab es noch nicht),
  analog zum pickers.nvim-Register; Top-Level-`README.md` hatte keinen Test-Abschnitt, daher
  unangetastet gelassen.
  Commit: `a43edc9` (test: real assertion-based coverage for core/, config/, bindings/, ui merge
  logic), direkt auf `main` gepusht.
- [x] **dap.nvim** — fertig. Anders als pickers.nvim/cmdlog.nvim nutzt dieses Repo
  plenary.nvim's busted-Suite (`describe`/`it`/`assert`) statt eines eigenen Harness — Konvention
  aus `TESTS/README.md` beibehalten, nicht auf den framework-freien Stil umgestellt.
  Größter Hebel: die 11 fast-identischen Sprach-Definitionstabellen (`assembly`, `bash`,
  `browser`, `c`, `csharp`, `go`, `javascript`, `lua`, `python`, `rust`, `zig`) statt 11
  Einzeldateien mit zwei generischen, tabellengetriebenen Specs abgedeckt:
  `languages/contract_spec.lua` (gemeinsamer `setup()`/`load()`-Contract: Rückgabe `false` ohne
  `dap`, `load()` befüllt `dap.configurations[key]` mit `{type, name, request}`-förmigen Einträgen)
  und `languages/adapter_setup_spec.lua` (Adapter-Pfad-Gate über ein gestubtes `wkddap.config`,
  plus Spot-Checks für die zwei echten Abweichungen: `assembly` prüft nie den Adapter-Pfad,
  `lua` gated stattdessen auf das `osv`-Plugin).
  Danach der Rest durchgegangen: `core/*` (breakpoints, capabilities, init, setup, state — echte
  Logik, ohne Live-Session testbar), `config/init.lua` (Merge-Semantik, `get_adapter_path`/
  `validate_adapter`), `utils/*` (paths, validation inkl. Koroutinen-Picker-Flow, mason, executable
  als Re-Export-Pin), `registry.lua`/`configurations/init.lua` (bestehende Dateien um die
  register()/register_all()/validate()-Erfolgspfade und die Haupt-Load-Schleife erweitert, vorher
  war nur der custom_configs-Merge abgedeckt), `adapters/init.lua`, `integrations/menu.lua`,
  `bindings/*` (autocmds, keymaps gegen die echte lib.nvim-Keymap-Registry, Orchestrierung —
  usercmds hatte bereits Coverage), `ui/*` (signs/highlights direkt gegen echte vim-APIs,
  virtual_text/provider/dapui/dapview/der init.lua-Orchestrator über ein gestubtes
  `dap-view`/`dapui`/`dap` statt einer Live-Session), das Top-Level-`init.lua`
  (`wkddap.setup()`, inkl. eines echten, ungemockten End-to-End-Laufs als Smoke-Test des
  "degradiert graziös ohne nvim-dap"-Vertrags) sowie `health.lua` (Smoke-Test).
  Bewusst ausgelassen: `@types/init.lua` (nur `---@meta`-Annotationen, kein Laufzeitcode),
  `plugin/dap.lua` (einzeiliges Early-Return-Guard, keine Verzweigung).
  Lokale Ausführung: `plenary.nvim` lag bereits unter
  `C:\Users\bartl\AppData\Local\nvim-data\lazy\plenary.nvim` (lazy.nvim-Datenverzeichnis),
  `lib.nvim` unter `E:\repos\lib.nvim` — beide via `PLENARY_PATH`/`LIB_NVIM_PATH` genau wie in
  `TESTS/README.md`/CI dokumentiert eingebunden, Suite lief real durch `nvim --headless`.
  Testlauf: 357 Zeilen/4 Spec-Dateien → 30 Spec-Dateien, 199 grüne Checks, 0 Fails, 0 Errors.
  `luacheck lua plugin TESTS` und `stylua --check lua/ plugin/ TESTS/` beide grün.
  `TESTS/README.md` um einen Coverage-Abschnitt (abgedeckt/ausgelassen, inkl. Begründung für den
  generischen Sprach-Contract-Ansatz) ergänzt.
  Commit: `5f2da6e` (test: cover the language-config contract, core, config, utils, bindings,
  adapters, UI wiring), direkt auf `main` gepusht.
- [x] **casedesk.nvim** — fertig (Runde 4, nach kurzer Pause durch wöchentliches API-Limit
  neu gestartet). 32 neue `TESTS/*_spec.lua`-Dateien (plenary/busted-Stil, wie im Repo bereits
  Konvention), `TESTS/README.md` neu angelegt. Vorher 5 von 46 Quelldateien mit echten Tests
  (config, meta, registry, templates + Smoke-Suite), danach ~35 Module mit dedizierten
  Assertion-Suiten: config, registry, resolve, usage, meta, plan, apply, blueprint, render,
  templates, doctor, normalize, migrate, extract/{supportinfo,stream,doclinks,facts},
  stream_format, detect, sla/{clock,stream,init,notify}, similar, solution, query,
  terminology, links, commands, linkcheck, blocks, replygate, ki, marks, timeline, ocr,
  attachments.
  **Echter Bug gefunden und gefixt:** `lua/casedesk/doctor.lua`'s Notes-Alias-Check nutzte das
  klassische `has_notes and nil or (...)`-Lua-Idiom, das bei `nil` im "true"-Zweig immer auf den
  Fallback kollabiert — der Ambiguitäts-Guard griff dadurch nie, `to` zeigte immer auf das
  Notes.md-Rename-Ziel, selbst wenn Notes.md schon existierte, sodass `normalize.lua` eine
  Alias-Datei auf ein bestehendes Notes.md umzubenennen versucht hätte statt es als ambig zu
  behandeln. Fix: eine Zeile (`(not has_notes) and (...) or nil`) plus erklärender Kommentar.
  Testlauf: 40 Tests/6 Dateien → 386 Assertions/38 Dateien, 0 Fails, 0 Errors.
  `luacheck .` (0 Warnings/Errors, 87 Dateien) und `stylua --check .` beide grün.
  Bewusst ausgelassen: `ui.lua`, `bindings/usrcmds.lua` (deklarative Route-Table),
  `bindings/keymaps.lua`/`bindings/autocmds.lua` (No-op-Stubs), `@types/init.lua`
  (reine Annotationen), `export.lua` (externer pandoc/Headless-Chromium-Prozess),
  `attachments.lua`'s `pick_from_downloads` (natives Windows-`OpenFileDialog` via PowerShell),
  `ocr.lua`'s `M.run` jenseits des images.nvim-Guards, `linkcheck.lua`'s `M.run`/`M.check` +
  `replygate.check`'s URL-Zweig (echte HTTP-HEAD-Requests — nur die reine
  Target-Collection-Logik ist getestet), `sla/notify.lua`'s `M.setup()` (echter
  libuv-Timer/Autocmd-Singleton — `M.check`'s Warn/Dedup-Logik ist direkt getestet).
  Commit: `3cc4cd9` (test: cover config, core, extraction, SLA and search modules),
  direkt auf `main` gepusht.
- [x] **buffer-ctx.nvim** — fertig (Runde 5). Eigener framework-freier Harness (wie
  pickers.nvim/cmdlog.nvim) beibehalten. 6 neue Spec-Dateien: `config_spec.lua`
  (config/init.lua Deep-Merge + health.lua), `bindings_spec.lua` (keymaps/usrcmds/autocmds
  end-to-end über die Clipboard-Register), `boilerplate_spec.lua` (alle 5 Templates + Registry),
  `util_spec.lua` (clip/cursor + lib.nvim-present/absent-Zweige via `package.preload`),
  `ops_edge_spec.lua` (annotation.lua alle Typen, git.lua alle Modi gegen echte Temp-Git-Repos
  inkl. detached HEAD, Error-Pfade), `format_extra_spec.lua` (format/init.lua Command-Gates +
  restliche format/misc.lua-Zweige). Vorher 5 Spec-Dateien/~24 von 46 Dateien mit echter
  Coverage, danach 11 Spec-Dateien/40 von 46 Dateien. 5/5 → 11/11 Spec-Dateien grün (stabil über
  3 Wiederholungsläufe). `stylua --check` clean, `luacheck lua TESTS plugin` 0 Warnings/Errors
  über 59 Dateien.
  **Zwei echte Bugs gefunden, bewusst nur als Regressionstest gepinnt (nicht gefixt, s.u.
  Fix-Tasks):**
  1. `format/text_width.lua`: Reflow einer Bullet-/Nummer-Zeile duplitiert den Marker
     (`detect_prefixes()` extrahiert ihn, `flush()` strippt aber nur Whitespace vor dem
     Tokenizing, wodurch der Marker zusätzlich als normales Token re-emittiert wird) —
     z.B. `"- one two three"` bei Breite 12 → `"-  - one two"` statt `"- one two"`.
     **Mittlerweile gefixt** (separate Session, Commit `3c99c3c`): `flush()` strippt jetzt
     den vollen erkannten Präfix (Indent + Marker) statt nur Whitespace von der ersten Zeile.
     Dabei zeigte sich ein zweiter, verwandter Fehler: `wrap_words()` fügte vor dem ersten
     Wort immer ein Trenn-Leerzeichen ein, obwohl der Präfix sein eigenes bereits mitbringt
     (Ergebnis ohne diesen zweiten Fix: `"-  one two"`, weiterhin doppeltes Leerzeichen) —
     analog dazu gefixt, wie eine umgebrochene Folgezeile ihr erstes Wort schon ohne
     zusätzliches Trennzeichen an `cont_prefix` anhängt.
  2. `format/enum_lines.lua`: `alpha`/`ALPHA`-Enum-Stile emittieren pro Label einen
     überflüssigen führenden Buchstaben (Off-by-one in `alpha_marker()`'s Digit-Loop-Exit) —
     3 Tokens ergeben `za.`, `zb.`, `zc.` statt `a.`, `b.`, `c.`.
     **Mittlerweile gefixt** (separate Session, Commit `79893f9`).
  Kein Bug, aber notiert: `util/map.lua`'s lib.nvim-Erkennung (`type(lib_map) == "function"`)
  ist immer `false`, weil `require("lib.nvim.bindings.keymap")` eine über `__call` aufrufbare
  Table zurückgibt statt einer reinen Function — buffer-ctx nutzt lib.nvim's Keymap-Helper
  dadurch nie (Fallback auf `vim.keymap.set` verhält sich aber identisch; einziger sichtbarer
  Effekt: `:checkhealth` meldet lib.nvim für diesen einen Punkt immer als "not found").
  Bewusst ausgelassen: `plugin/buffer_ctx.lua` (3-Zeilen-Load-Guard), Telescope-Extension
  (dünner UI-Adapter, telescope.nvim nicht im Test-Runtimepath), alle `@types`/`types/init.lua`
  (reine `---@meta`-Anker), `table_fmt.lua`'s `scope=cwd` (bräuchte echtes cwd-Mutieren,
  worauf alle anderen Suiten über cwd-relative Buffer-Namen angewiesen sind).
  Commit: `6290f8b` (test: cover config, bindings, boilerplate, and ops/format edge cases),
  direkt auf `main` gepusht.
- [x] **debugging.nvim** — fertig (Runde 6). Eigener framework-freier Harness beibehalten.
  10 neue Spec-Dateien: `init_spec.lua`, `actions_spec.lua` (module_reload, neotree_safety,
  reports), `autocmds_runtime_spec.lua`, `nvim_options_spec.lua`, `keylogger_spec.lua`,
  `tools_spec.lua` (buffer_inspector, cursor/state, vardump, proc_trace gestubbt),
  `markdown_spec.lua`, `bindings_spec.lua`, `views_spec.lua`, `capture_spec.lua`
  (alle 4 Noice-Retrieval-Strategien + echter `:messages`-Fallback). Vorher 5 Spec-Dateien/
  ~6 von 34 Dateien mit echter Coverage, danach 15 Spec-Dateien/~23 von 34.
  6/6 → 15/15 Specs grün, 0 Fails. `luacheck lua plugin TESTS` 0 Warnings/Errors (52 Dateien),
  `stylua --check` clean.
  **Ein echter Bug gefixt** (trivialer Blocker für den eigenen Test):
  `markdown/inline_debug.lua`'s `M.gather()` rief `vim.fn.mkdir(debugfolder)` ohne `"p"` auf →
  unabgefangener `E739`-Crash bei `:Debug markdown inline`, sobald `stdpath("data")/debuglog`
  noch nicht existiert.
  **Ein Bug gepinnt, nicht gefixt** (würde einen Pfad ändern, von dem ein Nutzer abhängen
  könnte — s.u. Fix-Task): in derselben Funktion wird `out_path` als
  `debugfolder .. "_debuglog_" .. ts .. ".log"` ohne Pfadtrenner zusammengesetzt, wodurch die
  Log-Datei als *Sibling* von `markdown_inline/` landet statt darin — das gerade erst
  angelegte Verzeichnis bleibt immer leer. Gepinnt mit `BUG:`-Assertion in `markdown_spec.lua`.
  **Mittlerweile gefixt** (separate Session, Commit `8ac567e`): nutzt jetzt
  `lib.nvim.fs.path.joinpath`, analog zur bestehenden Konvention in `views/capture/init.lua`.
  **Drei weitere Quirks notiert, nicht verändert:** `tools/vardump/init.lua`'s
  Word-under-Cursor nutzt `%w+` (kein Underscore) → dumpt bei `hello_from_cursor` nur `hello`;
  `views/capture/init.lua`'s `capture_messages()` meldet `ok=false` auch wenn Content erfasst
  wurde, sofern `save_file`/`clipboard` beide `false` sind; `views/init.lua`'s `setup()`
  akkumuliert Config über mehrere Aufrufe statt zu resetten (anders als `config/init.lua`).
  Bewusst ausgelassen: 6× `@types/init.lua` (reine Annotationen), `health.lua`
  (deklarativer `:checkhealth`-Reporter), `views/debug_helper.lua` (bestätigt toter Code laut
  eigenem Datei-Header), `views/display.lua`'s Timer/Window-Choreografie-Funktionen,
  `tools/proc_trace.lua`'s `M.watch()` (echtes Terminal+PowerShell-Spawning),
  `tools/startup.lua`'s Subprocess-Messfunktionen (reiner Parser `M.parse` ist getestet).
  Commit: `7b05563`, direkt auf `main` gepusht.
- [x] **recommender.nvim** — fertig (Runde 7). Eigener framework-freier Harness beibehalten.
  6 neue Spec-Dateien: `javascript_analyzer_spec.lua`, `python_analyzer_spec.lua`,
  `treesitter_analyzer_spec.lua`, `float_autocmds_spec.lua`, `keymaps_spec.lua`,
  `util_lib_spec.lua` (lib.lua/notify.lua/progress.lua inkl. simuliert-abwesender
  Fallback-Pfade); `config_spec.lua` um eine Assertion erweitert. Um `treesitter.lua`
  testbar zu machen: verhaltensgleiches Refactoring — inline Alias-Building-Block in ein
  lokales `build_suggestions()` extrahiert und zusammen mit `common_prefix`/`collect_chains`
  über `M._internal` exponiert (gleiche Konvention wie bereits in debugging.nvim's
  `autocmds/sources.lua`). Vorher 5 von 23 Dateien mit echten Specs, danach 11.
  5 → 11 Specs, 0 Fails, stabil über Wiederholungsläufe. `luacheck lua TESTS` 0
  Warnings/Errors (36 Dateien), `stylua --check` clean.
  **Echter Bug gefunden, gepinnt statt gefixt** (s.u. Fix-Task): `analyzers/treesitter.lua`'s
  Tree-sitter-Query fragt nach `field_expression`/`call_expression`-Knoten, aber die mit
  Neovim 0.12.2 gebundelte tree-sitter-lua-Grammatik nennt sie `dot_index_expression`/
  `function_call` — die Query parst nicht, der Fehler wird by-design still verschluckt
  (fehlender/nicht-passender Parser → "keine Findings" statt Fehler), wodurch
  `analyzer = "treesitter"` auf jeder passenden Neovim-Version aktuell **gar nichts findet**.
  Gepinnt als `BUG:`-Assertion in `treesitter_analyzer_spec.lua`.
  **Mittlerweile gefixt** (separate Session, Commit `cc338f6`): Query auf
  `dot_index_expression`/`function_call` umgestellt (empirisch gegen Neovim 0.12.2 verifiziert).
  Dabei wurde ein zweiter, in dieser Coverage-Runde nicht entdeckter Folgebug gefunden und
  mitgefixt: `Query:iter_matches` liefert pro Capture eine Liste von Knoten statt eines
  einzelnen `TSNode`, wodurch der Analyzer selbst nach der Namenskorrektur nichts gefunden
  hätte.
  **Sekundärer Hinweis (kein Bug, Verbesserungsvorschlag):** `usrcmds.lua`'s
  `classify_pos_args`/`resolve_cfile` haben echte pure Logik, sind aber aktuell nicht testbar,
  weil das Modul beim Laden transitiv `ui.kit` (ui.nvim) requirt, das in CI nicht als
  Sibling-Checkout verfügbar ist — ein Lazy-Require von `float.rendering`/`float.keymaps`
  erst innerhalb von `execute()` würde das ohne Verhaltensänderung entsperren.
  Bewusst ausgelassen (ui.kit-Ladeketten-CI-Problem): `init.lua`, `bindings/init.lua`,
  `bindings/usrcmds.lua`, `float/rendering.lua`, `float/keymaps.lua`. Weitere Auslassungen:
  `custom_aliases.lua`/`config/DEFAULTS.lua` (reine Datentabellen), `health.lua`
  (deklarativer Reporter), `bindings/autocmds.lua` (bewusst leerer Stub), `@types.lua`
  (reine Annotationen).
  Commit: `6e7fb65`, direkt auf `main` gepusht.
- [x] **language.nvim** — fertig (Runde 8, nach kurzer Unterbrechung durch API-Sessionlimit
  in zwei Etappen gelandet: erster Agent schrieb 21 neue Spec-Dateien, wurde beim
  Lint-Cleanup unterbrochen; zweiter Agent hat übernommen statt neu zu starten). Eigener
  framework-freier Harness beibehalten. 6 → 27 Spec-Dateien: `cache_spec.lua`,
  `collect_spec.lua`, `job_spec.lua`, `native_spec.lua`, `regions_spec.lua`,
  `language_init_spec.lua`, `live_spec.lua`, `bindings_keymaps_autocmds_spec.lua`,
  `bindings_usrcmds_spec.lua`, `spell_init_spec.lua`, `spell_providers_cli_spec.lua`,
  `spell_ui_spec.lua`, `thesaurus_spec.lua`, `wordlists_spec.lua`,
  `translate_{files,filter_indent,history,init,motion,output,providers}_spec.lua`
  (plus `actions_spec.lua`/`ignore_spec.lua`/`run.lua` erweitert).
  Beim Lint-Cleanup fiel ein **echter fehlender Assertion-Fix** auf (kein reiner Lint-Nit):
  in `translate_providers_spec.lua` fehlte — anders als bei allen Parallel-Fällen
  (`d_done`/`s_done`/`c_done`/`p_done`) — die Assertion `H.ok(q_done, "resolves")` für
  einen der Provider; ergänzt. Außerdem eine veraltete Aussage in `TESTS/README.md`
  korrigiert: `ignore.add_persistent` wird jetzt tatsächlich getestet (über
  `spell.dictionary.ignore_file`, umgeleitet auf eine Fixture-Datei).
  Vorher ~6 von 51 Dateien mit echter Coverage, danach 43 von 51 (4 reine `@types`-Dateien,
  4 bewusst ausgeklammert). 27/27 Specs grün, 0 Fails. `luacheck lua plugin TESTS` 0
  Warnings/Errors (81 Dateien), `stylua --check` clean.
  Keine neuen echten Bugs gefunden (anders als bei den vorherigen Runden).
  Bewusst ausgeklammert (ui.kit-Ladeketten-CI-Problem wie bei recommender.nvim):
  `spell/ui/panel.lua`, `spell/ui/item_menu.lua`, `translate/window.lua`'s Picker-Flow
  (nur als Collaborator gestubbt). Weitere Auslassung: `spell/providers/cspell_server.lua`
  (echter persistenter Node/cspell-Prozess), 4× `@types`-Module.
  Commit: `51dd7d1` (test: cover cache, collect, job, spell, and translate gaps),
  direkt auf `main` gepusht.
- [x] **open.nvim** — fertig (Runde 9). Eigener framework-freier Harness beibehalten.
  9 neue Spec-Dateien: `config_spec.lua`, `util_platform_spec.lua`, `registry_spec.lua`,
  `keywords_spec.lua` (vim.system gestubbt, kein echter Subprocess), `context_spec.lua`
  (volle `resolve()`/`default_target()`-Branch-Matrix, netrw-Tree-Resolver), 
  `bindings_keymaps_spec.lua`, `handlers_spec.lua` (default/browser/notepad/nvim_internal/
  image — vorher 0% Coverage), `integrations_spec.lua` (urlview, menu), `picker_spec.lua`.
  Bemerkenswert: anders als bei recommender.nvim/language.nvim antizipiert ist `ui.nvim`
  in diesem Repo tatsächlich als CI-Sibling gecheckt out — `picker.lua` und
  `integrations/menu.lua` brauchten daher keine Auslassung und bekamen echte,
  nicht-gemockte Coverage.
  Vorher 6 Spec-Dateien/~12 von 26 Dateien mit Coverage, danach 15 Spec-Dateien/24 von 26.
  6/6 → 15/15 Specs grün, stabil über 4 Wiederholungsläufe. `luacheck lua plugin TESTS`
  0 Warnings/Errors, `stylua --check` clean.
  Keine Bugs gefunden.
  Bewusst ausgeklammert: `health.lua` (deklarativer Reporter), `@types/init.lua`
  (reine Annotationen), `integrations/telescope.lua`'s Finder/Previewer-Internals
  (telescope.nvim selbst nicht im CI-Checkout, nur lib.nvim/ui.nvim).
  Commit: `a8dbe1d` (test: cover config, registry, context, keywords, handlers, and
  integrations), direkt auf `main` gepusht.
- [x] **replacer.nvim** — fertig (Runde 10, nach dem gescheiterten ersten Versuch komplett neu
  gestartet — der vorherige Agent wurde vom Wochenlimit beendet, bevor er irgendetwas
  geschrieben/committet hatte). Anders als bei den meisten anderen Runden nutzt dieses Repo
  KEINEN `_spec`-Suffix und KEINEN gemeinsamen `run.lua`-Aggregator: `TESTS/*.lua` sind
  eigenständige Skripte, je einzeln per `nvim --headless -u NONE -c "luafile TESTS/<name>.lua"
  -c "qa"` ausgeführt (siehe `.github/workflows/ci.yml`), Konvention beibehalten statt auf
  `_spec`/`run.lua` umgestellt.
  5 neue Dateien: `config_merge.lua` (config/init.lua + config/DEFAULTS.lua — alle Coercer
  `as_bool`/`as_pos_int`/`as_engine`/`as_search_engine`/`as_progress_style`/`as_string_list`/
  `as_keymaps`, verschachtelter fzf/telescope-Deep-Merge, `setup()`/`get()`/`resolve()`'s
  Merge-Semantik inkl. der Tatsache, dass `setup()` kumulativ ist statt zurückzusetzen),
  `argtypes_debug_error.lua` (argtypes.lua's zwei Composer-Argument-Typen — zurückgeholt über
  lib.nvim's eigene Argtype-Registry, da sonst lokal —, debug.lua's `:ReplaceDebug`-Dispatch,
  error.lua's typisierte Fehler/`safe_call`-Hülle), `health_pickers_tscode.lua` (health.lua
  gegen ein gestubbtes `vim.health` zur Report-Erfassung unabhängig von zufällig installierten
  Optional-Tools, die Backend-agnostischen Hälften von `pickers/common.lua`/`pickers/utils.lua`,
  tscode.lua's echte Tree-sitter-String/Comment-Klassifikation, util/notify.lua-Smoke-Test),
  `bindings_wiring.lua` (die komplette `bindings/{init,usrcmds,keymaps,autocmds}.lua`-Schicht
  plus der echte `:ReplaceTest`-Float, den sie antreibt), `init_dispatch.lua`
  (`replacer/init.lua`'s Orchestrierung: die alte positionale `run()`-Form, der
  Dry-run/Export-"Plan"-Pfad inkl. `[replacer-plan]`-Diff-Scratch-Buffer, der
  "kein Picker verfügbar"-Fallback, `request.filter`-Hook, der echte
  Confirm-vor-ALL-Flow inkl. `confirm_wide_scope` vs. Single-File-Scope, sowie dispatch's
  eigene `cfg.checkpoint`/`cfg.confirm_per_file`-Verdrahtung — im Gegensatz zu den isolierten
  Unit-Tests dieser beiden Module in `feature_smoke.lua`, die einen Fake-`apply_func` nutzen).
  Vorher 8 Dateien (davon 2 — `health_debug.lua`/`utf8_offsets.lua` — nie in CI verdrahtet),
  danach 13 (8 CI-Schritte in `.github/workflows/ci.yml`, je einer pro neuer Suite ergänzt,
  matching dem Stil der 4 bestehenden Schritte).
  **Echter Bug gefunden, gepinnt statt gefixt** (s.u. Fix-Task): `config/init.lua`'s `M.get()`
  verspricht laut eigenem Docstring "a deep copy, to avoid accidental mutation by callers",
  ist aber `vim.tbl_deep_extend("force", {}, state)` — dieser Aufruf merged ein verschachteltes
  Sub-Table nur dann tief, wenn BEIDE Seiten an diesem Schlüssel bereits eine Table haben; ein
  Schlüssel, der nur auf einer Seite existiert (hier: jeder Schlüssel, da das erste Argument
  `{}` ist), wird per Referenz übernommen. Jede von `get()` zurückgegebene verschachtelte Table
  (`keymaps`, `fzf`, `telescope`, `hooks`, `messages`, `file_types`/`globs`/`exclude`) ist somit
  dasselbe Table-Objekt wie im privaten `state` des Moduls — eine Mutation des scheinbar
  reinen Snapshots korrumpiert lautlos die persistente Config für den Rest der Session. Gepinnt
  mit einer Regressions-Assertion in `config_merge.lua`; ein echter Fix (`vim.deepcopy(state)`)
  ist eine bewusst separate Änderung.
  Bewusst ausgelassen: `pickers/fzf.lua`/`pickers/telescope.lua`'s `run()`-Funktionen (beide
  requiren hart ein echtes Picker-Backend — fzf-lua/telescope.nvim —, keines davon ist CI-
  Sibling-Checkout, nur lib.nvim/ui.nvim/pickers.nvim sind es; die Backend-agnostische Logik,
  auf die beide aufbauen, `pickers/common.lua`, ist vollständig ohne Backend abgedeckt),
  `@types`/`types/*.lua` (reine `---@meta`-Annotationen).
  Testlauf: 8 → 13 Test-Dateien, alle 9 CI-verdrahteten grün (0 FAIL), über 2 Wiederholungsläufe
  stabil. `find lua plugin -name '*.lua' | xargs luacheck` (genau der CI-Befehl) 0
  Warnings/Errors über 41 Dateien; `stylua --check lua/` (genau der CI-Befehl) grün. TESTS/ ist
  in diesem Repo bewusst NICHT Teil des luacheck/stylua-Gates (anders als bei den meisten
  anderen Runden) — die neuen Dateien wurden trotzdem mit `luacheck`/`stylua` geprüft und sind
  sauber. `TESTS/README.md` neu angelegt (gab es noch nicht); Top-Level-`README.md` hatte
  keinen Test-Abschnitt, daher unangetastet gelassen.
  Commit: `053e1d6` (test: cover config merge, argtypes/debug/error, health/pickers/tscode,
  bindings, and init dispatch), direkt auf `main` gepusht.
- [x] **github_stats.nvim** — fertig (Runde 11). Dieses Repo nutzt plenary/busted
  (`describe`/`it`, `scripts/test.sh` → `PlenaryBustedDirectory TESTS/` mit
  `scripts/minimal_init.lua`), Konvention beibehalten; Spec-Dateien werden per `_spec.lua`
  automatisch eingesammelt, es gibt keinen Aggregator, in den man neue Dateien eintragen
  müsste. Dependencies wie in CI: `lib.nvim`, `ui.nvim` **und** `plenary.nvim` sind harte
  Abhängigkeiten (`LIB_NVIM_DIR`/`UI_NVIM_DIR`/`PLENARY_DIR`, sonst `.deps/<name>` bzw.
  Sibling-Checkout) — anders als bei recommender.nvim/language.nvim ist `ui.nvim` hier also
  verfügbar, `integrations/menu.lua` und `usrcmds/utils.lua`s `ui.kit.note`-Float brauchten
  daher keine Auslassung.
  13 neue Spec-Dateien: `api_spec.lua`, `fetcher_spec.lua`, `background_spec.lua` (enthält
  auch `repo_discovery`), `dashboard_state_spec.lua` (state + movement),
  `dashboard_actions_spec.lua` (actions + detail), `dashboard_lifecycle_spec.lua`,
  `diff_spec.lua`, `visualization_spec.lua`, `ui_state_spec.lua`, `analytics_query_spec.lua`,
  `usrcmds_spec.lua`, `bindings_spec.lua` (keymaps/autocmds/`setup()`/Kontextmenü/utils),
  `health_spec.lua`. Zusätzlich 4 bestehende Dateien erweitert: `storage_spec.lua`
  (On-Disk-Layout, Listing, Löschen — vorher nur das Read-Memo), `export_spec.lua`
  (die CSV/Markdown-Writer selbst, `format_number`, pdfport-Gate, Schreibfehler),
  `retention_spec.lua` (24h-Rate-Limit von `maybe_run_all`, `format_bytes`),
  `date_presets_spec.lua` (alle Builtins, `M.list()`, jede Ablehnung von `resolve()`).
  **Kein einziger Netzwerkzugriff:** jeder Request-Pfad ist an einer Naht gekappt, die *vor*
  dem `require` des Testobjekts in `package.loaded` ersetzt wird — `lib.nvim.net.curl` in
  `api_spec`/`health_spec`, `github_stats.api` in fetcher/background/usrcmds,
  `github_stats.fetcher` überall dort, wo ein Force-Refresh ausgelöst wird. Einziger
  Subprozess im ganzen Lauf ist `curl --version` aus dem Dependency-Check von `health.lua`.
  `health_spec.lua` ersetzt zusätzlich `github_stats.config` komplett, weil das echte
  `check_config()` `config.init()` *ohne Argumente* aufruft und damit im echten
  `stdpath("config")`-Verzeichnis des Nutzers landen würde.
  **Ein echter Bug gefunden und direkt gefixt** (eindeutig falsch, in-Repo existiert bereits
  der korrekte, getestete Helper): `dashboard/detail.lua` maß die angezeigte Periode mit
  `vim.fn.strptime()`. Die Funktion existiert auf jeder Plattform als Vimscript-Funktion,
  *funktioniert* aber nur dort, wo die C-Bibliothek `strptime(3)` liefert — Neovim unter
  Windows gibt für jede Eingabe glatt `0` zurück, beide Datumswerte parsten also auf denselben
  Zeitpunkt und die Kopfzeile las sich bei jeder Spanne als „(1 days)". Nutzt jetzt
  `analytics.count_days()` (gleiche inklusive Tageszählung, die der Dashboard-Header schon
  verwendet); CHANGELOG-Eintrag unter „Unreleased → Fixed" ergänzt.
  **Zwei weitere echte Bugs gefunden, bewusst nur gepinnt statt gefixt** (beides sichtbare
  Verhaltensänderungen, je mit `BUG:`-Kommentar an der Assertion):
  1. `bindings/usrcmds/utils.lua`s `split_lines()` hängt bei *jedem* Aufruf eine leere Zeile
     an (das Muster `([^\n]*)\n?` matcht am Subject-Ende ein weiteres Mal). `show_float()`
     ruft es pro Element eines Zeilen-Arrays auf — jeder mehrzeilige Report dieses Plugins
     (`:GithubStats show`/`summary`/`chart`/`diff`/`paths`/`referrers`, die Detail-Ansicht)
     wird dadurch doppelt zeilenumbrochen ausgegeben.
  2. `export.lua`s `write_lines()` pcallt zwar das `writefile`, nicht aber das `mkdir`, das
     `ensure_parent_dir()` davor macht — ein nicht anlegbares Elternverzeichnis (z.B. weil der
     Pfad bereits als Datei existiert) entkommt als rohes `E739: Cannot create directory`
     statt als das „Export failed: …", das `:GithubStats export` verspricht. Genau die
     Fehlerklasse, gegen die `ensure_parent_dir()` laut eigenem Kommentar eingeführt wurde.
  **Kein Bug, aber notiert:** die `M.complete()`-Funktionen in `bindings/usrcmds/*.lua` haben
  keinen Aufrufer mehr — seit der Composer-Migration completet `:GithubStats <sub>` über die
  registrierten Typen `GH_REPO`/`GH_DATE_OR_PRESET`/`GH_PERIOD` — und ihre Slot-Arithmetik
  zählt weiterhin von der alten flachen `:GithubStatsShow …`-Kommandozeile. In `usrcmds_spec`
  in genau dieser Legacy-Form gepinnt, da sie als Public API erreichbar bleiben. Zweite
  Notiz: `date_presets`' `get_week_start()` beginnt die Woche montags, `analytics.rollup_weekly()`
  dagegen sonntags — unabhängige Features, aber uneinig darüber, wann eine Woche anfängt.
  Bewusst ausgelassen: `@types`-Dateien (3× unter `lua/github_stats/@types/` plus
  `dashboard/@types/init.lua` und `state/@types/init.lua`, reine `---@meta`-Annotationen),
  `config/DEFAULTS.lua` (deklarative Tabelle ohne Verzweigung; ihre Werte sind indirekt über
  jeden getesteten Fallback abgedeckt), der echte API-Probe-Request in `health.lua` (dessen
  Verzweigung 200/401/403/404/sonstige/undekodierbar/leer/curl-Fehler ist über den gestubbten
  Client vollständig abgedeckt — nur der echte Request fehlt, absichtlich), die
  `_pdf`-Export-Varianten jenseits des pdfport-Contracts (ein echtes PDF bräuchte pandoc plus
  TeX-Engine als externe Prozesse), sowie das Rendering von `integrations/menu` (Item-Liste und
  jeder Callback sind abgedeckt; das Öffnen bräuchte `nvzone/menu`, kein CI-Checkout).
  Testlauf: 9 → 22 Spec-Dateien, 109 → 482 grüne Assertions, 0 Fails, 0 Errors; über drei
  Wiederholungsläufe stabil, `scripts/test.sh` beendet mit Exit 0. `luacheck .` 0
  Warnings/Errors über 67 Dateien und `stylua --check .` (genau die CI-Befehle; `TESTS/` ist
  hier *Teil* beider Gates, anders als bei replacer.nvim) beide grün.
  `TESTS/README.md` neu angelegt (gab es noch nicht): Bootstrap/Env-Vars, ein Abschnitt „No
  network, ever" mit den konkreten Nahtstellen, eine Tabelle Spec → Subject, die bewussten
  Auslassungen mit Begründung und die zwei gepinnten Bugs. Top-Level-`README.md` hat keinen
  Test-/Coverage-Abschnitt, daher unangetastet gelassen.
  Commit: `1b9b638` (test: cover api, fetcher, background, dashboard layers, bindings and
  health), direkt auf `main` gepusht und per `git merge-base --is-ancestor HEAD origin/main`
  verifiziert.
- [ ] restliche 🟠/🟡 Plugins — noch nicht begonnen, siehe Tabelle oben.
