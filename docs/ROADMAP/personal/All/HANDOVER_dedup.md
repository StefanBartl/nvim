# Handover — Deduplizieren nach `lib.nvim` — ABGESCHLOSSEN

Stand: 2026-08-27. Alle drei "Zu tun"-Punkte sind umgesetzt, getestet und
gepusht. Der Auftrag **„`lib.nvim` konsequent als Dependency nutzen"** ist
damit komplett und aus `FINISH/MERGED.md` nach `FINISH/Merged_Finished.md`
gewandert — dort steht der ausführliche Bericht (Modul für Modul, inklusive
der beiden Stellen, an denen die Umsetzung von dem abwich, was hier ursprünglich
geplant war: `table_wrap.lua`s zusätzliche interne Abhängigkeiten und die
dritte `version_ok`-Kopie in `lib.health.lua` selbst).

Kurzfassung, wer nur diese Datei liest:

| Was | Ziel |
| --- | --- |
| Markdown-Tabellen-Renderer | `lib.nvim.markdown.table` — markdown.nvim + buffer-ctx.nvim umgestellt |
| `deep_merge` + `config.get` | `lib.lua.config` — cascade.nvim + spotlight.nvim umgestellt |
| `health.check_require` + `version_ok` | `lib.nvim.health` — dap/debugging/documentation/runtime-analysis + lib.health.lua selbst |
| HTML-Escaping | `lib.lua.strings.encoding.html_escape` — documentation.nvim + runtime-analysis.nvim |
| `spawn_env.array` | `lib.nvim.cross.run.env.array` — pdfport.nvim + reposcope.nvim |

Alle Repos einzeln committet und auf `main` gepusht (lib.nvim, markdown.nvim,
buffer-ctx.nvim, cascade.nvim, spotlight.nvim, dap.nvim, debugging.nvim,
documentation.nvim, runtime-analysis.nvim, pdfport.nvim, reposcope.nvim).
`duplicate_functions.py` bestätigt: keine der behandelten Duplikate mehr da.
Übrig sind nur bewusst nicht angefasste Kandidaten: `config.M.get`,
`try_require`, und (Nachtrag) `notify.resolve` (buffer-ctx/fileops) sowie
`M.augroup` (cascade/spotlight) — beide strukturell dasselbe wie
`try_require`, Soft-Dependency-Brücken, die genau ohne lib.nvim funktionieren
müssen. Details in `Merged_Finished.md`.

---

## Ein unbestätigter Verdacht aus einem früheren Chat, weiterhin offen

Während eines früheren Chats war die **Cmdline-Autocompletion** einmal weg: `:`
schlug keine Befehle mehr vor, während die Befehle selbst liefen
(`:Reposcope status` ging). Kurz danach ging es wieder, ohne dass etwas
geändert wurde — der Verdacht des Users war ein Sync-Fehler. Headless nicht
reproduzierbar gewesen. Falls es wiederkommt: erster Blick gehört blink.cmp
und seiner Cmdline-Quelle, nicht dem `usercmd`-Register.

---

## Arbeitsregeln (weiterhin gültig für Folgearbeit in diesem Bereich)

- Commit/Push/Pull **immer auf `main`**, pro Repo einzeln.
- Commit-Messages **ohne** `Co-Authored-By: Claude`.
- Code, Kommentare und Doku in den Repos **englisch**; Konversation deutsch;
  Roadmap-/Handover-Dateien folgen dem Bestand und sind deutsch.
- Vor jedem Commit: `stylua lua && luacheck lua`, dann der Test-Runner des
  Repos. **`stylua lua` nie über die nvim-Config laufen lassen** — sie ist
  nicht stylua-formatiert, ein Lauf formatiert 141 Dateien nebenbei um. Dort
  nur die tatsächlich geänderten Dateien einzeln formatieren.
- **Kein bare `git stash`** — der Stash-Stack ist über Worktrees geteilt.
