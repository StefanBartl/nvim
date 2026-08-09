# `cmdlog.nvim`

---

## Aus `MyPlugin-Notes/cmdlog/` (Analyse 2026-08-08)

Quelle: `E:/repos/Notes/MyPlugin-Notes/cmdlog/` (`cmdlog-dev-notes.md`,
`OPTIONS.CONFIG.md`, `ui/`, `core/favorites/cache.md`) und der cmdlog-Block in
`MyPlugin-Notes/TODOS.md`.

**Gegen den Code geprüft** (`E:/repos/cmdlog.nvim/lua/cmdlog/`) — die Notizliste
umfasst 17 Punkte, davon sind die meisten längst gebaut. Erledigt und deshalb
hier *nicht* mehr aufgeführt: `checkhealth` (`health.lua`), Favoriten-Notizen
(`core/notes.lua`), projektbasierte History (`core/project_history.lua`),
projekt-scoped Favoriten (`project_scoped` in DEFAULTS), Fehler-/Status-Tracking
(`core/errors.lua` + `✗`-Marker in `picker_utils.lua`), Löschen von Einträgen
(`mappings.delete = "<C-x>"`), Tags (`core/tags.lua`), Usage-Stats
(`core/stats.lua`), Risky-Command-Highlighting (`core/risky.lua`), Previewer für
`:help`/`:term`/`:lua`/`:!shell` (`ui/telescope-previewer.lua`), Keymaps über
`setup()`, which-key-Integration, Umbau auf `:Cmdlog <subcommand>`, Privacy-Filter
(`redact_patterns`), `extra_files`, Herkunfts-Marker im kombinierten Picker,
`mappings.cycle_source`, Picker-Legende, Favoriten-Undo/manuelle Sortierung
sowie Favoriten-Export/Import (CLI-Tool weiterhin offen, siehe dessen
`ROADMAP.md`).

Der Cache-Befund aus `core/favorites/cache.md` (Favoriten-Cache ist korrekt,
History-Cache war es nicht) ist ebenfalls umgesetzt.

---

