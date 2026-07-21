# `pickers.nvim`

1. **`entry_actions` in `pickers.keys` absorbieren** (Phase 1) — `create_file`/`open_background` leben noch als eigener Config-Namespace neben `keys`, obwohl sie strukturell dieselbe Art von In-Picker-Binding sind. War als Breaking-Change-Entscheidung offen gelassen, du hast dich noch nicht dazu geäußert.

2. **`pickers.builtins`-Registry um ~17 Einträge erweitern + `usrcmds/` löschen** (Phase 4) — deine bewusste Entscheidung von eben, vorerst so gelassen. Steht als klar dokumentierter Folgeschritt in der ROADMAP, falls du später doch willst.

- `:PickersResume` / `:PickersScopes` — neue Commands, nie angefangen
- Per-scope `find`-Overrides, Result-count/preview-Toggles
- Optionale Default-Keymaps für `system`/`repos`-Scopes
- Cross-Platform-Audit von `shellescape`/Pfad-Handling

---

