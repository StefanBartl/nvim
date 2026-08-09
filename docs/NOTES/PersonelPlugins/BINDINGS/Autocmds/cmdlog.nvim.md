# cmdlog — Autocmds Cheatsheet

**Stale as of the 2026-08-09 checklist pass** — this file used to say "none",
which was accurate at the time but the plugin has since grown two autocmd
registrations:

| Event(s) | Scope | Source | Description |
| --- | --- | --- | --- |
| `CmdlineLeave` | global, one augroup (`cmdlog_tracker`) | `core/tracker.lua` | Records every `:` command into project history / usage stats / known-error tracking. Gated by `setup({ track_commands = false })` (default `true`) |
| `BufWritePost`, `TextChanged`, `TextChangedI` | note buffer (buffer-local, created per note) | `core/notes.lua` (`attach_autosave`) | Writes the note buffer's content to disk. Only attached when `notes.enabled` and `notes.autosave` (both default `true`) |

Cross-reference: `docs/BINDINGS.md` in the repo documents both (the second
one already did; `CmdlineLeave` was added by a later roadmap feature after
this file was last written). `docs/BINDINGS.md` explicitly notes that
`lua/cmdlog/bindings/autocmds.lua` is a descriptive catalog only — the
actual `nvim_create_autocmd` calls stay in `core/tracker.lua` and
`core/notes.lua` since one is buffer-local and dynamically created.
