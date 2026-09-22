# gitsuite.nvim & Schwesterplugins — Backlog

> Archiv für erledigte Task-Karten aus
> [`ROADMAP/handovers/IMPLEMENTATION-PLAN.md`](../handovers/IMPLEMENTATION-PLAN.md).
> **TASKS** = Audits, Sweeps, Reviews, Migrationen. **FEATURES** = Konzepte,
> Baupläne, neue Fähigkeiten. Aufteilung folgt Commit `445e307` der
> nvim-Config. Jede Karte wird beim Fertigstellen aus dem Plan
> ausgeschnitten und landet hier (siehe dessen
> [Lebenszyklus-Abschnitt](../handovers/IMPLEMENTATION-PLAN.md#lebenszyklus-erledigtes-wandert-ins-backlog)).

## TASKS

| ID | Titel | Repo(s) | Datum | Karte |
|---|---|---|---|---|
| GS-13 | `filetree.nvim`: eigener Porcelain-Parser → `lib.nvim.git` | filetree.nvim, lib.nvim | 2026-09-22 | [GS-13](TASKS/GS-13_filetree-porcelain-to-lib.md) |
| GS-14 | Sammel-Swaps `insights`/`buffer-ctx`/`diff`/`fileops` → `lib.nvim.git` | insights.nvim, buffer-ctx.nvim, diff.nvim, fileops.nvim, lib.nvim | 2026-09-22 | [GS-14](TASKS/GS-14_sammel-swaps-lib-git.md) |
| GS-15 | `ui.nvim`s `git_clickable` auf lib-Primitive, plus `lib.nvim.git.checkout` | ui.nvim, lib.nvim, gitsuite.nvim | 2026-09-22 | [GS-15](TASKS/GS-15_ui-nvim-git-clickable-to-lib.md) |

## FEATURES

_Noch keine archivierten Feature-Karten._

## Hinweis zu früheren Wellen (`GS-00`…`GS-12`)

Wellen 0–2 (`GS-00`–`GS-11`) und der Quick Win `GS-12` sind laut
`IMPLEMENTATION-PLAN.md` ebenfalls abgeschlossen, liefen aber vor der
Einführung dieses Backlog-Archivs und hatten in der bisherigen Plan-Fassung
keine eigenen Karten in diesem Format — nur Kurzeinträge in dessen
Ausgangslage-Tabelle. Ihre Historie steht in den `git log`s der jeweiligen
Repos; sie wird hier nicht rückwirkend rekonstruiert.
