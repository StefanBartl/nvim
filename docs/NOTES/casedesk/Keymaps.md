# casedesk — Keymaps Cheatsheet

No global keymaps. casedesk is command-driven (`:Case`/`:Cases`, see
[`Usercmds.md`](./Usercmds.md)) — the only bindings it registers are three
buffer-local ones inside the infocard's `kit.viewer` surface, set up fresh
each time `:Case info [nr]` opens one.

Source: `lua/bindings/usrcmds/case/ui.lua`, `M.info()`.

| lhs | mode | scope | action |
| --- | --- | --- | --- |
| `e` | n | buffer-local (infocard surface) | Close the infocard, open `M.edit_info` (the `kit.form` to edit title/company/priority/tosca-version/name/notes) |
| `s` | n | buffer-local (infocard surface) | Close the infocard, open the case's `Summary.md` |
| `o` | n | buffer-local (infocard surface) | Close the infocard, open the case folder (filetree reveal if available, else netrw) |

Registered via `lib.nvim.map` with `{ buffer = surf.bufnr, nowait = true }` —
gone as soon as the infocard closes, never leak into any other buffer.

## Not casedesk's own

`q` and `<Esc>` close the infocard too, plus it closes automatically on
focus loss — but that's `lib.nvim.ui.kit.viewer`'s own generic behavior
(every `kit.viewer` surface in the whole config gets it), not something
casedesk sets up itself. Listed in the infocard's own footer line
("`e edit · o open folder · s summary · q close`") for discoverability, but
there's no `map("n", "q", ...)` call anywhere in this module.
