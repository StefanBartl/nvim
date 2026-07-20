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
| `navigate_down` (`j`) | Move selection down | "GitHub Stats: navigate down" | disable-able |
| `<Down>` (fixed) | Same as navigate_down | none | always |
| `navigate_up` (`k`) | Move selection up | "GitHub Stats: navigate up" | disable-able |
| `<Up>` (fixed) | Same as navigate_up | none | always |
| `<C-d>` (fixed) | Scroll half page down | "GitHub Stats: scroll half page down" | always |
| `<C-u>` (fixed) | Scroll half page up | "GitHub Stats: scroll half page up" | always |
| `<C-f>` (fixed) | Full-page scroll down | "GitHub Stats: scroll full page down" | always |
| `<C-b>` (fixed) | Full-page scroll up | "GitHub Stats: scroll full page up" | always |
| `gg` (fixed) | Jump to top | "GitHub Stats: jump to top" | always |
| `G` (fixed) | Jump to bottom | "GitHub Stats: jump to bottom" | always |
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

## which-key

Collects `{key, desc, buffer}` as keymaps are registered, one `pcall`
`which_key.add` call at the end. **v3 `add` API only** — no v2 `register`
fallback (unlike emojis/fileops/filetree/gopath, which support both).
