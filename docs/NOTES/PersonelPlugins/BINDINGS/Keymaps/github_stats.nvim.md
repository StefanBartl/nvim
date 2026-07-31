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
| `quit` (`q`) | Close dashboard | "GitHub Stats: quit dashboard" | only if `keybindings.quit ~= ""` |
| `<Esc>` (fixed) | Close dashboard (fallback, regardless of `quit` config) | "GitHub Stats: quit dashboard" | always |
| `show_help` (`?`) | `vim.notify` overlay listing every current keybinding | "GitHub Stats: show help" | disable-able |

Detail-view float: `<BS>` (n) closes it and reopens the main dashboard after
a 100ms defer — registered every time `:GithubStats show` produces a
floating buffer.

## Notes

- **`navigate_down`/`navigate_up` deliberately do NOT use this module's
  existing `move_down(state, count)`/`move_up(state, count)` helpers**
  (found 2026-07-31 while adding count support). Those delegate to
  `move_to_index()`, which assumes 3 lines per repo entry
  (`target_line = 2 + 3*target_index`) while entries actually render 5-6
  lines — a real, pre-existing bug already flagged as Priority-0 in this
  repo's own `docs/ROADMAP.md`. Confirmed with a headless test: for the
  identical single step, `move_down(state,1)` lands on a different
  `scroll_offset` than the currently-shipped single-step function. Instead,
  a `count` parameter was added directly to the shipped, correct
  `move_cursor_down`/`move_cursor_up` (loops their existing single-step
  body) — behavior-identical to before for `count=1` by construction, and
  doesn't inherit the line-height bug. If `move_down`/`move_up` are ever
  fixed for the ROADMAP item, `navigate_down`/`up` could switch to them.

## which-key

Collects `{key, desc, buffer}` as keymaps are registered, one `pcall`
`which_key.add` call at the end. **v3 `add` API only** — no v2 `register`
fallback (unlike emojis/fileops/filetree/gopath, which support both).
