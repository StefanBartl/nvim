# casedesk — Keymaps Cheatsheet

No global keymaps. casedesk is command-driven (`:Case`/`:Cases`/`:Tricentis`, see
[`Usercmds.md`](./Usercmds.md)) — every binding it registers is buffer-local
to a `kit.viewer` surface, set up fresh each time that surface opens and
gone as soon as it closes.

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

Registered via `lib.nvim.map` with `{ buffer = surf.bufnr, nowait = true }` —
gone as soon as its surface closes, never leak into any other buffer.

## Not casedesk's own

`q` and `<Esc>` close the infocard too, plus it closes automatically on
focus loss — but that's `lib.nvim.ui.kit.viewer`'s own generic behavior
(every `kit.viewer` surface in the whole config gets it), not something
casedesk sets up itself. Listed in the infocard's own footer line
("`e edit · o open folder · s summary · q close`") for discoverability, but
there's no `map("n", "q", ...)` call anywhere in this module.
