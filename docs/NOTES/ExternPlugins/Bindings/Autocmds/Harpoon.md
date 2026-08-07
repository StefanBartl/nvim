# Harpoon — Autocmds

**Status: durchgehend [custom]**, keine Zeilen-Markierung nötig —
`harpoon.nvim` selbst registriert keine eigenen Autocmds, gegen die
"custom" hier kontrastieren würde; alle vier Gruppen sind vollständig
eigener Code obendrauf.

| Gruppe | Event(s) | Quelle | Zweck |
|---|---|---|---|
| `HarpoonHardening` | `BufLeave`, `FocusLost` (konfigurierbar via `autocmd_events`) | [config/harpoon/hardening.lua](../../../../../lua/config/harpoon/hardening.lua) | Debounced Save (Default 200 ms, `debounce_ms`), damit Änderungen nicht erst beim Beenden landen. |
| `HarpoonHardening` | `VimLeavePre` | dito | Nicht-debounced Flush eines noch ausstehenden Saves beim Beenden. |
| `HarpoonPinMarks` | `FileType harpoon` | [config/harpoon/pin_marks.lua](../../../../../lua/config/harpoon/pin_marks.lua) | 📌-Marker (virtual text, HL-Gruppe `HarpoonPinMark`) an alle Zeilen hängen, die dauerhafte Defaults sind. |
| `HarpoonPinMarks` | `TextChanged`, `TextChangedI` (buffer-lokal im Quick-Menu) | dito | Marker beim Umsortieren/Löschen im Menu live nachziehen. |
| `HarpoonPersistPaths` | `VimEnter` (`once`, nur beim allerersten Start auf der Maschine) | [config/harpoon/persist_paths.lua](../../../../../lua/config/harpoon/persist_paths.lua) | Einmaliges Seeding der Default-Pfade. Marker: `stdpath("state")/harpoon_persist_paths.initialized`. Danach nie wieder automatisch — Nachziehen nur explizit per `:Harpoon defaults sync`. |

Zusätzlich (kein Autocmd, aber derselbe Persistenz-Pfad): das Quick-Menu-Toggle
ist in `hardening.lua` gewrappt, sodass auch das Schließen des Menus einen Save
auslöst.
