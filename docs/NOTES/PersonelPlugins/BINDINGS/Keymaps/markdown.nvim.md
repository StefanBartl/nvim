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

## which-key

`bindings/which_key.lua`, `M.setup()` — labels `<leader>t` as "Markdown"
and `<leader>tv` as "Markdown TableView" (the two leader-prefixed groups;
every other default key is a bare motion/bracket pair with its own `desc`,
no group needed). Soft-guarded, no-op if which-key is absent. Handles v3
(`wk.add`) and v2 (`wk.register`).

## Notes

- `docs/BINDINGS.lua`'s `default_keys.editing`/`.tableview` tables match `DEFAULT_KEYMAPS`/`apply_tableview` id-for-id.
