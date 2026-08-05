# casedesk — Autocmds Cheatsheet

None. Confirmed by a repo-wide grep across `lua/bindings/usrcmds/case/*.lua`
for `autocmd`/`augroup`/`nvim_create_autocmd` — zero matches.

casedesk is purely command- and callback-driven: every `:Case`/`:Cases`
route (see [`Usercmds.md`](./Usercmds.md)) runs synchronously or through a
`kit.*` component's own callback (`on_submit`/`on_select`/`on_answer`), and
the one async path (`:Cases linkcheck`, via `lib.nvim.net.curl`) resolves
through a plain Lua callback, not an event. There's no "when a case buffer
opens" or "on save" hook anywhere in the module — `:Case sync`/`:Case add`
are the explicit, user-triggered equivalent of what an autocmd would
otherwise paper over automatically, matching the rest of the module's
"nothing happens without a command" design.

If that ever changes (e.g. a future `BufWritePost` hook to auto-detect a new
link and offer to add it to `.case.json`), this file is where it'd be
documented — same convention as every other module in
`docs/NOTES/PersonelPlugins/BINDINGS/Autocmds/`.
