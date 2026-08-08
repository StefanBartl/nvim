# `color_my_acii`-Roadmap

---

## Aus `MyPlugin-Notes/color_my_ascii/` (Analyse 2026-08-08)

Quelle: `E:/repos/Notes/MyPlugin-Notes/color_my_ascii/`
(`FEATURE-LIST.md`, `v0.2.0.md` — letztere ist eine gekürzte Kopie der ersten).

**Gegen den Code geprüft** (`E:/repos/color_my_ascii.nvim/lua/color_my_ascii/`).
Der grösste Teil der Liste ist gebaut: `cache_manager.lua`,
`debounce_manager.lua`, `health.lua`, `debug/**` (inkl. `inspect.lua`),
`config/DEFAULTS.lua`, `commands/schemes.lua`, ein umfangreiches
`languages/`-Verzeichnis (>25 Sprachen) und die gesamte Fence-API
(`api/fences.lua`, `commands/fence/{export,format,import,lang,open,run,select,wrap,yank}.lua`,
`fence_hl.lua`, `fence_jump.lua`).

Der einzige substanzielle Punkt der eigenen Repo-Roadmap ist laut
`All/Roadmap-Effort-Overview.md` „LSP-in-Fence via otter.nvim-Adapter" —
das entspricht dem Notiz-Punkt „LSP Integration (Semantic Highlighting)" und
wird dort verfolgt, nicht hier.

Was aus den Notizen wirklich offen ist. **Hinweis:** erledigte Punkte werden
hier entfernt, sobald sie umgesetzt sind — Details + Commit-Referenz landen
stattdessen in `E:/repos/color_my_ascii.nvim/docs/FEATURES.md`.

---

### 1. Generisches Fence-Repair-Command

`:Fence align` (Kanten-Breite von Boxen begradigen) ist umgesetzt — siehe
`FEATURES.md`. Offen ist noch der zweite, breitere Teil der ursprünglichen
Notiz:

- [ ] Command, das verschiedene Regeln (wie das obige align, aber auch
      andere Reparaturen) auf einen fence/buffer/cwd anwendet, sozusagen
      ein generisches fence-repair-command.

**Aufwand:** Mittel
**Nutzen:** mittel — die eigenen Doc-Diagramme (z. B. die Verzeichnisbäume in
`IDEAS/NEW_PLUGIN.md`) sind genau die Zielgruppe.

### 2. Weitere Markup-Formate ausser Markdown

ASCII-Blöcke in Code-Kommentaren (Lua/Python etc.) sind umgesetzt — siehe
`FEATURES.md` (`config.comment_ascii`, expliziter `-- ascii`/`-- /ascii`-
Marker). Offen ist noch der ursprünglich nur als Kontext erwähnte, nie als
Checkbox geführte Teil:

- [ ] „Support für README.org, .rst, .adoc" — native Fence-Erkennung für
      diese Markup-Formate, analog zur Markdown-Fence-Erkennung.

**Aufwand:** Quick Win je Format
**Nutzen:** niedrig.

## name

Passt der name `color_my_ascii.nvim` eigentlich noch ?

---
