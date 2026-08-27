# reposcope.nvim — Keymaps Cheatsheet

Sources: `lua/reposcope/bindings/keymaps.lua`, `ui/actions/readme_viewer.lua`, `utils/stats.lua`, `ui/actions/status_view.lua`

**2026-08-09: `docs/BINDINGS.md` no longer omits the component-local
keymaps below** — all are now documented there too, in a dedicated
"Close-UI" adjacent section. This file's own "Component-local" table below
is kept as the one place they're all shown side by side.

## Global open/close (`M.set_user_keymaps`, only if `config.get_option("keymaps") ~= false`)

| lhs (config key) | mode | action | desc |
| --- | --- | --- | --- |
| `<leader>rs` (`keymaps.open`) | n | `pcall`-wrapped `open_ui()`; prints an error via `print()` (not `notify`) on failure | "Open Reposcope" |
| `<leader>rc` (`keymaps.close`) | n | Same pattern, `close_ui()` | "Close Reposcope" |

Each only registered if its config value is truthy/non-empty.

## Prompt-field keymaps (`M.set_prompt_keymaps`, buffer-local to every prompt buffer)

Built from an actions table, each action individually configurable via
`config.prompt_keymaps` (a value can be a list for multiple lhs, e.g.
`focus_next`); set an action to `false`/`""` to disable it.

| Action | Default lhs | mode | action |
| --- | --- | --- | --- |
| `confirm` | `<CR>` | i | `prompt_input.on_enter()` |
| `nav_up` | `<Up>` | n, i | Navigate list up, fetch README for newly-selected repo. `3<Up>` moves 3 rows in one call (`vim.v.count1`, since 2026-07-31, clamped to list bounds); harmless in insert mode since `vim.v.count1` never leaks a stale normal-mode count into an insert-mode mapping's dispatch (verified) |
| `nav_down` | `<Down>` | n, i | Navigate list down, fetch README. Same count support as `nav_up` |
| `focus_next` | `<C-w>`, `<C-l>`, `<Tab>` (list) | n, i | Focus next UI panel |
| `focus_prev` | `<C-h>`, `<S-Tab>` (list) | n, i | Focus previous panel |
| `open_viewer` | `<C-v>` | n, i | Open README viewer |
| `open_editor` | `<C-b>` | n, i | Open README editor |
| `clone` | `<C-c>` | n, i | Prompt and clone selected repo |
| `backspace` | `<BS>` | n, i | Custom: suppressed at column 0, line 2 of the `keywords` prompt buffer (notifies "Backspace disabled..."); otherwise feeds a real `<BS>` |
| `preview_scroll_up` | `<C-u>` | n, i | `preview_manager.scroll(-1)` — half-page up in the preview window, focus stays in the prompt (Telescope-style peek scroll) |
| `preview_scroll_down` | `<C-d>` | n, i | `preview_manager.scroll(1)` — same, half-page down |
| `help` | `?` | n only | Opens the `?` keymap cheatsheet (`ui/actions/help_view.lua`); deliberately normal-mode only so `?` still types in insert mode |
| `toggle_favorite` | `<C-f>` | n, i | Toggles favorite status for `repository_cache.get_selected()`, via `state/favorites_state.lua` |

## Close-UI keymaps (`M.set_close_ui_keymaps`, over background/preview/list/all-prompt buffers, tagged `"reposcope_ui"`)

| lhs | mode | action | desc |
| --- | --- | --- | --- |
| `<Esc>` | n | `close_ui()` | "Close Reposcope" |
| `<Esc>` | i, t, v | `<C-\><C-n>` (switch to normal mode first) | "Switch to normal mode" |
| `<C-w>` | n | `close_ui()` | "Close Reposcope" |
| `<C-w>` | i, t, v | `<Nop>` | "Disabled" |

## Component-local

Not part of `set_ui_keymaps()`/`set_prompt_keymaps()`; each is set/unset by
its own component whenever it opens/closes.

| lhs | mode | Where | action |
| --- | --- | --- | --- |
| `q` | n | `ui/actions/readme_viewer.lua` (`nvim_buf_set_keymap`) | Closes the README viewer, restores prompt autocmds + prompt keymaps |
| `q` / `<Esc>` | n | `utils/stats.lua` | Closes the stats popup buffer/window |
| `q` / `<Esc>` | n | `ui/actions/help_view.lua`, via `lib.nvim.ui.kit`'s `nice_quit` | Closes the `?` keymap cheatsheet |
| `<CR>` / `<2-LeftMouse>` | n | `ui/actions/status_view.lua` (`lib.nvim.bindings.keymap`, buffer-local, every interactive `--out` backend of `:Reposcope status`) | Row under cursor → `lib.nvim.ui.kit.confirm` prompt → on yes, `:edit`s that repository's `README.md`. No readable README.md just notifies, no prompt |
| `p` / `P` / `f` | n | `ui/actions/status_view.lua` (same backends) | Push / pull (`--ff-only`) / fetch the repo under the cursor, via `utils/repo_actions.lua`. Spinner on the row while running, then that one row is re-read |
| `S` | n | `ui/actions/status_view.lua` (same backends) | Nested popup with `git status --short --branch` + last 5 commits (`repo_status.status_detail`) |
| `s` | n | `ui/actions/status_view.lua` (same backends) | Cycles sort: discovery → name → state (worst first) → last-commit age |
| `r` / `R` | n | `ui/actions/status_view.lua` (same backends) | Re-read the row under cursor / re-scan the whole directory |
| `y` | n | `ui/actions/status_view.lua` (same backends) | Yanks the repo path into `+` and `"` |
| `?` | n | `ui/actions/status_view.lua` (same backends) | Lists every status-overview key, generated from `ROW_KEYMAPS` |
| `q` | n | `ui/actions/status_view.lua` (buffer-local on a README opened from a status row) | Wipes the README buffer and restores the overview on the same row |

All of the `:Reposcope status` row keys above come from a single `ROW_KEYMAPS`
table in `status_view.lua`, which also generates the winbar legend and the `?`
cheatsheet — same single-source-of-truth pattern as `help_view.lua`. `r`, `R`
and `y` carry no `label`, so they're omitted from the legend (which would
otherwise wrap) but still listed under `?`.

## which-key

No dedicated which-key module/group registration (`wk.add`/`wk.register`) —
confirmed against source, still true as of 2026-08-09. But **every** keymap
set via `bindings/keymaps.lua` (global open/close, every prompt action,
close-UI) now carries a `desc`, which which-key auto-lists without any
explicit registration needed — a real, if passive, form of support that
didn't exist when this file previously said "no which-key integration at
all". The one thing still missing: `<leader>r` is a genuine shared prefix
(`<leader>rs`/`<leader>rc`) that a `wk.add({ { "<leader>r", group = "..." } })`
call could label as a group, and nothing does.

## Notes

- Opening the README viewer explicitly tears down the prompt autocmds and prompt keymaps before installing its own `q` keymap; `close_viewer()` restores them — the two keymap sets are mutually exclusive **by design**, not overlapping accidentally.
- See [Autocmds cheatsheet](../Autocmds/reposcope.nvim.md) for the prompt-buffer autocmds these keymaps interact with.

## Changelog

- 2026-08-18: Filled in the `:Reposcope status` row keys that were missing
  here (`p`/`P`/`f` had landed earlier and were never recorded), and added the
  new `S`/`s`/`r`/`R`/`y`/`?` plus the README-return `q`. All of them are now
  declared in one `ROW_KEYMAPS` table that also generates the winbar legend and
  the `?` cheatsheet, so this table is the only place that can still drift.
  Worth remembering: the "pressing p does nothing visible" symptom was
  `utils/debug.lua` swallowing INFO-level notifies outside dev mode, not a
  missing keymap.
- 2026-08-09 (3): Added the `status_view.lua` component-local row: `<CR>`/
  `<2-LeftMouse>` on a `:Reposcope status` row opens that repository's
  `README.md`, gated behind a `lib.nvim.ui.kit.confirm` yes/no prompt.
- 2026-08-09 (2): Added `toggle_favorite` (`<C-f>`) — toggles the selected
  repository's favorite status via the new `state/favorites_state.lua`
  (roadmap item "Favoriten für Repositories", `personal/reposcope.nvim.md`).
- 2026-08-09: Added `preview_scroll_up`/`preview_scroll_down` (`<C-u>`/`<C-d>`,
  Telescope-style peek-scroll of the README preview without leaving the
  prompt) and `help` (`?`, keymap cheatsheet) prompt actions. Corrected the
  which-key note (see above) and confirmed `docs/BINDINGS.md` now documents
  the two component-local keymaps this file already tracked.
