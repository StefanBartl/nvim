# casedesk — Keymaps Cheatsheet

Almost no global keymaps. casedesk is command-driven
(`:Case`/`:Cases`/`:Tricentis`, see [`Usercmds.md`](./Usercmds.md)) — every
binding it registers besides the one below is buffer-local to a
`kit.viewer` surface, set up fresh each time that surface opens and gone as
soon as it closes.

## `<leader>cs` — case-aware session save (global)

Source: `lua/bindings/mappings/custom.lua` (not `lua/bindings/usrcmds/case/`
— it's casedesk-aware but lives with the config's other `<leader>c*`
utility keymaps rather than in casedesk's own module tree; kept out of
`sessions.nvim`'s own `keymaps` block so that one stays generic). Concept:
[docs/ROADMAP/casedesk/SESSIONS.md](../../ROADMAP/casedesk/SESSIONS.md) §5.

Saves the current Neovim session under the case number
(`resolve.sync(nil)`, the same buffer→case lookup `:Case snow`/`:Case
activity`/etc. all use) when the focused buffer belongs to a case,
otherwise falls through to `sessions.nvim`'s own auto-resolve (project/
branch-aware name, not a hardcoded `"last"`). Explicit-only — no autosave
hook overwrites a case session on exit, so a stray split from an unrelated
task never silently clobbers a case's saved layout.

Every case also gets this run once automatically right after `:Case new`
finishes scaffolding (SESSIONS.md §3) — a case has a session from the
moment it's created, not only after the first manual `<leader>cs`.

### `:Cases list` — the mark view

Source: `lua/bindings/usrcmds/case/ui.lua`, `M.list_all()`, backed by
`marks.lua` (a flat, session-global set of case numbers — not buffer-local,
survives this view closing). ROADMAP.md's "marking system wie in
filetree.nvim": mark cases here, run `:Cases close` whenever afterward.

| lhs | mode | action |
| --- | --- | --- |
| `m` | n | Toggle the mark on the case under the cursor, re-render (`[x]`/`[ ]` prefix) |
| `m` | x (Visual-line) | Toggle the mark on every case in the selected line range |
| `c` | n | If anything is marked: close the view and run `:Cases close` (§ below) on the marks. Otherwise: warn, no-op |

`q`/`<Esc>` close the view without touching marks — same generic
`kit.viewer` behavior as the infocard below, not something this view sets
up itself.

### `:Case info [nr]` — the infocard

Source: `lua/bindings/usrcmds/case/ui.lua`, `M.info()`.

| lhs | mode | action |
| --- | --- | --- |
| `e` | n | Close the infocard, open `M.edit_info` (the `kit.form` to edit title/company/priority/tosca-version/name/notes) |
| `s` | n | Close the infocard, open the case's `Summary.md` |
| `o` | n | Close the infocard, open the case folder (filetree reveal if available, else netrw) |

### `:Case reply check` — the reply-gate report

Source: `lua/bindings/usrcmds/case/ui.lua`, `M.reply_check()`. Both keys
are conditional — set up only when the report has something for them to
act on.

| lhs | mode | action |
| --- | --- | --- |
| `c` | n | Only if emojis were found. Close the report, call `replygate.clear_emojis` on the buffer that was checked (not the report itself) |
| `s` | n | Always present. Close the report, switch to the checked buffer, run `language.spellcheck(nil, "buffer")` |

Registered via `lib.nvim.bindings.keymap` with `{ buffer = surf.bufnr, nowait = true }` —
gone as soon as its surface closes, never leak into any other buffer.

## Not casedesk's own

`q` and `<Esc>` close the infocard too, plus it closes automatically on
focus loss — but that's `lib.nvim.ui.kit.viewer`'s own generic behavior
(every `kit.viewer` surface in the whole config gets it), not something
casedesk sets up itself. Listed in the infocard's own footer line
("`e edit · o open folder · s summary · q close`") for discoverability, but
there's no `map("n", "q", ...)` call anywhere in this module.
