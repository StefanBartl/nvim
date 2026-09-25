# gitsuite.nvim & Schwesterplugins — Backlog

> Archiv für erledigte Task-Karten aus
> [`ROADMAP/handovers/IMPLEMENTATION-PLAN.md`](../Final_Checks/gitsuite.nvim.md).
> **TASKS** = Audits, Sweeps, Reviews, Migrationen. **FEATURES** = Konzepte,
> Baupläne, neue Fähigkeiten. Aufteilung folgt Commit `445e307` der
> nvim-Config. Jede Karte wird beim Fertigstellen aus dem Plan
> ausgeschnitten und landet hier (siehe dessen
> [Lebenszyklus-Abschnitt]($REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/gitsuite.nvim/ROADMAP/IMPLEMENTATION-PLAN.md#lebenszyklus-erledigtes-wandert-ins-backlog)).

## TASKS

| ID | Titel | Repo(s) | Datum | Karte |
|---|---|---|---|---|
| GS-13 | `filetree.nvim`: eigener Porcelain-Parser → `lib.nvim.git` | filetree.nvim, lib.nvim | 2026-09-22 | [GS-13](TASKS/GS-13_filetree-porcelain-to-lib.md) |
| GS-14 | Sammel-Swaps `insights`/`buffer-ctx`/`diff`/`fileops` → `lib.nvim.git` | insights.nvim, buffer-ctx.nvim, diff.nvim, fileops.nvim, lib.nvim | 2026-09-22 | [GS-14](TASKS/GS-14_sammel-swaps-lib-git.md) |
| GS-15 | `ui.nvim`s `git_clickable` auf lib-Primitive, plus `lib.nvim.git.checkout` | ui.nvim, lib.nvim, gitsuite.nvim | 2026-09-22 | [GS-15](TASKS/GS-15_ui-nvim-git-clickable-to-lib.md) |
| GS-16 | Remote-URL-Grammatik (`parse_remote`/`host_kind`/`build`) nach `lib.nvim` heben | lib.nvim, gitsuite.nvim, github_stats.nvim, documentation.nvim | 2026-09-22 | [GS-16](TASKS/GS-16_remote-url-grammar-to-lib.md) |
| GS-17 | README-Doku: Pflichtseiten (requirements/installation/quickstart/configuration/commands) | gitsuite.nvim | 2026-09-22 | [GS-17](TASKS/GS-17_readme-doku-pflichtseiten.md) |
| GS-18 | README-Doku: Rest, `:DocMap`-Prüfung, vimdoc-Abgleich | gitsuite.nvim | 2026-09-22 | [GS-18](TASKS/GS-18_readme-doku-rest.md) |
| GS-26 | `fileops`: Konflikt-Highlighting/Blame-Fallback → gitsuite delegieren | fileops.nvim, gitsuite.nvim | 2026-09-22 | [GS-26](TASKS/GS-26_fileops-conflict-blame-duplikate.md) |

## FEATURES

| ID | Titel | Repo(s) | Datum | Karte |
|---|---|---|---|---|
| GS-20 | Konflikt-Konsumenten (`has_conflicts`): Fence-Filter, Buffer-Report, Devcontainer-Preflight | gitsuite.nvim, color_my_ascii.nvim, debugging.nvim, sandbox.nvim | 2026-09-22 | [GS-20](FEATURES/GS-20_konflikt-konsumenten.md) |
| GS-21 | `ai.nvim`: `opts.conflict`-Scope (beide Merge-Seiten gelabelt im KI-Kontext) | ai.nvim, gitsuite.nvim | 2026-09-22 | [GS-21](FEATURES/GS-21_ai-nvim-conflict-scope.md) |
| GS-22 | `:Git status todos\|lint\|spell` (Pre-Commit-Gates über geänderte Dateien) | gitsuite.nvim, insights.nvim | 2026-09-22 | [GS-22](FEATURES/GS-22_status-todos-lint-spell.md) |
| GS-23 | `:Git status relink` (Referenzen nach git-erkanntem Rename reparieren) | gitsuite.nvim, filetree.nvim | 2026-09-22 | [GS-23](FEATURES/GS-23_status-relink.md) |
| GS-24 | `sessions.nvim` beim Branch-Wechsel speichern/laden (opt-in) | gitsuite.nvim, sessions.nvim | 2026-09-22 | [GS-24](FEATURES/GS-24_branch-sessions-integration.md) |
| GS-25 | Post-Action-Konsumenten: `filetree`/`fileops` reagieren auf gitsuite-Events | filetree.nvim, fileops.nvim, gitsuite.nvim | 2026-09-22 | [GS-25](FEATURES/GS-25_post-action-konsumenten.md) |
| GS-27 | lazygit-Einstieg aus `reposcope`/`cmdlog`/`sandbox` | reposcope.nvim, cmdlog.nvim, sandbox.nvim, gitsuite.nvim | 2026-09-22 | [GS-27](FEATURES/GS-27_lazygit-einstiege.md) |
| GS-28 | Mehrdeutigen Konflikt per Trennerwahl auflösen (`vim.ui.select`) | gitsuite.nvim | 2026-09-22 | [GS-28](FEATURES/GS-28_ambiguous-separator-select.md) |

## Hinweis zu früheren Wellen (`GS-00`…`GS-12`)

Wellen 0–2 (`GS-00`–`GS-11`) und der Quick Win `GS-12` sind laut
`IMPLEMENTATION-PLAN.md` ebenfalls abgeschlossen, liefen aber vor der
Einführung dieses Backlog-Archivs und hatten in der bisherigen Plan-Fassung
keine eigenen Karten in diesem Format — nur Kurzeinträge in dessen
Ausgangslage-Tabelle. Ihre Historie steht in den `git log`s der jeweiligen
Repos; sie wird hier nicht rückwirkend rekonstruiert.
