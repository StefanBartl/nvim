Stand 2026-10-17, spät. Das ausführliche Handover liegt im Vault (`tasks-vault/lib.nvim/handovers/session-stand-2026-10-15_HANDOVER.md`, wird von einem anderen Chat weitergeführt); der Symlink in `docs/ROADMAP/handovers` zeigt darauf. Diese Datei hält nur, was den Nutzer braucht, und die Commit-Liste des ganzen Chats.

**Warum noch nicht im Backlog:** Die unten genannten Tasks sind im Vault noch offen, und sie brauchen alle den Nutzer, ein Konto oder einen Anlass (keine davon kann ein Agent allein abschließen). Erst wenn keine davon mehr offen ist, wandern beide Handover nach `tasks-vault/lib.nvim/handovers/ERLEDIGT/` und der Symlink `docs/ROADMAP/handovers/session-stand-2026-10-15_HANDOVER.md` wird aus der nvim-config entfernt. Prüfen: die IDs dieser Datei gegen `list --status=open,doing,blocked,decision --format=ids` abgleichen.

## Läuft gerade

- Nichts. Kein Agent läuft.

## Offen, braucht den Nutzer

Entscheidungen (status=decision bzw. actor=me/pair):

- `lib.nvim/entscheidungen-review-reste-von-contract-fs-und-json`: zehn Fragen mit Optionen, Empfehlung und einer Zeile "Entscheidung:". Blockiert `lib.nvim/review-reste-der-contract-fs-json-module-entscheidungen-und`.
- `replacer.nvim/hooks-on-rejects-a-non-function-at-registration-document-and`: `hooks.on` wirft bei Nicht-Funktionen schon bei der Registrierung. Empfehlung: so lassen, dokumentieren, festhalten.
- `lsp.nvim/k10-load-budget-decision` (neu): Ladezeit 41,5 ms bei Budget 40 ms. Empfehlung: eigenes Budget 60 ms in `.testing.lua`.
- `testing.nvim/d8-process-net-default-decision` (neu): `process_net` standardmäßig auf `warn`? Empfehlung: ja.
- `testing.nvim/d8-workspace-trust-decision` (neu): Herkunft der Trust-Liste und Verhalten in CI. Empfehlung: Trust-Speicher plus `trust.roots`, `CI=true` gilt als Trust. Danach baut `testing.nvim/d8-workspace-trust-build` `--trust`.
- `runtime-analysis.nvim/persistent-data-panel`: zweiten echten Fall benennen oder verwerfen.
- `docmap-desktop/rules-api-catalog-and-run`: klären, ob es mit der rules.nvim-Arbeit kollidiert.
- `documentation.nvim/repo-named-paths-outside-root`: Sicherheitsentscheidung.
- `testing.nvim/cache-affected-remaining-limits`: zwei Entscheidungen (Lese-Ledger, State-Warn bei `soft`).
- `hover.nvim/hover-zoom-mit-dem-mausrad-navigieren-im-zoom-mit-gehaltenem` (actor=pair): Tasten bestätigen.
- Sternentscheidung: `ALL/decide-whether-a-review-at-reasoning-level-high-earns-the-st`.

Handchecks und Konten:

- `lsp.nvim/gx-on-an-env-link-in-a-real-neovim-0-12-session-hand-check`, `lsp.nvim/live-check-lspsaga-replacements`, `ui.nvim/try-the-ui-option-float-in-a-real-session`, `gitsuite.nvim/live-test-checklist`.
- `rules.nvim/rules-vault-erster-gruener-ci-lauf-github-startet-die-jobs-n`: GitHub-Billing.
- `ai.nvim/completion-thinking-tokens-gegen-max-tokens-512-live-messen` und `language.nvim/translate-markdown-deepl-mit-echtem-schluessel-messen-platzh`: brauchen echte API-Schlüssel.

Sonst:

- Fremde, nicht committete Änderung in `tasks.nvim/lua/tasks_nvim/links.lua` (seit 16.10., 22:07): doppelter Kommentarblock, `"\0"`-Trenner ersetzt, Bedingung `#names > 1` entfernt. Sieht nach liegengebliebener Sabotage einer anderen Sitzung aus; nicht angefasst.
- `wkdbook-tasks.nvim/import-from-rules-and-bootstrap` steht auf `blocked`, obwohl der Blocker erledigt ist (fremder Befund, sollte auf `open`).
- Board-Taste während eines Schreibvorgangs: entschieden und gebaut als "ablehnen mit Meldung" (tasks-desktop `f309087`), bewusst nicht gepuffert. Umstellbar in `App.refusedWhileSaving()`.

## Offen, aber nicht von diesem Chat abschließbar

- `lib.nvim/test-suite-einmaliger-unreproduzierbarer-spec-fehler-flake-i`: wartet auf ein neues Auftreten (FAIL-Zeile sichern).
- `testing.nvim/ui-explorer-actions` und `testing.nvim/explorer-g-cheatsheet-and-footer-via-lib-nvim-keymap-cheatsh`: blockiert.
- `terminal.nvim/release-docs` und `testing.nvim/m1-fleet-parity`: `doing` in anderen Sitzungen.

## Offen für cdx (neue Folge-Tasks)

- `lib.nvim/migrate-lib-nvim-s-own-deprecated-calls-found-by-dev-depreca` (XS): drei eigene veraltete Aufrufe, die der neue Scanner fand (Kit-Datei mit Spiegel in ui.nvim).
- `markdown.nvim/core-slug-count-headings-inside-block-quotes-and-list-items` (bug, S).
- `testing.nvim/d8-artifacts-names-and-placeholders` (nach m6).
- 16 UI-05-Tasks aus dem Confirm-Sweep (Tag `interactive-confirm-sweep`), z.B. `ALL/tasksvault-create-ask-instead-of-force`, `ALL/tasks-open-offer-near-matches`, `rules.nvim/ui05-vault-create-and-catalog-ask`, `replacer.nvim/confirm-per-file-resume-after-only-some`, `gopath.nvim/probe-cancel-is-not-no-match`; Liste: `list --tags=interactive-confirm-sweep`.

## Offen: Reviews

- Nicht reviewt (alle CI ✅): lib.nvim `f12b67d`, mdview.nvim `7497500`, testing.nvim `8bcb150` + `2c9c8a4`, tasks-desktop `f309087`, tasks.nvim `5b4c363`, fileops.nvim `cd9c137`, github_stats.nvim `a4f37dc`.

## Erledigt in der letzten Runde (sechs Handover-Tasks)

- `lib.nvim/deprecation-watcher`: `lib.nvim.dev.deprecations` (`f12b67d`), meldet veraltete Neovim-Aufrufe beim Speichern (opt-in) und in `:checkhealth lib`.
- `lsp.nvim/conformance-findings`: K3/K11/K14 waren schon behoben (`d93eb22`), K10 als Entscheidungs-Task.
- `mdview.nvim/linkhover-…`: `-N`-Anker und verschachtelte Überschriften (`7497500`).
- `testing.nvim/security-model-d8-controls`: `--isolate-home` (`8bcb150`, `2c9c8a4`), Reste als Tasks.
- `wkdbook-tasks.nvim/board-a-move-key-…`: Taste wird mit Meldung abgelehnt (`f309087`).
- `ALL/interactive-confirm-sweep`: 43 Plugins durchsucht; Fixes in tasks.nvim `5b4c363`, fileops.nvim `cd9c137`, github_stats.nvim `a4f37dc`; 16 Folge-Tasks.

## Erledigt davor (Auszug)

- Reviews (hoch bzw. max) aller bis dahin offenen Code-Commits, alle Funde behoben:
  - documentation.nvim `9547e5b`/`4306a4d` -> `1d645fe` (LuaJIT-Ladesentinel, Retry greift), `48af295` (Shim-Header, `has()` auf simulierten Hosts).
  - lib.nvim `7b2aa46` -> `8082573`, `c9e7dcc` (Mason-Registry auf frischer Maschine, hängender Scan, Grenzen des Auto-Triggers, macOS-Link `/var`).
  - debugging.nvim `cc606e5` -> `fd8cb71` (Health-Abschnitt verschluckte Externals).
  - replacer.nvim `00b9c41` -> `3ec25ce` (fehlendes vs. werfendes Modul).
  - github_stats.nvim `124de98` -> `6af514b`, `bd4f475` (Mindestversion lib.nvim, harter Assert).
- `lsp.nvim/ensure-install-listen-bei-lib-nvim-deps-project-anmelden`: `46d5854`, Review-Fixes `2ea0c57` (luaformatter unter Windows ausgelassen, tote Filetypes in `UNSCANNED`, ehrlicher Health-Check, gecachte PATH-Lookups).
- Fünf Tasks in einer Runde:
  - `lib.nvim/kit-viewer-aus-insert-mode-key-…` done: `4157e37`, `126eb04`, ui.nvim `e23b4cd`; Review-Fix `be73728`, ui.nvim `d14506a` (Insert-Mode auch nach beschreibbarem Umweg).
  - `lib.nvim/review-reste-…`: Kleinkram `2278a98`, Review-Fix `0e45c06`; Rest wartet auf die Entscheidungstask (siehe oben).
  - `wkdbook-tasks.nvim/obsidian-wikilinks` done: tasks.nvim `9c4701d`, Review-Fix `63db840`.
  - `wkdbook-tasks.nvim/flackernder-browser-test-the-board-…` done: tasks-desktop `8276444`.
  - `wkdbook-tasks.nvim/flackernder-browser-test-the-inbox-…` done: tasks-desktop `fd52473`.

## Commits dieses Chats

CI ist in allen Repos auf dem jeweils letzten Commit grün (tasks-desktop `a9814a0`). ✅ = Review über "normal" (hoch/max, kein `ultracode`-Agent, siehe Sternentscheidung) bzw. reine Doku; "Fix-Commit" = Fix zu einem Review, ohne eigenes neues Review; "—" = nicht festgestellt.

| Commit | Repo | Beschreibung | Review |
|---|---|---|---|
| `7f5d584` | lib.nvim | fs.write.atomic Symlink, spawn on_exit, table partial CR | ✅ |
| `2142700` | lib.nvim | run_argv: taskkill-Callback signalisiert keinen geschlossenen Job | ✅ |
| `a80002e`, `b825356` | lib.nvim | `lib.nvim.hooks`, `lib.nvim.fs.portable` | ✅ |
| `5db98db`, `cbee792` | lib.nvim | Review-Fixes zu den vorigen | Fix-Commits |
| `5186175`, `d8c4349`, `7431033`, `b8fb8eb`, `3f9a600` | lib.nvim | help-float-Completion, utf8.scrub, cache stats, git-Peel-Test, skip-worktree | ✅ |
| `a9986c1`, `3c9b7de`, `68378c1`, `4569147`, `b7e1498` | lib.nvim | scoring, window.matches, messages.status, keymap.cheatsheet, registry | ✅ |
| `4bf4aa7`, `c3e4d61`, `97ce134`, `3dbfd62`, `36bed5d` | lib.nvim | Review-Fixes und Test-Wartezeit | Fix-Commits |
| `364cc68`, `f9c16a9`, `061f542`, `b15f611`, `247e610` | lib.nvim | best_target_window, tab_buffers, regions, capabilities, download_cached | ✅ |
| `aae5ad9` | lib.nvim | Review-Fixes zu den fünf oberen | Fix-Commit |
| `105d876`, `25e9771`, `25eeaa0` | lib.nvim | scoring Name/Delta, `:split` kopiert Matches nicht, ci-verified Publish-Race | — (CI ✅) |
| `bf40419` | lib.nvim | fs.json schreibt durch einen Symlink | — (CI ✅) |
| `ec849bc`, `b3b9b8a`, `7e71971` | lib.nvim | net.curl: Download-Cache mit Alters- und Größengrenze | — (CI ✅) |
| `b33f18f` | lib.nvim | fs.portable: Wurzel hinter `scheme://` | Fix-Commit |
| `7b2aa46` | lib.nvim | `deps.project` | ✅ |
| `8082573`, `c9e7dcc` | lib.nvim | Review-Fixes `deps.project`, macOS-Nachfix | Fix-Commits |
| `a6c3bcb` | lib.nvim | Doku: `status()`-Konvention | ✅ (Doku) |
| `4157e37`, `126eb04` | lib.nvim | kit: Viewer aus Insert-Mode, Compare-Regression | ✅ |
| `be73728` | lib.nvim | kit.picker: Insert-Mode nach beschreibbarem Umweg | Fix-Commit |
| `2278a98` | lib.nvim | json.canonical-Perf, create_exclusive, Doku, Specs | ✅ |
| `0e45c06` | lib.nvim | create_exclusive-Test, read_bounded-Hilfe | Fix-Commit |
| `efed67f1` | nvim-config | buffer_jump nutzt `tab_buffers` | ✅ |
| `beddf504`, `325e32db` | nvim-config | Handover usrcmd-help-float, `lib.nvim.md` | ✅ (Doku) |
| `1a5ddb9` | sessions.nvim | `sessions.portable` als Wrapper über `fs.portable` | ✅ |
| `3563f28` | sessions.nvim | leeres cwd, Health-Check, Doku | Fix-Commit |
| `567e60d` | replacer.nvim | `replacer.hooks` auf `lib.nvim.hooks` | ✅ |
| `b29c57e` | replacer.nvim | nil-Loch, nur `before_apply` vetoed | Fix-Commit |
| `00b9c41` | replacer.nvim | Health `lib.nvim.hooks` | ✅ |
| `3ec25ce` | replacer.nvim | Review-Fixes Health | Fix-Commit |
| `9547e5b`, `4306a4d` | documentation.nvim | `lang_registry` auf `lib.nvim.registry`, Shim `has` | ✅ |
| `1d645fe`, `48af295` | documentation.nvim | Review-Fixes | Fix-Commits |
| `cc606e5` | debugging.nvim | Health Recent-Popup | ✅ |
| `fd8cb71` | debugging.nvim | Review-Fixes | Fix-Commit |
| `124de98` | github_stats.nvim | `max_bytes` an net.curl | ✅ |
| `6af514b`, `bd4f475` | github_stats.nvim | Review-Fixes | Fix-Commits |
| `46d5854` | lsp.nvim | ensure_install bei `deps.project` anmelden | ✅ |
| `2ea0c57` | lsp.nvim | Review-Fixes | Fix-Commit |
| `6cf07f9`, `98a1d02`, `a0d05fc` | tasks.nvim | Umstellung auf lib.nvim.contract.* und fs.* | ✅ |
| `2e25a03`, `6a3f7ad` | tasks.nvim | Review-Fixes | Fix-Commits |
| `9c4701d` | tasks.nvim | Obsidian-Wikilinks | ✅ |
| `63db840` | tasks.nvim | Review-Fixes Wikilinks | Fix-Commit |
| `40eeabc` | lib.nvim | kit.picker: Augroup pro Instanz wird beim Schließen gelöscht | ✅ (hoch) |
| `662f420` | ui.nvim | Spiegel von `40eeabc`, CHANGELOG | ✅ (hoch) |
| `a9814a0` | tasks-desktop | Review-Fixes Browser-Tests (`write()`, `settled()`, `test.slow`) | Fix-Commit |
| `2fe5896` | tasks-desktop | engine.lock auf tasks.nvim `98a1d02` | – (Pin, CI ✅) |
| `8276444`, `fd52473` | tasks-desktop | Board- und Inbox-Browser-Test warten auf den Schreibvorgang | ✅ |
| `834591a` | ui.nvim | `:UI`/`:Theme` als Composer-Verben | ✅ |
| `fd16dda` | ui.nvim | Review-Funde 1 bis 6 | Fix-Commit |
| `e23b4cd` | ui.nvim | kit: Spiegelung von `4157e37`/`126eb04` | ✅ |
| `d14506a` | ui.nvim | Spiegel von `be73728`, CHANGELOG | Fix-Commit |
| `06a3976` … `edef0ec` (19 Commits, siehe Vorstand) | tasks-vault | Tasks done, Cache-Task, Handover, spec.quotes, help-float-Entscheidung | ✅ (Doku) |
| `c8b265e` … `cc17792` (15 Commits, siehe Vorstand) | tasks-vault | Tasks done bzw. neu, Folgetasks | ✅ (Doku) |
| `5b00ace`, `276a85a`, `6dbafa2`, `467821d`, `5f43394`, `fbd2722`, `b5497c9`, `429ff65`, `8e618d15`, `b1f5a200`, `574a133f`, `16ec4e74`, `a4a3e2ea`, `b2a1576a`, `059ff026` | tasks-vault | Nutzer-Punkte, Plan, Status `doing`, done, Folgetasks | ✅ (Doku) |
| `f12b67d` | lib.nvim | `dev.deprecations`: veraltete Neovim-Aufrufe melden | offen (CI ✅) |
| `7497500` | mdview.nvim | Link-Hover: `-N`-Anker, verschachtelte Überschriften | offen (CI ✅) |
| `8bcb150`, `2c9c8a4` | testing.nvim | `--isolate-home`, macOS-Nachfix | offen (CI ✅) |
| `f309087` | tasks-desktop | Board-Taste während Schreibvorgang mit Meldung ablehnen | offen (CI ✅) |
| `5b4c363` | tasks.nvim | Nachfrage vor Überschreiben eines `--to=file:`-Ziels | offen (CI ✅) |
| `cd9c137` | fileops.nvim | Bulk-Rename: Überspringen/Überschreiben vorhandener Ziele | offen (CI ✅) |
| `a4f37dc` | github_stats.nvim | Fetch im Intervall: Nachfrage statt `force`-Hinweis | offen (CI ✅) |
| `faea04da`, `2fc02a9a`, `30f5ab24`, `a46dec57`, `0ea48021`, `1f2471b5`, `0e84c560`, `262f824a`, `1f9f5eb4` | tasks-vault | sechs Handover-Tasks: doing, done, Folge-Tasks | ✅ (Doku) |

## Umgebung und Regeln

- Im lib.nvim-Worktree scheitern `telemetry_wrap_spec` (braucht `RUNTIME_ANALYSIS_DIR=E:/repos/runtime-analysis.nvim`) und `git_spec` (Branchname statt `main`); das ist erwartet. Unter PowerShell scheitern zusätzlich `spawn_env_spec` und `system_job_spec` (Umgebung `=EXITCODE`, kein `sh`); unter Git Bash und in der CI grün.
- Die lib.nvim-Vollsuite braucht lokal etwa 4,5 Minuten (`run_argv_spec` allein etwa 24 s); ein 120-s-Timeout bricht sie mitten ab und sieht wie ein Hänger aus.
- ui.nvim-CI: `kit_drift_spec` vergleicht mit lib.nvim `ci-verified`; nach einem Kit-Fix in lib.nvim erst dessen CI abwarten, sonst ist der ui.nvim-Lauf rot.
- tasks-desktop-Browser-Tests: nur mit einem Worker, ein fremder Hub auf Port 17698 kann warten lassen.
- Vor jedem Push: `stylua --check .` und die Vollsuite abwarten; `git log origin/main..HEAD` prüfen (im Vault gingen zweimal fremde Commits mit: `ff0fb63`, `e7a2dffa`).
- Backslashes nie durch Heredocs oder Python-Strings, nur per Write/Edit oder `chr(92)`.
- Eine Sabotage ändert genau eine Stelle; erst dann beweist der neue Test etwas.
- In der nvim-config nur die eigene Datei per Pfad committen (dort liegen fremde uncommittete Änderungen).
- Nach jedem `done` im Vault `check` fahren.
