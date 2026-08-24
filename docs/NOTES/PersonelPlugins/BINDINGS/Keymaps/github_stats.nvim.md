# github_stats.nvim — Keymaps Cheatsheet

Source: `lua/github_stats/bindings/keymaps.lua`, `M.setup_keymaps(buf)`
Cross-reference: `docs/BINDINGS.md` — verified current and precise.

All buffer-local to the dashboard buffer, mode `n` — none of these is ever a
global keymap. Uses a local `map_key()` helper that wraps `vim.keymap.set`
with an automatic debounced re-render after the action runs, plus a few
direct `vim.keymap.set` calls for fixed/always-on bindings.

The tables below are split along that same line — configurable via
`keybindings` vs. fixed, plus the blockers and the separate detail-view
float. This is the file's real structure, not a formatting choice: it is
what the paragraph above already described in prose, and
`BINDINGS-FORMAT.md` §1 wants it as a heading per table so each row carries
its own scope label.

## Blocked keys (`<Nop>`, always on)

| lhs (config key / default) | action | desc | condition |
| --- | --- | --- | --- |
| `h`,`l`,`<Left>`,`<Right>`,`<PageUp>`,`<PageDown>`,`<Home>`,`<End>` | `<Nop>` | none | Always — blocks native cursor movement that would race with dashboard state |

## Configurable bindings (`map_key()`, disable-able via `keybindings`)

| lhs (config key / default) | action | desc | condition |
| --- | --- | --- | --- |
| `navigate_down` (`j`) | Move selection down | "GitHub Stats: navigate down" | disable-able; `5j` moves 5 repos (`vim.v.count1`, since 2026-07-31) |
| `navigate_up` (`k`) | Move selection up | "GitHub Stats: navigate up" | disable-able; same count support |
| `show_details` (`<CR>`) | Show repository details | "GitHub Stats: show repository details" | disable-able |
| `refresh_selected` (`r`) | Drop the storage read memo, then re-render from disk (no API call) | "GitHub Stats: re-read from disk and refresh" | disable-able; meaning changed 2026-08-25 |
| `refresh_all` (`R`) | Force-fetch every configured repo | "GitHub Stats: refresh all repositories" | disable-able |
| `force_refresh` (`f`) | Force-fetch only the selected repo | "GitHub Stats: force refresh selected repository" | disable-able |
| `cycle_sort` (`s`) | Cycle `clones→views→name→trend`. `Ns` advances N | "GitHub Stats: cycle sort criteria" | disable-able |
| `cycle_time_range` (`t`) | Cycle `7d→30d→90d→max` | "GitHub Stats: cycle time range" | disable-able; last step was `all` until 2026-08-23 |
| `custom_time_range` (`T`) | Prompt (`vim.fn.input`) for a free-form time range (e.g. `3m`, `since:2025-01-01`, a `date_presets` name); rejected with an error notification if unrecognized by `analytics.parse_time_range` | "GitHub Stats: enter custom time range" | disable-able; added 2026-08-09 |
| `max_time_range` (`m`) | Set the range to `max` — the longest duration the stored data covers — and notify the resolved span (`analytics.get_history_span`) | "GitHub Stats: set maximum time range" | disable-able; added 2026-08-23 |
| `quit` (`q`) | Close dashboard | "GitHub Stats: quit dashboard" | only if `keybindings.quit ~= ""` |
| `show_help` (`?`) | `vim.notify` overlay listing every current keybinding | "GitHub Stats: show help" | disable-able |

## Fixed bindings (direct `vim.keymap.set`, not configurable)

| lhs (config key / default) | action | desc | condition |
| --- | --- | --- | --- |
| `<Down>` (fixed) | Same as navigate_down | none | always; same count support |
| `<Up>` (fixed) | Same as navigate_up | none | always; same count support |
| `<C-d>` (fixed) | Scroll half page down | "GitHub Stats: scroll half page down" | always; raw `vim.v.count` scrolls exactly that many lines when given (e.g. `1<C-d>`), falls back to the fixed 10-line default when count is 0 (since 2026-07-31) |
| `<C-u>` (fixed) | Scroll half page up | "GitHub Stats: scroll half page up" | always; same count support |
| `<C-f>` (fixed) | Full-page scroll down | "GitHub Stats: scroll full page down" | always; `vim.v.count1` scrolls N pages (since 2026-07-31) |
| `<C-b>` (fixed) | Full-page scroll up | "GitHub Stats: scroll full page up" | always; same count support |
| `gg` (fixed) | Jump to top | "GitHub Stats: jump to top" | always; raw `vim.v.count` jumps to repo index N when given (Vim's `NgG` convention), else top (since 2026-07-31) |
| `G` (fixed) | Jump to bottom | "GitHub Stats: jump to bottom" | always; raw `vim.v.count` jumps to repo index N when given, else bottom |
| `<Esc>` (fixed) | Close dashboard (fallback, regardless of `quit` config) | "GitHub Stats: quit dashboard" | always |

## Detail-view float

Registered every time `:GithubStats show` produces a floating buffer — a
different buffer from the dashboard, hence its own table.

| lhs (config key / default) | action | desc | condition |
| --- | --- | --- | --- |
| `<BS>` | Closes the float and reopens the main dashboard after a 100ms defer | none | always, while the detail float is open |


## Notes

- **`navigate_down`/`navigate_up` deliberately do NOT use `move_down(state,
  count)`/`move_up(state, count)`** (found 2026-07-31 while adding count
  support) — those delegated to a private `move_to_index()` that assumed 3
  lines per repo entry (`target_line = 2 + 3*target_index`) while entries
  actually render 5 lines, a real bug flagged as Priority-0 in this repo's
  `docs/ROADMAP.md`. A `count` parameter was added directly to the shipped,
  correct `move_cursor_down`/`move_cursor_up` instead. **Update (checklist
  pass, 2026-08-06)**: `move_to_index`/`move_down`/`move_up`/`move_first`/
  `move_last` were confirmed dead (never called from anywhere) and removed
  from `dashboard/movement.lua` entirely, so this is no longer a live
  landmine — only `move_cursor_down`/`move_cursor_up` remain. The
  line-height bug they carried is separately fixed: `dashboard/render.lua`
  now exports `M.ENTRY_LINES = 5` as the single source of truth for every
  scroll/cursor calculation in `dashboard/{state,render,movement}.lua`.

## which-key

Collects `{key, desc, buffer}` as keymaps are registered, one `pcall`
`which_key.add` call at the end. **v3 `add` API only** — no v2 `register`
fallback (unlike emojis/fileops/filetree/gopath, which support both).

## Changelog

- 2026-08-25: `refresh_selected` (`r`) now drops
  `github_stats.storage`'s read memo before re-rendering, and its which-key
  description changed to "re-read from disk and refresh". Before the memo
  existed, `r` re-rendered from whatever was already in memory -- which was
  the same thing every other keypress did, so the binding had no distinct
  effect at all. It is now the documented way to pick up a change written by
  another window or another Neovim instance. No new binding; nothing else in
  this table moved.
- 2026-08-23: added `max_time_range` (default `m`) — one keypress to the
  maximum locally stored duration, alongside the `t` cycle and the `T`
  prompt. `TIME_RANGE_CYCLE`'s last step changed `all` → `max` (identical
  filtering, i.e. none; `all` remains accepted from `setup()` and the `T`
  prompt). The dashboard header grew to `HEADER_LINES = 5` — the extra line
  carries the key hints, which are now generated from the *effective*
  keybindings instead of a hardcoded string, so a remap shows up here and a
  key disabled with `""` disappears from the hint line entirely. The status
  line appends the window the active range resolved to
  (`Range:max (2025-03-04 -> 2026-08-22, 172 days)`).
- 2026-08-09: added `custom_time_range` (default `T`), a free-form time
  range prompt alongside the existing `cycle_time_range` (`t`) 7d/30d/90d/all
  cycle. New `analytics.parse_time_range` accepts `Nd`/`Nw`/`Nm`/`Ny`,
  `since:YYYY-MM-DD`, a bare ISO date, `all`, or any `date_presets` name
  (built-in or user-custom).

## Count on the two cycles (2026-08-24)

`Ns` / `Nt` advance that many positions. Both counts are taken **modulo the
cycle length**, so `5s` over a four-entry cycle lands one along instead of
looping four extra times for nothing, and `4s` is a deliberate no-op. A
count larger than the cycle is a fat-fingered keypress, not a request to
spin.

This closes the count audit's entry and brings the two cycles in line with
the rest of this dashboard — `j`/`k`, `<C-d>`/`<C-u>`, `<C-f>`/`<C-b>` and
`Ngg`/`NgG` already read a count, which is exactly why their absence here
stood out. No `desc` strings changed.

Also rolled back the last two raw-API autocmds (`BufWipeout` in
`dashboard/init.lua`, `VimResized` in `dashboard/layout.lua`). Their comment
said `lib.nvim.autocmd.create` did not forward `buffer`, so the wrapper
would have turned them into global listeners. It forwards it now — verified
at runtime that both stay buffer-scoped with no global leak.
