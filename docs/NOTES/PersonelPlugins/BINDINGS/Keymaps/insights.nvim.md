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

| lhs (config key, default) | action | desc |
| --- | --- | --- |
| `def_cfg.keymaps.jump` (`gd`) | Resolves the import entry on the cursor's line, jumps or floats to its definition | "insights: go to import definition" |
| `def_cfg.keymaps.preview` (`gp`) | Always reveals the import definition in a floating preview | "insights: preview import definition" |
