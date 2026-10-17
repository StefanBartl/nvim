Stand 2026-10-17. Das ausführliche Handover liegt im Vault (`tasks-vault/lib.nvim/handovers/session-stand-2026-10-15_HANDOVER.md`); der Symlink in `docs/ROADMAP/handovers` zeigt darauf. Diese Datei hält nur, was den Nutzer braucht, was noch läuft, und die Commit-Liste des ganzen Chats. Alles andere ist erledigt oder als Task im Vault (`list --actor=me`).

## Läuft gerade

- Nichts. Der Fix der vier Review-Funde zu tasks-desktop `8276444`/`fd52473` ist `a9814a0` (CI grün): `write()` mit 15-s-Budget an allen Schreibstellen, `settled()` greift im Inbox-Test, `test.slow()` statt fester 7 s, Kommentar zur Teilstring-Suche.

## Offen, braucht den Nutzer

Jeder Punkt ist ein Task im Vault (actor `me` bzw. `pair`):

- `lib.nvim/entscheidungen-review-reste-von-contract-fs-und-json` (status=decision, neu): zehn Fragen mit Optionen, Empfehlung und einer Zeile "Entscheidung:". Blockiert `lib.nvim/review-reste-der-contract-fs-json-module-entscheidungen-und` (Kleinkram dort ist erledigt, `2278a98`).
- `replacer.nvim/hooks-on-rejects-a-non-function-at-registration-document-and` (decision): `hooks.on` wirft bei Nicht-Funktionen schon bei der Registrierung. Empfehlung: so lassen, dokumentieren, per Test festhalten.
- `wkdbook-tasks.nvim/board-a-move-key-during-a-write-is-dropped-silently-while-th`: Entscheidung, ob eine Board-Taste während eines Schreibvorgangs mit Meldung abgelehnt oder gepuffert wird (Task ist `open`, S).
- `hover.nvim/hover-zoom-mit-dem-mausrad-navigieren-im-zoom-mit-gehaltenem` (actor=pair): Mausrad-Zoom, Tasten bestätigen.
- `docmap-desktop/rules-api-catalog-and-run`: erst klären, ob es mit der laufenden rules.nvim-Arbeit kollidiert.
- `documentation.nvim/repo-named-paths-outside-root`: Sicherheitsentscheidung.
- `testing.nvim/cache-affected-remaining-limits`: zwei Entscheidungen (Lese-Ledger, State-Warn bei `soft`).
- Handchecks: `lsp.nvim/gx-on-an-env-link-in-a-real-neovim-0-12-session-hand-check`, `lsp.nvim/live-check-lspsaga-replacements`, `ui.nvim/try-the-ui-option-float-in-a-real-session`.
- Sternentscheidung: `ALL/decide-whether-a-review-at-reasoning-level-high-earns-the-st`. Alle Code-Commits wurden mit Reasoning "hoch" reviewt (zuletzt teils "max"), keiner mit `ultracode`-Agent.
- Fremde, nicht committete Änderung in `tasks.nvim/lua/tasks_nvim/links.lua` (seit 16.10., 22:07): doppelter Kommentarblock, `"\0"`-Trenner ersetzt, Bedingung `#names > 1` entfernt. Sieht nach liegengebliebener Sabotage einer anderen Sitzung aus; nicht angefasst.

## Offen für cdx (Vault)

- `testing.nvim/explorer-g-cheatsheet-and-footer-via-lib-nvim-keymap-cheatsh` (weich nach `testing.nvim/ui-explorer-actions`, das noch offen ist).
- `lib.nvim/test-suite-einmaliger-unreproduzierbarer-spec-fehler-flake-i` (braucht ein neues Auftreten mit gesicherter FAIL-Zeile).
- `wkdbook-tasks.nvim/board-a-move-key-during-a-write-is-dropped-silently-while-th` (open, S): vorher entscheiden, ob die Taste mit einer Meldung abgelehnt oder gepuffert wird (steht auch oben bei den Entscheidungen).
- Laut Vault schon erledigt (von anderen Sitzungen): `contract-doc-engine-git-asynchron-vorwaermen`, `new-warn-…-wikilinks-ambig`, `plan-files-wikilinks-in-target`, `language.nvim/task-translate-markdown-deepl-…`, `duplicate-id-stubs-…`, `ops-lua-a-thin-local-helper-…`, `kit-picker-augroup-…` (`40eeabc`).
- Als Nächstes laut `done`/`next`: `lib.nvim/deprecation-watcher`, dann `detached-spawn-watcher`, `paginated-api-partial-results`; cdx: `terminal.nvim/release-docs`, `wkdbook-tasks.nvim/tasks-desktop-erledigt-ladezeichen-beim-zeitraumwechsel`, `tasks-desktop-menueleiste-ein-tab-stopp`.

## Offen: Reviews

- Keine. lib.nvim `40eeabc` und ui.nvim `662f420` sind reviewt (hoch): kein Fehler, nur zwei kosmetische Nitpicks (Test deckt nur zwei Schließwege ab, obwohl alle funktionieren; ui.nvim-CHANGELOG führt `Fixed` vor `Changed`), bewusst nicht behoben.

## Erledigt seit dem letzten Stand (Auszug)

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
