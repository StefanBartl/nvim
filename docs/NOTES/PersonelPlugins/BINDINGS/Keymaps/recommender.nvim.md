# recommender.nvim — Keymaps Cheatsheet

Source: `lua/recommender/bindings/keymaps.lua`, `lua/recommender/float/keymaps.lua`
(module root renamed from `recommender_nvim` -> `recommender`, 2026-07 refactor)
Bridge: `lib.map()` in `util/lib.lua` — tries `lib.nvim.map`, falls back to `vim.keymap.set`.
Cross-reference: `docs/BINDINGS.md` — thorough and accurate, matches source exactly; also points to `doc/recommender.nvim.txt` §8 for the vimdoc version.

## Global (`cfg.keymaps ~= false`, default enabled)

| lhs | mode | action | desc |
| --- | --- | --- | --- |
| `<leader>lr` | n | `:Recommender` | "Recommender" |
| `<leader>lR` | n | `:Recommender -r` (replace mode) | "Recommender (replace mode)" |
| `<leader>lrr` | n | `:Recommender regex` | "Recommender (regex)" |
| `<leader>lrt` | n | `:Recommender treesitter` | "Recommender (treesitter)" |
| `<leader>lrj` | n | `:Recommender javascript` | "Recommender (javascript)" |
| `<leader>lrp` | n | `:Recommender python` | "Recommender (python)" |
| `<leader>lrh` | n | `:Recommender regex 5` (high threshold) | "Recommender (high threshold)" |
| `<leader>lrc` | n | `:Recommender -c` (project-wide, cwd scope) | "Recommender (project-wide, cwd)" |

Added 2026-07-24: `javascript`/`python` regex-based analyzer backends
(roadmap item "additional analyzer backends for other languages"), each with
its own quick-access global keymap alongside the existing regex/treesitter
ones.

Also added 2026-07-24: `<leader>lrc` for `-c`/`--cwd` (roadmap item
"project-wide (cwd) analysis" — aggregates chain counts across every file
under `getcwd()` matching the active analyzer's extensions, instead of just
the current buffer; insertion still targets the current buffer). Only
regex/javascript/python support it — combining with treesitter is a hard
error.

## Suggestion float (buffer-local, attached each time it opens — `float/keymaps.lua`)

| lhs | action |
| --- | --- |
| `j` / `<Down>` | Next selectable suggestion (layout: blank line, then groups of 3) |
| `k` / `<Up>` | Previous suggestion |
| `q` / `<Esc>` | Close the float |
| `<CR>` | Insert alias at cursor row into the best target window; in `replace_mode`, registers a one-shot `WinClosed` autocmd (see [Autocmds cheatsheet](../Autocmds/recommender.nvim.md)) and runs `:Replace <chain> <var>` if a local-var name could be parsed, else falls back to a plain `nvim_put` |
| `y` | Yank selected alias to `+`/`*` registers, notify |
| `A` | Insert **all** visible aliases at once |
| `<BS>` | Mark current chain `ignored` for this buffer session, refresh list |
| `U` | Clear all `ignored` entries, refresh |
| `?` | Notify inline help listing every key |

## which-key

Soft, guarded group label only: `<leader>lr` → "Recommender". No individual
key labels — no-op if which-key isn't installed. Only runs if
`cfg.keymaps ~= false`.
