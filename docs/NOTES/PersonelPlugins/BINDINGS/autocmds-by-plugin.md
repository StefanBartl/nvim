# Autocmds — consolidated, by plugin

One scrollable/searchable document with every autocmd across all 26
plugins, condensed to event/augroup/pattern/action. For full prose
(why each one exists, known issues, doc-staleness notes), follow the link
to that plugin's own file in [Autocmds/All.md](../../NOTES/PersonelPlugins/BINDINGS/Autocmds/All.md).

See also: [by event](autocmds-by-event.md), [by filetype/scope](autocmds-by-filetype.md).

## [buffer-ctx.nvim](../../NOTES/PersonelPlugins/BINDINGS/Autocmds/buffer-ctx.md)

| Event(s) | Augroup | Pattern | Action |
| --- | --- | --- | --- |
| `BufDelete`, `BufWipeout` | `BufferCtxMarkCleanup` | — | Drop `:Mark` state for the buffer |

## [cascade.nvim](../../NOTES/PersonelPlugins/BINDINGS/Autocmds/cascade.nvim.md)

| Event(s) | Augroup | Pattern | Action |
| --- | --- | --- | --- |
| `FileType` | `cascade_list_keymaps` | `cfg.lists.filetypes` | Binds buffer-local list keymaps |
| `FileType` | `cascade_list_format` | `cfg.lists.filetypes` | Sets `formatlistpat`/`formatoptions` for `gq` hanging indent (independent of `keymaps.preset`) |
| `BufWritePre` | `cascade_renumber_save` | `*` | Renumbers ordered lists before write |

## [color_my_ascii.nvim](../../NOTES/PersonelPlugins/BINDINGS/Autocmds/color_my_ascii.nvim.md)

| Event(s) | Augroup | Pattern | Action |
| --- | --- | --- | --- |
| `FileType` | `ColorMyAscii` | `markdown` | Per-buffer highlighting + `:Fence` family |
| `ColorScheme` | `ColorMyAsciiFenceLineHl` | `*` | Re-resolves fence-line/content highlight groups |
| `ColorScheme` | `ColorMyAsciiHl` | `*` | Re-applies dynamically created (fixed-hex) ASCII-art highlight groups |
| `TextChanged`, `TextChangedI` | `ColorMyAsciiBuffer_<bufnr>` | buffer-local | Re-highlights (adaptive debounce) |
| `BufDelete` | `ColorMyAsciiBuffer_<bufnr>` | buffer-local | Clears highlighter state/cache |
| `BufDelete`, `BufWipeout` | `ColorMyAsciiFenceApiCache` | `*` | Invalidates fences-API cache entry |
| `BufWritePost` | `ColorMyAsciiFenceOpen_<tbuf>` | buffer-local (temp) | Syncs edited fence content back to source |
| `{BufWipeout,BufDelete,BufUnload}` (once) | `ColorMyAsciiFenceOpen_<tbuf>` | buffer-local (temp) | Cleans up `:Fence open` temp state |
| `CursorMoved` | none | Telescope prompt | Live scheme preview |
| `BufDelete` | `ColorMyAsciiDebounce` | `*` | Cancels pending debounce timer |

## [dap.nvim](../../NOTES/PersonelPlugins/BINDINGS/Autocmds/dap.nvim.md)

| Event(s) | Augroup | Pattern | Action |
| --- | --- | --- | --- |
| `User` | `DapNvimAuto` | `DapUIWindowOpen` | `cursorline = true` |
| `User` | `DapNvimAuto` | `DapUIWindowClose` | `cursorline = false` |

## [debugging.nvim](../../NOTES/PersonelPlugins/BINDINGS/Autocmds/debugging.nvim.md)

| Event(s) | Augroup | Pattern | Action |
| --- | --- | --- | --- |
| `WinEnter` | `DebugViewsAuto` | — | Auto-refresh tagged debug view |
| `BufWinEnter` | `DebugViewsAuto` | — | Same, keyed off buffer |
| `FileType` | `DebugViewsAuto` | `{messages,noice}` | Registers `q`/`<Esc>` close keymaps |

## [diff.nvim](../../NOTES/PersonelPlugins/BINDINGS/Autocmds/diff.nvim.md)

| Event(s) | Augroup | Pattern | Action |
| --- | --- | --- | --- |
| `VimLeavePre` | `diff_cleanup` | — | Wipes tracked scratch buffers |
| `OptionSet` | `diff_native_diffthis` | `diff` | Mirrors exit keymap onto native diffmode buffers (opt-in) |

## [emojis.nvim](../../NOTES/PersonelPlugins/BINDINGS/Autocmds/emojis.nvim.md)

None — intentionally empty stub.

## [fileops.nvim](../../NOTES/PersonelPlugins/BINDINGS/Autocmds/fileops.nvim.md)

| Event(s) | Augroup | Pattern | Action |
| --- | --- | --- | --- |
| `BufWritePre` | `fileops_auto_mkdir` | — | Creates parent dirs before write |
| `CursorHold`/`CursorHoldI` | `fileops_on_hold_preview` | — | Git hunk/line preview (opt-in, off) |
| `CursorMoved`, `BufHidden`, `InsertEnter` (once) | `fileops_on_hold_cleanup` | buffer-local | Clears preview virtual text |
| `ModeChanged` | `fileops_on_hold_modeclear` | — | Clears preview on mode change |
| `BufWinEnter` | `fileops_conflict_marks_on` | — | Highlights conflict markers |
| `BufWinLeave` | `fileops_conflict_marks_off` | — | Clears conflict-marker matches |

## [filetree.nvim](../../NOTES/PersonelPlugins/BINDINGS/Autocmds/filetree.nvim.md)

~40 autocmds across nav/ui/fileops/search/paths/org/git/lsp/infra/plugin-wide
categories. As of 2026-07-26, keymap-setup for ~28 features funnels through
**one** `FileType` autocmd (`filetree_tree_attach`, on `{neo-tree,NvimTree}`
or the adapter's declared filetypes) instead of each feature owning its own
— see the [full file](../../NOTES/PersonelPlugins/BINDINGS/Autocmds/filetree.nvim.md)
for the complete table (too large to usefully condense here). Notable
non-keymap-setup ones: `VimResized`/`ColorScheme` (ui, opt-in), `VimEnter`
(×2, cwd_sync catch-up + neotree-injection defer), `VimLeavePre`/`BufHidden`
(org/session), `DiagnosticChanged` (lsp, opt-in), `DirChanged` (file_watcher,
opt-in).

## [github_stats.nvim](../../NOTES/PersonelPlugins/BINDINGS/Autocmds/github_stats.nvim.md)

| Event(s) | Augroup | Pattern | Action |
| --- | --- | --- | --- |
| `VimEnter` | `GithubStatsAutoFetch` | — | Background fetch cycle + auto-open dashboard |
| `BufWipeout` (once) | none | dashboard buffer | Tears down dashboard state |

## [gopath.nvim](../../NOTES/PersonelPlugins/BINDINGS/Autocmds/gopath.nvim.md)

| Event(s) | Augroup | Pattern | Action |
| --- | --- | --- | --- |
| `BufWritePost` | `GopathPathCacheInvalidate` | — | Drop directory-listing caches (always on) |
| `BufWritePost` | `GopathCacheAutoRebuild` | `{*.lua,*.vim}` | Debounced truncated-path cache rebuild (opt-in) |

## [insights.nvim](../../NOTES/PersonelPlugins/BINDINGS/Autocmds/insights.nvim.md)

| Event(s) | Augroup | Pattern | Action |
| --- | --- | --- | --- |
| `VimEnter` (configurable) | `Insights_conflicts` | — | Quickfix unresolved git conflicts |
| `BufWritePost` (configurable) | `Insights_unimported` | astro/jsx/tsx/vue/svelte | Warn on unimported components |
| `TermOpen` | `Insights_devserver` | — | Detect dev-server command |
| `TermRequest` | `Insights_devserver` | — | Same, via OSC title change |
| `VimLeavePre` | `Insights_devserver` | — | Kill tracked dev servers |

## [language.nvim](../../NOTES/PersonelPlugins/BINDINGS/Autocmds/language.nvim.md)

| Event(s) | Augroup | Pattern | Action |
| --- | --- | --- | --- |
| `BufDelete` | `language_nvim` | — | GC spell-session state, detach live diagnostics |
| `BufWinEnter`, `FileType` | `language_nvim` | — | Initial live spell scan (opt-in) |
| `TextChanged`, `InsertLeave` | `language_nvim` | — | Debounced live rescan (opt-in) |
| `WinScrolled` | `language_nvim` | — | Rescan on scroll, visible-scope (opt-in) |
| `BufWritePre` | `language_nvim` | — | Block write on spelling errors (opt-in, off) |
| `TextChanged`, `TextChangedI` | `language_translate_window` | input buf | Debounced re-translate |
| `WinClosed` | `language_translate_window` | — | Tears down translate floats |
| `VimLeavePre` | none | — | Kills cspell sidecar job |

## [lib.nvim](../../NOTES/PersonelPlugins/BINDINGS/Autocmds/lib.nvim.md)

Library — nothing eager. Dynamic, opt-in-per-caller only:
`{WinLeave,BufLeave}` (window focus-close), `{TextChangedI,TextChanged}`
(kit picker query), `WinClosed` (kit surface lifecycle), `ColorScheme` (kit
theme), `{TextChanged,TextChangedI}` (kit preview / cache auto-invalidation,
opt-in), `BufWritePost` (cache auto-invalidation / docmap watch, both
opt-in), `VimLeavePre` (logger flush; telemetry counter flush),
`VimEnter` (telemetry lifecycle reminder), `{BufDelete,BufWipeout}`
(debounce buffer cleanup), `User LazyDone` (nvim_usrcmds helptags, opt-in).

The two `VimLeavePre` rows and the `VimEnter` one register per
`logger.new()` / `telemetry.new()` call, not at require time — augroups
`lib_logger_<name>` and `lib_telemetry_<namespace>`.

## [markdown.nvim](../../NOTES/PersonelPlugins/BINDINGS/Autocmds/markdown.nvim.md)

| Event(s) | Augroup | Pattern | Action |
| --- | --- | --- | --- |
| `FileType` | `MarkdownNvimTableView` | markdown/mdx/md | TableView keymaps + commands |
| `FileType` | `MarkdownNvimRefs` | markdown/mdx/md | Snapshot heading anchors |
| `BufWritePre` | `MarkdownNvimRefs` | `*.md,*.markdown,*.mdx` | Sync anchors+TOC on save (mode=save) |
| `TextChanged`,`TextChangedI` | `MarkdownNvimRefs` | same | Debounced live sync (mode=live) |
| `BufWipeout` | `MarkdownNvimRefs` | same | Teardown |
| `BufWritePre` | `MarkdownNvimLinksSanitize` | `*.md,*.markdown,*.mdx` | Normalize inline-link targets (sanitize_on_save) |
| `BufWritePost` | `MarkdownNvimLinkDiagnostics` | `*.md,*.markdown,*.mdx` | Rerun dead-link/duplicate-anchor check (links.diagnostics.mode=save) |
| `FileType` | `MarkdownNvimKeymaps` | markdown/mdx/md | Install default keymaps |
| `FileType` | `MarkdownNvimUserCommands` | markdown/mdx/md | Install buffer-local commands |
| `FileType` | `MarkdownNvimFold` | markdown/mdx/md | Set fold options |
| `BufDelete`,`BufWipeout` | `MarkdownNvimScopeFoldCache` | — | Invalidate fold-block cache |
| `ColorScheme` | `MarkdownNvimHL` | `*` | Re-apply blockquote HL / re-strip link underline |
| `FileType`,`BufEnter` | `MarkdownNvimHL` | markdown family | Re-apply blockquote overlay |
| `ColorScheme` | `MarkdownNvimFencedFix` | — | Re-apply fenced-code HL overrides |
| `InsertLeave`,`TextChanged` | `MarkdownNvimTableMode_<bufnr>` | buffer-local | Debounced table re-align |
| `BufWipeout` | same | buffer-local | Cancel debounce, delete augroup |
| `TextChanged`,`TextChangedI` | ungrouped | buffer-local | Live refs tracking (per `:Markdown refs live on`) |
| `BufEnter` | `MarkdownNvimPreviewRefresh` | `*.md` | Refresh external `markdown-preview.nvim` |

## [mdview.nvim](../../NOTES/PersonelPlugins/BINDINGS/Autocmds/mdview.nvim.md)

| Event(s) | Augroup | Pattern | Action |
| --- | --- | --- | --- |
| `BufEnter` | `MdviewAutocmds` | ft_pattern | Snapshot buffer content |
| `BufEnter` | `MdviewAutocmds` | ft_pattern | Apply `browser.behavior` on switch |
| `TextChanged`,`TextChangedI` | `MdviewAutocmds` | ft_pattern | Push full buffer to relay |
| `BufWritePost` | `MdviewAutocmds` | ft_pattern | Forced full resync push |
| `CursorMoved`,`CursorMovedI` | `MdviewAutocmds` | ft_pattern | Throttled scroll-sync send (opt-out) |
| `VimLeavePre` | `MdviewAutocmds` | none | Stops relay process |
| `TextChanged`,`TextChangedI`,`BufWritePost` | `MdviewPreviewTabSync` | — | Sync open tab preview |
| `BufEnter`,`BufWinEnter`,`FileType` | `MdviewPreviewTabSync` | — | Close tab preview on takeover |

## [migrate.nvim](../../NOTES/PersonelPlugins/BINDINGS/Autocmds/migrate.nvim.md)

None.

## [cmdlog](../../NOTES/PersonelPlugins/BINDINGS/Autocmds/cmdlog.md)

None.

## [sandbox.nvim](../../NOTES/PersonelPlugins/BINDINGS/Autocmds/sandbox.nvim.md)

None (documented as intentional).

## [open.nvim](../../NOTES/PersonelPlugins/BINDINGS/Autocmds/open.nvim.md)

None.

## [pdfport.nvim](../../NOTES/PersonelPlugins/BINDINGS/Autocmds/pdfport.nvim.md)

| Event(s) | Augroup | Pattern | Action |
| --- | --- | --- | --- |
| `FileType` | `pdfport_tree` | `NvimTree` | Register nvim-tree integration keymaps |
| `FileType` | `pdfport_oil` | `oil` | Register oil.nvim integration keymaps |
| `FileType` | `pdfport_netrw` | `netrw` | Register netrw integration keymaps |

## [pickers.nvim](../../NOTES/PersonelPlugins/BINDINGS/Autocmds/pickers.nvim.md)

| Event(s) | Augroup | Pattern | Action |
| --- | --- | --- | --- |
| `VimEnter` (once) | `pickers.nvim`/none | — | Registers defaults if `setup()` was never called |
| `CursorMoved` | `PickersSelectedIndexAUG_<bufnr>` | results buf | Debounced index-overlay redraw |
| `TextChangedI`,`TextChanged` | same | prompt buf | Same, on prompt edits |
| `BufDelete` (once) | none | results buf | Cleanup extmarks/timer |
| `BufReadPost` | `pickers.nvim` | real file bufs | Record `smart.frecency` visit (opt-in, off by default; added 2026-07-26) |
| `VimLeavePre` | `pickers.nvim` | — | Flush `smart.frecency` store to disk (same opt-in) |

## [recommender.nvim](../../NOTES/PersonelPlugins/BINDINGS/Autocmds/recommender.nvim.md)

| Event(s) | Augroup | Pattern | Action |
| --- | --- | --- | --- |
| `WinClosed` | `RecommenderNvimReplaceInsert` | matched in callback (`TelescopePrompt`) | One-shot: insert alias after `:Replace` finishes |

## [replacer.nvim](../../NOTES/PersonelPlugins/BINDINGS/Autocmds/replacer.nvim.md)

None.

## [reposcope.nvim](../../NOTES/PersonelPlugins/BINDINGS/Autocmds/reposcope.nvim.md)

| Event(s) | Augroup | Pattern | Action |
| --- | --- | --- | --- |
| `QuitPre` | none (manual id-tracking) | matched in callback (`reposcope://*`) | Closes whole Reposcope UI |
| `TextChangedI` | `reposcope_prompt_autocmds` | `*` | Store prompt field text |
| `CursorMoved`,`CursorMovedI`,`InsertEnter`,`InsertLeave` | same | `*` | Force cursor to line 2 |

## [runtime-analysis.nvim](../../NOTES/PersonelPlugins/BINDINGS/Autocmds/runtime-analysis.nvim.md)

None.

## [sessions.nvim](../../NOTES/PersonelPlugins/BINDINGS/Autocmds/sessions.nvim.md)

| Event(s) | Augroup | Pattern | Action |
| --- | --- | --- | --- |
| `VimEnter` (once, nested, configurable off) | `SessionsNvim` | — | Autoload contextual session |
| `VimLeavePre` (configurable on) | `SessionsNvim` | — | Autosave to fixed session name |

## [spotlight.nvim](../../NOTES/PersonelPlugins/BINDINGS/Autocmds/spotlight.nvim.md)

| Event(s) | Augroup | Pattern | Action |
| --- | --- | --- | --- |
| `WinNew`,`BufWinEnter`,`TabNewEntered` | `spotlight_windows` | `*` | Apply every active spotlight to windows that have none yet (deferred one tick; `matchadd()` is window-local) |
| `WinClosed` | `spotlight_windows` | `*` | Drop the closed window's match-ledger entry |
| `ColorScheme` | `spotlight_highlights` | `*` | Redefine `Spotlight1..8` (configurable off) |
| `OptionSet` | `spotlight_highlights` | `background` | Switch between the dark and light palette |
| `VimEnter` | `spotlight_persist` | `*` | Restore the persisted spotlights (configurable off) |
| `VimLeavePre` | `spotlight_persist` | `*` | Flush a pending debounced state save |

**Deliberately absent**: no `TextChanged`/`CursorMoved`/`CursorHold`. A
pattern-based highlight needs no invalidation when the text moves — that is the
whole reason `matchadd()` was chosen over extmarks.
