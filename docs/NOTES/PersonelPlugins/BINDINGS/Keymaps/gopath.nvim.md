# gopath.nvim — Keymaps Cheatsheet

Source: `lua/gopath/bindings/keymaps.lua`, `M.setup(config)`
Cross-reference: `docs/BINDINGS.md` — verified current and precise, cleanest of the audited repos.

Direct `vim.keymap.set` calls (no `lib.nvim.map` indirection here, unlike
most sibling plugins), wrapped by a local `map_many()` helper supporting a
single lhs or a list of lhs strings; skips registration if the config value
is `false`/`nil`/`""`. Gated overall by `config.mappings ~= false`.

| lhs (config key / default) | mode | action | desc |
| --- | --- | --- | --- |
| `open_here` / `gP` | n | Resolve path under cursor, `:edit` it | "gopath: open here" |
| `open_split` / `` g\| `` | n | Resolve + open in horizontal split | "gopath: open in split" |
| `open_vsplit` / `g\` | n | Resolve + open in vsplit | "gopath: open in vsplit" |
| `open_tab` / `g}` | n | Resolve + open in new tab | "gopath: open in tab" |
| `copy_location` / `gY` | n | Copy `path:line:col` | "gopath: copy path:line:col" |
| `debug` / `g?` | n | Print resolution chain to `:messages` | "gopath: debug under cursor" |
| `check` / `gC` | n | Report whether path under cursor exists; offer to create if missing | "gopath: check path exists / offer create" |
| `probe` / `<leader>pp` | n | Suffix-based fuzzy path search on token/`<cfile>` under cursor, opens in vsplit | "gopath: probe path under cursor (vsplit)" |
| `probe` / `<leader>pp` | v | Same, on the visual selection (exits visual first so `'<`/`'>` marks are set) | "gopath: probe selected path (vsplit)" |

## which-key

Registers a label **only** for `probe` (both `n` and `v`) — gopath's other
keys are single `g`-prefixed and don't need a shared group per the module's
own comment. Supports both v3 `add` and v2 `register` APIs.
