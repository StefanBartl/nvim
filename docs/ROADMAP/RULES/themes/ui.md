# UI/UX conventions

Topic-sorted synthesis of UI/UX-relevant guidelines and patterns from the per-plugin
reports. Each entry links back to its source report; follow the link for full
file:line grounding.

## Notifications

- Standard notify handle: `require("lib.nvim.notify").create("[modul]")` in every
  file with error output, instead of raw `vim.notify` — from
  [nvim-config](../nvim-config.md), [buffer-ctx.nvim](../plugins/buffer-ctx.nvim.md)
  (`util/notify.lua`), [filetree.nvim](../plugins/filetree.nvim.md)
  (`util/notify.lua`), [fileops.nvim](../plugins/fileops.nvim.md)
  (`util/notify.lua`).
- Notify is strictly a UI-layer concern; pure/core modules return `(result, err)`
  or `(ok, msg)` and never call `notify` themselves — from
  [diff.nvim](../plugins/diff.nvim.md) (`core/resolve.lua`, `core/git.lua`,
  `core/url.lua`), [emojis.nvim](../plugins/emojis.nvim.md) (`core/scope.lua`),
  [fileops.nvim](../plugins/fileops.nvim.md) (`ops/*.lua`),
  [debugging.nvim](../plugins/debugging.nvim.md) (`capture/init.lua` — status
  returned, not notified, because it has multiple call sites).
- Bulk/destructive actions: ask for confirmation once, not once per item — from
  [sandbox.nvim](../plugins/sandbox.nvim.md) (`confirm.destructive` +
  `bulk_confirm_then`).
- Truncation of scan results should notify the user explicitly
  (`notify.warn(...capped at %d...)`), never cap silently — from
  [recommender.nvim](../plugins/recommender.nvim.md) (`project.lua:80-90`).
- Fallback between alternative backends (e.g. two competing panel-UI plugins)
  should notify a warning when the non-preferred backend is chosen, never
  silently degrade — from [dap.nvim](../plugins/dap.nvim.md) (`ui/provider.lua`).
- Friendly error mapping: known CLI stderr patterns get mapped to a short, fixed
  user message (never a raw multi-line stderr dump in a popup); the raw text
  still goes to a log for postmortem — from
  [sandbox.nvim](../plugins/sandbox.nvim.md) (`friendly_error.lua`),
  [fileops.nvim](../plugins/fileops.nvim.md) (`explain_fs_error`).

## Picker / command UX

- Composer-driven `:Verb <subcommand>` command trees are the standard UX for any
  plugin with more than a handful of subcommands — appears across nearly every
  plugin (`lib.nvim.usercmd.composer`); best examples: 
  [documentation.nvim](../plugins/documentation.nvim.md) (`:DocMap`/`:DocBrowse`,
  multi-level dynamic completion), [sandbox.nvim](../plugins/sandbox.nvim.md)
  (`:Sandbox`), [pickers.nvim](../plugins/pickers.nvim.md) ("Route Tree" driving
  dispatch + completion + docs from one structure).
- Cheatsheet/help overlay (`?`) should read from the *same* keymap table that
  drives the actual bindings, never a hand-maintained duplicate — from
  [documentation.nvim](../plugins/documentation.nvim.md) (`browse/init.lua`'s
  `KEYS` table), [sandbox.nvim](../plugins/sandbox.nvim.md) (list-view `?`
  cheatsheet), [filetree.nvim](../plugins/filetree.nvim.md) (`?` cheatsheet, plus
  a deliberate double-registration into neo-tree's own state just so its `?`
  popup can see the bindings too).
- which-key group labels should be derived dynamically (e.g. longest common
  prefix of the actually configured lhs values), not hardcoded — a hardcoded
  group key breaks silently after user remapping — from
  [images.nvim](../plugins/images.nvim.md) (`common_prefix`,
  `bindings/keymaps.lua:79-104`).
- Visual-mode multi-select is offered as the idiomatic alternative to a `count`
  prefix for "act on N items" — from [sandbox.nvim](../plugins/sandbox.nvim.md)
  (list-view bulk actions), [filetree.nvim](../plugins/filetree.nvim.md) (marks:
  mark-then-act instead of count).
- Statusline components: small, consistent contract — count active resources,
  short string, configurable prefix, empty string when inactive — from
  [diff.nvim](../plugins/diff.nvim.md) (`diff.status()`, `init.lua:83-98`).
- Custom single-line prompt buffers should lock the cursor to the input row via
  a small set of autocommands (`CursorMoved`, `CursorMovedI`, `InsertEnter/Leave`)
  rather than build a bespoke input widget from scratch — from
  [reposcope.nvim](../plugins/reposcope.nvim.md) (`prompt_autocmds.lua`).
- Tagged scratch/log windows: find existing windows via a window-local tag
  variable rather than a module-level registry table — a stale registry was a
  concrete, previously-reproduced bug source — from
  [debugging.nvim](../plugins/debugging.nvim.md) (`views/display.lua`).
- Custom TUI/dashboard buffers that keep their own visual state (cursor,
  scroll) outside real buffer lines must block every native cursor-movement key
  (`<Nop>`) that could desync the internal state from the rendered view — from
  [github_stats.nvim](../plugins/github_stats.nvim.md)
  (`block_cursor_movement`, `bindings/keymaps.lua:58-83`).
- Graceful visual degradation: prefer a working-but-imperfect fallback (ASCII
  block-color rendering when no terminal graphics protocol is available) over a
  hard failure — from [images.nvim](../plugins/images.nvim.md) (README "ASCII
  fallback").
- Progress indicators for long external operations should truncate/format
  unboundedly-long external strings (image digests, registry URLs) before
  display — from [sandbox.nvim](../plugins/sandbox.nvim.md) (`progress_label()`).
- One finalization point for progress indicators across every async exit path
  (success, error, exception, sync cache-hit), implemented by wrapping the
  callback itself with a `closed` guard rather than duplicating cleanup at each
  exit — from [pdfport.nvim](../plugins/pdfport.nvim.md) (`dispatcher.lua:176-196`).

## Window/buffer handling

- Two competing "exclusive" UIs (e.g. neo-tree vs. a picker's explorer source)
  should track who displaced whom and reopen the displaced one exactly once,
  guarded by a double `vim.schedule` defer because a freshly created window can
  briefly report the previous window's buffer on `WinEnter` — from
  [nvim-config](../nvim-config.md) (`autocmds/explorer-singleton.lua`).
- Deleting a buffer whose windows are visible: redirect those windows to an
  alternate buffer *before* deleting, so Neovim doesn't auto-create an empty
  scratch buffer — from [fileops.nvim](../plugins/fileops.nvim.md)
  (`switch_windows_off`, `ops/file.lua:574-621`).
- `gitsigns.preview_hunk_inline`-style previews that can scroll-jump: save
  `winsaveview()` + cursor first, restore via `vim.schedule` after — from
  [fileops.nvim](../plugins/fileops.nvim.md) (`on_hold.lua:319-347`).
</content>
