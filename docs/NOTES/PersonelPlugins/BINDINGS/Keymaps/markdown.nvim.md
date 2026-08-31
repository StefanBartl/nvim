# markdown.nvim — Keymaps Cheatsheet

Source: `lua/markdown/bindings/keymaps.lua`
Cross-reference: `docs/BINDINGS.lua`, `docs/keymaps.md` — both current for keymaps/commands.

Buffer-local, installed on `FileType` for markdown/mdx/md (see
[Autocmds cheatsheet](../Autocmds/markdown.nvim.md)). Gated overall by
`enable_keymaps` (default on) and individually overridable via
`config.keymaps[id]` (`false` disables, string/table remaps). Installed via
`pcall(vim.keymap.set, ...)`, warns (doesn't error) on failure.

## `DEFAULT_KEYMAPS`

| id | mode | lhs | action | feature/flag |
| --- | --- | --- | --- | --- |
| toggle_bold | v | `**` | Wrap selection in `**bold**` | `map_double_asterisk` (default on) |
| wrap_link_n | n | `<leader>[` | Wrap word under cursor in a link (auto-detects URL/path→target vs plain text→label) | `map_wrap_link` (default on) |
| wrap_link_v | v | `<leader>[` | Same, visual | `map_wrap_link` |
| prev_heading | n,v,x | `<C-p>` | Goto previous heading | — |
| prev_heading_bracket | n | `[[` | Same, alt key | — |
| next_heading | n,v,x | `<C-f>` | Goto next heading | — |
| next_heading_bracket | n | `]]` | Same, alt key | — |
| prev_heading_level | n | `<leader><C-p>` | Goto prev heading at count-level | — |
| next_heading_level | n | `<leader><C-f>` | Goto next heading at count-level | — |
| fold_toggle_zf | n | `zf` | Toggle fold under cursor (overrides built-in `zf`) | `use_zf_override` (default on) |
| fold_toggle | n | `<localleader>f` | Same, non-overriding | — |
| unfold_all | n | `zu` | Unfold all, center | — |
| fold_prev_heading | n | `zi` | Fold prev heading, center. `3zi` hops back 3 headings before folding (`vim.v.count1`, since 2026-07-31 — has its own private Setext-aware single-hop search, so this needed its own loop rather than delegating to `prev_heading`'s) | — |
| fold_h2plus | n | `zk` | Toggle outline, keeps H1/H2 open. `3zk` folds below heading level 3 instead of the fixed H2 default (raw `vim.v.count`, since 2026-07-31 — mirrors `toc`'s existing "count sets the level" convention below) | — |
| toc | n | `<leader>toc` | Insert/refresh TOC (`vim.v.count` = max heading level) | feature `toc` (survives `just_enable={"toc"}` even with keymaps off) |
| cursor_action_2click | n | `<2-LeftMouse>` | Open anchor/image/url/file under cursor (silent — a miss is a normal, frequent mouse-move outcome); double-click on a heading toggles its fold instead | — |
| cursor_action_cclick | n | `<C-LeftMouse>` | Same | — |
| cursor_action | n | `ma` | Same, non-silent | — |
| open_image | n | `mi` | Open image. With images.nvim, snacks.nvim (`Snacks.image`) or image.nvim installed, offers an in-Neovim float preview vs. the system viewer; `image.preview` = `"ask"` (default) / `"preview"` / `"system"`. With none installed, system viewer, no prompt. Remote images and failed previews always fall back to the system handler. images.nvim preferred when several are installed (2026-08-07) — the only one of the three that draws on native Windows Neovim in WezTerm, via `images.browse.draw_in_window()`. | soft dep: images.nvim *or* snacks.nvim *or* image.nvim |
| jump_anchor | n | `mj` | Jump to anchor | — |
| heading_inc / _dec | n | `<C-Right>`/`<C-Left>` | Shift current line's heading level by `vim.v.count1` | — |
| heading_inc_visual / _dec_visual | v,x | `<C-Right>`/`<C-Left>` | Shift visual selection's headings | — |
| heading_inc_all / _dec_all | n | `<S-Right>`/`<S-Left>` | Shift ALL headings, or (if fenced-scope on and cursor inside a fenced block) only that block's | — |
| table_next_cell / _prev_cell | n | `]\|` / `[\|` | Next/prev table cell. `3]\|` moves 3 cells (`vim.v.count1`, since 2026-07-31), stopping early at a table edge rather than erroring | feature `table` |
| table_format | n | `<leader>mtf` | Format the table at the cursor — routed through `commands.table.run({"format"})`, i.e. literally the argument-less `:Markdown table format` (same cursor scope, same `config.table` alignment, same "Table formatted" notify) rather than calling `table_fmt` directly, so key and command can't drift (since 2026-08-31) | feature `table` |

## TableView keys (`M.apply_tableview`, independent of `enable_keymaps`)

| lhs | action |
| --- | --- |
| `<leader>tvt` | `:TableViewToggle` |
| `<leader>tvx` | `:TableViewBox` |
| `<leader>tvs` | `:TableViewSelect` |
| `<leader>tvb` | `:TableViewOpenBrowser` |
| `<leader>tvc` | `:TableViewClose` |
| `<leader>tvm` | `:Markdown table mode toggle` |

## Dynamic float-close keymaps (not documented anywhere else)

| lhs | mode | Where |
| --- | --- | --- |
| `q`/`<Esc>` | n | `tableview/renderer.lua` — closes the floating TableView preview |
| `<CR>` | n | `tableview/views/table_selector.lua` — renders chosen table + closes selector |
| `q`/`<Esc>` | n | same — closes selector |

## TableView popup keys (interactive resize/reorder + write-back, `tableview/renderer.lua`)

Buffer-local to the floating preview buffer ITSELF (not markdown buffers),
Normal mode only. Set once in `ensure_view()` when the popup buffer is
created; not gated by `enable_keymaps` (same rationale as the `q`/`<Esc>`
close keys above — this popup has no "editing surface" config flag to
opt out of). No-op when the cursor is on a border/separator/label line
(`resolve_cursor_target()` returns nil via `state.row_map`).

Column widening is applied to the in-memory parsed table's per-column
width-override map (`state.col_overrides`) — display-only, never written
back. Row moves mutate `state.tables[i].rows` in place (a real reorder, not
display-only) and DO get written back on `:w`.

| lhs | action |
| --- | --- |
| `<M-Right>` / `<M-l>` | `resize_current_column(1)` — widen the column under the cursor |
| `<M-Left>` / `<M-h>` | `resize_current_column(-1)` — narrow it; floors at the column's natural content width (never truncates — would misalign `\|` down the column) |
| `<M-Up>` / `<M-k>` | `move_current_row(-1)` — swap the row under the cursor with the row above |
| `<M-Down>` / `<M-j>` | `move_current_row(1)` — swap the row under the cursor with the row below |
| `:w` | `write_back()` (via `BufWriteCmd`) — write the current row order to the source |

**h/j/k/l exist because `<M-Up>`/`<M-Down>` didn't reliably reach Neovim**
(reported 2026-08-08: resize with `<M-Left>`/`<M-Right>` worked, but the
row keys "didn't really work") — the working theory is a
terminal/multiplexer intercepting Alt+Up/Down (common for scrollback/pane
nav) before it becomes a keycode Neovim sees, same class of issue as
Alt+Arrow conflicts elsewhere. Not confirmed against this machine's
WezTerm config specifically; if h/j/k/l also fail, the keycodes likely
aren't reaching Neovim at all (check `:map <M-Up>` for a mapping, and
whether WezTerm even sends a distinct sequence for it).

**`write_back()`** (bound to `:w`): serializes each shown table (via
`build_lines_from_markdowntable`, NATURAL widths — `col_overrides` is
intentionally ignored) and replaces the original line range
(`mt.start_line`/`mt.end_line`) at its source:
- `mt.bufnr` (tagged by `parser.get_tables`, resolved from the `0` "current
  buffer" sentinel) if that buffer is still valid → `nvim_buf_set_lines`,
  marks the buffer modified, does NOT save it.
- else `mt.source` (tagged by `parser.get_tables_from_file`, the
  `%`/`cwd`/`<path>` TableView scopes reading files not open as buffers) →
  `readfile`/`writefile` directly to disk, immediately.
- else (no known origin, e.g. a hand-built `mt`) → skipped, silently.

This only works because the popup buffer's `buftype` is `"acwrite"`, not
`"nofile"`: Neovim's `:write` hard-errors (`E382`) on a `nofile` buffer
REGARDLESS of a registered `BufWriteCmd` autocommand — `acwrite` is the
one buftype `:write` will actually dispatch to `BufWriteCmd` for, and even
then only once the buffer has a name (`E32` otherwise, hence
`nvim_buf_set_name(buf, "markdown-tableview://" .. buf)` in
`ensure_view()`). `q`/`<Esc>` still force-close via `nice_quit(..., {
force = true })` regardless, so unsaved popup edits are silently
discardable as before — `acwrite` only changes what `:w` does, not what
closing does.

## which-key

`bindings/init.lua`, `M.setup()` — labels `<leader>t` as "Markdown",
`<leader>tv` as "Markdown TableView" and `<leader>mt` as "Markdown Table"
(the leader-prefixed groups; every other default key is a bare
motion/bracket pair with its own `desc`, no group needed). Soft-guarded,
no-op if which-key is absent. Handles v3 (`wk.add`) and v2
(`wk.register`).

## Notes

- `docs/BINDINGS.lua`'s `default_keys.editing`/`.tableview`/`.tableview_popup` tables match `DEFAULT_KEYMAPS`/`apply_tableview`/`ensure_view`'s Alt-key mappings id-for-id.

## Changelog

- 2026-08-08: added the "TableView popup keys" section — `<M-Right>`/`<M-Left>`/`<M-Up>`/`<M-Down>` interactive column-resize and row-insert/remove keymaps, buffer-local to the floating preview.
- 2026-08-08 (2): row keys reported not working; changed from insert/remove-row to move-row (swap with the row above/below) per feedback, added `<M-h>`/`<M-j>`/`<M-k>`/`<M-l>` as terminal-safe alternates, and added `:w` write-back (row order only, to the source buffer or file — see the popup-keys section above for the `acwrite`/`BufWriteCmd` mechanism).
- 2026-08-31: added `<leader>mtf` (id `table_format`) — the argument-less `:Markdown table format` on a key, plus the `<leader>mt` which-key group it needs.
