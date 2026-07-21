# insights.nvim — Keymaps Cheatsheet

Source: `lua/insights/bindings/keymaps.lua`, `ui/scratch.lua`, `imports/init.lua`
Cross-reference: `docs/BINDINGS.md` — comprehensive, verified to match source exactly; very good cross-reference.

Plain `vim.keymap.set(...)`, no wrapper. Every mapping carries a `desc`, so
which-key.nvim discovers them automatically.

| lhs (config key, default) | mode | action | desc | condition |
| --- | --- | --- | --- | --- |
| `cfg.fileinfo.keymap` (`<leader>fi`) | n | Opens the file-info float for the current buffer | "insights: file info float" | `cfg.fileinfo.enable ~= false` and key truthy |
| `cfg.keymaps.symbols_telescope` (`<leader>ps`) | n | Fetches symbol index, opens `ui.telescope` | "insights: symbols (telescope)" | key truthy |
| `cfg.keymaps.symbols_fzf` (`<leader>pS`) | n | Same, opens `ui.fzf` | "insights: symbols (fzf)" | key truthy |

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
