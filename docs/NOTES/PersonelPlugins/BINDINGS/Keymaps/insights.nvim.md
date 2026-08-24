# insights.nvim — Keymaps Cheatsheet

Source: `lua/insights/bindings/keymaps.lua`, `ui/scratch.lua`, `imports/init.lua`
Cross-reference: `docs/BINDINGS.md` — comprehensive, verified to match source exactly; very good cross-reference.

Plain `vim.keymap.set(...)`, no wrapper.

## which-key

No explicit group registration — every mapping carries a `desc`, so
which-key.nvim discovers and labels them individually on its own. No-op
if which-key is absent (nothing here depends on it).

| lhs (config key, default) | mode | action | desc | condition |
| --- | --- | --- | --- | --- |
| `cfg.fileinfo.keymap` (`<leader>fi`) | n | Opens the file-info float for the current buffer | "insights: file info float" | `cfg.fileinfo.enable ~= false` and key truthy |
| `cfg.keymaps.symbols_telescope` (`<leader>ps`) | n | Scans and opens `ui.telescope` via `symbols/open.lua` | "insights: symbols (telescope, cwd functions)" | key truthy |
| `cfg.keymaps.symbols_fzf` (`<leader>pS`) | n | Same, opens `ui.fzf` | "insights: symbols (fzf, cwd functions)" | key truthy |

Since 2026-08-24 both `symbols_*` keys take either a plain lhs string (cwd +
functions, the historical behavior) or `{ lhs, scope?, type?, rebuild? }`.
There is deliberately no `ui` field — the UI is which of the two keys this
is. The `desc` is built from the resolved choice, so which-key shows
`insights: symbols (telescope, buffer tables)` rather than a fixed label.

**The desc cells above therefore name the *default-config* descs, not a
template.** `drift.lua`'s `is_live` compares a documented desc to a live one
by exact string equality, so a `{scope} {type}` placeholder in that column
would make `:Bindings check` report both mappings as documented-but-not-
registered on every run. If you configure a non-default scope or type, the
live desc changes with it and those two rows have to be updated to match —
that is the cost of the desc carrying real information.

Both mappings now dispatch through `symbols/open.lua`, the same entry point
`:Insights symbols` uses. Before that they scanned and opened a picker
themselves and had drifted: no empty-result guard, no `rebuild`.

## Scratch-buffer keymaps (`ui/scratch.lua`, buffer-local)

| lhs (config key, default) | action | desc |
| --- | --- | --- |
| each key in `ui_cfg.close_keys` (default `{"q","<Esc>"}`) | Force-deletes the scratch buffer | "insights: close scratch buffer" |
| `ui_cfg.follow_key` (`gf`) | Parses current line for a leading `path:line`, `:edit`s that file at `lnum` | "insights: follow path:line" |
| caller-supplied via `opts.keymaps` | Generic passthrough — applied buffer-local | caller-supplied |

## Imports report buffer (via `ui.scratch.open`)

Only shown for the scratch-buffer view of `:Insights imports` (not the
`telescope`/`fzf` picker mode). 2026-07-25: imports now spans Lua, Python,
JS/TS, Go, Rust, C/C++ (`imports/langs/*.lua`); `gd`/`gp` stayed Lua-only —
on a non-Lua entry they just notify instead of erroring.

| lhs (config key, default) | action | desc |
| --- | --- | --- |
| `def_cfg.keymaps.jump` (`gd`) | Resolves the Lua import entry on the cursor's line, jumps or floats to its definition (non-Lua: notifies "Lua-only") | "insights: go to import definition" |
| `def_cfg.keymaps.preview` (`gp`) | Always reveals the import definition in a floating preview (same Lua-only gate) | "insights: preview import definition" |
