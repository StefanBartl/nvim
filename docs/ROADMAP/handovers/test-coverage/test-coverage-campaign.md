# Test-Coverage-Kampagne über alle nvim-Plugins — Handover

## Table of content

  - [Restliche Plugins (Reihenfolge für die Fortsetzung)](#restliche-plugins-reihenfolge-fr-die-fortsetzung)
  - [Regeln für diese Session (aus CLAUDE.md / Nutzer-Vorgaben)](#regeln-fr-diese-session-aus-claudemd--nutzer-vorgaben)
  - [Ausgangslage (2026-09-15)](#ausgangslage-2026-09-15)
  - [Aktueller Stand (2026-09-16, nach zwei Wochenlimit-Unterbrechungen)](#aktueller-stand-2026-09-16-nach-zwei-wochenlimit-unterbrechungen)
  - [Fortschritt](#fortschritt)

---

## Restliche Plugins (Reihenfolge für die Fortsetzung)

26 von 36 Plugins sind fertig -- die urspruengliche Warteschlange ist mit dieser Runde komplett (siehe "Fortschritt" unten). 9 weitere (`images.nvim`,
`ai.nvim`, `hover.nvim`, `runtime-analysis.nvim`, `lib.nvim`, `markdown.nvim`,
`documentation.nvim`, `media.nvim`, `ui.nvim`) sind laut Survey bereits 🟢/✅ und bekommen
laut Kampagnenregel keine volle Runde, außer eine konkrete Prüfung findet doch eine Lücke.
Runde 27 (lsp.nvim, letzter Punkt der urspruenglichen Warteschlange) laeuft, zusammen mit
fuenf Re-Audit-Runden der aeltesten fertigen Repos. Nutzer-Entscheidung 2026-09-18:
**jedes Plugin auf 100% pushen**, innerhalb der bisherigen Definition (weiterhin ohne
@types, echtes Live-Backend-Rendering, echte externe Prozesse). Danach beginnt ein
systematischer Re-Audit aller 27 Runden, aeltestes Repo zuerst.

Verbleibende 0 (🟠 dann 🟡, wie im Survey unten priorisiert) sind die Warteschlange,
in dieser Reihenfolge abzuarbeiten:

(keine -- die urspruengliche Liste ist mit Runde 27 komplett)

## Regeln für diese Session (aus CLAUDE.md / Nutzer-Vorgaben)

- Seit 2026-09-17 bis zu 3 Agents gleichzeitig (vorher 1), je ein Repo pro Agent. Den
  Handover schreibt ausschließlich die Hauptsession — parallele Agents würden sich hier
  gegenseitig überschreiben; sie berichten stattdessen zurück.
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
| insights.nvim | 49 | 9 | ✅ fertig (Runde 12, Commit `1be0f7a`; 7 → 31 Spec-Dateien) |
| sessions.nvim | 17 | 9 | ✅ fertig (Runde 13, Commit `0034df3`) |
| pdfport.nvim | 50 | 10 | ✅ fertig (Runde 14, Commit `3c9273a`) |
| emojis.nvim | 23 | 11 | ✅ fertig (Runde 15, Commit `5ea0333`) |
| fileops.nvim | 18 | 11 | ✅ fertig (Runde 16, Commit `7060232`) |
| reposcope.nvim | 113 | 12 | ✅ fertig (Runde 17, Commit `98a9a36`) |
| gopath.nvim | 77 | 16 | ✅ fertig (Runde 18, Commit `394b4b3`) |
| color_my_ascii.nvim | 95 | 17 | ✅ fertig (Runde 19, Commit `adcb5ef`) |
| diff.nvim | 23 | 17 | ✅ fertig (Runde 20, Commit `d7aa3a5`) |
| cascade.nvim | 48 | 18 | 🟡 mittel |
| sandbox.nvim | 270 | 19 | 🟡 mittel (sehr großes Repo) |
| data.nvim | 16 | 20 | ✅ fertig (Runde 23, Commit `a64c208`) |
| spotlight.nvim | 27 | 19 | ✅ fertig (Runde 24, Commit `5931a55`) |
| mdview.nvim | 78 | 24 | ✅ fertig (Runde 25, Commit `166904e`) |
| filetree.nvim | 129 | 26 | ✅ fertig (Runde 26, Commit `811bfed`) |
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

## Aktueller Stand (2026-09-18)

**27 von 36 Plugins fertig — die ursprüngliche Prioritäts-Warteschlange (Runden 1-27,
inklusive lsp.nvim als letztem Punkt) ist komplett.**

**Nutzer-Entscheidung 2026-09-18: jedes Plugin auf 100% pushen.** Definition dabei
unverändert (bestätigt vom Nutzer): weiterhin ohne reine `@types`/`---@meta`-Dateien, ohne
Rendering das ein echtes Live-Backend braucht (telescope/fzf-lua/snacks), ohne echte externe
Prozesse (echtes Docker, echtes pandoc, echter Netzwerk-Request an einen echten Server).
"100%" heißt: jede Datei mit echter Logik hat eine echte Assertion-Suite. Seither läuft ein
**systematischer Re-Audit aller fertigen Runden**, ältestes Repo zuerst — Ziel ist nicht,
jede Runde von Grund auf zu wiederholen, sondern ehrlich zu prüfen, ob die damaligen
Auslassungs-Gründe noch gelten (z.B. ist ein Backend inzwischen doch CI-Sibling? gibt es neue
Dateien seit der Runde ohne Spec?) und die wiederkehrenden Bug-Familien gezielt nachzuprüfen.

**Re-Audit-Fortschritt:** Runden 1-5 (pickers/cmdlog/dap/casedesk/buffer-ctx) fertig geprüft.
Runden 6-11 (debugging/recommender/language/open/replacer/github_stats) laufen parallel.
Danach weiter mit Runde 12 (insights.nvim) aufwärts, sechs Agents gleichzeitig.

**Nebenfund bei lsp.nvim (Runde 27):** während der eigenen Nachverifikation lief parallel
eine andere Session direkt im selben `E:\repos\lsp.nvim`-Checkout (unabhängig von dieser
Kampagne, echte Bugfixes an `completion`/`health`/`config`/`lsp_signature`/`ts_ls`) und
pushte mehrfach auf `origin/main`, während der Rebase dieser Runde lief. Ein `git rebase`
geriet dadurch in einen echten Konflikt (dieselbe Windows-Pfad-Ursache war unabhängig auch
hier gefunden und bereits gefixt) — sauber aufgelöst, nichts verloren, am Ende beide
Fix-Historien im finalen Commit `30e3e6a` vereint. Lehre: `git rebase`/`git push` in einem
gemeinsam genutzten Checkout können durch fremde Commits mitten im eigenen Lauf brechen;
`&&`-Ketten mit nachgeschaltetem `| tail`/`grep` verschleiern dabei den echten Exit-Code
der vorderen Befehle (siehe Abschnitt "Fehler und Lektionen" weiter unten, falls vorhanden,
sonst: `cmd | tail` liefert `tail`s Exit-Code, nicht `cmd`s — bei einer `&&`-Kette also nie
verlässlich für Fehlererkennung).

**Bugfix-Bilanz:** von den ursprünglich 25 gepinnten Bugs plus den seither in Re-Audit-Runden
neu gefundenen sind **30 offen**, der Rest gefixt (Details: Report, Abschnitt "Gefixt"/
"Offen (gepinnt)"). Die Health-Familie ("Dependency fehlt, ruft sie danach trotzdem auf")
steht bei 8 gefunden / 5 gefixt (zuletzt cmdlog.nvim) / 3 offen (gopath.nvim `create.lua`,
pickers.nvim, casedesk.nvim).

Alle Coverage- und Bugfix-Commits sind per `git merge-base --is-ancestor` gegen
`origin/main` verifiziert, inklusive eigener Nachvollzugsläufe der Suiten (nicht nur
Agenten-Meldungen übernommen).

Details zu allen offenen Pins nach Repo: siehe Report `docs/ROADMAP/reports/TESTS-Abdeckung.md`,
Abschnitt "Offen (gepinnt)".

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
  **Re-Audit (2026-09-18, 100%-Nachziehrunde):** zwei der Runde-1-Auslassungen hielten nicht
  mehr. `pickers/health.lua` galt als "nichts Prüfbares" — `M.check()` ist aber ein
  Funktionskörper, dessen Absturz sich per `pcall` sehr wohl nachweisen lässt.
  `sources/drives.lua` galt als "keine stabile Mock-Fläche ohne `vim.system` zu ersetzen" —
  `vim.system` ist aber ein globaler Wert, kein `require()`-Upvalue, also direkt
  monkeypatchbar (dieselbe Technik wie open.nvims `keywords_spec`, Runde 9).
  **Zwei Bugs gefunden, beide gepinnt statt gefixt:** `health.lua`s letzte Zeile ruft
  `require("lib.nvim.bindings.usercmd.composer").checkhealth("Pickers")` bedingungslos und
  außerhalb jedes `pcall` — bei echtem Fehlen crasht `:checkhealth pickers` komplett statt den
  Report fertigzustellen. **Das sechste Repo mit dem "Dependency fehlt, ruft sie trotzdem
  auf"-Muster** — und die erste Instanz davon, die noch offen ist (die anderen fünf sind
  bereits gefixt). Zweitens: `smart/frecency.lua`s `M.patch()` löst die gemeinsame
  `"pickers.nvim"`-Augroup per Namen ohne `clear=true` auf → ein zweiter `setup()` mit
  aktivierter Frecency registriert einen zweiten `BufReadPost`/`VimLeavePre`-Handler statt den
  ersten zu ersetzen (live gegen `nvim_get_autocmds()` verifiziert: 1 → 2).
  Geprüft und **nicht** als Bug befunden (Sorgfalt gegen Übertreibung): der vermeintliche
  Drive-Letter-vs-Doppelpunkt-Split in `smart/search.lua`s rg-Parser ist sicher (der `%d+`-
  Zwang nach dem ersten `:` verhindert, dass `C:` als Trenner gelesen wird); Byte-vs-Zeichen-
  Spalten werden konsistent durch alle drei Engine-Adapter gereicht; `drives.lua`s
  Dauer-Cache ist laut eigenem Kommentar bewusst ("drives don't change during a session").
  Testlauf: 575 → 592 grüne Checks, 0 Fails über mehrere Wiederholungsläufe. Beide Gates grün
  über 75 Dateien (`.luacheckrc` bekam `vim.system` in die `globals`-Liste).
  Commit: `b5184a1` (test: re-audit round 2 -- close drives.lua/health.lua gaps, pin two bugs).
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
  **Re-Audit (Runde 2, 2026-09-18):** Round 2s Auslassungsgründe für die komplette Telescope-
  Glue-Schicht (`ui.mappings`, `ui.cycle`, `ui.telescope-previewer`) beruhten auf zwei falschen
  Annahmen: telescope.nvim ist doch verfügbar (als lazy.nvim-Sibling lokal und als frischer
  Checkout in CI), und diese Module haben doch eigene Logik (`ui.mappings`s Delete-Mapping
  verzweigt real zwischen Einzel- und Multi-Selection, Confirm-nur-einmal-fürs-Batch,
  Fehler-Aggregation die "cancelled" ausfiltert). Zusätzlich hatte `core.tracker` (der komplette
  `CmdlineLeave`-Recorder) außer dem Load-Smoke-Test null Assertions. Neu abgedeckt: `core.tracker`
  über echte Tastatureingaben (`nvim_feedkeys(..., "x", ...)`, nicht `vim.cmd("normal! ...")` --
  Letzteres wirft am `v:errmsg`-Pfad vorbei, den dieses Modul für seine Fehlererfassung braucht,
  empirisch verifiziert), `ui.telescope-previewer`s komplettes Branch-Dispatch, `ui.mappings`'
  komplette `attach_mappings`-Factory, `ui.cycle`s Rotation, `picker_utils.open_picker`s echter
  Telescope- **und** fzf-Zweig (vorher beide weg-gemockt), `ui.risky_test` jetzt mit echten
  Notify-Assertions statt reinem Pcall-Smoke, `core.shell`s SHELL-unset-Probing-Zweig (HOME über
  `vim.uv.os_homedir` gefaked). **Bug gefunden und gefixt** (sechste Instanz derselben Familie
  nach diff/emojis/gopath/filetree): `health.lua`s letzte Zeile rief unbedingt
  `require("lib.nvim.bindings.usercmd.composer")` -- bei fehlendem lib.nvim brach
  `:checkhealth cmdlog` direkt nach der eigenen "lib.nvim fehlt"-Meldung ab. Fix: `pcall`-Guard
  analog zum Check darüber, plus ein Regressionstest der vor dem Fix nachweislich rot war.
  Windows-Verdachtsfälle geprüft und **nicht** als Bug befunden: `project_history.get_git_root()`
  hat nie Backslashes (vim.fs.find/dirname normalisieren schon); `core.tracker.setup()`s zweiter
  Aufruf verdoppelt nichts (lib.nvim's `autocmd.group(name, true)` cleared korrekt). Testlauf ohne
  Telescope/fzf-lua: 279 passed/0 failed/6 skipped (deckt sich mit Runde 2s Testumgebung); mit
  Telescope.nvim + fzf-lua als echte Siblings: **329 passed, 0 failed, 0 skipped** -- von mir
  gegen beide Konfigurationen persönlich nachgefahren und bestätigt. `luacheck lua` (40 Dateien)
  und `stylua --check lua TESTS` beide grün.
  Commit: `df6f716` (test: close the telescope-availability gap, tracker, and a health.lua crash).
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
  **Re-Audit (2026-09-18, 100%-Nachziehrunde):** hält fast vollständig — der Tabellen-Ansatz
  für die 11 Sprachdateien passt weiterhin auf jede der 11 (keine neue Sprache/kein neuer
  Adapter seit Runde 3), und alle fünf gezielt geprüften Bug-Familien (Windows-Pfade,
  ungeschützte FS-Aufrufe, Fehler-memoisierende Caches, health.lua-ruft-fehlende-Dependency,
  Autocmd-Teardown/doppeltes setup()) sind **nicht** vorhanden — jeweils einzeln verifiziert,
  nicht nur angenommen (z.B. `bindings/autocmds/init.lua` erzeugt seine einzige Augroup
  bewusst mit `clear=true` und einem erklärenden Kommentar genau gegen Doppel-Registrierung).
  Vier echte, kleine Lücken per Abgleich aller `M.<name>`-Exporte gegen jede Testreferenz
  gefunden und geschlossen: `utils/notify.lua` hatte gar keine eigene Spec;
  `registry.lua`s `enabled_languages()`/`registered_languages()` liefen nur transitiv über
  den Leerfall von `health.check()` mit; `wkddap.enabled_languages()` hatte dieselbe Lücke wie
  ihr bereits getesteter Zwilling; `languages/lua.lua`s dokumentierte, aber im Repo nie
  aufgerufene `M.launch_server()` war komplett ungetestet. Keine neuen Bugs.
  Testlauf: 199 → 209 grüne Checks, 30 → 31 Spec-Dateien, 0 Fails über zwei Wiederholungsläufe.
  `luacheck lua plugin TESTS` 0/0 über 74 Dateien, `stylua --check` grün.
  Commit: `9f207c0` (test: close round-3 re-audit gaps), direkt auf `main` gepusht.
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
  **Re-Audit (2026-09-18, 100%-Nachziehrunde):** beide früher gefixten Bugs verifiziert intakt
  (`format/enum_lines.lua`s Off-by-one, Commit `79893f9`; `format/text_width.lua`s
  Marker-Duplizierung + `wrap_words()`-Folgefehler, Commit `3c99c3c`). Zwei neue Bugs gefunden,
  beide gepinnt statt gefixt: `format/column_align.lua` berechnet die Zielspalte aus dem
  **Byte**-Offset, zielt aber auf eine **Display**-Spalte (`strdisplaywidth`) — ein Mehrbyte-
  Zeichen vor der Selektion lässt das Füllzeichen zu kurz werden und die Ausrichtung eine
  Spalte zu weit links landen (empirisch mit `"xä5"` verifiziert). Und `mark/init.lua`s
  `M.setup()` registriert seinen `BufDelete`/`BufWipeout`-Cleanup über eine String-Augroup
  ohne `clear = true` → ein zweites `setup()` verdoppelt den Autocmd (empirisch verifiziert:
  2 statt 1 Einträge) — dieselbe Familie wie der bereits gefixte pdfport.nvim-Bug, hier aber
  harmlos, weil `clear_marks()` idempotent ist. `util/map.lua`s lib.nvim-Erkennungs-Kosmetik
  (immer `false`, weil `require(...)` eine per `__call` aufrufbare Table statt einer
  `function` liefert) bleibt unverändert dokumentiert, kein Bug.
  Testlauf: 356 → 359 Assertion-Stellen, 11/11 Specs grün über 5 Wiederholungsläufe.
  `luacheck lua TESTS plugin` 0/0 über 59 Dateien, `stylua --check` grün. Kein `lua/`-Quelltext
  angefasst — nur Test-Dateien und README.
  Commit: `a11e95c` (test: re-audit round 5 -- confirm both fixes, pin two new bugs).
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
  **Re-Audit (Runde 6, 2026-09-18):** die vier wiederkehrenden Bug-Familien einzeln
  durchgeprüft — Augroups schon korrekt mit `clear = true` (Kommentar verweist auf die eigene
  Fix-Historie dazu), Byte/Spalten-Nutzung an jeder Cursor-Berührungsstelle konsistent,
  Windows-Pfadverdachtsfälle in `autocmds/sources.lua` und `lib.nvim.fs.collect_recursive`
  intern konsistent auch bei gemischten Trennzeichen. Keine neuen Dateien seit Runde 6, keine
  falsch angenommene Sibling-Verfügbarkeit (das Repo referenziert nirgends telescope/fzf-lua/
  snacks/plenary). **Ein echter Bug gefunden und sofort gefixt** (siebtes Repo dieser Familie,
  sechster Fix): `health.lua`s letzter Abschnitt rief `require(...).checkhealth("Debug")`
  ungeschützt auf, obwohl dieselbe Funktion wenige Zeilen darüber genau dieses Modul schon
  als potenziell fehlend meldet. Trivialer, unzweideutiger Fix (nur der bereits kaputte Pfad
  ändert sich), daher direkt gefixt statt gepinnt, passend zu diesem Repos eigener
  Fix-Historie für genau diese Bug-Klasse. Verifiziert in beide Richtungen (Fix zurückgesetzt →
  Test schlägt fehl; Fix wieder her → grün). Neue `health_spec.lua` pinnt die Regression.
  Testlauf: 15 → 16 Specs, alle grün über zwei Wiederholungsläufe von mir persönlich
  nachgefahren. `luacheck lua plugin TESTS` (53 Dateien) und `stylua --check` beide grün.
  Commit: `5bdd781`.
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
  **Re-Audit (Runde 7, 2026-09-18):** genau der Verbesserungsvorschlag aus Runde 7 wurde jetzt
  umgesetzt -- statt eines Lazy-Requires wurde `package.loaded["ui.kit"] = {}` vor dem ersten
  `require` gestubbt, die reine Logik aus `bindings/usrcmds.lua`, `float/rendering.lua` und
  `float/keymaps.lua` über `M._internal` exponiert (gleiche Konvention wie `treesitter.lua`
  seit Runde 7) und drei neue Specs geschrieben. CI braucht weiterhin keinen echten
  ui.nvim-Checkout. Alle anderen Auslassungsgründe (Bug-Familien a-d, Sibling-Verfügbarkeit,
  Dokumentationslücke bei `statusline_spec.lua` im README behoben) einzeln nachgeprüft, keine
  neuen Bugs gefunden -- nur ein Test-Artefakt (`resolve_cfile`s `findfile()`-Zweig liefert
  unter Windows native Backslash-Pfade, im Test durch Normalisierung vor dem Vergleich
  behoben, keine Quelländerung). 12 → 15 Specs, alle grün über von mir persönlich
  nachgefahrene Wiederholungsläufe. `luacheck lua TESTS` (41 Dateien) und `stylua --check`
  beide grün.
  Commit: `bef1939`.
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
  **Re-Audit (Runde 8, 2026-09-18):** zwei Auslassungsgründe waren inzwischen veraltet.
  `health.lua` war als "deklarativ, kein berechneter Wert" ausgeklammert -- stimmt nicht mehr:
  `check_hover()`s Vier-Zustands-Erkennung, `check_grammar()`s Client-Liste und
  `check_translate()`s Deepl-Key-Auflösung sind echte, berechnete Logik. Neue
  `health_spec.lua` treibt `M.check()` direkt mit gestubbten Collaborators. Und
  `spell/providers/cspell_server.lua` war komplett als "braucht echtes Node/cspell"
  ausgeklammert, obwohl seine externen Aufrufe ausschließlich über `language.util.job` und
  reines `vim.fn.jobstart/chansend/jobstop` laufen -- genauso stubbbar wie die anderen
  CLI-Provider. Neue `spell_providers_cspell_server_spec.lua` (Kandidatenpfade, `on_stdout`s
  Line-Buffering inklusive einer über zwei Chunks gesplitteten Zeile, Request/Reply-Matching,
  `cancel()`, `on_exit()`, der `VimLeavePre`-Kill-Handler) -- kein echtes Node/cspell beteiligt.
  **Ein Bug gefunden, gepinnt statt gefixt** (elftes Repo dieser Familie -- diesmal mit drei
  statt einem Aufruf): `health.lua`s `check_lib()` meldet einen fehlenden
  `bindings.usercmd.composer` korrekt als Warnung, aber `M.check()`s eigener Rest ruft
  danach dreimal ungeschützt direkt in dasselbe Modul -- `:checkhealth language` crasht
  komplett statt hinter der Warnung zu degradieren, und jede Sektion danach fällt
  stillschweigend weg. Gepinnt mit `BUG:`-Assertion in `health_spec.lua`, da der eigentliche
  Fix (drei Aufrufe schützen) eine Quelländerung ist, keine reine Test-Angelegenheit.
  Testlauf: 27 → 29 Specs, 0 Fails über zwei von mir persönlich nachgefahrene
  Wiederholungsläufe. `luacheck lua plugin TESTS` (83 Dateien) und `stylua --check` beide grün.
  Commit: `780aea6`.
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
  **Re-Audit (Runde 9, 2026-09-18):** kein Code seit Runde 9 geändert, alle Auslassungsgründe
  einzeln nachgeprüft und bestätigt (telescope.lua bleibt ausgeschlossen -- echte
  CI-Sibling-Lücke, nicht nur lokal fehlend). **Ein Bug gefunden und gefixt** (achtes Repo
  dieser Familie, siebter Fix): `health.lua`s letzte Zeile rief den Composer ungeschützt auf,
  obwohl derselbe Check ihn Zeilen darüber schon als fehlend meldet -- `pcall`-Guard analog
  zu jedem anderen optionalen Dependency-Check in derselben Datei, gepinnt mit neuer
  `health_spec.lua`. **Ein zweiter Bug gefunden, gepinnt statt gefixt**: `context.lua`s
  `gather()` prüft für sein Visual-Signal sowohl `mode() == "v"/"V"/CTRL-V` als auch die
  `'<`/`'>`-Marks -- die aber von Neovim erst beim VERLASSEN des Visual-Modus committet
  werden. Beide Bedingungen können nie gleichzeitig zutreffen: auf dem `:Open`-Kommandopfad
  (der Visual-Modus immer vorher verlässt) ist `signals.visual` deshalb immer `nil`; im
  einzigen Pfad, auf dem `mode()=="v"` während des Callbacks noch gilt, sind die Marks
  stattdessen ein Überbleibsel einer früheren, unabhängigen Selektion. Empirisch mit echten
  Cursor-/Keymap-Tests verifiziert, bevor gepinnt wurde. Der eigentliche Fix (`getpos("v")` +
  Cursor statt `'<`/`'>`) wäre eine bewusste Verhaltensänderung, kein Nebeneffekt einer
  Coverage-Runde -- daher `BUG:`-Assertion in `context_spec.lua`, nicht direkt geändert.
  Testlauf: 15 → 16 Specs, 16/16 grün über zwei von mir persönlich nachgefahrene
  Wiederholungsläufe. `luacheck lua plugin TESTS` (45 Dateien) und `stylua --check` beide grün.
  Commit: `553a445`.
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
  **Mittlerweile gefixt** (separate Session, Commit `7031f73`): `config.get()` nutzt jetzt
  `vim.deepcopy(state)`.
  **Re-Audit (Runde 10, 2026-09-18):** `pickers/fzf.lua`/`pickers/telescope.lua`s `run()`
  waren komplett ausgeklammert, weil beide angeblich ein echtes Backend brauchen -- stimmt
  nicht: nur die jeweils letzte Zeile (`fzf.fzf_exec(...)`/`picker:find()`) ist
  Backend-spezifisch, alles davor (Candidate/Entry-Maker-Bau, jeder
  `attach_mappings`/`actions`-Handler inkl. echtem `confirm_all` → `ui.kit.confirm`,
  Replace-and-reopen's rekursiver Re-Run, der `<C-f>`-Filter-Guard, Telescopes
  Previewer-Highlight-Mathematik, fzfs `to_fzf_key`-Notation) ist reine Plugin-Logik. Neue
  `TESTS/pickers_backends.lua` stubt genau diese eine Render-Zeile und deckt den Rest real ab
  -- 35 neue Assertionen. Beim Verifizieren (nicht erst beim Schreiben) aufgefallen: die
  Filter-Guard-Tests nahmen an, `pickers.nvim` sei nicht auf dem rtp -- stimmt bei einem
  Ad-hoc-`nvim -l`-Lauf, aber nicht bei der CI-Invocation (pickers.nvim als echter Sibling
  wie jede andere Suite), wo `pickers.refine` real auflöst und auf Neovims Standard-
  `vim.ui.select` trifft, das headless auf stdin ewig blockiert hätte. Gefixt durch
  gezieltes Blocken von `require("pickers.refine")` via `package.preload`, damit der
  "nicht installiert"-Pfad unabhängig vom rtp-Inhalt deterministisch getroffen wird -- hätte
  sonst CI zum Hängen gebracht.
  **Ein Bug gefunden, gepinnt statt gefixt** (zwölftes Repo dieser Familie): `health.check()`s
  `check_lib_nvim()` meldet+degradiert bereits korrekt bei fehlendem
  `lib.nvim.bindings.usercmd.composer`, aber `M.check()` requirt dasselbe Modul wenige Zeilen
  später erneut, ungeschützt, für den Composer-Preflight (`:Replace`/`:Surround`
  checkhealth) -- crasht auf derselben fehlenden Dependency statt zur bereits ausgegebenen
  Warnung zu degradieren. Reproduziert über einen echten `package.preload`-Stub (echter
  Require-Fehlschlag, keine gefakte Table).
  **Zwei veraltete Kommentare korrigiert**: `refine_wiring.lua`s Header behauptete, `run()`
  brauche ein geladenes Telescope/fzf ("manuell geprüft") -- oben widerlegt; `TESTS/README.md`s
  Auslassungsgrund für `pickers/utils.lua`s `setup_highlight_groups`/`ansi_snippets` nannte
  fehlende Backend-Verfügbarkeit, der echte Grund (laut Quellcode-Kommentar) ist schlicht
  kein Aufrufer mehr irgendwo im Repo.
  Testlauf: 9 → 10 CI-Suite-Dateien, 374 → 411 Assertionen, über zwei von mir persönlich
  nachgefahrene komplette Läufe stabil (alle 10 Dateien einzeln, exakt wie CI). `find lua
  plugin -name '*.lua' | xargs luacheck` (41 Dateien) und `stylua --check lua/` beide grün.
  Commit: `6153561`.
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
  **Mittlerweile gefixt** (separate Sitzung dieser Kampagne): die beiden gepinnten Bugs --
  `split_lines()`s `gmatch`-Zeilenverlust (jetzt `vim.split`) und `ensure_parent_dir()`s
  verschlucktes `mkdir`-Fehler (jetzt propagiert) -- Commit `6a85943`; dabei zusätzlich ein
  E937 beim Dashboard-`BufWipeout`-Teardown gefunden und gefixt (`ui_state.forget_buffer()`
  statt eines redundanten zweiten Delete) -- Commit `dfdb1d8`. Danach, in einer weiteren
  separaten Sitzung: ein wörtliches `".."`-Pfadsegment beim Bau der Tracking-Datei-Pfade in
  `fetcher.lua`/`retention.lua` gefixt -- Commit `26d34b2`.
  **Re-Audit (Runde 11, 2026-09-18):** alle drei Fix-Commits oben verifiziert, ihre
  Regressionstests bestätigt vorhanden; die beiden ersten waren in `TESTS/README.md` schon
  korrekt vermerkt, der `26d34b2`-Fix war es nicht -- jetzt nachgetragen. Die vier
  wiederkehrenden Bug-Familien einzeln geprüft: alle `health.lua`-Zweige mit fehlender
  Dependency sind bereits vor dem Zugriff gegated; das eine Augroup
  (`bindings/autocmds.lua`) passt `clear = true` durch, lib.nvim's Wrapper hält sich daran;
  keine Drive-Letter/Doppelpunkt-Pfadparsung im ganzen Repo. **Zwei echte Lücken gefunden und
  geschlossen** (6 neue Tests in `dashboard_render_spec.lua`, 1 in `statusline_spec.lua`):
  `dashboard/highlights.lua` hatte echte, nie geprüfte Verzweigungen (Clones/Views-Label-vs-
  Value-Split, Period-Zeilen-Sparkline-vs-Label-Split, Flat-Trend-Färbung, Eintrags-
  Trennmarke); `statusline.lua`s TTL-Cache-Hit-Pfad wurde nie erreicht, weil `before_each`/
  `after_each` jeweils `invalidate()` rufen, sodass jeder bisherige Test nur einen kalten
  Cache sah. **Ein Bug gefunden und sofort gefixt** (test-only, kein Produktionsrisiko):
  `retention_spec.lua`s `today_midnight()` fütterte UTC-Kalenderfelder (`os.date("!*t")`) in
  `os.time(table)`, das sein Argument aber immer als LOKALE Zeit interpretiert -- das UTC-
  Offset wurde dadurch lautlos wieder addiert, "heute" driftete in den ersten Stunden des
  UTC-Tages einen Tag zurück (live reproduziert: bei 00:51 UTC schlug der Cutoff-Test
  deterministisch fehl, 12 statt erwarteter 11 gelöschter Dateien). Gefixt auf direktes
  `os.time()`, passend zu `retention.lua`s eigenem, korrektem `cutoff_date()`.
  **Ein Bug gefunden, gepinnt statt gefixt** (echter Produktionsbug, kein trivialer Fix):
  `dashboard/render.lua`s `fit_width()` polstert/kürzt die Status-Header-Zeile nach
  Byte-Länge, nicht nach Display-Breite. Unsichtbar für die eingebauten ASCII-Zeiträume,
  aber `dashboard.time_range` akzeptiert über die Config jeden String ohne Validierung --
  ein Mehrbyte-Wert würde die feste Header-Breite lautlos brechen. Gepinnt als
  `BUG:`-Regressionstest.
  Testlauf: 492 → 499 Assertionen (491 davon vorher tatsächlich grün, 1 im betroffenen
  UTC-Zeitfenster reproduzierbar rot -- s.o.), alle 499 grün über zwei von mir persönlich
  nachgefahrene Wiederholungsläufe. `stylua --check .` und `luacheck .` (69 Dateien) beide
  grün.
  Commit: `479fd9c`.
- [x] **insights.nvim** — fertig (Runde 12). Eigener framework-freier Harness
  (`TESTS/harness.lua`, aggregiert über eine explizite Liste in `TESTS/run.lua`)
  beibehalten, kein plenary. Anders als bei open.nvim/github_stats.nvim ist hier **nur
  `lib.nvim` CI-Sibling** — `ui.nvim` wird zwar von zwei Modulen wirklich gebraucht
  (`ui/scratch.lua` requirt `ui.kit` beim Laden, `devserver` lazy für den Prompt), ist in
  CI aber nicht ausgecheckt; beide sind daher gegen ein `ui.kit`-Double abgedeckt, das
  *vor* dem `require` des Testobjekts in `package.loaded` liegt. Die Suite läuft damit
  identisch mit und ohne installiertes ui.nvim.
  24 neue Spec-Dateien, 2 bestehende erweitert:
  **imports** — `imports_langs_contract_spec.lua` (der gemeinsame `ImportLang`-Vertrag
  einmal tabellengetrieben über alle sechs Scanner: deklarierte Metadaten, Degenerat-
  Eingaben, Zeilennummern, `is_external`, und dass nur Lua einen Tree-sitter-Pfad
  beansprucht — plus der Test, dass keine zwei Sprachen dieselbe Dateiendung
  beanspruchen, was sonst jede Zählung im Report verdoppeln würde),
  `imports_langs_detail_spec.lua` (nur die echten Abweichungen: Pythons mehrzeilige
  Klammerform + Kommentar-Stripping, JS' fünf Scan-Pässe inkl. `type`-Keyword und der
  4a/4b-Dedup, Gos `go.mod`-Lookup, Rusts verschachtelte Brace-Expansion, C's
  `external`-Entscheidung schon zur Scanzeit) — dasselbe Muster wie bei dap.nvims 11
  Sprachdateien in Runde 3, statt sechs Beinahe-Kopien;
  `imports_ts_requires_spec.lua`, `imports_resolve_spec.lua`,
  `imports_definition_spec.lua`, `imports_graph_spec.lua`, `imports_report_spec.lua`
  (`insights.imports` end-to-end gegen einen Fixture-Baum: Scan, Filtersprache mit
  Sprach-IDs/Aliassen/Gruppen/Präfix-Grenzen, alle vier Reports, beide Writer,
  `run`/`run_reverse`/`run_unused`).
  **symbols** — `symbols_patterns_parser_spec.lua`, `scan_rg_spec.lua`,
  `scan_cache_spec.lua`, `symbols_ts_lua_spec.lua`, `symbols_index_spec.lua`,
  `symbols_open_spec.lua`.
  **metrics/smells** — `metrics_analyzer_spec.lua`, `metrics_report_spec.lua`,
  `metrics_init_spec.lua`, `smells_run_spec.lua`.
  **restliche Features** — `unimported_spec.lua`, `conflicts_spec.lua`,
  `compress_tree_spec.lua`, `devserver_extra_spec.lua`, `ui_fileinfo_spec.lua`.
  **Verdrahtung** — `bindings_spec.lua` (Keymaps echt über lib.nvims Registry gebunden,
  Autocmd-Gruppen, `:Insights`-Completion an jeder Position plus ein Dispatch-Check pro
  Subkommando und pro Feature-Gate), `health_init_spec.lua` (`:checkhealth insights`
  gegen aufgezeichnete `vim.health`-Aufrufe, `setup()` end-to-end inkl. des
  „ohne hover.nvim und ohne lib.nvim.deps"-Pfads, sowie die komplette öffentliche
  Fassade). Erweitert: `config_spec.lua` (um `expand_paths`, inkl. des Sonderfalls
  `compress.outdir == ""`), `TESTS/run.lua` (nach Schichten neu sortiert).
  **Kein einziger Subprozess, kein Netz:** `rg`, `git`, `dot`, `tar`/`zip`/PowerShell und
  die Kill-Tools sind je an genau einer Naht gekappt, die vor dem `require` ersetzt wird
  (`insights.scan.rg`, `insights.util.platform`, `lib.nvim.ui.list` +
  `lib.nvim.cross.executable`, bzw. `vim.system`/`vim.fn.executable` direkt). Einzige
  bewusste Ausnahme: die beiden devserver-Suiten starten ein echtes
  `nvim --headless -c qa!`, weil `track()` den Channel zu einer OS-PID auflöst und eine
  erfundene Channel-Nummer gar nichts aufzeichnet. Tree-sitter wird **nicht** gestubbt,
  sondern gegen die mitgelieferte Grammatik gefahren.
  **Vier echte Bugs gefunden, bewusst nur gepinnt statt gefixt** (alle vier sind
  sichtbare Verhaltensänderungen; je `BUG:`-Kommentar an der Assertion):
  1. `symbols/parser.lua`s `parse_vimgrep_line` splittet an den ersten drei Doppelpunkten
     — der Doppelpunkt des Laufwerksbuchstabens frisst das `filename`-Feld. `rg_index.build`
     übergibt `vim.fn.getcwd()` als Suchwurzel, unter Windows also `E:\repos\…`, wodurch
     **jede** von rg gedruckte Zeile als unparsebar verworfen wird: `:Insights symbols`
     findet auf Windows gar nichts, und zwar lautlos (die Fehlerliste wird nur gezählt,
     nicht angezeigt). Empirisch verifiziert, nicht hergeleitet.
  2. `symbols/ts_lua.lua`s `assignment_statement`-Zweig ist toter Code: er liest Ziel und
     Wert über `node:field("left")`/`node:field("right")`, tree-sitter-lua exponiert
     `variable_list`/`expression_list` aber als *typisierte Kinder*, nicht als benannte
     Felder. Mit `symbols.use_treesitter_for_lua = true` liefert ein Modul im Stil
     `M.foo = function() … end` also überhaupt keine Symbole, während dasselbe Modul als
     `function M.foo() … end` alle liefert.
  3. `symbols/ts_lua_tables.lua` hat denselben Defekt an eigener Stelle
     (`par:field("variable_list")[1]` ist immer nil) → ein Feld in
     `local cfg = { inner = {} }` heißt im Picker `inner` statt `cfg.inner`.
     Bemerkenswert: `imports/ts_requires.lua` **und** `imports/definition.lua` tragen
     beide schon einen `child_of_type`-Helfer mit einem Kommentar, der genau das erklärt
     — das Repo weiß es also, diese zwei Aufrufstellen nicht.
  4. `tree/init.lua`s Glob→Regex-Übersetzung escapt Metazeichen mit Luas `%` statt mit dem
     `\`, das die .NET-Regex-Engine hinter `-match` versteht. Aus dem Default `*/.git/*`
     wird `.*[\/]%.git[\/].*` — ein Muster, das ein literales `%` verlangt und damit nie
     matcht. Unter Windows enthalten `:Insights tree` und `:Insights count` deshalb das
     komplette `.git/`. `node_modules` (ohne Metazeichen) übersteht die Übersetzung und
     funktioniert; der Unix-Zweig reicht die Globs unverändert an `find -not -path` und
     ist nicht betroffen.
  **Zwei weitere Eigenheiten als dokumentiertes Verhalten gepinnt, nicht als Bug:**
  `langs/go.lua` meldet jeden Eintrag eines gruppierten `import ( … )`-Blocks eine Zeile
  zu früh (`()` im gmatch-Muster erfasst den Matchbeginn, die Rechnung ist aber
  `e + off - 1`); die Einzeilenform ist korrekt. Und `ui/scratch.lua`s Follow-Key teilt
  den Doppelpunkt-blinden Fleck aus (1), fällt aber im Imports-Report nicht auf, weil
  dessen Pfade relativ sind.
  Bewusst ausgelassen: `ui/fzf.lua`/`ui/telescope.lua` jenseits ihres
  „Backend fehlt"-Guards (je ein Aufruf in einen Picker, der weder Dependency noch
  CI-Checkout ist — die Entry-Form, die sie bekommen, ist dort gepinnt, wo sie gebaut
  wird), `config/@types/init.lua` (reine `---@meta`-Annotationen), `plugin/insights.lua`
  (dreizeiliger `vim.g.loaded_insights`-Guard ohne Verzweigung), `ts_lua*.scan_cwd`
  (läuft über jede `.lua`-Datei des cwd und lädt sie in einen Buffer — misst die Maschine,
  nicht den Scanner; der Per-Buffer-Scan darin ist vollständig abgedeckt, die
  Walk-und-Ignore-Logik zusätzlich über `metrics.analyzer.list_files`), sowie die echten
  Spawns selbst (Graphviz, pandoc, git, tar, rg, `kill_tree` gegen einen realen
  Prozessbaum — jeder Zweig *drumherum* ist abgedeckt).
  Testlauf: 7 → 31 Spec-Dateien, 112 → 1590 ausgeführte Assertions, 0 Fails, über 3
  Wiederholungsläufe stabil (Exit 0). `luacheck lua plugin TESTS` 0 Warnings/Errors über
  83 Dateien und `stylua --check lua plugin TESTS` (genau die CI-Befehle; `TESTS/` ist
  hier *Teil* beider Gates) beide grün. `TESTS/README.md` neu geschrieben: Bootstrap
  inkl. der ui.nvim-Erklärung, ein Abschnitt „No subprocesses, no network" mit einer
  Tabelle Spawn → Naht → Spec, das Spec-Register nach Clustern, die
  Tree-sitter-Begründung (eine Query mit veralteten Knotennamen scheitert *still*), die
  vier gepinnten Bugs und die bewussten Auslassungen. Zusätzlich `.gitignore` um
  `TESTS/.fixture-*/` ergänzt, damit ein abgebrochener Lauf kein Fixture-Verzeichnis
  versehentlich stagen kann. Top-Level-`README.md` hat keinen Test-/Coverage-Abschnitt,
  daher unangetastet gelassen.
  Commit: `1be0f7a` (test: cover imports, symbols, metrics, the feature modules and the
  wiring), direkt auf `main` gepusht und per `git merge-base --is-ancestor HEAD
  origin/main` verifiziert.
  **Mittlerweile gefixt** (separate Sitzungen dieser Kampagne): alle vier Pins. Bug 1 und
  das gleichgeartete `ui/scratch.lua`-Follow-Key über Commit `6031069` (Doppelpunkt-Scan
  beginnt jetzt hinter einem `^%a:[/\\]`-Laufwerksbuchstaben-Präfix); Bug 2, 3 und 4 über
  Commit `dcbe57a` (neuer `child_of_type()`-Helfer in `ts_lua.lua`/`ts_lua_tables.lua`
  statt der nicht existierenden `field("left")`/`field("right")`; `tree/init.lua`s
  Glob→Regex-Escaping jetzt `\` statt `%`).
  **Re-Audit (Runde 12, 2026-09-18):** alle vier Fixes bestätigt vorhanden und mit
  Regressionstests belegt. Die vier Bug-Familien einzeln geprüft: Augroups bereits
  idempotent mit eigenem Doppel-Setup-Test; Byte/Zeichen-Position in
  `imports/definition.lua`, `imports/langs/util.lua` und allen `ts_lua*`/
  `symbols/parser.lua`-Stellen erneut durchgesehen, weiterhin korrekt. **Drei neue,
  eigenständige Bugs gefunden und sofort gefixt** (jeweils mit Regressionstest belegt,
  der gegen den zurückgesetzten Code nachweislich fehlschlägt):
  1. **Vierzehntes Repo der Health-Familie**: `health.lua`s `M.check()` schließt mit einem
     ungeschützten `require("lib.nvim.bindings.usercmd.composer").checkhealth(...)` --
     obwohl `check_lib()` genau diese Dependency Zeilen darüber schon als fehlend meldet.
     `pcall`-Guard ergänzt, Test in `health_init_spec.lua`.
  2. **Derselbe Doppelpunkt-Blindpunkt wie Bug 1 aus Runde 12, aber an einer vierten
     Stelle**: `ui/fzf.lua`s Default-Action parst `path:line` über
     `sel[1]:match("^([^:]+):(%d+)")` -- genau der Windows-Laufwerksbuchstaben-Blindpunkt,
     der in `symbols/parser.lua` und `ui/scratch.lua` schon gefixt wurde, hier aber
     übersehen, weil jede bisherige Spec das gesamte `insights.ui.fzf`-Modul wegstubt statt
     seinen Körper auszuführen. Neue `TESTS/ui_fzf_spec.lua` treibt das echte Modul zum
     ersten Mal.
  3. **Wieder Windows-Pfadtrenner, an drei Stellen gleichzeitig**: `scan_cwd()`s
     Ignore-Liste (`.git/`, `node_modules/`, …) in `ts_lua.lua`, `ts_lua_tables.lua` und
     `ts_lua_strings.lua` matcht mit `/`-hartkodierten Lua-Patterns gegen
     `vim.fn.globpath`s Ausgabe im nativen Trennzeichen (Backslash unter Windows) --
     schließt unter Windows also lautlos gar nichts aus. `TESTS/README.md` hatte
     behauptet, das sei "dieselbe Logik" wie `metrics.analyzer.list_files`, das aber schon
     immer zuerst auf `/` normalisiert -- die Behauptung war veraltet. In allen drei
     Dateien identisch gefixt, gegen einen echten kleinen Fixture-Baum in
     `symbols_ts_lua_spec.lua` gepinnt.
  Nebenbei eine veraltete "Quirk"-Notiz in `TESTS/README.md` entfernt, die behauptete,
  `ui/scratch.lua`s Follow-Key könne einem absoluten Windows-Pfad weiterhin nicht folgen --
  kann es seit Bug 1 dieser Runde.
  Testlauf: 31 → 32 Specs, 1342 → 1362 Assertion-Aufrufstellen, über zwei von mir
  persönlich nachgefahrene Wiederholungsläufe stabil. `luacheck lua TESTS` (83 Dateien)
  und `stylua --check lua TESTS` beide grün.
  Commit: `6bbab32`.
- [x] **sessions.nvim** — fertig (Runde 13, erste Runde der Drei-Agenten-Phase). Eigener
  framework-freier Harness (`TESTS/harness.lua` + `TESTS/run.lua` mit expliziter Spec-Liste)
  beibehalten, keine Migration. 7 → 17 Spec-Dateien, 77 → 487 statische Assertion-Stellen,
  17/17 grün über 5 Laufe, Exit 0 — auch CI-exakt ohne `LIB_NVIM_PATH` über die
  Sibling-Auflösung. `luacheck lua TESTS` 0/0 über 36 Dateien, `stylua --check lua TESTS`
  grün (beide Gates schließen `TESTS/` ein). Kein `lua/`-Quelltext angefasst: reine Test-
  und Doku-Arbeit.
  Neu: `git_spec.lua` (`current_branch`/`project_root` inkl. des prozessfreien
  `.git/HEAD`-Fallbacks gegen handgeschriebene Fixtures — normales `.git`, detached HEAD,
  Müll-HEAD, Worktree-`.git`-*Datei* mit absolutem und relativem `gitdir:`, Upward-Walk),
  `state_spec.lua`, `layout_spec.lua`, `core_spec.lua` (save/load/list/delete/rename,
  Blacklist-Wipe über alle drei Kriterien, beide Namensauflösungs-Regeln, Hooks inkl.
  werfendem Hook, `relative_paths`, Tab-Sessions, hidden-modified-Buffer, unsourcebare
  Session-Datei), `picker_spec.lua` (beide Backends über `package.loaded`-Stubs bis zur
  Rendering-Grenze), `health_spec.lua`, `keymaps_spec.lua`, `usercmds_spec.lua` (jedes
  `:Session`-Subkommando über echte `:`-Aufrufe inkl. Completion, `toggle-track` in allen
  fünf Zweigen), `autocmds_spec.lua` (VimEnter/VimLeavePre/Dirty-Events per
  `nvim_exec_autocmds`; `autoload = "ask"` einmal über ui.kit, einmal über den
  handgerollten Float mit echten Tastendrücken), `init_spec.lua`; `statusline_spec.lua`
  erweitert. Der Harness bekam `H.stub()` (Modul ersetzen *oder* per `package.preload`-Fehler
  als "nicht installiert" erscheinen lassen) und `H.fresh()`; Fixtures hängen jetzt an
  `TESTS/` statt an `getcwd()`, weil `git_spec` das Arbeitsverzeichnis bewegt.
  **Zwei Bugs gefunden, beide gepinnt statt gefixt** (je ein Wechsel von "wirft" zu
  "meldet", also sichtbare Verhaltensänderung): `core.save`/`core.save_tab` kapseln
  `:mksession` in `pcall`, nicht aber das `ensure_dir()` darüber — ein nicht anlegbarer
  `cfg.root` entkommt als rohes `E739`, auch aus dem `VimLeavePre`-Autosave heraus;
  `layout.restore` prüft nur `type(tree) ~= "table"` und lässt `{}`/`[]` durch, worauf
  `build()` an `attempt to get length of local 'children' (a nil value)` stirbt statt das
  eine Zeile vorher versprochene "corrupt or missing layout file" zu melden.
  Zusätzlich als Verhalten gepinnt (kein Defekt): `core.rename` zieht `.state.json` nicht
  mit, zwischen Umbenennen und nächstem Save fallen `:Session load` und der Autoload auf
  `default_name` zurück.
  Bewusst ausgelassen: `@types/init.lua` (reine Annotationen), `config/DEFAULTS.lua`
  (deklarativ; die OS-abhängigen Blacklist-Pfade sind über `config_spec` abgedeckt), die
  Rendering-Hälfte beider Picker-Backends (snacks.nvim/telescope.nvim sind weder Dependency
  noch CI-Checkout), `health.lua`s abschließender `composer.checkhealth("Session")`-Aufruf
  (berichtet über lib.nvims eigene Registry, die lib.nvim dort testet).
  `TESTS/README.md` deutlich ausgebaut (Spec-Tabelle inkl. des bisher fehlenden
  `buforder_spec`, Abschnitt "No network, no subprocesses" mit Nahtstellen-Tabelle,
  Laufreihenfolge, neue Harness-Helfer, Coverage-Abschnitt, die zwei Pins);
  `docs/CONTRIBUTING.md`s Test-Absatz beschrieb noch den alten Umfang — aktualisiert.
  Commit: `0034df3` (test: cover core, git, state, layout, picker, health and the bindings
  layer), direkt auf `main` gepusht.
  **Mittlerweile gefixt** (separate Sitzung, Commit `9005c46`): beide Pins. `ensure_dir()`
  meldet einen fehlgeschlagenen `mkdir` jetzt statt rohem `E739`, `layout.restore` validiert
  einen dekodierten Baum jetzt statt `{}`/`[]` durchzulassen.
  **Re-Audit (Runde 13, 2026-09-18):** beide Fixes bestätigt vorhanden. Alle vier
  Bug-Familien einzeln geprüft: kein weiteres Byte/Spalten-Problem (keine Text-Positions-
  Logik im ganzen Plugin); Windows-Drive-Colon in `git.lua`s Worktree-`.git`-Datei-Parser
  bereits korrekt gegated (`^%a:`-Check vor dem `gitdir:`-Split); `bindings/autocmds/init.lua`
  korrekt idempotent (`autocmd.group(name, true)`, bereits mit eigenem Doppel-`enable()`-Test
  belegt). **Ein Bug gefunden und sofort gefixt** (dreizehntes Repo dieser Familie): der
  abschließende `composer.checkhealth("Session")`-Aufruf lief unbedingt, obwohl der Preflight
  drei Zeilen darüber (`lib_composer_ok`) schon weiß, ob der `require` scheitern wird -- bei
  fehlendem lib.nvim crashte `:checkhealth sessions` mit "loop or previous error loading
  module" statt zur bereits angezeigten Fehlermeldung zu degradieren. Crash vor dem Fix
  reproduziert, dann mit `if lib_composer_ok then` gegated, Regressionstest in
  `health_spec.lua` ergänzt. **Eine echte Lücke gefunden und geschlossen**:
  `portable.lua`s `boundary_replace` hat laut eigenem Docstring zwei echte Verzweigungen
  (Sibling-Präfix-Grenzcheck, damit `E:/repos/ui.nvim` nicht `E:/repos/ui.nvim-backup`
  korrumpiert; Mid-Needle-Overlap-Resume nach einem abgelehnten Match) -- keine davon hatte
  je eine Assertion. Beide Verzweigungen einzeln durch gezieltes Wiedereinführen des jeweiligen
  Fehlers verifiziert (Test schlägt fehl → Quellcode zurückgesetzt → Test grün), bevor die
  Specs final standen. Nebenbei ein Test-Tippfehler in `config_spec.lua` gefixt (`"\f.txt"`
  wurde von Luas eigenem Escaping zu einem Form-Feed-Byte, nicht zum beabsichtigten
  literalen Backslash -- die Assertion war aus dem falschen Grund grün).
  Testlauf: 17 Specs, 498 → 504 Assertionen, über zwei von mir persönlich nachgefahrene
  Wiederholungsläufe stabil. `luacheck lua TESTS` (36 Dateien) und `stylua --check lua TESTS`
  beide grün.
  Commit: `12a4fb6`.
- [x] **pdfport.nvim** — fertig (Runde 14). Eigener framework-freier Harness beibehalten.
  10 → 21 Spec-Dateien, 192 → 1059 Assertion-Aufrufstellen, 21/21 grün über fünf
  Wiederholungsläufe (Exit 0, `PDFPORT_TESTS_OK`), ausgeführt mit exakt dem CI-Kommando.
  `stylua --check lua plugin TESTS` grün, `luacheck lua plugin TESTS` 0/0 über 75 Dateien.
  Kernpunkt der Runde: **kein Producer und kein Extraktions-Tool wird ausgeführt.** Jeder
  `spawn_capture`/`vim.system`/`uv.spawn`-Pfad ist an einer Naht gekappt, die *vor* dem
  `require` des Testobjekts in `package.loaded` liegt — dafür kam `H.with_modules` in den
  Harness, weil die Module ihre Deps beim Laden an Upvalues binden und ein nachträglicher
  Feld-Patch zu spät käme. Assertiert wird die **argv, die gespawnt worden wäre**, plus pro
  Producer die vier Callback-Zweige (sauberer Exit / Exit≠0 mit stderr / Timeout / Binary
  fehlt).
  Neu: `producer_argv_spec` (alle neun Producer inkl. qpdfs `--`-Terminator, chromiums
  `file:///`-URL, soffices Scratch-Dir+Rename, Ghostscripts `gs`/`gswin64c`/`gswin32c`-
  Auflösung, pandocs Engine-Kette), `backend_argv_spec` (pdftotext, pdfplumber/docling inkl.
  `%q`-Quoting des generierten Python-Scripts, marker, tesseract), `config_util_spec`,
  `tmpfile_cache_spec`, `dispatcher_spec`, `picker_batch_spec`, `renderers_spec`,
  `bindings_spec`, `integrations_spec`, `public_api_spec` (inkl. des github_stats.nvim-
  Vertrags in genau der aufgerufenen Form: `can_create("markdown") == true` als
  Boolean-Vergleich, `create{...}` → `result.status`/`result.error`), `health_spec`
  (`:checkhealth` gegen ein wählbares Tool-Set: volle Maschine, nackte Maschine, pandoc
  ohne Engine, curl-Gate vor den API-Keys).
  **Drei Bugs gefunden, alle gepinnt statt gefixt:** `backends/tesseract.lua`s
  `finish_error()` meldet `page_idx - 1`, obwohl `process_next()` den Index bereits
  weitergezählt hat — ein Fehlschlag auf Seite 1 meldet "1 Seite verarbeitet"; der
  formgleiche `fail()` in `backends/ollama.lua` rechnet mit `page_idx - 2` richtig, beide
  stammen erkennbar aus derselben Vorlage. `bindings/autocmds.lua` verspricht in Modul-Doc
  und Kommentar, die eigene Augroup zu leeren und neu zu bauen, tut es aber nicht, weil
  `lib.nvim`s `autocmd.create` einen String-`group` über `M.group(name)` **ohne** das
  `clear`-Argument auflöst — ein zweites `setup()` mit `auto_open_on_read` hinterlässt zwei
  `BufReadCmd *.pdf`-Autocmds und der Mode-Picker geht doppelt auf. Wichtig für andere
  Repos: das ist **kein lib.nvim-Bug** — `create()` darf die Gruppe nicht leeren, sonst
  löschte jedes zweite `create` das erste; falsch ist die Idempotenz-Annahme des Aufrufers.
  Drittens memoisieren `integrations/fzf.lua` und `integrations/telescope.lua` per Pfad,
  **bevor** `result.status` geprüft wird — eine einmal gescheiterte Extraktion wird für die
  ganze Session als Fehlertext wiedergespielt, und fzfs Cache ist modulweit, ein frischer
  Picker leert ihn also nicht; `util/cache.lua` verweigert genau das ausdrücklich.
  Zwei Nicht-Bugs notiert: `platform.reset_cache()` leert nur den eigenen `pymod:`-Cache,
  nicht die Memoisierung in `lib.nvim.core`; `integrations/telescope.lua`s `filetype_hook`
  schreibt in den Preview-Buffer, bevor es dessen Gültigkeit prüft (fzf guardet davor).
  Bewusst ausgelassen: `@types/init.lua`, `plugin/pdfport.lua` (Load-Guard), die eigentliche
  PDF-Produktion/-Extraktion (ohne Tools plus Dokumentenkorpus nicht prüfbar), der
  erfolgreiche poppler-Lauf in `rasterize.render_page`, die Bildanzeige in
  `renderers/terminal` (was chafa/kitty/imgcat in ein pty malen, sieht eine Headless-Spec
  nicht), das Picker-Plumbing von telescope/fzf, der echte HTTP-Request in
  claude/gemini/ollama (Request-Shape und Antwortverarbeitung sind über ein gefaktes
  `ai.nvim` abgedeckt), `health.check()` ohne lib.nvim (praktisch unerreichbar, da
  `bindings/usrcmds.lua` den Composer auf Modulebene requirt).
  Ehrlich dokumentiert statt versteckt: zwei Subprozess-Reste bleiben — `vim.fn.executable()`-
  Probes dort, wo das echte `pdfport.platform` läuft, und der Registry-`available()`-Walk,
  der bei den beiden Python-Backends einmalig `python -c "import ..."` ausführt. Die bisherige
  README-Behauptung "Nothing here shells out to … Python …" wurde entsprechend korrigiert.
  Commit: `3c9273a` (test: cover producer/backend argv, dispatcher, renderers, bindings and
  the public API), direkt auf `main` gepusht.
  **Re-Audit (Runde 14, 2026-09-18):** alle drei gepinnten Bugs explizit nachgeprüft und
  bestätigt weiterhin gepinnt, Quellcode unverändert -- keiner still gefixt, keiner
  veraltet. Die vier Bug-Familien einzeln durchgeprüft: jeder "Dependency fehlt"-Zweig in
  `health.lua` ist korrekt gegated; der eine ungeschützte Composer-Aufruf am Ende von
  `check()` ist die dokumentierte, unvermeidbare Ausnahme, da `bindings/usrcmds.lua` den
  Composer schon beim Modul-Laden requirt -- pdfport kann ohne ihn gar nicht laden. Kein
  weiteres Augroup mit derselben Ursache wie `autocmds.lua`s bekannter Bug. Keine Byte/
  Zeichen-Verwechslung (nur Ganzzahl-Mathematik bei Seiten/Crop, kein Substring-Zugriff auf
  extrahierten Text). Keine Windows-Separator-Bugs (`netrw.lua`/`integrations/init.lua`
  prüfen beide Trenner korrekt, `oil.lua`s Konkatenation ist richtig und dokumentiert
  warum, `chromium.lua`s `file://`-URL-Bau behandelt Laufwerksbuchstaben korrekt).
  **Eine echte Lücke gefunden und geschlossen**: `integrations/telescope.lua`s
  `M.previewer()` hatte null Coverage -- der Auslassungsgrund ("requirt hart ihr
  Picker-Plugin") stimmte für das echte `telescope.nvim`, war aber veraltet als Grund, die
  reine Logik nicht zu testen: `require("telescope.previewers")` passiert innerhalb des
  Funktionskörpers und lässt sich genauso über `package.loaded` faken wie `neo-tree`/
  `nvim-tree`/`oil` es an anderer Stelle in dieser Suite schon tun. Neuer Spec-Block deckt
  Titel, Pfadauflösung (`.path`/`.filename`-Fallback), den Extraktions-Request und --
  bisher nur als Kommentar behauptet -- Telescopes eigene Kopie von Bug 3 (Cache-vor-
  Status-Check), jetzt mit echten `BUG:`-Assertionen gepinnt statt nur erwähnt. Dabei eine
  ungenaue README-Gruppierung korrigiert: `fzf.lua` requirt `fzf-lua` gar nicht hart, seine
  Coverage war schon vollständig -- nur Telescopes Seite hatte die Lücke.
  Testlauf: 21 Spec-Dateien, 1048 → 1057 Assertion-Aufrufstellen, über drei
  Wiederholungsläufe stabil (zwei davon von mir persönlich nachgefahren). `luacheck lua
  plugin TESTS` (75 Dateien) und `stylua --check lua plugin TESTS` beide grün.
  Commit: `4bb13eb`.
- [x] **emojis.nvim** — fertig (Runde 15). Eigener framework-freier Harness beibehalten,
  Specs weiter über die explizite Liste in `run.lua`. 9 → 22 Spec-Dateien, 261 → 773
  Assertions, 0 Fails über drei Wiederholungsläufe (Exit 0, `EMOJIS_TESTS_OK`).
  `stylua --check lua TESTS` grün, `luacheck lua TESTS` 0/0 über 47 Dateien. Hier sind
  `lib.nvim` **und** `ui.nvim` CI-Siblings, `ui.kit` ist also echt verfügbar statt gestubbt.
  13 neue Dateien: `config_merge_spec`, `insert_spec` (byte-genaues Einfügen zwischen
  Multibyte-Nachbarn), `nav_spec`, `util_lib_spec` (beide Pfade jedes lib.nvim-Accessors),
  `actions_spec`, `commands_dispatch_spec` (Routing, NO_SCOPE-Bypass, Range-Präzedenz,
  Completion an jeder Position), `search_run_spec`, `picker_engine_spec` (Engine-Matrix
  gegen telescope/fzf-lua-Doubles), `frecency_spec`, `overlay_modes_spec` (Grid über die
  eigenen Keymaps gefahren), `api_spec`, `bindings_spec`, `health_spec`; die vier
  bestehenden Pure-Layer-Specs um Stray-VS16, dangling ZWJ, Regional-Indicator-Paarung und
  `encode`-Round-Trips erweitert. Der Harness bekam einen Assertion-Zähler und
  `H.notices(fn)`, weil mehrere Zweige *nur* melden.
  **Fünf Bugs gefunden, alle gepinnt:** (1) der Visual-Zweig in `init.lua` liest die
  Marken, die Neovim erst beim Verlassen des Bereichs setzt, während das Preset `toggle`
  in `mode = { "n", "x" }` bindet — die erste Selektion bricht mit "no previous visual
  selection" ab, danach wird still die *vorherige* Selektion umgeschaltet; das
  dokumentierte Feature funktioniert nie korrekt, die Range-Form des Ex-Kommandos dagegen
  schon. (2) `overlay/frecency.lua`s `save()` ruft `mkdir` außerhalb jedes pcall → rohes
  `E739` aus *jeder* Emoji-Einfügung, obwohl der Moduldoc genau das ausschließt (bekannte
  Familie, vgl. Runde 11/13). (3) `search.lua`s gieriger `file:line:`-Split verliert gegen
  das eigene Shortcode-Vokabular (`:100:` für das Hundert-Punkte-Emoji) → Müll-Quickfix,
  für `clear`/`replace` `E484` auf einen erfundenen Pfad; Windows-Laufwerksbuchstaben sind
  hier zufällig nicht betroffen. (4) `RG_PATTERN` deckt nur drei der vier
  `core.patterns.RANGES` ab, Misc Technical fehlt — `cwd`-Aktionen überspringen diese
  Glyphen still. (5) `health.check()` meldet einen fehlenden lib.nvim-Composer als Error
  und ruft danach `composer.checkhealth()` unbedingt auf.
  Bewusst ausgelassen: `@types.lua`, `config/DEFAULTS.lua` als Datentabelle (nur Stichprobe
  der Form: jedes Pick decodiert auf einen passenden `names`-Eintrag, keine
  Codepoint-Kollisionen), `plugin/*.lua` (Load-Guard bzw. `helptags`-Lauf, unter `-u NONE`
  ohnehin nicht gesourct), die echten Picker-Backends, der echte `rg`-Prozess, die
  Float-Geometrie des Overlays (gehört `ui.kit`; die gerenderten Zeilen werden trotzdem
  echt geprüft).
  Commit: `5ea0333`, direkt auf `main` gepusht.
  **Mittlerweile gefixt** (separate Sitzungen dieser Kampagne): Bug (1) und (2) über
  Commit `7583459` (`checkbox_target()`s Visual-Zweig liest jetzt `vim.fn.getpos("v")` +
  Cursor statt der erst beim Verlassen von Visual committeten `'<`/`'>`-Marken;
  `frecency.lua`s `mkdir` jetzt pcall-gewrappt); Bug (5) über Commit `dd6a0fb` (der
  Composer-Aufruf jetzt `pcall(require, ...)`-gewrappt) -- dieses Repo war damit die
  ERSTE Instanz der "Health ruft ihre fehlende Dependency trotzdem" Familie, die die
  Kampagne seitdem in elf weiteren Repos wiedergefunden hat. Bug (3) und (4) (Shortcode-vs-
  Quickfix-Parser, `RG_PATTERN`-Lücke) sind weiterhin offen/gepinnt.
  **Re-Audit (Runde 15, 2026-09-18):** ein sehr solider Fund -- die drei Fix-Commits waren
  bereits alle mit Regressionstests belegt, kein Diff seit Runde 15 außer genau diesen
  dreien. Die vier Bug-Familien einzeln durchgeprüft: kein weiterer Preflight mit derselben
  Form wie der gefixte; keine Augroups überhaupt (`bindings/autocmds.lua` ist ein bewusster
  Leer-Stub); Byte/Spalten-Nutzung durchgehend konsistent geprüft; keine Windows-Pfad-
  Vergleiche im ganzen Repo (der einzige Colon-Parsing-Bug in `search.lua` ist der bereits
  bekannte, weiterhin gepinnte). **Eine echte, kleine Lücke gefunden und geschlossen**:
  `health.lua`s Neovim-Versions-Gate erreichte nie seinen `warn`-Zweig, da die Suite auf
  aktuellem Neovim läuft -- `vim.fn.has` per Hand gestubbt (dieselbe Technik wie beim
  ripgrep-present/absent-Paar), um ihn zu erreichen. Keine neuen Bugs.
  Testlauf: 22 Specs, 773 → 775 Checks, stabil über zwei von mir persönlich nachgefahrene
  Wiederholungsläufe. `luacheck lua TESTS` (47 Dateien) und `stylua --check lua TESTS`
  beide grün.
  Commit: `9de7b6d`.
- [x] **fileops.nvim** — fertig (Runde 16). Framework-freier Harness beibehalten
  (`function(H)`-Specs, Eintrag in `run.lua`). 9 → 19 Spec-Dateien, 199 → 805 Assertions,
  fünf Läufe hintereinander identisch grün (Exit 0, `FILEOPS_TESTS_OK`).
  `stylua --check .` grün (TESTS *ist* Teil dieses Gates), `luacheck lua` 0/0 über 18
  Dateien — TESTS ist hier nicht im luacheck-Gate, wurde aber zusätzlich geprüft (0/0).
  10 neue Specs: `file_paths_spec` (Leerzeichen, Sonderzeichen, Glob-Klammern,
  Laufwerksbuchstaben, cwd- vs. Bufferdir-Anker, `ensure_parent`-Fehlerwortlaut),
  `file_delete_spec` (Trash vs. permanent mit geprüfter argv, Unsaved-Guard,
  Fensterbuchhaltung nach dem Löschen, `on_before_delete`-Veto, `diagnose_lock`),
  `cycle_edge_spec`, `bulk_edge_spec`, `usrcmds_dispatch_spec` (jedes Subkommando über das
  echte Ex-Kommando inkl. Prompts und Completion jedes Slots), `keymaps_spec`,
  `autocmds_spec` (auto-mkdir inkl. Remote-Skip, conflict_marks, on_hold-Event-Mapping),
  `init_api_spec`, `notify_spec`, `health_menu_spec`. Alle Fixtures unter
  `vim.fn.tempname()`, nichts fasst das Repo an. Am Runner: `run.lua` registriert das
  eigene `lua/` jetzt **absolut** auf `package.path` — vorher konnte ein Spec, das die cwd
  wechselt, jedes noch nicht aufgelöste `require("fileops.…")` kaputtmachen.
  **Fünf Bugs gefunden, alle gepinnt.** Der gefährlichste: `bindings/keymaps.lua` ruft
  `delete_fn({})` ohne Optionen, sodass die Delete-Taste seit dem Default-Wechsel auf
  `"trash"` weiterhin **permanent und ohne Undo** löscht und `on_before_delete` nie
  aufruft — obwohl der Modul-Header behauptet, `:File delete` zu spiegeln. Drei weitere
  sind Windows-only: `ops/cycle.lua` friert mit `follow_symlinks = false` die Navigation
  ein (Trenner-Mismatch zwischen Join und Buffername, `canon` normalisiert unter Windows
  nicht → `:File next`/`prev` als lautloser No-op); `ops/bulk.lua` lässt nach
  `bulk rename` einen Phantom-Buffer zurück (derselbe Mismatch, `nvim_buf_set_name` läuft
  nie, das nächste `:w` schreibt den alten Namen zurück); `ops/file.lua`s `delete_path`
  nimmt Verzeichnisse an, die `uv.fs_unlink` nie löschen kann, verbrennt das Retry-Budget
  an einem `EPERM` und macht danach einen Virenscanner verantwortlich. Fünftens leakt
  `features/conflict_marks.lua` bei jedem erneuten `:edit` drei Matches, deren IDs
  überschrieben und damit unlöschbar werden.
  Zusätzlich zwei Eigenheiten als dokumentiertes Verhalten gepinnt (kein Bug): `:saveas`
  normalisiert den Buffernamen, das `:file` hinter `rename`/`edit_new` nicht; und ein Plan
  aus einer Wurzel *mit* Trenner ergibt andere Pfadstrings als dieselbe Wurzel ohne.
  Bewusst ausgelassen: `@types/init.lua`, `plugin/fileops.lua`, `config/DEFAULTS.lua` als
  Tabelle, `reload_explorers`/`refresh_explorers` jenseits ihres `package.loaded`-Guards
  (dafür gibt es den separaten `explorer-integration`-CI-Job), `on_hold`s
  Preview-Rendering, die Backends von `lib.nvim.fs.trash`/`cross.fs.lock` (fremdes Repo).
  Zwei Zweige sind nachweislich **unerreichbar** und deshalb dokumentiert statt getestet:
  der `unknown subcommand`-Zweig in `usrcmds.dispatch` (composer meldet vorher) und
  `bulk.plan`s "cannot read directory"-Guard.
  `docs/CONTRIBUTING.md` behauptete, `TESTS/` sei eine plenary/busted-Suite — das war es
  nie; korrigiert samt echtem Aufruf.
  Commit: `7060232` (test: cover the bindings layer, the ops failure paths, and Windows
  path handling), direkt auf `main` gepusht.
  **Mittlerweile gefixt, alle fünf.** Bug 1 (der gefährlichste, `bindings/keymaps.lua`s
  ungeschütztes `delete_fn({})`) über Commit `e7185fc` (liest jetzt `config.get().delete`
  pro Aufruf). Bug 2-4 (`ops/cycle.lua`s No-op-Navigation, `ops/bulk.lua`s Phantom-Buffer,
  beide derselbe Windows-Trenner-Mismatch zwischen `/`-Join und `nvim_buf_get_name`s
  Schreibweise; `ops/file.lua`s Verzeichnis-Unlink-Retry-Budget) über Commit `81e15ee`. Bug
  5 (`conflict_marks.lua`s Match-Leak bei erneutem `:edit` ohne vorheriges `BufWinLeave`)
  über Commit `ffc1c9a`.
  **Re-Audit (Runde 16, 2026-09-18):** alle fünf Fixes bestätigt vorhanden. Die
  Windows-Pfadbehandlung noch einmal komplett durchgesehen: die `comparable()`/
  `vim.fs.normalize()`-Fixes aus der vorherigen Runde sind konsistent auf beiden Seiten
  jedes Pfadvergleichs angewendet, keine unnormalisierte Stelle übrig; Laufwerksbuchstaben-
  Erkennung nutzt bereits `^%a:[\\/]`, keine naive `:find(":")`-Suche. Augroups bereits
  idempotent (`autocmd.group(name, true)`, in `lib.nvim`s Quelle gegen `nvim_create_augroup`
  mit `clear=true` verifiziert). **Ein Bug gefunden und sofort gefixt** (fünfzehntes Repo
  der Health-Familie): `health.lua`s `M.check()` meldete einen fehlenden
  `lib.nvim.bindings.usercmd.composer` korrekt per `vim.health.error()`, requirte ihn dann
  aber am Funktionsende erneut ungeschützt -- crasht statt bei der Warnung zu enden.
  Trivialer, unzweideutiger Fix (nur der bereits kaputte Pfad ändert sich), direkt gefixt,
  gepinnt in `health_menu_spec.lua` über einen simulierten fehlenden Composer.
  **Zwei echte Bugs gefunden und sofort gefixt**, entdeckt beim Schließen einer veralteten
  Auslassung (`on_hold`s Preview-Rendering stand als "bräuchte ein echtes Repo plus zwei
  Subprozesse pro Idle-Event" auf der Ausschluss-Liste -- stimmt nicht mehr, `git_spec.lua`/
  `git_async_spec.lua` nutzen längst ein echtes Temp-Repo für genau diesen Tausch): (1)
  `get_previous_line_async` baute `git show <sha>:<file>` mit dem ABSOLUTEN Bufferpfad --
  gegen echtes Git verifiziert, dass `<rev>:<path>` `<path>` gegen die Repo-Wurzel auflöst,
  nicht gegen das Dateisystem, wodurch dieser Aufruf schon immer lautlos mit
  `fatal: path '...' does not exist in '<rev>'` scheiterte -- die Fallback-Preview hat noch
  nie im echten Einsatz ein Frame gerendert. Gefixt: fragt jetzt nach `sha .. ":./" ..
  fnamemodify(file, ":t")`, da `cwd` schon das Datei-Verzeichnis selbst ist. (2) `truncate()`
  ist dokumentiert als "so viele Zeichen", schneidet aber byte-indexiert mit `#s`/
  `string.sub` -- bei ASCII harmlos, aber ein Mehrbyte-UTF-8-Zeichen nahe der Schnittstelle
  würde halbiert, was `nvim_buf_set_extmark` eine kaputte `virt_text`-Byte-Sequenz übergibt
  (empirisch bestätigt: Neovim lehnt das nicht ab, rendert nur die verstümmelten Bytes).
  Gefixt mit `vim.fn.strchars`/`vim.fn.strcharpart`, No-op-Änderung für reines ASCII. Beide
  mit echten Regressionstests in neuer `on_hold_preview_spec.lua` belegt, inklusive eines
  dedizierten Mehrbyte-Falls (`string.rep("é", 20)`), der das alte Halbierungsmuster exakt
  reproduziert.
  Testlauf: 19 → 20 Specs, 804 → 831 Assertionen, über drei Läufe stabil (zwei davon von mir
  persönlich nachgefahren, einer mit CI's exakten `-i NONE -u NONE`-Flags). `luacheck lua`
  (18 Dateien) und `stylua --check .` beide grün.
  Commit: `037d3bb`.
- [x] **reposcope.nvim** — fertig (Runde 17). 10 → 35 Spec-Dateien, 236 → 1910 ausgeführte
  Assertions, 35/35 grün über 4 Wiederholungsläufe plus einen in Glob- statt Run-Reihenfolge
  (die Specs sind also voneinander unabhängig). `luacheck lua plugin TESTS` 0/0 über 151
  Dateien, `stylua --check` grün. Kein `lua/`-Quelltext angefasst.
  Der Harness bekam `with_stubs(stubs, reload, fn)`: Doubles in `package.loaded`, Subjekt
  entladen, danach aus einem Volltabellen-Snapshot restaurieren — hier zwingend, weil jedes
  Modul seine Abhängigkeiten beim Laden an File-Locals bindet.
  Abgedeckt: die ganze Netzwerkschicht ohne einen einzigen Request (curl/gh/wget gegen ein
  gestubbtes `spawn_capture`, geprüft wird die argv, das 20s-Timeout, Erfolg/Exit-Code/
  Timeout/Metrik-Fan-out), alle drei Such- und README-Fetcher über die volle Response-Matrix,
  die drei README-Manager tabellengetrieben als ein Contract, die Clone-Argv-Builder, der
  README-Cache (RAM/Disk-Tiering, Pfad-Sanitizer gegen Traversal, Freshness-Sidecar),
  Session/Query-Stats/Favorites, Config/State/Controller/Metriken/Bindings/Health/Actions und
  ein echter `open_ui()`/`close_ui()`-Durchlauf.
  Bemerkenswert: **Fehler werden hier nirgends memoisiert** — das in Runde 14 gefundene
  "gecachter Fehler vergiftet die Session"-Muster existiert nicht, jeder Fehlerpfad leert den
  Cache stattdessen; das ist explizit gepinnt.
  **Sechs Bugs gefunden, alle gepinnt.** Einer davon ist ein Credential-Leak: GitLabs
  `PRIVATE-TOKEN` stand nicht in `is_secret_header`s Liste, landete also im argv, lesbar für
  jeden anderen Prozess. **Inzwischen gefixt** — der Filter lebt in `lib.nvim.net.curl`, der
  Fix wirkt also für alle Dependents (Commit `5c6b1ac`). Offen bleiben: `clone_manager`s
  `not isdirectory(path)` (0 ist in Lua truthy → Pfad-Guard und `safe_mkdir` beide toter
  Code, in beide Richtungen), `unset_prompt_keymaps()`s falscher Aufräum-Tag (das Registry
  wächst pro Open/Close-Zyklus), `vim.json.decode("null")` → truthy `vim.NIL` in zwei von
  drei Fetchern (der GitLab-Fetcher daneben prüft `type(parsed) ~= "table"` und macht es
  richtig), `is_valid_path()`s Wurf ohne das laut Doc optionale zweite Argument, und der
  `Invalid buffer id` beim zweiten Öffnen des README-Viewers.
  Offen geblieben: direkte Assertions für die fensterbauenden `ui/`-Module (aktuell nur als
  Smoke über `open_ui`) und `preview_manager`s Scroll-/Inject-Logik.
  Commit: `98a9a36`.
  **Mittlerweile gefixt** (separate Sitzungen dieser Kampagne, nicht das Re-Audit selbst):
  `vim.json.decode("null")`-Crash über Commit `3c82ff3` (beide betroffenen Fetcher prüfen
  jetzt `type(parsed) ~= "table"`, analog zum GitLab-Fetcher); ein zweiter,
  normalize-vor-expand-Aspekt des PRIVATE-TOKEN-Themas über Commit `6d3cc12` (zieht mit
  `lib.nvim`s eigenem Fix nach).
  **Re-Audit (Runde 17, 2026-09-18):** alle sechs damals gepinnten Bugs einzeln gegen den
  aktuellen Quellcode nachgeprüft, nicht angenommen. Ergebnis: `clone_manager.lua`s toter
  Pfad-Guard, `unset_prompt_keymaps()`s falscher Tag, `is_valid_path()`s Wurf und der
  README-Viewer-Doppel-Open sind alle vier weiterhin offen und korrekt gepinnt. Die beiden
  oben genannten (JSON-Null-Crash, Credential-Leak-Nachzügler) waren dagegen bereits real
  gefixt, aber `TESTS/README.md`s "Findings pinned here"-Liste beschrieb sie noch als offen
  -- veraltete Doku, jetzt korrigiert und die verbleibenden vier neu durchnummeriert. Die
  vier wiederkehrenden Bug-Familien einzeln geprüft: `health.lua` degradiert korrekt bei
  fehlender optionaler Dependency; beide Augroups nutzen `clear = true`; `status_view.lua`
  behandelt Byte-vs-Display-Zelle durchgehend explizit und sorgfältig; Pfadbehandlung in
  `repos.lua`/`repo_status.lua`/`repo_actions.lua` läuft über `cwd`-relative
  `vim.system`-Aufrufe oder bereits normalisierende Helfer -- keine neuen Windows-Bugs.
  **Eine echte Lücke gefunden und geschlossen**: `ui/config.lua`, das gemeinsame Layout/
  Theme-Singleton, von dem jedes `*_config`-Modul (background/list/preview/prompt) seine
  Geometrie ableitet, hatte echte Verzweigungslogik (`update_layout()`s Pin-vs-Derive-
  Semantik, `update_theme()`s dark/light/custom/invalid-Zweige) und **null** Spec-Coverage
  -- stand nicht einmal auf der "bewusst ausgelassen"-Liste. Neue `ui_config_spec.lua`
  (26 Assertionen), isoliert über `with_stubs` neu geladen, damit nichts in das echte,
  von anderen Modulen bereits referenzierte Singleton durchsickert.
  Testlauf: 34 → 35 Spec-Dateien, 1908 → 1934 ausgeführte Assertionen (per temporärem
  Assertion-Zähler gemessen, vor dem Commit wieder entfernt), 0 Fails über zwei von mir
  persönlich nachgefahrene Wiederholungsläufe. `luacheck lua plugin TESTS` (152 Dateien)
  und `stylua --check lua plugin TESTS` beide grün. Kein `lua/`-Quelltext angefasst -- reine
  Test- und Doku-Arbeit.
  Commit: `ab97158`.
- [x] **gopath.nvim** — fertig (Runde 18). Hier war die Ausgangslage anders als überall
  sonst: `docs/CONTRIBUTING.md` beschrieb eine plenary-Suite, **die es nie gab**. Die echte
  Konvention sind zwei headless-Runner unter `scripts/ci/` mit eigenem `check()`-Harness;
  `TESTS/*.lua` sind *manuelle* Anleitungen (Cursor hinstellen, Keymap drücken), die CI nur
  auf Syntax prüft. Konvention beibehalten und ausgebaut statt migriert: neuer
  `scripts/ci/harness.lua`, ein Runner, der `scripts/ci/specs/*_spec.lua` automatisch
  einsammelt (kein Aggregator zu pflegen, `GOPATH_SPEC=<substring>` filtert), und ein
  CI-Job `unit-tests` formgleich zu den bestehenden.
  0 → 17 Spec-Dateien, +435 Checks / ~1600 Assertions, 3 Läufe stabil. `luacheck lua plugin`
  0/0 über 78 Dateien, `stylua --check lua/ plugin/` grün (TESTS und scripts sind hier
  bewusst nicht Teil der Gates — die neuen Dateien wurden trotzdem geprüft).
  **Acht Bugs gefunden, alle gepinnt.** Der schönste: `cmd = { "explorer.exe", path:gsub(...) }`
  — ein unparenthesiertes `gsub` im letzten Slot eines Table-Konstruktors liefert *beide*
  Rückgabewerte, die Ersetzungsanzahl landet als drittes argv-Element (`explorer.exe C:\a\b 3`);
  `revealer.lua` schreibt dasselbe `gsub` in einer Konkatenation und ist korrekt. Dazu:
  `expand_right` nimmt das Terminator-Zeichen mit in den Pfad (unter Windows unauffällig, weil
  Win32 ein trailing space toleriert — verifiziert), `tailsearch.sanitize`s Drive-Strip läuft
  vor der Backslash-Normalisierung und schließt Kleinbuchstaben aus, die Vorzeilen-Suche für
  mehrzeilige `require(...)` ist toter Code, `providers/token.lua` zerstört das `path(line)`-
  Format seines eigenen Docstrings, `check_under_cursor`s `help`-Zweig ist unerreichbar,
  `invalidate_caches()` vergisst `_pdir_*`, und `create.lua`s "lib.nvim fehlt"-Fallback requirt
  ungeschützt genau die fehlende Dependency.
  `docs/CONTRIBUTING.md` korrigiert, `TESTS/README.md` neu angelegt (Trennung manuelle Guides
  ↔ automatisierte Suites). Commit: `394b4b3`.
  **Mittlerweile gefixt** (separate Sitzungen, drei Commits): `health.lua`s Composer-Aufruf
  jetzt `pcall`-gewrappt (`1cc43e1`); Backslash-geschriebene Pfad-Kandidaten werden vor
  `fnamemodify`/`fs_stat` jetzt zu `/` normalisiert, betrifft drei Dateien (`20b3132`);
  `resolve_and_copy` verifiziert jetzt tatsächlich, dass `setreg`/der Schreibvorgang
  ankam, statt Ausbleiben eines Wurfs als Erfolgsbeweis zu nehmen (`a6c9079`, `0f9eae3`).
  **Re-Audit (Runde 18, 2026-09-18):** alle acht ursprünglichen Pins einzeln gegen den
  aktuellen Quellcode nachgeprüft -- alle acht weiterhin offen und korrekt gepinnt, dazu
  die drei obigen Fixes bestätigt real und mit eigenen Specs belegt. Alle `pcall(require,
  ...)`-Soft-Dependency-Stellen (30+) auf dieselbe "Dependency fehlt, ruft sie trotzdem
  auf"-Form durchsucht -- keine zweite Instanz gefunden, jede andere Stelle gated korrekt
  auf `ok`. Augroups durchgesehen: `bindings/autocmds.lua` passt bereits `clear=true`; zwei
  ungruppierte Top-Level-Autocmds in `alias_index.lua`/`binding_index.lua` registrieren
  sich nur einmal pro `require()` (nicht pro `setup()`), ein Duplikat wäre harmlos-idempotent
  -- kein echter Bug. **Ein Bug gefunden und sofort gefixt** (derselbe Fehlerklasse wie
  Commit `20b3132`, dort aber übersehen): `resolvers/common/linepath.lua`s drei direkte
  `fs_stat`-Proben riefen `vim.fs.normalize()` auf rohen, noch nicht Backslash-zu-Slash
  konvertierten Kandidatentext -- unter Linux/macOS scheiterte ein Backslash-geschriebener
  Kandidat lautlos an der Auflösung. Trivialer, unzweideutiger Fix, direkt angewendet.
  **Ein neuer Bug gefunden und gepinnt** (kein mechanischer Fix möglich, braucht eine echte
  Design-Entscheidung): `resolvers/go/import_path.lua`s `parse_import` ist als einziger von
  acht Sprach-Resolvern nicht an sein eigenes Import-Keyword verankert -- ein bloßes
  `line:match('"([^"]+)"')` feuert auf jeden String-Literal mit `/`, der zufällig wie ein
  Package aussieht, auch wenn es keiner ist. Zwei Coverage-Lücken in `init.lua`s
  `_setup_cache` geschlossen (`use_cache = false` überspringt den Refresh-Timer korrekt;
  ein veralteter Cache plant genau einen deferred Rebuild).
  Testlauf: 435 → 439 Checks, ~1600 → 1610 Assertionen, alle drei echten CI-Runner
  (`headless_tests.lua` 8/8, `functional_tests.lua` 38/38, `unit_tests.lua` 439/1610) über
  zwei von mir persönlich nachgefahrene Wiederholungsläufe stabil. `luacheck lua plugin`
  (78 Dateien) und `stylua --check lua/ plugin/` beide grün.
  Commit: `945a3fa`.
- [x] **color_my_ascii.nvim** — fertig (Runde 19). Die bestehenden 15 Specs hingen fast alle am
  `:Fence`-Werkzeugkasten; die Schichten darunter — wo ein Fehler nicht crasht, sondern ein
  Highlight drei Spalten zu weit links landet — hatten nichts. 15 → 28 Spec-Dateien,
  324 → 5566 ausgeführte Assertions, 5 Läufe stabil, beide Lint-Gates grün über 127 Dateien.
  Kernstück `byte_offsets_spec`: Extmark-Positionen in echtem Mehrbyte-Inhalt (Umlaute 2 B,
  Box-Drawing 3 B, CJK 3 B, Emoji 4 B) gegen handgezählte Byte-Offsets, plus die Assertion,
  dass kein Extmark mitten in einem Codepoint beginnt. Dazu die Fence-API **als Vertrag**,
  genau in den Formen, in denen `markdown.nvim` sie aufruft, und der Teardown über jeden
  Löschweg — **kein E937 hier**, der Handler löscht nichts, er räumt nur auf.
  Ebenfalls gepinnt und positiv: ein voller Render-Durchlauf ruft `nvim_set_hl` **null Mal**;
  die Gruppen entstehen ausschließlich beim Config-Bau. Das Repo macht es richtig.
  **Sechs Defekte gefunden.** Zwei davon **inzwischen gefixt** (Commit `0437fe0`):
  `ensure-blank-lines` fügte Leerzeilen *in* den Block ein und zerstörte damit die ASCII-Art,
  die das Plugin hervorheben soll (die Zustandsmaschine kannte kein öffnend/schließend), und
  der `unique_words`-Lookup war hash-order-abhängig, weil acht Wörter von zwei Sprachen
  gleichzeitig als unique deklariert sind. Offen: die comment_ascii-Highlights liegen
  `#prefix + 1` Bytes zu weit links (gestrippter Text als Koordinatensystem für Extmarks in
  der ungestrippten Zeile), `parser.get_byte_offset` wirft für jede Spalte > 0 (fährt
  `vim.str_utf_pos` als Iterator, das eine Tabelle liefert), `enable_bracket_highlighting`
  kann Bracket-Highlighting nicht abschalten, und zwölf Keywords stehen doppelt in ihrer
  eigenen Sprachdatei. Commit: `adcb5ef`.
  **Re-Audit (Runde 19, 2026-09-18):** alle vier verbleibenden Pins explizit gegen den
  aktuellen Quellcode nachgeprüft -- alle vier weiterhin offen, korrekt gepinnt, keiner
  verloren oder stillschweigend geändert. Veraltete Doku gefunden: `TESTS/README.md`s
  "Pinned bugs and findings" listete die beiden schon per `0437fe0` gefixten Defekte
  weiterhin als offen -- die README wurde nach dem Fix nie aktualisiert, jetzt korrigiert.
  **Ein neuer Bug gefunden und sofort gefixt** (das exakte "warnt, crasht dann in dieselbe
  Dependency"-Muster, das die Kampagne immer wieder findet, hier aber nicht als
  `health.lua`-Sonderfall, sondern in der Composer-Handoff-Logik): `health.lua`s
  `checkhealth` meldete "lib.nvim not found" per `health.error`, requirte dann aber am Ende
  ungeschützt erneut genau dasselbe fehlende Modul, um den Report zu übergeben -- riss den
  Report direkt nach der erklärenden Warnung ab. Gefixt durch Wiederverwendung der Modul-
  Referenz aus dem ersten `pcall(require, ...)` und Auslassen der Übergabe, wenn der
  fehlschlug. Regressionstest über `package.preload`/`package.loaded`-Stub ergänzt.
  **Zwei echte Lücken gefunden und geschlossen**: `fence_content_highlight`s Default-
  Shade-Modus (`"auto"`, gewählt wenn `shade` fehlt) entscheidet nach `vim.o.background`
  zwischen Lighten/Darken -- jeder bisherige Test setzte explizit `shade = "darken"` und
  überging diesen Zweig komplett; `theme_presets.resolve_auto`s Hellhintergrund-Bailout
  (liefert nil, fällt auf "subtle" zurück) und seine Längste-Zeichenkette-zuerst-Priorität
  (`"gruvbox-material"` gewinnt gegen das bloßere `"gruvbox"`, das es als Substring auch
  enthält) waren nie geprüft. Sonst nichts Neues: kein dritter Byte/Spalten-Fall über die
  zwei bekannten hinaus gefunden; alle Augroups nutzen `lib.nvim`s idempotenten
  `augroup.create.clear`-Helfer außer einer Stelle in `commands/fence/open.lua`, die aber
  per Buffernummer geschlüsselt ist (nie innerhalb einer Session wiederverwendet, also
  praktisch nicht ausnutzbar); ein möglicher Windows-Case-Mismatch in `export.lua`s
  `relpath` ist explizit als "best-effort, fällt auf absolut zurück" dokumentiert, kein
  Crash, nicht pin-würdig.
  Testlauf: 28 Specs, 859 → 866 Assertion-Aufrufstellen, über zwei von mir persönlich
  nachgefahrene Wiederholungsläufe stabil. `luacheck` (127 Dateien, per explizitem
  File-Globbing statt Verzeichnisform -- letztere scheitert unter Windows mit "Permission
  denied", ein lokales luacheck-Limit, kein echter Fund) und `stylua --check` beide grün.
  Commit: `22b9115`.
- [x] **diff.nvim** — fertig (Runde 20, Gap-Closing statt From-Scratch). Das ehrliche Audit
  vorweg: das Repo war wirklich das bestabgedeckte der Warteschlange, aber **schichtweise
  ungleich** — die reinen Layer und die Render-Erfolgspfade waren gut, die gesamte
  Verdrahtungsschicht hatte null Assertions (`bindings/*`, `features/origin.lua`, `health.lua`,
  `core.run_buffers`, `view=float`, `scratch.track/discard/wipe_on_exit`, sämtliche
  Fehlerarme von `core/render.lua`). 17 → 27 Spec-Dateien, 295 → 694 Assertion-Stellen,
  5 Läufe stabil, beide Gates grün über 53 Dateien. Kein `lua/`-Quelltext angefasst.
  **Zwei Windows-Verdachtsfälle wurden empirisch geprüft und sind korrekt** — und genau
  deshalb gepinnt statt dem Zufall überlassen: `core/git.lua` normalisiert mit
  `vim.fs.normalize` (faltet Backslashes *und* schreibt den Laufwerksbuchstaben groß), und
  `has_hidden_segment` funktioniert, weil `vim.fs.dir` auf jeder Plattform
  Forward-Slash-Relativnamen liefert.
  **Drei Bugs gefunden, alle gepinnt:** `core/directory.lua`s ungeschütztes `readfile` →
  rohes `E484` an `directory.run`s eigenem Fehlervertrag vorbei, **und `on_done` feuert nie**,
  ein API-Aufrufer wartet ewig (derselbe Fehlertyp, den der Nutzer-Commit `df2652f` eine
  Schicht darüber gerade geschlossen hatte); `scratch.track()` dedupliziert nicht, sodass
  `status()` `diff:3` melden kann; und `health.lua`s "lib.nvim fehlt"-Zweig ruft danach
  unbedingt in lib.nvim hinein — dieselbe Familie wie emojis.nvim (Runde 15) und gopath.nvim
  (Runde 18), inzwischen **drei Repos mit demselben Muster**.
  Während der Runde landete der Nutzer-Commit `df2652f` auf `origin/main`; der Agent hat
  rebased und `render_edge_spec` auf den neuen `on_done`-Vertrag umgestellt.
  Commit: `d7aa3a5` (dessen Text "295 → 681" sagt, die Zählung vor dem Rebase; korrekt sind
  694 — bewusst nicht force-gepusht).
  **Mittlerweile gefixt** (separate Sitzung, Commit `7f5f2dd`): `health.lua`s Composer-Aufruf
  ist jetzt `pcall`-gewrappt.
  **Re-Audit (Runde 20, 2026-09-18):** genuiner Befund von "nichts zu tun" -- beide Pins
  (`core/directory.lua`s ungeschütztes `readfile`, `core/scratch.lua`s fehlende
  Deduplizierung) live gegen den aktuellen Code neu verifiziert (durch Zurücksetzen des
  jeweiligen Stubs bestätigt: beide weiterhin rot ohne Fix). Alle vier Bug-Familien
  einzeln durchgeprüft, kein einziger neuer Fund: `health.lua`s Fix korrekt und getestet,
  jeder andere Preflight (`pickers_bridge.lua`, `init.lua`s `ok_deps`, `core/url.lua`s
  `ok_rt`, `features/image_compare.lua`s `ok_images`) gatet seinen Folgeaufruf schon
  korrekt; beide Augroups nutzen bereits `clear = true` direkt (mit Kommentar, warum
  bewusst kein Wrapper); Byte/Codepoint-Mathematik in `render.lua`s Wort-Diff ist
  durchgehend codepoint-bewusst (inklusive eines schon gepinnten, früher gefixten
  Off-by-one); keine Colon-Parsing-Stellen im ganzen Repo, `core/git.lua` normalisiert
  bereits korrekt. Kein Diff seit Runde 20 außer dem einen Fix-Commit. Keine neuen Bugs,
  keine geschlossenen Lücken -- ehrlich nichts zu tun, wie von diesem Auftrag selbst
  verlangt statt Busywork zu erfinden.
  Testlauf: 27/27 Specs weiterhin grün (693/694 Assertion-Aufrufstellen, unverändert, da
  keine Spec hinzukam/entfiel), von mir persönlich nachgefahren. `luacheck lua plugin
  TESTS` (53 Dateien) und `stylua --check .` beide grün. Kein neuer Commit -- `HEAD` war
  schon `origin/main`s Tip.
- [x] **cascade.nvim** — fertig (Runde 21). Coverage wurde nicht geschätzt, sondern mit
  einer `debug.sethook("l")`-Zeilensonde gemessen — das machte den Audit ehrlich: zwei Module
  (`health.lua`, `integrations/menu.lua`) hatten exakt **null** Abdeckung, weil kein Spec sie
  überhaupt requirte. 7 → 17 Spec-Dateien, 462 → 981 Assertion-Aufrufstellen, 80% → 83%
  ausführbarer Zeilen, 17/17 grün über 5 Läufe, beide Lint-Gates grün über 68 Dateien. Kein
  `lua/`-Quelltext angefasst in dieser Runde selbst.
  **Sechs Bugs gefunden, zwei inzwischen gefixt (Commit `c23ea33`):** `lists/move.lua`
  verankerte den Renumber-Basiswert an der Zeile, die nach dem `:move` zufällig erste ist →
  `1. 2. 3. 4.` driftete bei jedem Move um +1 (empirisch reproduziert, dann per
  `renumber.peek_base_start()` vor dem Move + neuem `forced_base_start`-Parameter gefixt,
  gegen sowohl `move.line` als auch `move.selection`, gegen normale und bewusst bei 5
  beginnende Listen verifiziert). Und: `lists.cycle`s Default-Ring konnte nicht schließen,
  weil `lists.types` nur zwei der vier vom Cycle erzeugten Markerarten kannte — eine `a)`-Zeile
  verlor jede Listen-Erkennung. Der erste Fix-Versuch (`types` einfach um ascii+roman erweitert,
  ascii vor roman) schloss den Ring *nicht* — Testlauf zeigte `I. → *` statt `I. → -`; die
  Ursache war, dass `ascii` und `roman` denselben Delimiter-Regex teilen und `ascii-first` die
  eigene `I.`-Ausgabe des Zyklus als ascii zurückliest. `roman` vor `ascii` behebt es, weil
  normale Buchstaben (a, b, c, …) keine gültigen römischen Zahlen sind und durchfallen.
  Offen geblieben (vier, alle in `TESTS/README.md` dokumentiert): zwei der drei Augroups in
  `bindings/autocmds.lua` werden nur geleert, wenn ihr Feature-Gate durchkommt (deaktiviertes
  Feature hinterlässt lebende Handler bis zum Neustart — Spiegelbild von pdfport.nvims Fund);
  `cycle_group_add`/`remove` mutieren `config.DEFAULTS` direkt, weil `lib.lua.config.deep_merge`
  nur die oberste Ebene kopiert; `:Cascade indent N`/`dedent N` ignorieren `N`; `cycle remove`
  schneidet mehrwortige Werte am ersten Leerzeichen ab.
  Byte-Offsets systematisch durchprobiert und **nichts gefunden** — cascade ist durchgehend
  byte-konsistent, gepinnt in `multibyte_spec.lua` (72 Assertions gegen Umlaute/CJK/Emoji).
  Windows-Pfade/ungeschützte FS-Aufrufe: strukturell nicht anwendbar (keine Pfadbehandlung im
  Repo). `health.lua`s "Dependency fehlt"-Zweig ruft die Dependency **nicht** unbedingt auf —
  echt geprüft, nicht angenommen.
  `docs/CONTRIBUTING.md` behauptete wieder eine plenary-Suite, die es nie gab (dasselbe Muster
  wie gopath.nvim, Runde 18) — korrigiert.
  Coverage-Commit: `77ea4f3`, Bugfix-Commit: `c23ea33`.
  **Re-Audit (Runde 21, 2026-09-18):** alle drei verbleibenden offenen Punkte einzeln
  gegen den aktuellen Quellcode bestätigt (Augroup-Gating-Reihenfolge statt fehlendem
  `clear=true` -- `lib.augroup` selbst cleart immer korrekt, geprüft in dessen eigener
  Quelle; `config.DEFAULTS`-Mutation; `indent`/`dedent N`/`cycle remove`s Argument-Bugs),
  dazu die beiden bereits gefixten Bugs (Renumber-Drift, Cycle-Ring) mit ihren
  Regressionstests bestätigt, die jetzt das KORREKTE Verhalten erwarten statt der alten
  Buggy-Erwartung. Die vier Bug-Familien einzeln durchgeprüft: `health.lua` ruft nie in
  die als fehlend gemeldete Dependency hinein (per gefaktem `require`-Fehlschlag echt
  getestet); Byte-Offsets bleiben durchgehend korrekt; keine Pfadbehandlung im Repo, also
  strukturell keine Windows-Bugs. **Drei echte Coverage-Lücken gefunden und geschlossen**
  (per manueller Probe vorab verifiziert, bevor Assertions geschrieben wurden):
  `marker.advance`s Checkbox-Reset-Zweig, `transform.block_range`s abwärts gerichteter
  Marker-Scan, `cycle.date.span`s "Cursor vor dem Datum"-Frühausstieg.
  **Ein neuer Bug gefunden und gepinnt** (nicht gefixt, da eine bewusste Design-Entscheidung
  nötig wäre): `renumber.tree`, direkt über eine explizite Range aufgerufen, die mehr als
  einen Listen-Block umfasst (der `:Cascade renumber`/`run_command`-Pfad, anders als `M.all`,
  das vorher aufteilt), setzt den zweiten Blocks Zähler-Neustart vom `base_start` des
  ERSTEN Blocks ab statt vom eigenen -- z.B. wird `5. 6.` / Leerzeile / `9. 10.` zu
  `5. 6.` / Leerzeile / `5. 6.` statt `9. 10.`.
  Testlauf: weiterhin 17 Spec-Dateien, 981 → 995 Assertion-Aufrufstellen, über zwei von mir
  persönlich nachgefahrene Wiederholungsläufe stabil. `luacheck lua scripts TESTS`
  (68 Dateien) und `stylua --check lua scripts TESTS` beide grün.
  Commit: `0bc75e6`.
- [x] **sandbox.nvim** — fertig (Runde 22, größtes Repo bisher: 270 Dateien). Nach Risiko
  geschichtet: Spawn-Grenze zuerst (das ist ein Sandbox-Plugin, die argv *ist* der Vertrag),
  dann Use-Case-Schicht, Config/State/API, Wiring, UI zuletzt. 17 → 37 Spec-Dateien,
  136 → 883 grüne Testfälle, 5 Läufe stabil, beide Gates grün über 308 Dateien. Kein
  `lua/`-Quelltext angefasst.
  Größter Fund: `engine_parity_spec`/`long_running_spec` prüften nur Methodennamen bzw. einen
  Vertreter für docker — was podman/nerdctl tatsächlich in die argv schreiben, sah niemand.
  `adapters/argv_matrix_spec` fährt jetzt jede Methode aller drei Aggregatoren plus die
  WSL-Engine durch, inkl. Pfaden mit Leerzeichen, Registry-Host mit Port, und dem Beweis, dass
  ein Passwort über stdin geht und nie in der argv landet. `usecases_contract_spec` pinnt alle
  55 Ein-Zeilen-Delegationen gegen die Dateien auf Platte (eine neue Datei ohne Tabelleneintrag
  macht die Suite rot). `routes_spec` fährt den echten Composer mit echten Ex-Kommandos.
  **Drei Bugs gefunden, keiner gefixt:** `adapters/wsl/list_distros.lua` liest UTF-16LE als
  Text (der eigene Kommentar behauptet "vim.system decodes it" — nichts decodiert; `text = true`
  steuert nur Zeilenenden) → `:Sandbox wsl list` ist auf genau der Plattform, für die das
  Feature existiert, komplett kaputt und lautlos — empirisch auf der echten Maschine des
  Nutzers gemessen (388 Bytes, 194 davon NUL). `ui/inspect_view.lua`s Fehlerlisten-Zweig ist
  toter Code (ein `string[]` ist eine Table, läuft also immer durch `vim.inspect`).
  `keymaps = false` bindet weiterhin `<RightMouse>`, weil der Kontextmenü-Trigger allein an
  `config.menu.enable` hängt.
  `.luacheckrc` um zwei begründete `unused_args = false`-Ausnahmen erweitert.
  Commit: `eb2145f`.
  **Re-Audit (Runde 22, 2026-09-18):** kein Diff seit Runde 22, alle drei gepinnten Bugs
  (WSL-UTF-16LE-Fehlinterpretation, `inspect_view.lua`s toter Fehler-Zweig,
  `keymaps = false` bindet `<RightMouse>` trotzdem) bestätigt weiterhin offen und korrekt
  gepinnt. Die vier Bug-Familien einzeln geprüft: `health.lua`s "CLI fehlt"-Zweig fällt
  korrekt zu `engine_utils.responds()` durch (degradiert zu `false`, kein Crash, schon
  gepinnt); die eine Augroup-Nutzung ist buffer-gescoped mit `once = true`, kein
  `setup()`-weites Doppel-Registrierungsrisiko; keine Byte/Spalten-Verwechslung
  (`hover.lua`s `image_at` indiziert direkt am übergebenen Byte-Offset); keine
  Colon/Laufwerksbuchstaben-Bugs (der eine echte Colon-Split, `repo:tag` vs.
  `registry:port`, ist bereits mit einem Windows-realistischen Fall getestet).
  **Eine echte Lücke gefunden und geschlossen**: die vier Telescope-Front-End-Dateien
  (`telescope/{picker,containers,images,wsl}.lua` + die Extension) hatten null Coverage.
  Runde 22s Grund ("telescope.nvim ist keine Dependency oder CI-Sibling") stimmt zwar --
  telescope.nvim ist inzwischen sogar ein echter Sibling-Checkout unter `nvim-data/lazy`,
  aber weiterhin kein CI-Checkout --, verwechselte aber "kann nicht getestet werden" mit
  "braucht das echte Paket": die Wiring-Logik (Entry-Formatierung, Ref-Berechnung,
  Tasten-zu-Kommando-Mapping) lässt sich über `package.loaded`-Doubles für
  `telescope.pickers`/`finders`/`config`/`actions`/`actions.state` prüfen -- dieselbe
  Technik, die diese Suite für `ui.kit`-Prompts längst nutzt. Neue
  `telescope_spec.lua` (23 Checks).
  Testlauf: 883 → 906 Checks, 37 → 38 Spec-Dateien, über zwei von mir persönlich
  nachgefahrene Wiederholungsläufe stabil (mein erster Lauf hing zunächst mit
  "module not found"-Fehlern, weil ich `LIB_NVIM_PATH`/`UI_NVIM_PATH` relativ statt absolut
  gesetzt hatte -- einige Specs wechseln das Arbeitsverzeichnis, ein relativer rtp-Eintrag
  löst sich danach gegen das neue cwd auf; mit absoluten Pfaden lief alles grün, kein
  echter Bug). `luacheck lua TESTS` (310 Dateien) und `stylua --check .` beide grün.
  Commit: `d2ea226`.
- [x] **data.nvim** — fertig (Runde 23). Audit bestätigte die Datei-Ratio: die Happy Paths
  aller vier Verben (JSON/YAML/XML/CSV o.ä.) waren echt getestet, die *Fehlerhälfte* jedes
  Moduls fehlte komplett (`scope/source.lua`/`util/safe_call.lua` ganz ohne eigene Spec,
  `sink.lua`s komplette `write_split`-Fehlerseite ungetestet). 17 → 29 Spec-Dateien,
  190 → 494 Tests, 309 → 847 Assertion-Aufrufstellen, 4 Läufe stabil, beide Gates grün über
  122 Dateien. Kein `lua/`-Quelltext angefasst.
  Zwei Auftragspunkte trafen hier nachweislich nicht zu (kein Ausweichen, sondern verifiziert):
  das Plugin macht null Dateisystem-I/O (kein `readfile`/`mkdir`/`uv.fs_*`, per Grep bestätigt),
  und `github_stats.nvim` benutzt data.nvim nicht (kein Repo unter `E:\repos` requirt es).
  **Sechs Bugs gefunden, keiner gefixt:** `:checkhealth data` meldet auf einer funktionierenden
  Installation zwei Fehler, weil `lib.lua.yaml.encode`/`lib.lua.xml.encode` aufrufbare Tables
  sind (`__call`), health aber auf `type(...) == "function"` gated — data.nvims eigener Bug,
  gleiche Ursache wie ein Fund in buffer-ctx.nvim. `:YAML` über einen leeren Scope löscht ihn
  still. Ein UTF-8-BOM wird nirgends gestrippt — YAML klebt ihn an den ersten Key und meldet
  Erfolg. Ein leeres JSON-*Objekt* wird als leeres *Array* zurückgeschrieben
  (`lib.lua.json.encode`); die bestehende Round-Trip-Fixture lief blind daran vorbei, weil
  `assert.same` Metatables ignoriert. Zeilenweises Ersetzen des Scopes während des
  Filter-Prompts invertiert den Extmark → "'start' is higher than 'end'", Filterergebnis
  verloren. Ein tab-eingerückter YAML-Child wird still auf die Dokumentwurzel befördert.
  Positiv gepinnt: `health.lua`s "Dependency fehlt"-Arme rufen **nicht** in die fehlende
  Dependency hinein — mit allen acht Deps gleichzeitig abwesend durchgefahren.
  `TESTS/README.md` neu angelegt (gab es nicht).
  Commit: `a64c208`.
  **Noch am selben Tag, separate Sitzungen**: ein CI-/Testinfra-Fix (Commit `3046062`:
  `luacheck` schließt installierte Deps jetzt aus, `test.sh`s Exec-Bit wiederhergestellt),
  eine Testflakiness behoben (Commit `e613be5`: Bare-Flag-Tests nahmen fälschlich an,
  `vim.fn.has('clipboard') == 1` gelte immer), und ein neuer, in Review gefundener Bug
  gefixt (Commit `9937f5c`): `register.write()` behandelte `setreg`s Ausbleiben eines Wurfs
  als Beweis für einen erfolgreichen Schreibvorgang, aber `setreg("+"/"*", ...)` wirft nie
  bei fehlendem Clipboard-Provider -- es tut einfach nichts. Betrifft nur `+`/`*` (jedes
  andere Register hält immer, was zuletzt gesetzt wurde), jetzt mit echtem Round-Trip-Check.
  **Re-Audit (Runde 23, 2026-09-18):** ein sehr frischer Fall -- Runde 23 selbst und alle
  drei obigen Fix-Commits waren alle vom selben Tag. Alle sechs ursprünglich gepinnten
  Bugs (Health-`__call`-False-Positive, YAML-löscht-leeren-Scope, BOM-Handling, leeres
  JSON-Objekt-Roundtrip, Extmark-Inversion, tab-eingerückter YAML-Child) explizit gegen den
  aktuellen Quellcode nachgeprüft: alle sechs weiterhin vorhanden und korrekt gepinnt,
  keiner stillschweigend gefixt. Die vier Bug-Familien einzeln durchgeprüft: `health.lua`
  gated jeden Dependency-Zweig schon korrekt (mit allen acht Deps gleichzeitig abwesend
  gegengeprüft); keine Augroups im ganzen Repo (`bindings/autocmds.lua` ein bewusster
  No-op-Stub); keine Byte/Spalten-Verwechslung (nur zeilenbasierte Positionslogik, die eine
  echte Subtilität dabei ist schon Bug 5 oben); kein Dateisystem-I/O, also keine
  Windows-Pfad-Angriffsfläche (per Grep bestätigt: kein `readfile`/`writefile`/
  `fnamemodify`/Pfadtrenner im ganzen `lua/`-Baum). Keine neuen Bugs, keine geschlossene
  Lücke -- ehrlich nichts zu tun, keine Busywork erfunden.
  Testlauf: 29 Spec-Dateien, 496/496 weiterhin grün über zwei von mir persönlich
  nachgefahrene Wiederholungsläufe. `luacheck .` (52 Dateien) und `stylua --check .` beide
  grün. Kein neuer Commit -- `HEAD` war schon `origin/main`s Tip.
- [x] **spotlight.nvim** — fertig (Runde 24). Audit wie bei diff.nvim (Runde 20): schichtweise
  ungleich, die reinen Layer gut, `core/match.lua` (das Ledger, auf dem die
  `matchadd()`-Entscheidung ruht), `bindings/autocmds.lua`, `health.lua`, `ui/list.lua`,
  `integrations/menu.lua` und der Persistenz-Store-Round-Trip komplett ungetestet, **kein
  einziges Mehrbyte-Byte** in der ganzen Suite. 17 → 29 Spec-Dateien, 472 → 1159 Assertionen,
  4 Läufe (davon einer in umgekehrter Reihenfolge) stabil, beide Gates grün über 59 Dateien.
  Kein `lua/`-Quelltext angefasst.
  **Fünf Bugs gefunden, keiner gefixt.** Der schwerste, und genau das vom Auftrag benannte
  Muster: `cursor.selection` schneidet eine Mehrbyte-Selektion mitten im Codepoint ab
  (`col('.')` ist das erste Byte des Zeichens) — ein markiertes `Ä`/`日`/`🚀` liefert 1 Byte,
  nichts leuchtet je auf, verschiedene Glyphen mit gleichem Lead-Byte kollabieren auf denselben
  Text. `health.check()`s letzte Anweisung ruft unbedingt in die Dependency, die sie gerade als
  fehlend gemeldet hat — **das vierte Repo mit diesem Muster** (nach emojis/gopath/diff).
  `ui.list.filter` findet einen Spotlight ohne `origin` nicht über seinen eigenen Text
  (`ipairs` bricht am ersten `nil`-Feld ab). Die gemergte Options-Tabelle teilt ihre Sub-Tables
  mit `DEFAULTS`, obwohl dessen Kommentar "Never mutate it at runtime" sagt (gleiche Familie
  wie replacer.nvim, Runde 10, nur auf der Schreibseite). `integrations/menu.lua` schreibt
  Padding ins Label statt `opts.icon` zu nutzen, gegen den expliziten Vertrag von
  `ui.contextmenu.entry`.
  Positiv gepinnt: `\%Nc` ist korrekt eine Byte-Spalte (verifiziert inkl. Negativfall: Zeichen-
  und Display-Spalte des gleichen Tokens dürfen NICHT matchen); ein voller Render-Durchlauf
  ruft `nvim_set_hl` null Mal; kein E937 über alle vier Teardown-Wege; zweites `setup()`
  idempotent (`augroup.create.clear` löst über eine id auf, nicht den Namen — der
  pdfport.nvim-Fehler existiert hier nicht).
  Commit: `5931a55`.
  **Re-Audit (Runde 24, 2026-09-18):** kein Diff seit Runde 24. Alle fünf gepinnten Bugs
  (Mehrbyte-Selektionsabschnitt, `health.lua`s viertes Instance-Muster, `ui.list.filter`s
  `ipairs`-Abbruch, geteilte `DEFAULTS`-Sub-Tables, `menu.lua`s Padding-statt-`icon`) im
  aktuellen Quellcode bestätigt weiterhin vorhanden und korrekt gepinnt. Augroup-
  Idempotenz, Windows-Pfadbehandlung (case-insensitiver Präfixvergleich auf normalisierten
  Pfaden, kein Colon-Split) und die `ui.nvim`-Auslassung (echter Sibling-Checkout, aber
  bewusst wegen "braucht echtes Backend" ausgeklammert, nicht wegen Nichtverfügbarkeit)
  jeweils erneut geprüft, alle korrekt. **Eine echte Lücke gefunden und geschlossen**:
  `hover.lua`s Positions-Callback hat drei Zweige auf `core.count.count()`s Ergebnis --
  ok, `nil` (über der Zähl-Obergrenze), `pcall`-Fehlschlag -- `hover_spec.lua` prüfte nur
  den ersten, obwohl `TESTS/README.md` fälschlich schon vollständige Obergrenzen-Coverage
  behauptete. **Ein echter Test-Suite-Bug gefunden und gefixt**: die README behauptet, die
  Suite laufe "in der aufgelisteten Reihenfolge und in umgekehrter" -- beim tatsächlichen
  Verifizieren mit umgekehrter `SPECS`-Reihenfolge brach `qf_all_spec.lua` (`expected 3,
  got 4`). Ursache: `autocmds_spec.lua`s `teardown_case(":q on a split (buffer stays
  loaded)", ...)` lässt seinen Buffer absichtlich geladen, um zu beweisen, dass `:q` einen
  Pin nicht invalidiert -- korrekt --, wischt ihn danach aber nie weg, anders als jeder
  Schwesterfall. Der übrig gebliebene Buffer überlebte die Spec und blies jeden späteren
  buffer-weiten Scan um eins auf. Gefixt: `teardown_case` gibt jetzt die Buffernummer
  zurück, damit dieser eine Fall sie explizit per `bwipeout!` entfernen kann.
  Testlauf: 1159 → 1166 Assertionen (29 Spec-Dateien, unverändert -- nur zwei bestehende
  Dateien editiert), über vier Läufe stabil (davon einer erneut in umgekehrter
  Reihenfolge, die den Fix tatsächlich bestätigt) plus zwei von mir persönlich
  nachgefahrene Standardläufe. `luacheck lua plugin TESTS` (59 Dateien) und
  `stylua --check lua plugin TESTS` beide grün.
  Commit: `1928336`.
- [x] **mdview.nvim** — fertig (Runde 25). Audit: ganze Verzeichnisse ohne Coverage
  (`adapter/browser/*`, `adapter/{control,detached,install,log,preview_tab}.lua`, 17 von 19
  `bindings/usrcmds/*`-Actions, der komplette `bindings/usrcmds/start/*`-Baum,
  `core/{events,session}.lua`, `utils/{diff,diff_granular}.lua`), während die
  Live-Session-Kernlogik solide war. 19 → 30 Spec-Dateien, headless-nvim-Harness 120 → 239
  grüne Checks, busted-Suite 8 → 13 (busted lokal nicht installierbar, stattdessen über
  plenarys gebündeltes luassert/busted-Engine real ausgeführt — dieselbe Assertion-Semantik
  wie das echte CI-Kommando). `luacheck lua/mdview --no-color` (genauer CI-Befehl) 0/0 über
  81 Dateien, `stylua --check lua TESTS` clean.
  **Drei Bugs gefunden, keiner gefixt** (alle in bewusst totem Code: `utils/diff_granular.lua`,
  laut eigenem Docstring "buggy Myers attempt that dropped real changes", dessen einziger
  Aufrufer `core/events.lua` laut eigenem Docstring dormant/durch `live_push.lua` abgelöst ist):
  der Myers-Backtrace liefert bei einer gleich langen Zeilen-Ersetzung null Edits statt eines
  falschen — der Change wird komplett verschluckt; direkte Folge, `push_buffer(bufnr, false)`
  sendet dann gar nichts; und wenn `diff_granular` doch einen Edit liefert (Insert/Append),
  extrahiert `push_buffer` den falschen Chunk (`d.count` statt der echten `d.lines`-Länge).
  Ein Fix würde `core/events.lua` auf `utils/line_diff.lua` umstellen — eine Architekturänderung
  an ungenutztem Code, bewusst nur gepinnt.
  **Ein trivialer Bug direkt gefixt** (kein Coverage-Fund, sondern beim Dokumentieren
  aufgefallen): `package.json`s `test:lua`/`test:lua:nvim`-Skripte zeigten auf `tests/lua`
  (klein) statt `TESTS/` (groß) — auf einem case-sensitiven Filesystem wären beide lokal ins
  Leere gelaufen. Zwei Zeilen korrigiert.
  Commit: `166904e`.
  **Mittlerweile gefixt** (separate Sitzung, Commit `cbebc48`): `start/server/launcher.lua`s
  `has_display()` gab `nil` statt `false` zurück, wenn kein Display verfügbar war.
  **Re-Audit (Runde 25, 2026-09-18):** kein weiterer Quelldiff seit Runde 25 außer dem
  Fix oben, bereits korrekt gepinnt und verifiziert. Berichtigung zur eigenen Runde-25-
  Notiz: `busted` **ist** doch lokal installierbar (per `luarocks install busted` unter
  `AppData/Roaming/LuaRocks/bin/busted.bat`, nur nicht auf dem PATH) -- diese Runde lief
  die echte `busted TESTS/lua` genauso wie CI, nicht mehr über plenarys gebündelte Engine
  als Ersatz. Augroup-Idempotenz, Byte/Spalten-Konsistenz und Windows-Colon-Parsing
  (letzteres lebt clientseitig in TypeScript, außerhalb dieses Audits) einzeln erneut
  geprüft, alles korrekt. **Ein Bug gefunden und sofort gefixt** (siebzehntes Repo dieser
  Familie): `health.lua`s `M.check()` degradiert korrekt bei fehlendem lib.nvim, ruft am
  Funktionsende aber ungeschützt erneut in `lib.nvim.bindings.usercmd.composer.checkhealth`
  hinein -- crasht bei jedem lib.nvim, das alt/unvollständig genug ist, um dieses Submodul
  nicht zu haben, und verschluckt jeden vorherigen ok/warn/error desselben Aufrufs. Crash
  reproduziert, dann mit demselben `pcall`-Idiom gefixt, das eine Zeile darüber schon
  steht. **Zwei echte Lücken gefunden und geschlossen**, keine in Runde 25s eigener
  Auslassungsliste erwähnt: `helper/copy_lines.lua`s lib.nvim-Clone-vs-Fallback-Zweig (auf
  dem echten `BufEnter`-Pfad live genutzt); `bindings/usrcmds/init.lua`s `M.attach()`, das
  der Harness nie erreichte, weil `setup()` nie aufgerufen wurde -- `_log_level_routes`
  exponiert (Konvention analog zum bestehenden `_parse_start_args`).
  Testlauf: 30 → 33 Spec-Dateien; nvim-Harness 239 → 247 Checks; busted 13 → 19 Checks;
  über zwei von mir persönlich nachgefahrene Wiederholungsläufe beider Suiten stabil.
  `luacheck lua/mdview --no-color` (81 Dateien) und `stylua --check lua TESTS` beide grün.
  Commit: `59c4a6e`.
- [x] **filetree.nvim** — fertig (Runde 26, 129 Dateien, Gap-Closing nach Risiko-Reihenfolge:
  Fs-Ops/Argv/Fehlerpfade zuerst, dann Bridge-Vertrag zu fileops.nvim, Caching, Buffer/Window-
  Lifecycle, Adapter-Helper). 6 → 7 automatisierte Testdateien (neue `TESTS/gaps.lua`),
  696 → 858 grüne Checks, 2 Wiederholungsläufe stabil, beide Gates grün über 135 Dateien.
  **Ein echter Bug gefunden und sofort gefixt** (trivialer, unzweideutiger Blocker):
  `health.lua`s Composer-Preflight rief am Funktionsende `require(...).checkhealth(...)`
  ungeschützt auf, obwohl dieselbe Funktion weiter oben denselben fehlenden lib.nvim bereits
  saubet meldet — **das fünfte Repo mit dem "Dependency fehlt, ruft sie trotzdem"-Muster**.
  Regressionstest verifiziert (lokal zurückgesetzt → Test schlägt fehl; mit Fix → grün).
  Bewusst noch nicht erreicht, für eine Folgerunde vermerkt: `infra/file_watcher.lua`,
  `nav/{auto_reveal,buffer_cycle,reveal_alt,tree_traverse}.lua`,
  `paths/lua_require_copy.lua`, `search/{filter,live_search}.lua`,
  `ui/{window_style,window_size_cycler,cursor_hide,tree_reset,size_info,preview}.lua`.
  CI-Workflow um `gaps.lua` ergänzt.
  Commit: `811bfed`.
  **Re-Audit/Follow-up (Runde 26, 2026-09-18):** genau die von Runde 26 selbst vertagte
  Liste war diesmal der eigentliche Auftrag, nicht nur Nachprüfung. Repo-weit auch die vier
  Bug-Familien erneut durchgeprüft (alle ~16 Verfügbarkeits-Guard-Stellen plus 118
  `pcall(require, ...)`-Stellen auf das Health-Muster durchsucht -- nichts über den schon
  gefixten Fund hinaus; alle Augroups passen `clear=true`; alle 27 Cursor-/Extmark-
  Aufrufstellen zeilen-weise statt spalten-genau, keine Byte/Display-Verwechslung; keine
  naive Colon-Pfadparsung, `copy_require_relative()` live gegen einen echten
  Backslash-`getcwd()` bestätigt korrekt). Sibling-Checkouts (neo-tree.nvim, nui.nvim,
  plenary.nvim, nvim-web-devicons, telescope.nvim) alle real unter `nvim-data/lazy`
  vorhanden, `adapter_lines.lua` findet sie dort schon -- nichts veraltet.
  **Alle 14 vertagten Dateien mit echten Assertion-Suiten geschlossen** (in `TESTS/gaps.lua`):
  `infra/file_watcher`, `nav/{auto_reveal,buffer_cycle,reveal_alt,tree_traverse}`,
  `paths/lua_require_copy`, `search/{filter,live_search}`,
  `ui/{window_style,window_size_cycler,cursor_hide,tree_reset,size_info,preview}`.
  **Zwei Testfehler gefunden und gefixt** (kein Plugin-Bug): Runde 26s eigener
  `health.lua`-Test sabotiert `lib.nvim.bindings.usercmd.composer` und ruft `health.check()`
  transitiv auf -- vergiftet dabei dauerhaft `package.loaded["filetree"]`/
  `["filetree.commands"]` (Luas "loop or previous error"-Sentinel), falls das der erste
  echte `require("filetree")` im Prozess war, und brach dadurch jeden späteren bloßen
  `require` -- gefixt, indem der Test diese zwei Cache-Einträge beim eigenen Restore mit
  löscht. Und die neue `reveal_alt`-Spec tappte in Vims Leerer-Scratch-Buffer-Wiederverwendungs-
  Falle (`:edit` recycelt die Buffernummer), `window_size_cycler`s Spec versuchte ein
  Fenster zu resizen, das das einzige in seinem Tabpage war (nicht resizebar) -- beide im
  Testcode selbst gefixt.
  Testlauf: repo-weit (smoke+units+menu+cwd_mode+sidebar_guard+gaps+refs) 858 → 945 Checks,
  `gaps.lua` allein 162 → 249, über zwei komplette Wiederholungsläufe stabil (von mir
  persönlich nachgefahren). `stylua --check .` und `luacheck lua docs/BINDINGS.lua TESTS`
  (135 Dateien) beide grün, plus der Vimdoc-Referenz-Konsistenzcheck.
  Commit: `8976113`.
- [x] **lsp.nvim** — fertig (Runde 27, 176 Dateien, letzter Punkt der ursprünglichen
  Warteschlange). 6 neue Spec-Dateien nach Risiko sortiert: `attach_spec.lua` (`core/attach.lua`s
  `on_init`/`on_attach`-Guards und -Effekte), `filter_spec.lua` (die zwei reinen
  Diagnostic-Listen-Helfer unter `core/handlers`), `mason_node_spec.lua` (der npm
  `.bin/<name>.cmd`-Shim-Parser end-to-end gegen einen echten, umgeleiteten `stdpath("data")`,
  inklusive Windows-Only-Gate und Backslash-Normalisierung), `rootresolvers_spec.lua`
  (`lua_ls`s `strict_root_from`-Algorithmus gegen echte Temp-Verzeichnisse: Scope-Switch,
  VCS-vor-Marker-Suchreihenfolge, Neovim-Config-Verzeichnis gewinnt immer; plus `marksman`s
  eigene Marker-Liste und `eslint_prettier`s `find_root`-Unnamed-Buffer-Guard),
  `autocmds_wiring_spec.lua` (der `LspAttach`-Handler für die `gr*`-Default-Kollisionen und
  seine Group-Lifecycle), `usercmds_wiring_spec.lua` (drei zuvor ungetestete `:Lsp*`-Kommando-
  Module: `formatter`, `workspace_diagnostics`, `mobile_diagnostics`).
  **Ein echter Windows-spezifischer Test-Infra-Bug gefunden und gefixt** (kein Plugin-Bug):
  `TESTS/minimal_init.lua`s `fnamemodify(path, ":p")` hängt bei existierenden Verzeichnissen
  einen abschließenden Backslash an; zusammen mit rtp's vorwärtsschrägstrich-basiertem
  `findfile("plugin/plenary.vim", ...)` ergab das unter Windows ein nie aufgelöstes `\/`, sodass
  `PlenaryBustedDirectory`/`PlenaryBustedFile` nie definiert wurden und der Lauf lautlos hing
  statt zu fehlern (auf Linux/CI harmlos, da ein doppelter `/` dort toleriert wird). Fix:
  `vim.fs.normalize()` auf das Ergebnis von `fnamemodify`. Eigener Fund, unabhängig davon aber
  auch von einer parallel arbeitenden Peer-Session im selben Checkout gefunden und bereits
  gefixt — siehe Randnotiz im Abschnitt "Aktueller Stand" oben zum Rebase-Konflikt, der daraus
  entstand.
  Bewusst noch nicht erreicht, für eine Folgerunde vermerkt (Details inkl. Begründung in
  `TESTS/README.md`): die einzelnen `servers/*`-Server-Module (`clangd.lua`, `csharp.lua`,
  `gopls.lua`, `zig.lua`, `webdev/*`, `mobiledev/*` — je ein `vim.lsp.config()`-Aufruf plus
  Capabilities/Root-Wiring, ein generischer Contract-Spec analog zu dap.nvim wäre der nächste
  Schritt); `core/root_scope_picker.lua`/`core/workspace_picker.lua`; die Integrations-Module
  jenseits ihres generisch getesteten Adapter-Contracts; `tools/deprecated_help/**` und
  `tools/lsp_signature`s reine Formatierungshelfer.
  Testlauf: 697 → 729 Checks (die zusätzlichen 32 stammen aus der oben erwähnten Peer-Session,
  die parallel eigene Specs erweitert hat), 0 Fails über alle 51 Spec-Dateien, mehrfach
  wiederholt zur Stabilitätsprüfung. `luacheck lua scripts TESTS` (231 Dateien) und
  `stylua --check` beide grün.
  Commit: `30e3e6a`.
- [ ] restliche Plugins — noch nicht begonnen, siehe Tabelle oben.

## Bug/Security/Performance-Review der Kampagne selbst (2026-09-18)

Auf Nutzerwunsch ("checke nochmal das implementierte auf bugs, security oder
performance optimierungen") ein separater Durchgang, keine neue Runde: sechs
parallele Review-Agenten haben die tatsächlichen Quellcode-Änderungen dieser
Kampagne (nicht die Test-Coverage selbst) geprüft — lib.nvim/github_stats.nvim
(Credential-Fix, split_lines/export, E937), insights.nvim (Windows-Pfad- und
Tree-sitter-Fixes), fileops.nvim (delete_fn, on_hold.lua), gopath.nvim
(linepath.lua), cascade.nvim (renumber/cycle) und die übrigen `health.lua`-
Fixes plus Test-Infra-Fixes. Jeder Fund wurde von mir selbst nachverifiziert
(nie ungeprüft übernommen).

**Vier neue echte Bugs gefunden, drei gefixt, einer gepinnt:**
1. **github_stats.nvim** (`680adb8`): `create_pdf()` verschluckte den Fehler
   von `ensure_parent_dir()` -- derselbe Bug, den mein eigener früherer Fix
   (`6a85943`) für `write_lines()` behoben hatte, aber am analogen zweiten
   Call-Site übersehen. Gefixt, Regressionstest verifiziert am zurückgesetzten
   Code.
2. **debugging.nvim** (`50afa0b`): `health.lua` requirte `lib.nvim.health` auf
   Modulebene, komplett ungeschützt -- ein fehlendes/veraltetes lib.nvim hätte
   `require("debugging.health")` selbst crashen lassen, noch vor jedem
   `:checkhealth`-Abschnitt. Der bereits gefixte `pcall`-Guard am Funktionsende
   (`5bdd781`) wäre nie erreicht worden. Fix: Require in `M.check()` verschoben,
   mit Fallback-Kopie des Helfers (der historisch ohnehin lokal in dieser Datei
   lag, bevor er nach lib.nvim extrahiert wurde).
3. **insights.nvim** (`9c6be5e`, `27744f7`): drei Funde in einer Runde --
   `M.foo = function() end` wurde unter dem bloßen Feldnamen "foo" statt der
   vollen "M.foo" gemeldet (Kollisionsrisiko zwischen unabhängigen Dateien);
   Mehrfachzuweisungen (`local a, b = 1, function() end`) prüften nur den
   ersten Wert, jeder weitere wurde nie inspiziert; die Windows-Regex-Escape-
   Menge für `tree/init.lua`s Exclude-Globs deckte `{`/`}`/`|`/`\` nicht ab --
   ein Backslash-geschriebener Exclude ließ `-match` mit "Unrecognized escape
   sequence" komplett durchfallen. Beim Schreiben des Regressionstests für
   Letzteres zusätzlich ein unabhängiger Test-Isolations-Bug gefunden:
   `compress_tree_spec.lua`s Restore-Schleife lief über `pairs(saved)`, aber
   `saved[name] = nil` erzeugt in Lua keinen Tabellen-Eintrag -- jedes Modul,
   das vor diesem Test noch nicht geladen war, wurde nie zurückgesetzt und
   blieb für den Rest des Prozesses auf dem Fake-Stub hängen. Alle vier
   gefixt, jeweils gegen zurückgesetzten Code verifiziert.
4. **cascade.nvim** (ursprünglich gepinnt in `3f91d2d`): die
   Roman-vor-Ascii-Reihenfolge (mein eigener Fix aus `c23ea33`, nötig damit
   der Cycle-Ring schließt) lässt `marker.parse` sieben Buchstaben (c/d/i/l/m/
   v/x) fälschlich als römische Ziffern lesen -- eine ganz normale
   `a) b) c) d)`-Liste wird ab dem dritten Punkt bei jedem Renumber (Save,
   `:Cascade renumber`, Move) lautlos korrumpiert (`c)` → `iii)`). Live über
   die echte `renumber.tree()`-Fassade reproduziert, nicht nur am isolierten
   Parser. Ursprünglich gepinnt statt gefixt, weil ein echter Fix block-weite
   Kind-Konsistenz-Verfolgung braucht (kein mechanischer Ein-Zeilen-Fix) und
   ein Zurückdrehen der Reihenfolge stattdessen den bereits gepinnten
   Ring-Schluss-Fall gebrochen hätte -- ausdrücklich nicht selbst entschieden.
   **Auf ausdrücklichen Nutzerwunsch danach doch gefixt** (Commit `0865850`):
   `marker.parse` bekommt einen neuen optionalen dritten Parameter
   `prefer_kind`, der vor `types`' eigener Reihenfolge probiert wird und für
   jeden anderen Aufrufer (Cycle, Facade-Kommandos) unverändert bleibt, da
   niemand sonst ihn übergibt. `renumber.tree` bekommt eine neue
   `kind_by_width`-Tabelle (Schwester von `counters`), die sich pro
   Einzugsbreite merkt, welche Art diese Liste bisher tatsächlich benutzt hat,
   und reicht sie als `prefer_kind` an jede weitere Zeile derselben Breite
   zurück -- invalidiert genau wie `counters` bei einem echten Bruch und beim
   Schließen einer tieferen Ebene. Drei Testfälle in `TESTS/lists_spec.lua`:
   der Kollisionsfall erwartet jetzt das korrekte Verhalten, ein neuer Fall
   bestätigt, dass eine echt römische Liste ("i) ii) iii)") ohne vorherigen
   Ascii-Kontext weiterhin korrekt als römisch startet, und ein dritter
   bestätigt, dass eine tiefere Ebene beim Schließen ihre Art-Erinnerung
   korrekt verliert, statt sie an einen späteren, unabhängigen Lauf an
   derselben Breite weiterzugeben. Gegen zurückgesetzten Code verifiziert
   (Pin-Test schlägt exakt mit der alten Korruption fehl); der volle
   Marker-/Renumber-/Cycle-Spec-Teilsatz läuft über mehrere Wiederholungen
   stabil (der komplette Suite-Lauf traf zwischenzeitlich auf ein
   unabhängiges, vorbestehendes `E326: Too many swap files`-Problem dieser
   sehr langen Sitzung -- durch Aufräumen von `nvim-data/swap/` behoben,
   betraf sieben unzusammenhängende Spec-Dateien, nicht diesen Fix).

**Sonst nichts gefunden**: lib.nvim (bis auf die bereits bekannte, nicht neu
behobene Vermischung mit einem unabhängigen winhighlight-Commit im selben
Push), fileops.nvim und gopath.nvim kamen aus ihren jeweiligen Reviews clean
heraus -- explizit auf Shell-Injection, Config-Frische, UTF-8-Grenzfälle und
Performance geprüft, nichts gefunden.

## Gezielter Check der neun 🟢-Repos (ab 2026-09-18)

Auf Nutzerwunsch: die neun Repos, die laut ursprünglicher Vorgabe keine volle
Runde bekommen "außer eine konkrete Prüfung findet doch eine Lücke" --
images.nvim, ai.nvim, hover.nvim, runtime-analysis.nvim, lib.nvim,
markdown.nvim, documentation.nvim, media.nvim, ui.nvim. Das war bisher nur
eine grobe Datei-Anzahl-Schätzung, nie ein echter Audit. runtime-analysis.nvim
wurde zunächst ausgelassen, weil eine aktive Peer-Session mit passendem Namen
("runtime-analysis.nvim startup profiler") parallel lief -- Konfliktvermeidung,
kein inhaltlicher Grund.

- [x] **images.nvim** — echter erster Audit, kein Nachweis-Stempel. Framework-
  freier `H.eq`/`H.ok`/`H.falsy`/`H.contains`-Harness + `TESTS/run.lua`, 27
  bereits substanzielle Specs (keine reinen Load-Smoke-Tests) bestätigt. 27 →
  33 Specs. **Ein echter Bug gefunden und gefixt**: `compare.lua`s `M.open`
  rief `require("ui.kit").compare(...)` ungeschützt auf, anders als jeder
  andere ui.kit-Pfad im Plugin (`init.lua`s `kit()`, `browse.lua`s
  `open_select`), die alle sauber degradieren -- `docs/installation.md`
  dokumentiert ui.nvim durchgehend als optional mit `vim.ui.select`-Fallback,
  aber `:Image compare` crashte stattdessen mit einem rohen "module 'ui.kit'
  not found". Crash reproduziert, dann gefixt (pcall + Notify, passend zur
  bestehenden Konvention), Regressionstest gegen zurückgesetzten Code
  verifiziert. Eine überzogene Doc-Zeile nebenbei korrigiert. Fünf echte
  Coverage-Lücken geschlossen (`cell.lua`, `scan.lua`, `guard.lua`,
  `integrations/menu.lua`, `ascii.lua`). Vier Bug-Familien geprüft, sauber
  (Augroups nutzen durchgehend `clear=true`, keine Byte/Spalten-Verwechslung,
  Windows-Pfadbehandlung empirisch bestätigt). `TESTS/README.md` neu angelegt.
  Testlauf: 33 Specs, über zwei von mir persönlich nachgefahrene
  Wiederholungsläufe stabil. `stylua --check` und `luacheck` (explizite
  Dateiliste statt Verzeichnisform -- Letztere ist auf dieser Maschine defekt,
  ein lokales Umgebungsproblem, kein echter Fund) beide grün über 75 Dateien.
  Commit: `bdc1b11`.
- [x] **ai.nvim** — echter erster Audit. Plenary/busted-Suite (anders als die
  meisten anderen Repos dieser Kampagne), über `scripts/test.sh`. 11
  Spec-Dateien / 132 Tests bereits solide bestätigt (`attachments.lua`,
  `config/init.lua`, `context/*`, `completion/prompt.lua`, die
  Provider-Registry, `providers/transport.lua`/`util.lua`/`sse.lua`, die
  `claude`/`gemini`-Provider). **Fünf echte Lücken geschlossen**: drei der
  fünf eingebauten Provider (`ollama.lua`, `openai.lua`, `loomai.lua`) hatten
  trotz gründlicher `claude`/`gemini`-Coverage null Specs; `ui/panel.lua`s
  echte Zustandsmaschine (Delta-Akkumulation, idempotentes Cancel,
  Snapshot-basiertes `cancel_all`); `ui/ghost.lua` (reine `vim.api`-Extmarks,
  brauchte gar kein Stubbing); `completion/context.lua`s cursor-relative
  Prefix/Suffix-Extraktion; `completion/init.lua`s `trigger()`/`accept()` --
  nur das Debounce-Wiring war vorher getestet, nicht die vier
  Stale-Response-Guards oder die Mehrzeilen-Einfüge-Mathematik. Keine Bugs
  gefunden -- alle vier Bug-Familien geprüft (Augroups korrekt, keine
  Byte/Spalten-Verwechslung, kein manuelles Pfad-Parsing im ganzen Repo,
  daher (d) nicht anwendbar).
  Testlauf: 132 → 225 Tests, 11 → 18 Spec-Dateien, über zwei von mir
  persönlich nachgefahrene Wiederholungsläufe stabil. `luacheck lua plugin
  TESTS` (47 Dateien) und `stylua --check` beide grün.
  Commit: `a55a0fd`.
- [x] **hover.nvim** — echter erster Audit, über `scripts/test.sh`
  (Plenary/busted). 19 Spec-Dateien / 474 Assertions bereits solide bestätigt.
  **Sieben echte Lücken geschlossen**: `classify.lua`, `bare_url.lua`,
  `health.lua`, `preview/binary.lua`, `preview/git.lua`, `preview/office.lua`,
  `preview/monitor.lua` hatten null direkte Coverage. Keine Bugs gefunden --
  alle vier wiederkehrenden Bug-Familien geprüft und sauber (Augroups korrekt
  mit `clear=true`, keine Byte/Spalten-Verwechslung, kein unguardeter
  Require-Crash in `health.lua`, Windows-Pfadbehandlung bereits robust).
  Testlauf: 19 → 26 Spec-Dateien, 474 → 572 Assertions, von mir persönlich
  zweimal nachgefahren (`LIB_NVIM_DIR="../lib.nvim" UI_NVIM_DIR="../ui.nvim"
  PLENARY_DIR=".../plenary.nvim" bash scripts/test.sh`) -- beide Male
  572/0/0 über alle 26 "Testing:"-Blöcke. `luacheck lua plugin` (41 Dateien)
  und `stylua --check .` beide grün.
  Commit: `53797f4`.
- [x] **documentation.nvim** — echter erster Audit, über `scripts/ci.sh`
  (eigener Framework-freier `TESTS/harness.lua`/`TESTS/run.lua`, kein
  Plenary/Busted). 100 bereits reife Specs bestätigt, 4-Job-CI (stylua,
  luacheck, tests, map) mit einer ungewöhnlich gut dokumentierten
  Bug-Historie im eigenen Code. **Eine echte Lücke geschlossen**: die
  `:DocMap`-Kommando-Dispatch-Schicht (`lua/documentation/bindings/usrcmds/*.lua`,
  ~17 Dateien -- Usage-Fehler, Kollisionserkennung, Sortierung,
  Buffer-Reuse, Git-Subprozess-Fehler/Timeout/Leerergebnis) hatte trotz
  gründlich getesteter Kern-Algorithmen eine Ebene darunter (`core/churn.rank`,
  `core/diff.compare`, `core/deps.path` usw.) null direkte Coverage. Zwei neue
  Specs nach den Repo-eigenen Konventionen (`usrcmds_readonly_spec.lua` mit
  literalen `Documentation.IR`-Fixtures, `usrcmds_git_spec.lua` mit echten
  Wegwerf-`git init`-Fixtures statt gestubbtem `vim.system`) -- pinnt dabei
  auch eine Buffer-Namenskollisions-Regression in `dot.lua`/`mermaid.lua`, die
  einmal gefixt, aber nie durch einen Test abgesichert war. Keine Bugs
  gefunden -- alle vier Bug-Familien geprüft und sauber (health.lua-Degradation
  korrekt, Augroups mit `clear=true` + Idempotenz-Guard, keine
  Byte/Spalten-Verwechslung, Windows-Pfadbehandlung hat eigenen
  Regressionstest).
  Testlauf: 100 → 102 Specs, von mir persönlich zweimal über `scripts/ci.sh
  tests` nachgefahren -- beide Male `DOCUMENTATION_TESTS_OK`, alle Specs
  grün. `scripts/ci.sh luacheck` (254 Dateien) und `stylua --check .` beide
  grün.
  Commit: `9ed7c11`.
- [x] **markdown.nvim** — echter erster Audit, über den framework-freien
  `TESTS/harness.lua`/`TESTS/run.lua` (32 bereits substanzielle Specs, echte
  Multi-Byte-Regression in `tableview_alignment_spec.lua`, `lib.nvim`/
  `hover.nvim` als echte Sibling-Checkouts in CI und lokal). **Vier echte
  Bugs gefunden und gefixt**, alle trivial/ohne Risiko, alle gegen
  zurückgesetzten Code reproduziert: (1) `health.lua` meldete "lib.nvim not
  found" und requirte das fehlende Modul danach trotzdem ungeschützt weiter
  -- crashte `:checkhealth markdown` direkt nach der Warnung, die genau das
  erklärt (identischer Fund wie zuvor in `color_my_ascii.nvim`, hier gespiegelt
  gefixt); (2) `scope/init.lua`s Fold-Cache-Augroup lief über einen
  namens-gecachten Wrapper ohne `clear=true` -- empirisch bestätigt: 3
  Modul-Reloads hinterließen 6 statt 2 lebende Autocmds; (3)
  `underline_headings.lua` bemaß die Setext-Unterstreichung über `#text`
  (Byte-Länge) statt Display-Breite -- "Über uns" (8 Spalten, 9 Bytes) bekam
  9 Zeichen Unterstrich; (4) `fold_prev.lua` (beiläufig beim
  Coverage-Schreiben gefunden) matchte nur `-`-unterstrichene Setext-
  Überschriften, nie `=` (im Widerspruch zum eigenen Doc-Kommentar), und die
  Suchschleifen-Untergrenze machte eine Setext-Überschrift auf den ersten
  zwei Pufferzeilen unerreichbar. Windows-Pfadbehandlung (`util/path.lua`)
  gezielt geprüft -- bereits gut gehärtet, kein Fund. Neun neue Specs,
  ~136 neue Assertions, u.a. ein echter Integrations-Vertragstest gegen den
  echten `color_my_ascii.nvim`-Sibling (vorher nur der eingebaute
  Fallback-Scanner getestet) und Regressionscoverage für den kürzlich
  gelandeten `clipboard.lua`-Rückgabewert-Fix.
  Testlauf: 32 → 41 Specs, von mir persönlich zweimal über `nvim --headless
  -i NONE -u NONE -c "set rtp+=." -c "luafile TESTS/run.lua" -c "qa!"`
  nachgefahren -- beide Male `MARKDOWN_TESTS_OK`. `luacheck lua` (exakter
  CI-Befehl, 81 Dateien) 0/0, `stylua --check .` grün.
  Commit: `9fe8537`.
- [x] **lib.nvim** — echter erster Audit der Basis-Lib als geteilte
  Abhängigkeit (vorher nur per Datei-Anzahl-Verhältnis eingeschätzt).
  Breadth-first, priorisiert nach Credential-Handling, Autocmd/Health-Helpern
  und Windows-Pfadkorrektheit -- exakt die wiederkehrenden Bug-Familien
  dieser Kampagne. **Zwei echte Bugs gefunden und gefixt** (beide gegen
  zurückgesetzten Code reproduziert): (1) `lib.nvim.autocmd.group()`/
  `get_augroup()` und `lib.nvim.bindings.autocmd.get_augroup()` übersprangen
  das erneute Clearen eines schon gecachten Augroups bei einem zweiten Aufruf
  mit `clear=true` -- **das ist die Root Cause von Bug-Familie (b) selbst**,
  nicht nur eine Fehlnutzung in den abhängigen Repos. Das Zwillingsmodul
  `lib.nvim.bindings.autocmd.group()` war dafür bereits gefixt, die anderen
  drei Call-Sites nicht; `lib.nvim.telemetry`s eigener Quelltext trägt sogar
  einen Kommentar, der genau diesen Fehler als Grund nennt, warum es
  `autocmd.group()` umgeht -- bekannt, lokal umschifft, nie an der Quelle
  gefixt. (2) `lib.nvim.fs.relpath` verglich Windows-Laufwerksbuchstaben
  case-sensitiv (`c:` vs `C:` als "kein gemeinsames Root" gelesen) und fiel
  auf den absoluten statt den relativen Pfad zurück -- **Bug-Familie (d)**,
  gefixt über denselben `drive_upper`-Helfer, den `normkey` dafür schon
  nutzt. **Architektur-Fund geflaggt, bewusst nicht gefixt**:
  `bindings/init.lua`s Kopfkommentar behauptete fälschlich, `map`/`usercmd`/
  `autocmd` seien "gone" -- alle drei existieren als volle Parallelbäume und
  werden von `telemetry` noch direkt requiret; genau diese Duplikation ist,
  warum der Augroup-Fix zwischen den Kopien divergierte. Kommentar korrigiert,
  Migrationsentscheidung als Folgeaufgabe an den Maintainer delegiert.
  **Neue, undokumentierte Credential-Lücke gepinnt** (nicht gefixt -- braucht
  eine API-Shape-Entscheidung): `curl.lua`s `opts.query` landet direkt im
  URL-Argv statt über den `-K`-Credential-Pfad wie Header/`bearer_token`/
  `auth` -- ein Token als `?api_key=...` leakt genau wie der ursprüngliche
  PRIVATE-TOKEN-Bug. In README + Moduldoku dokumentiert, mit `BUG:`-markierter
  Regression (`vim.system`-Monkeypatch) gepinnt. Nebenbei geprüft: der
  versehentlich mitgebundelte `winhighlight`-Change aus dem PRIVATE-TOKEN-Fix
  (`5c6b1ac`) ist korrekt und war bereits durch echte Assertion-Tests gedeckt
  -- kein Nachbesserungsbedarf. `lib.health`/`lib.nvim.health`/
  `lib.nvim.deps.health`/`usercmd.composer.check` gegen Bug-Familie (a)
  geprüft -- alle korrekt gegen fehlende Abhängigkeiten abgesichert, die
  Root-Cause für die 17+ Funde dieses Musters in abhängigen Repos liegt nicht
  in lib.nvim selbst. `TESTS/README.md` gegen die tatsächliche Spec-Liste in
  `TESTS/run.lua` abgeglichen (rund drei Dutzend Specs hatten gar keine
  Zeile).
  Testlauf: 58 → 60 Specs, von mir persönlich zweimal über `nvim --headless
  -u NONE -l TESTS/run.lua` nachgefahren -- beide Male `LIB_TESTS_OK`.
  `luacheck lua TESTS` (exakter CI-Befehl, 402 Dateien) 0/0, `stylua --check
  .` grün.
  Commit: `f3725e8`.
