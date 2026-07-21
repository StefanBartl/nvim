# markdown.nvim — Autocmds Cheatsheet

Sources: `lua/markdown/bindings/autocmds.lua`, `scope/init.lua`, `hl_options/init.lua`, `hl_options/hl_groups/blockquote.lua`, `fenced_fix/init.lua`, `core/table_mode.lua`, `commands/refs.lua`, `commands/preview.lua`

**⚠️ `docs/BINDINGS.lua`'s autocmd table is stale/incomplete** — missing
`MarkdownNvimScopeFoldCache`, `MarkdownNvimTableMode_<bufnr>`,
`MarkdownNvimPreviewRefresh`, and the ad-hoc `commands/refs.lua` live-tracking
autocmd. It also conflates two independent `ColorScheme` registrations
(`MarkdownNvimHL` vs. the separate `MarkdownNvimFencedFix`) into one row, and
omits blockquote's own `FileType`/`BufEnter` autocmd. Treat this file (and
source) as authoritative.

## `bindings/autocmds.lua`, `M.setup(cfg)`

| Augroup (clear=true) | Event(s) | Pattern | Condition | Action |
| --- | --- | --- | --- | --- |
| `MarkdownNvimTableView` | `FileType` | markdown/mdx/md/`markdown.*` | feature `tableview` | Installs TableView keymaps + buffer-local commands |
| `MarkdownNvimRefs` | `FileType` | same | feature `refs` AND `cfg.refs.mode` ∈ {save, live} (default `save`) | Snapshots heading anchors as a rename baseline |
| `MarkdownNvimRefs` | `BufWritePre` | `*.md,*.markdown,*.mdx` | mode == "save" | Syncs `#anchor` links + TOC on save |
| `MarkdownNvimRefs` | `TextChanged`,`TextChangedI` | same | mode == "live" | Debounced live sync |
| `MarkdownNvimRefs` | `BufWipeout` | `*.md,*.markdown,*.mdx` | feature `refs` + mode∈{save,live} | Tears down timers/extmarks |
| `MarkdownNvimKeymaps` | `FileType` | ftpat | `enable_autocmds ~= false` (default on) | Installs `DEFAULT_KEYMAPS` |
| `MarkdownNvimUserCommands` | `FileType` | ftpat | same | Installs `:Markdown` + `OpenWithSystemApplication` |
| `MarkdownNvimFold` | `FileType` | ftpat | same, and feature `fold` | Sets `foldmethod`/`foldexpr`/`foldenable`/`foldlevel`/`foldlevelstart` |

`apply_to_already_loaded(cfg)` isn't an autocmd — it immediately applies
keymaps/usercmds to already-open markdown buffers when `setup()` runs, so a
late `require` still picks up existing buffers.

## Elsewhere

| Augroup | Event(s) | Pattern | Condition | Action |
| --- | --- | --- | --- | --- |
| `MarkdownNvimScopeFoldCache` | `BufDelete`,`BufWipeout` | — | unconditional | Invalidates per-buffer memoized fold-block cache |
| `MarkdownNvimHL` | `ColorScheme` | `*` | feature `hl` or `link_hl` enabled (both default on) | Re-applies blockquote highlight (if `hl`) and re-strips link underline (if `link_hl`) — colorschemes reset treesitter groups, so the underline strip needs reapplying |
| `MarkdownNvimHL` (same group) | `FileType`,`BufEnter` | markdown/markdown.mdx/mdx | feature `hl` | Re-applies blockquote `matchadd` overlay for that buffer |
| `MarkdownNvimFencedFix` (**separate** group) | `ColorScheme` | default | feature `fenced_fix` (default on) | Re-applies fenced-code-block highlight overrides |
| `MarkdownNvimTableMode_<bufnr>` (per-buffer) | `InsertLeave`,`TextChanged` | buffer-local | `:Markdown table mode on/toggle` or `<leader>tvm` | Debounced (120ms) re-alignment of the GFM table under cursor |
| same group | `BufWipeout` | buffer-local | same | Cancels debounce, deletes the augroup |
| ungrouped (default augroup) | `TextChanged`,`TextChangedI` | buffer-local | `:Markdown refs live on`/`toggle` | Live-tracks refs; **distinct** from `bindings/autocmds.lua`'s config-driven "live" refs autocmd — created/removed per invocation, tracked in `live_au[bufnr]` |
| `MarkdownNvimPreviewRefresh` (created once, lazily, on first `:Markdown preview ...`) | `BufEnter` | `*.md` | preview session active + not busy + `markdown-preview.nvim` available | Re-runs `:silent! MarkdownPreview` to refresh the external host plugin's preview |
