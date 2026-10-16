Stand 2026-10-16. Das ausführliche Handover liegt im Vault (`tasks-vault/lib.nvim/handovers/session-stand-2026-10-15_HANDOVER.md`, zuletzt `4d0b90d`); der Symlink in `docs/ROADMAP/handovers` zeigt darauf. Diese Datei hält nur, was in diesem Chat noch zu tun ist.

## Noch in diesem Chat zu tun

**1. Reviews (Pflicht, bevor etwas als fertig gilt)**
- `1a5ddb9` (sessions.nvim): `sessions.portable` als Wrapper über `lib.nvim.fs.portable`. Nur CI grün, nicht reviewt.
- `567e60d` (replacer.nvim): `replacer.hooks` setzt auf `lib.nvim.hooks` auf. Nur CI grün, nicht reviewt.
- Prüfpunkte: Spec-Anpassung `"aa"`/`"aaa"` in sessions.nvim (neue Regel vor dem Treffer) und ob replacer wirklich überall `vetoable = alle vier Events` braucht.

**2. Migration, noch offen**
- `documentation.nvim/lang-registry-auf-lib-nvim-registry-umstellen` (M): `lang_registry.lua` auf `lib.nvim.registry`. Dasselbe Vorgehen wie bei replacer: Charakterisierungs-Tests gegen alt und neu.

**3. Tasks, die bereit sind (lib.nvim)**
- `lib.nvim/net-curl-download-cached-obergrenze-fuer-den-cache-alter-gro` (S): Alters- und Größengrenze für den Download-Cache (Vorlage: media.nvim).
- `lib.nvim/window-matches-split-kopierte-matches-im-ledger-behandeln` (S): Vim kopiert Matches bei `:split` ins neue Fenster, das Ledger kennt sie nicht.
- `lib.nvim/scoring-name-delta-pruefung-nur-an-einer-stelle` (XS): Name/Delta-Prüfung an einer Stelle bündeln (vorher prüfen, ob `36bed5d` es schon deckt).
- `lib.nvim/ci-verified-publish-race-bei-zwei-schnell-aufeinanderfolgend` (S, Bug): `publish ci-verified` scheitert am Push, wenn zwei Pushes dicht aufeinander folgen (Tests grün, Branch enthält den Commit trotzdem).
- `lib.nvim/project-scan-missing-parsers-and-tools` (M): laut `next` die nächste, braucht vorher eine kurze Planung (baut auf `lib.nvim.deps` und `treesitter.parser_policy`).

**4. Verbraucher der neuen Bausteine (anderes Repo)**
- `debugging.nvim/health-recent-popup-requirements` (S, entsperrt): nutzt `messages.status()` in `health.lua`.
- testing.nvim Explorer: erster Verbraucher von `keymap.cheatsheet` (Task dafür noch nicht angelegt).
- Rein kosmetisch: `github_stats.nvim/api.lua` könnte `raw_args = { "--max-filesize", … }` durch `max_bytes` ersetzen. Eine Migration auf `download_cached` entfällt (es holt JSON, keine Dateien).

**5. Aufräumen**
- Nach jedem `done` im Vault prüfen, ob ein "value estimates"-Lauf fertige Tasks in `ROADMAP/tasks/` wiederhergestellt hat (`check` meldet dann `duplicate-id`).

## Braucht dich

- `hover.nvim` Mausrad-Zoom (actor=pair, du bestätigst die Tasten).
- `docmap-desktop/rules-api-catalog-and-run` (erst klären, ob es mit der laufenden rules.nvim-Arbeit kollidiert).
- `documentation.nvim/repo-named-paths-outside-root` (Sicherheitsentscheidung).
- `lib.nvim` help-float-Entscheidung (`help-float-ui-usercmd-decision-migrate-or-attach`); die `spec.quotes`-Frage ist laut Handover entschieden (keine weiteren Verben).
- `testing.nvim/cache-affected-remaining-limits` (zwei Entscheidungen: Lese-Ledger, State-Warn bei `soft`).
- Handchecks: `gx` auf einen Env-Link in einem echten Neovim 0.12 und `live-check-lspsaga-replacements`.
- Entscheidung zum Stern: Alle Code-Commits wurden mit Reasoning "hoch" reviewt, keiner mit `ultracode`. Soll "hoch" für den Stern reichen?

## Dieser Chat bisher (Kurzfassung)

Gebaut und gereviewt in lib.nvim: `fs.write.atomic` (Symlink-Ziel), `spawn_command`/`spawn_shell_command` (Handle zuerst schließen), `markdown.table` (CR je Zeile), `run_argv` (PID-Wiederverwendung unter Windows, Ursache der Flakes), `hooks`, `fs.portable`, `composer.help` (Completion-Werte eigener Typen), `strings.utf8.scrub`, `cache` (`:Lib cache stats`), `git` (skip-worktree, Peel-Pfade auf jedem git), `lua.scoring`, `window.matches`, `messages.status()`, `keymap.cheatsheet`, `lib.nvim.registry`, `window.best_target_window`, `buf_win_tab.tab_buffers`, `treesitter.regions`, `terminal.capabilities`, `net.curl.download_cached`. Migriert: nvim-config (`buffer_jump`), sessions.nvim, replacer.nvim.

## Commits dieses Chats

| Commit | Repo | Beschreibung | Review |
|---|---|---|---|
| `7f5d584` | lib.nvim | fs.write.atomic Symlink, spawn on_exit, table partial CR | ✅ |
| `2142700` | lib.nvim | run_argv: taskkill-Callback signalisiert keinen geschlossenen Job | ✅ |
| `a80002e`, `b825356` | lib.nvim | `lib.nvim.hooks`, `lib.nvim.fs.portable` | ✅ |
| `5db98db`, `cbee792` | lib.nvim | Review-Fixes zu den vorigen | Fix-Commits |
| `5186175`, `d8c4349`, `7431033`, `b8fb8eb`, `3f9a600` | lib.nvim | help-float-Completion, utf8.scrub, cache stats, git-Peel-Test, skip-worktree | ✅ |
| `a9986c1`, `3c9b7de`, `68378c1`, `4569147`, `b7e1498` | lib.nvim | scoring, window.matches, messages.status, keymap.cheatsheet, registry | ✅ |
| `4bf4aa7`, `c3e4d61` (+ `97ce134`, `3dbfd62`, `36bed5d` der anderen Sitzung) | lib.nvim | Review-Fixes und Test-Wartezeit | Fix-Commits |
| `364cc68`, `f9c16a9`, `061f542`, `b15f611`, `247e610` | lib.nvim | best_target_window, tab_buffers, regions, capabilities, download_cached | ✅ |
| `aae5ad9` | lib.nvim | Review-Fixes zu den fünf oberen | Fix-Commit (CI ✅) |
| `efed67f1` | nvim-config | buffer_jump nutzt `tab_buffers` | ✅ |
| `1a5ddb9` | sessions.nvim | `sessions.portable` als Wrapper über `fs.portable` | **offen** (CI ✅) |
| `567e60d` | replacer.nvim | `replacer.hooks` setzt auf `lib.nvim.hooks` auf | **offen** (CI ✅) |
| `06a3976`, `3bec562`, `162a9ba`, `ca57fd3`, `9dca3a9`, `e1c6145`, `a0309a5`, `217c624`, `177bbc0`, `4dfdd91`, `415a492`, `2e5130d`, `8a0df82`, `4d0b90d` | tasks-vault | Tasks auf done, Cache-Task, Handover | ✅ (reine Doku) |

Haken = durch Reasoning über "normal" reviewt; keiner hat einen Stern (ultracode).

## Umgebung und Regeln

- Im lib.nvim-Worktree scheitern `telemetry_wrap_spec` (braucht `RUNTIME_ANALYSIS_DIR=E:/repos/runtime-analysis.nvim`) und `git_spec` (Branchname statt `main`); das ist erwartet.
- Vor jedem Push: `stylua --check .` und die Vollsuite abwarten, das Push-Kommando daran binden.
- Backslashes nie durch Heredocs oder Python-Strings, nur per Write/Edit oder `chr(92)`; im Handover/Notizen nicht ausschreiben.
- Eine Sabotage ändert genau eine Stelle; erst dann beweist der neue Test etwas.
- In der nvim-config nur die eigene Datei per Pfad committen (dort liegen fremde uncommittete Änderungen).
