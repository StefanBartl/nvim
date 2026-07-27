# sandbox.nvim — Autocmds Cheatsheet

**Update 2026-07-26 (later same day)**: no longer strictly "none" — two
**buffer-local, one-shot** `BufWipeout` autocmds exist, both pure cleanup,
neither registering a global augroup:

- `lua/sandbox/ui/list_actions.lua` — stops and closes a list view's
  `refresh_interval` timer (`vim.uv`/`luv` timer) when that view's specific
  buffer is wiped, so an auto-refreshing list doesn't keep a timer running
  against a buffer that no longer exists.
- `lua/sandbox/ui/log_follow_view.lua` — stops the `logs -f` background
  job when a `container logs-follow` buffer is wiped, so following a
  container's logs doesn't leak a job after you close the buffer (`q`
  inside the buffer does the same thing manually, before wipeout).

Both are scoped with `buffer = bufnr` and `once = true` — they fire for
exactly one specific scratch buffer and then remove themselves; there is
still no `nvim_create_augroup` anywhere in the repo, and no autocmd
listens buffer-agnostically or on a filetype/pattern basis. The prior
"still none" note (also dated 2026-07-26, written right after the
volumes/networks/compose/keymaps push) predates these two — they landed
later the same day alongside `refresh_interval`
(auto-refresh, task from `docs/ROADMAP.md` §5) and `logs-follow`
(live log follow, same section).

Cross-reference: `docs/BINDINGS.md`'s "## Autocmds" section and
`doc/sandbox.txt` (native `:help sandbox`, added 2026-07-26) now describe
the same two autocmds — previously both also said "None defined", caught
and fixed as part of finishing off the ROADMAP.md items.
