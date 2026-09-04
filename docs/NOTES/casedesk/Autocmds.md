# casedesk — Autocmds Cheatsheet

Exactly one, and it belongs to the SLA layer.

| event | group | source |
| --- | --- | --- |
| `FocusGained` | `CasedeskSlaNotify` | `casedesk.nvim`, `lua/casedesk/sla/notify.lua` |

It re-checks the watched cases' SLA clocks when the editor comes back to the
foreground, on top of the background timer the same `setup()` starts
(`config.sla_notify_interval_seconds`, default 900 — SLA.md §6C). Both are
guarded by `config.sla_notifications_enabled`: turn notifications off and
casedesk installs no autocmd at all.

Nothing else. Every `:Case`/`:Cases` route (see [`Usercmds.md`](./Usercmds.md))
runs synchronously or through a `kit.*` component's own callback
(`on_submit`/`on_select`/`on_answer`), and the one async path
(`:Cases linkcheck`, via `lib.nvim.net.curl`) resolves through a plain Lua
callback, not an event. There's no "when a case buffer opens" or "on save"
hook anywhere in the module — `:Case sync`/`:Case add` are the explicit,
user-triggered equivalent of what an autocmd would otherwise paper over
automatically, matching the rest of the module's "nothing happens without a
command" design.

> This page said **"None"** until 2026-09-04. The grep it cited was real, but
> it was run before the SLA notifier existed, and a cheatsheet asserting a
> negative goes stale without anything ever failing.

If that ever changes (e.g. a future `BufWritePost` hook to auto-detect a new
link and offer to add it to `.case.json`), this file is where it'd be
documented — same convention as every other module in
`docs/NOTES/PersonelPlugins/BINDINGS/Autocmds/`.
