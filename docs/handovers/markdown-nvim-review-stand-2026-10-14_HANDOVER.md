# markdown.nvim - Review-Stand (2026-10-14) HANDOVER

Repo: markdown.nvim, Branch main (Worktree `claude/markdown-nvim-review-5645c7` steht auf c3af5dd = origin/main).

## Commits (alle auf main, CI gruen auf Ubuntu/Windows/macOS)

| Commit  | Inhalt | Review |
|---------|--------|--------|
| dd19fe8 | fix(render): jedes Fenster zeichnet seine eigene Zeilenspanne | Runde 2 |
| 5a0aa2c | fix(render): Tabellenzeilen bekommen Inline-Marks ohne Raster | Runde 2 |
| 387636a | fix(tables): box behaelt Linien beim Write-back; csv/tsv sep-Option | Runde 1 |
| 93a3ef7 | docs(tables): einspaltige Org-Tabellen als GFM | Runde 1 |
| a1c52e2 | docs: Help, README, what-you-get, commands, health zum nativen Renderer | - |
| 0f9e571 | fix(tables): Review-Fixes Runde 1 (gfm escaped pipes/Alignment, org leere Zeilen, box <br>, Header-only GFM, TableView bottom-up) | selbst |
| c3af5dd | fix(render): Review-Fixes Runde 2 (conceal_guard, Raster/Render-Reihenfolge, render = true, Badge-/Klammer-Links, escaped brackets, Backtick-Runs, Rules, Regelbreite) | selbst |

Hinweis: Die Review-Agenten (Runde 1+2) haben die Funde geliefert, die Fixes sind
sabotage-getestet (Specs werden ohne Fix rot). Die Fix-Commits selbst sind noch nicht
nochmals durch einen ultracode-Agenten geprueft (gelber Haken).

## Offen

1. **Runde 3 des Reviews** (1 Agent): table_render, table_truncate, Zusammenspiel
   conceal_guard, und die jungen Fix-Commits 0f9e571 / c3af5dd. Lief beim Limit ab, kein Ergebnis.
2. **Design-Entscheidung aus Runde 1, Punkt 7** (nicht gefixt, bewusst offen) - in
   der Review-Schlussliste aufnehmen und mit dem User klaeren.
3. `render = true` als Kurzform in setup() ist noch nicht in der Doku erwaehnt.

## Regeln

Ein Agent gleichzeitig; stylua/luacheck gruen, Specs (zuletzt 62/62), Docs pflegen;
nach Abschluss commit/pull/merge/push auf main, CI pruefen; keine Co-Autorenschaft.
