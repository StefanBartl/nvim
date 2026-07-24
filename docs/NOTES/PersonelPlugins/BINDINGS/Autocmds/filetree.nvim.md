# filetree.nvim — Autocmds Cheatsheet

Sources: ~40 files under `lua/filetree/features/<category>/<name>/init.lua`, plus `lua/filetree/util/tree_attach.lua`, `lua/filetree/util/buffer.lua`, `lua/filetree/init.lua`, `lua/filetree/attach.lua`, `lua/filetree/util/confirm.lua`.

**⚠️ `docs/BINDINGS/AUTOCMDS.md` is stale in a verified, specific way**: it
claims `file_watcher`/`watcher_quarantine` fire on `User FileWatcherEvent` —
a repo-wide grep found **no such autocmd anywhere in source**. The real
`file_watcher` feature uses `FileType`/`DirChanged` (below); `watcher_quarantine`
registers no autocmds of its own at all (it only patches `vim.notify` and
neo-tree's `fs_watch.watch_folder` callback). The doc is also missing
`opened_sync`, `size_info`, `no_name_guard`, `layout_guard`, `auto_resize`,
and `ignore_list`'s autocmds. Treat this file (and source) as authoritative.

## nav

| Event(s) | Augroup | Condition | Action |
| --- | --- | --- | --- |
| `VimResized` | `filetree_auto_resize` | opt-in, default **off** | Recomputes target width from breakpoints, resizes tree window |
| `FileType` | `filetree_auto_resize` | same | Applies width when tree opens/focuses |
| `BufEnter` | `filetree_auto_reveal` | default **on** | Debounced reveal of the newly-entered buffer's file in the tree (never re-roots) |
| `WinEnter` | `filetree_auto_reveal` | same | Pauses auto-reveal for 500ms when entering the tree window itself |
| `BufEnter`, `WinEnter` | `filetree_cwd_sync` | opt-in, default **off** ("aggressive, overlaps auto_reveal/tree_traverse") | Resolves target root (`.git` → project_root → parent dir), silently `chdir`s, reveals/scrolls tree to match |
| `VimEnter` (once) | `filetree_cwd_sync` | same, only if `vim.v.vim_did_enter==0` at setup | "Startup catch-up" sync — no `BufEnter` fires for the already-current buffer |
| `BufDelete`, `BufWipeout`, `WinClosed` | `filetree_layout_guard` | feature enabled | If only the tree window remains, opens a new empty editor split so the user is never trapped inside the tree |
| `BufWinEnter` | `filetree_no_name_guard` | feature enabled | Redirects a stray `[No Name]` window to a real named buffer, wipes the stray buffer — scoped to the single triggering buf/win pair, not a tabpage-wide sweep (deliberate, to avoid racing the user's own navigation) |
| `FileType` | `filetree_reveal_alt`, `filetree_tree_traverse` | feature enabled | Keymap-setup for `B` and `-`/`+` |

## ui

| Event(s) | Augroup | Condition | Action |
| --- | --- | --- | --- |
| `CursorMoved` | `filetree_breadcrumbs` | feature enabled | Rebuilds & displays root→node breadcrumb (winbar/float/statusline) |
| `BufEnter` | `filetree_breadcrumbs` | same | Updates breadcrumb on editor buffer change |
| `WinClosed` | `filetree_breadcrumbs` | `mode="float"` | Closes the floating breadcrumb bar when the tree window closes |
| `BufEnter`, `WinEnter`, `BufWritePost` | `filetree_current_hl` | opt-in, default **off** ("hardcoded colours that only fit some colorschemes") | Debounced highlight of current file's line + parent dir's line |
| `ColorScheme` | `filetree_current_hl` | same | Re-applies highlight groups after colorscheme change |
| `BufEnter`, `WinEnter` | `filetree_cursor_hide` | feature enabled | Deferred: sets `winhighlight` to hide the block cursor in tree windows |
| `BufLeave`, `WinLeave` | `filetree_cursor_hide` | same | Strips the override back out |
| `FileType` | `filetree_window_style` | `cfg.statusline` (default on) | Blanks the statusline in tree windows |
| `BufWinEnter`, `WinEnter` | `filetree_window_style` | same | Re-applies blank statusline (guards against a statusline plugin re-asserting its own) |
| `ColorScheme` | `filetree_window_style` | `cfg.highlights_isolate` (default **off**) | Re-links tree Normal/NormalNC/EndOfBuffer groups to the editor's own |
| `FileType` | `filetree_preview` | feature enabled | Keymap-setup for `<Tab>`/`<CR>`/scroll keys |
| `BufLeave`, `WinLeave` | `filetree_preview` | same | Closes float preview / deactivates buffer-mode preview when leaving tree |
| `CursorMoved` | `filetree_preview` | same | Debounced live-update of active preview as tree cursor moves |
| `BufEnter` | `filetree_size_info` | opt-in, default **off** | Re-renders file/dir size eol extmarks on tree entry |
| `CursorHold` | `filetree_size_info` | same | Re-renders cached sizes; kicks off async `du`/PowerShell dir-size queries |
| `BufAdd`, `BufDelete`, `BufWipeout`, `BufWinEnter`, `BufWinLeave` | `filetree_opened_sync` | feature enabled, adapter exposes `redraw` | Debounced cheap redraw so "opened files" decoration stays in sync (deliberately **not** `BufEnter` — "far too chatty") |
| `FileType` | `filetree_tree_reset`, `filetree_window_size_cycler`, `filetree_cheatsheet` | feature enabled | Keymap-setup for `<Esc>`, `w`, `?` (cheatsheet: non-neotree only) |
| `BufLeave`, `WinLeave` | none (buffer-scoped) | popup open | Auto-closes cheatsheet popup / node-info popup |

## fileops

| Event(s) | Augroup | Action |
| --- | --- | --- |
| `FileType` | `filetree_copy_move` | Keymap-setup + renders clipboard C/X indicators immediately on attach |
| `BufEnter` | `filetree_copy_move` | Re-renders clipboard indicators when tree buffer re-entered |
| `BufWriteCmd` (scratch buf), `BufDelete` (scratch buf, once) | `filetree_rename_batch_<bufnr>` (per-instance) | On `:w`, diffs+executes batch rename; on delete, tears down its own augroup |
| `FileType` | `filetree_trash`, `filetree_open_replace`, `filetree_open_variants`, `filetree_create_from_template`, `filetree_smart_rename`, `filetree_buffer_save` | Keymap-setup for each feature's own keys |

`smart_create`'s `FileType` autocmd uses no explicit group name.

## search

| Event(s) | Augroup | Action |
| --- | --- | --- |
| `FileType` | `filetree_filter`, `filetree_live_search`, `filetree_find_files`, `filetree_grep_in_dir` | Keymap-setup for `/`/`<C-c>`, `gs`, `f`/`tf`, `gr`/`tg` |
| `TextChangedI`, `TextChanged` (input buf) | `filetree_filter_input_<bufnr>`, `filetree_live_search_input` (per-instance) | Debounced live-apply of filter / overlay update as user types |
| `BufLeave` (once, input buf) | same | Closes input + tears down its own group |

## paths / org

| Event(s) | Augroup | Action |
| --- | --- | --- |
| `FileType` | `filetree_path_copy`, `filetree_markdown_links` | Keymap-setup |
| `FileType` (no explicit group) | — | Keymap-setup for `copy_file_list`/`lua_require_copy` |
| `BufEnter`, `BufWritePost` | `filetree_marks` | Deferred (50ms) redraw of mark indicators |
| `FileType` | `filetree_marks` | Keymap-setup |
| `VimLeavePre` | `filetree_session` | `cfg.auto_save` (default on) — saves scroll/cursor/root/expanded-dirs to `stdpath("data")/filetree/sessions.json`, keyed by project root |
| `BufHidden` | `filetree_session` | same — also saves when tree buffer is hidden |
| `FileType` (once) | `filetree_session` | `cfg.auto_restore` (default on) — restores saved state after first attach |

## git / lsp / infra

| Event(s) | Augroup | Condition | Action |
| --- | --- | --- | --- |
| `FileType` | `filetree_git_status` | opt-in, default **off** | Debounced `git status --porcelain` refresh on tree entry |
| `BufWritePost`, `FocusGained` | `filetree_git_status` | same | Debounced refresh after save / focus return |
| `CursorMoved` | `filetree_git_status` | same | Re-renders (no requery) as tree cursor moves |
| `DiagnosticChanged` | `filetree_lsp_diagnostics` | opt-in, default **off** | Debounced recompute + render of per-file diagnostic-count extmarks (aggregated for dirs) |
| `BufEnter`, `BufWritePost` | `filetree_lsp_diagnostics` | same | Immediate recompute+render on tree (re)entry |
| `FileType` | `filetree_file_watcher` | opt-in, default **off** | Starts a `uv.fs_event` watch on tree root if not already watching |
| `DirChanged` | `filetree_file_watcher` | same | Re-watches the new cwd |
| `VimEnter` (once) | none | neotree adapter, race-condition fallback | Retries injecting `hide_by_name` into neo-tree's config if its own `setup()` hadn't run yet |
| `BufEnter`, `TextChanged` | `filetree_ignore_list_dim` | **non-neotree adapters only** | Dims (Comment-highlight) lines matching the ignore list (dim-based fallback) |

`hooks_api`, `project_root`, `safety`, `safety/backup`, `watcher_quarantine`
register **no autocmds or keymaps at all** — pure logic/event-bus modules.

## Plugin-wide / util

| Event(s) | Augroup | Condition | Action |
| --- | --- | --- | --- |
| `FileType` | `filetree_tree_attach` | always installed after `setup()` | Dispatches to every feature callback registered via `tree_attach.on_attach` — **currently only `compare/diff` uses this path** |
| `BufDelete` | `FiletreeBufferCache` | unconditional (runs as soon as `util.buffer` loads) | Invalidates the buffer-validity TTL cache |
| `FileType` | `filetree_adapter_keymaps` | `cfg.adapter_keymaps` is a table | Applies adapter-keymap overrides after the adapter's own keymaps are set |
| `VimEnter` (once) | none | `adapter.name=="neotree"`, startup not finished | Defers `filetree.attach.inject()` (neo-tree `?`-cheatsheet injection) |
| `FileType` (pattern `neo-tree-popup`) | `filetree_neotree_popup_search` | adapter is neotree | Deferred: deletes neo-tree's own `/`/`?` maps inside its `?` help popup so native `/` search works there |
| `WinClosed` (once, pattern=winid) | none | confirm popup shown | Treats any other way of closing the popup as "no" |

## Notes

- Also worth a cleanup note (not a docs issue, since it's correctly *not* documented): `github_stats.nvim`-style orphaned code doesn't apply here, but filetree.nvim's own `compare/diff` being the sole `tree_attach` consumer while every other feature still owns its own `FileType` autocmd is a real architectural inconsistency worth flagging if unifying dispatch is ever revisited.
