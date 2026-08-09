# github_stats.nvim — Keymaps Cheatsheet

Source: `lua/github_stats/bindings/keymaps.lua`, `M.setup_keymaps(buf)`
Cross-reference: `docs/BINDINGS.md` — verified current and precise.

All buffer-local to the dashboard buffer, mode `n`. Uses a local `map_key()`
helper that wraps `vim.keymap.set` with an automatic debounced re-render
after the action runs, plus a few direct `vim.keymap.set` calls for
fixed/always-on bindings.

| lhs (config key / default) | action | desc | condition |
| --- | --- | --- | --- |
| `h`,`l`,`<Left>`,`<Right>`,`<PageUp>`,`<PageDown>`,`<Home>`,`<End>` | `<Nop>` | none | Always — blocks native cursor movement that would race with dashboard state |
| `navigate_down` (`j`) | Move selection down | "GitHub Stats: navigate down" | disable-able; `5j` moves 5 repos (`vim.v.count1`, since 2026-07-31) |
| `<Down>` (fixed) | Same as navigate_down | none | always; same count support |
| `navigate_up` (`k`) | Move selection up | "GitHub Stats: navigate up" | disable-able; same count support |
| `<Up>` (fixed) | Same as navigate_up | none | always; same count support |
| `<C-d>` (fixed) | Scroll half page down | "GitHub Stats: scroll half page down" | always; raw `vim.v.count` scrolls exactly that many lines when given (e.g. `1<C-d>`), falls back to the fixed 10-line default when count is 0 (since 2026-07-31) |
| `<C-u>` (fixed) | Scroll half page up | "GitHub Stats: scroll half page up" | always; same count support |
| `<C-f>` (fixed) | Full-page scroll down | "GitHub Stats: scroll full page down" | always; `vim.v.count1` scrolls N pages (since 2026-07-31) |
| `<C-b>` (fixed) | Full-page scroll up | "GitHub Stats: scroll full page up" | always; same count support |
| `gg` (fixed) | Jump to top | "GitHub Stats: jump to top" | always; raw `vim.v.count` jumps to repo index N when given (Vim's `NgG` convention), else top (since 2026-07-31) |
| `G` (fixed) | Jump to bottom | "GitHub Stats: jump to bottom" | always; raw `vim.v.count` jumps to repo index N when given, else bottom |
| `show_details` (`<CR>`) | Show repository details | "GitHub Stats: show repository details" | disable-able |
| `refresh_selected` (`r`) | Re-render from cached data (no API call) | "GitHub Stats: refresh dashboard" | disable-able |
| `refresh_all` (`R`) | Force-fetch every configured repo | "GitHub Stats: refresh all repositories" | disable-able |
| `force_refresh` (`f`) | Force-fetch only the selected repo | "GitHub Stats: force refresh selected repository" | disable-able |
| `cycle_sort` (`s`) | Cycle `clones→views→name→trend` | "GitHub Stats: cycle sort criteria" | disable-able |
| `cycle_time_range` (`t`) | Cycle `7d→30d→90d→all` | "GitHub Stats: cycle time range" | disable-able |
| `custom_time_range` (`T`) | Prompt (`vim.fn.input`) for a free-form time range (e.g. `3m`, `since:2025-01-01`, a `date_presets` name); rejected with an error notification if unrecognized by `analytics.parse_time_range` | "GitHub Stats: enter custom time range" | disable-able; added 2026-08-09 |
| `quit` (`q`) | Close dashboard | "GitHub Stats: quit dashboard" | only if `keybindings.quit ~= ""` |
| `<Esc>` (fixed) | Close dashboard (fallback, regardless of `quit` config) | "GitHub Stats: quit dashboard" | always |
| `show_help` (`?`) | `vim.notify` overlay listing every current keybinding | "GitHub Stats: show help" | disable-able |

Detail-view float: `<BS>` (n) closes it and reopens the main dashboard after
a 100ms defer — registered every time `:GithubStats show` produces a
floating buffer.

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

- 2026-08-09: added `custom_time_range` (default `T`), a free-form time
  range prompt alongside the existing `cycle_time_range` (`t`) 7d/30d/90d/all
  cycle. New `analytics.parse_time_range` accepts `Nd`/`Nw`/`Nm`/`Ny`,
  `since:YYYY-MM-DD`, a bare ISO date, `all`, or any `date_presets` name
  (built-in or user-custom).
