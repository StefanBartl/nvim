Stand 2026-10-16, Abend. Das ausführliche Handover liegt im Vault (`tasks-vault/lib.nvim/handovers/session-stand-2026-10-15_HANDOVER.md`); der Symlink in `docs/ROADMAP/handovers` zeigt darauf. Diese Datei hält nur noch, was den Nutzer braucht, und die Commit-Liste des ganzen Chats. Alles andere ist erledigt oder als Task im Vault (`tasks-vault`, Befehl `list --actor=me`).

## Offen, braucht den Nutzer

Jeder Punkt ist ein Task im Vault (actor `me` bzw. `pair`):

- `hover.nvim/hover-zoom-mit-dem-mausrad-navigieren-im-zoom-mit-gehaltenem` (actor=pair): Mausrad-Zoom, du bestätigst die Tasten.
- `docmap-desktop/rules-api-catalog-and-run`: erst klären, ob es mit der laufenden rules.nvim-Arbeit kollidiert.
- `documentation.nvim/repo-named-paths-outside-root`: Sicherheitsentscheidung, wer einen Pfad außerhalb der Projektwurzel nennen darf.
- `testing.nvim/cache-affected-remaining-limits`: zwei Entscheidungen (Lese-Ledger im fs-Guard, State-Warn bei `soft`-Isolation).
- Handchecks: `lsp.nvim/gx-on-an-env-link-in-a-real-neovim-0-12-session-hand-check` (neu), `lsp.nvim/live-check-lspsaga-replacements`, `ui.nvim/try-the-ui-option-float-in-a-real-session`.
- Sternentscheidung: `ALL/decide-whether-a-review-at-reasoning-level-high-earns-the-st` (neu). Alle Code-Commits wurden mit Reasoning "hoch" reviewt, keiner mit `ultracode`; soll "hoch" für den Stern reichen?

Dazu für den Vault-Betrieb: `check` meldet 6 Fehler, die nicht aus diesem Chat stammen (zwei Stub-Dateien ohne Frontmatter in `filetree.nvim` und `insights.nvim`, ein erledigter Task in `testing.nvim/ROADMAP/tasks`). Task: `testing.nvim/duplicate-id-stubs-and-a-finished-task-left-in-roadmap-tasks` (actor=cdx).

## Erledigt seit dem letzten Stand (Auszug)

- Reviews von `1a5ddb9` (sessions.nvim) und `567e60d` (replacer.nvim): Folgefixes `3563f28` (leeres cwd wird gemeldet, Health-Check, Doku) und `b29c57e` (Hooks hinter einem nil-Loch, nur `before_apply` vetoed), `00b9c41` (Health meldet die `lib.nvim.hooks`-Abhängigkeit). Rest: Entscheidungstask `replacer.nvim/hooks-on-rejects-a-non-function-at-registration-document-and`.
- Migration `documentation.nvim/lang-registry-auf-lib-nvim-registry-umstellen`: `9547e5b` (Folge `4306a4d`, CI-Fix des `vim.fn.has`-Shims).
- Frühere "bereite" lib.nvim-Tasks, jetzt fertig: Download-Cache-Obergrenze `ec849bc` (+ `b3b9b8a`, `7e71971`), `window.matches` und `:split` `25e9771`, Name/Delta-Prüfung `105d876`, `ci-verified`-Publish-Race `25eeaa0`, `project-scan` (`lib.nvim.deps.project`) `7b2aa46`, Konvention `status()` `a6c3bcb`.
- Verbraucher: `debugging.nvim` Health-Popup `cc606e5`, `replacer.nvim` Health `00b9c41`, `github_stats.nvim` `max_bytes` statt `raw_args` `124de98`. Der Explorer-Verbraucher von `keymap.cheatsheet` ist Task `testing.nvim/explorer-g-cheatsheet-and-footer-via-lib-nvim-keymap-cheatsh`.
- Chat usrcmd-help-float: die Funde der Reviews sind behoben, ui.nvim `fd16dda` (alle sechs Funde) und tasks.nvim `6a3f7ad` (Spec für die Encoder-Regeln, eigenes `COPY_EXISTS`-Token, CHANGELOG, Spec-Anzahl). Rest als Tasks: `wkdbook-tasks.nvim/ops-lua-a-thin-local-helper-for-door-failure-door-refuse`, die Obsidian-Tasks sind entsperrt (`open`).
- Aufräumen nach `done`: `check` wurde über den ganzen Vault gefahren, keine wiederhergestellten Duplikate aus einem "value estimates"-Lauf gefunden.

## Commits dieses Chats

CI ist in allen Repos auf dem jeweils letzten Commit grün. Haken = Review über "normal"/"hoch" (kein `ultracode`, siehe Sternentscheidung oben); "Fix-Commit" = Fix zu einem Review, ohne eigenes neues Review; "—" = nicht festgestellt.

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
| `105d876`, `25e9771`, `25eeaa0` | lib.nvim | scoring Name/Delta an einer Stelle, `:split` kopiert Matches nicht (Doku + Spec), ci-verified Publish-Race | — (CI ✅) |
| `bf40419` | lib.nvim | fs.json schreibt durch einen Symlink statt ihn zu ersetzen | — (CI ✅) |
| `b33f18f` | lib.nvim | fs.portable: Wurzel direkt hinter `scheme://` beginnt an einer Grenze | Fix-Commit |
| `ec849bc`, `b3b9b8a`, `7e71971` | lib.nvim | net.curl: Download-Cache mit `max_age_s` und `max_total_bytes`, Review-Fixes, Test | — (CI ✅) |
| `7b2aa46` | lib.nvim | `deps.project`: fehlende Treesitter-Parser und Werkzeuge einer Wurzel | — (CI ✅) |
| `a6c3bcb` | lib.nvim | Doku: `status()` ist Statuszeilen-String oder Zustands-Snapshot | Doku |
| `efed67f1` | nvim-config | buffer_jump nutzt `tab_buffers` | ✅ |
| `1a5ddb9`, `3563f28` | sessions.nvim | `sessions.portable` als Wrapper über `fs.portable`, Folgefix | Fix-Commit (CI ✅) |
| `567e60d`, `b29c57e`, `00b9c41` | replacer.nvim | `replacer.hooks` auf `lib.nvim.hooks`, Folgefix, Health-Meldung | Fix-Commits (CI ✅) |
| `9547e5b`, `4306a4d` | documentation.nvim | `lang_registry` auf `lib.nvim.registry`, `vim.fn.has`-Shim für win32/mac/unix | — (CI ✅) |
| `cc606e5` | debugging.nvim | Health: Anforderungen des Recent-Popups | — (CI ✅) |
| `124de98` | github_stats.nvim | `max_bytes` an `lib.nvim` net.curl | — (CI ✅) |
| `6cf07f9` | tasks.nvim | contract/api/host/errors/json auf lib.nvim.contract.* | ⭐ (hoch, 7 Funde) |
| `98a1d02` | tasks.nvim | ops auf contract.ops, fsio auf lib.nvim.fs.* | ⭐ (hoch) |
| `2e25a03` | tasks.nvim | Fix der Funde 1 bis 4 | Fix-Commit |
| `a0d05fc` | tasks.nvim | fsio EXISTS/is_exists, ops ohne Wrapper, json-Spec entfernt | ⭐ (hoch) |
| `6a3f7ad` | tasks.nvim | Fix zum Review von `a0d05fc` | Fix-Commit |
| `2fe5896` | tasks-desktop | engine.lock auf tasks.nvim `98a1d02` | – (Pin, CI ✅) |
| `834591a` | ui.nvim | `:UI`/`:Theme` als Composer-Verben | ⭐ (hoch, 6 Funde) |
| `fd16dda` | ui.nvim | Fix aller sechs Funde zu `834591a` | Fix-Commit |
| `beddf504` | nvim-config | Handover usrcmd-help-float aktualisiert | Doku |
| `06a3976`, `3bec562`, `162a9ba`, `ca57fd3`, `9dca3a9`, `e1c6145`, `a0309a5`, `217c624`, `177bbc0`, `4dfdd91`, `415a492`, `2e5130d`, `8a0df82`, `4d0b90d`, `5068448`, `f65d003`, `481d91c`, `7bfc62d`, `edef0ec` | tasks-vault | Tasks auf done, Cache-Task, Handover, spec.quotes, help-float-Entscheidung | Doku |
| `c8b265e`, `ff39062`, `f71d53b`, `846fdd0`, `276a85a`, `c15400f`, `6dbafa2`, `fbd2722`, `467821d`, `5f43394`, `ff0fb63`, `b5497c9`, `429ff65`, `0ae1f40`, `cc17792` | tasks-vault | Tasks done bzw. neu (window-matches, ci-verified, scoring, download-cache, lang-registry, keymaps-false, project-scan, statusline, debugging-Health, replacer-Health, fallback-chain), Folgetasks | Doku |
| `5b00ace` | tasks-vault | nur-Nutzer-Punkte mit actor=me (gx-Handcheck, Sternentscheidung, lspsaga, rules-api, Repo-Pfade, Cache-Grenzen), Task für die check-Fehler | Doku |

## Umgebung und Regeln

- Im lib.nvim-Worktree scheitern `telemetry_wrap_spec` (braucht `RUNTIME_ANALYSIS_DIR=E:/repos/runtime-analysis.nvim`) und `git_spec` (Branchname statt `main`); das ist erwartet.
- Vor jedem Push: `stylua --check .` und die Vollsuite abwarten, das Push-Kommando daran binden.
- Backslashes nie durch Heredocs oder Python-Strings, nur per Write/Edit oder `chr(92)`; im Handover/Notizen nicht ausschreiben.
- Eine Sabotage ändert genau eine Stelle; erst dann beweist der neue Test etwas.
- In der nvim-config nur die eigene Datei per Pfad committen (dort liegen fremde uncommittete Änderungen).
- Nach jedem `done` im Vault `check` fahren: ein "value estimates"-Lauf stellt fertige Tasks in `ROADMAP/tasks/` wieder her (`duplicate-id`).
