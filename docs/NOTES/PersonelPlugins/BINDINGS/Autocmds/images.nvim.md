# images.nvim — Autocmds Cheatsheet

Sources: `lua/images/bindings/autocmds.lua`, `lua/images/init.lua`,
`lua/images/zen.lua`, `lua/images/hover_float.lua`, `lua/images/ascii.lua`,
`lua/images/redact.lua`
Cross-reference: `docs/BINDINGS.md` (current, includes keymaps/usercmds too).

| Event(s) | Augroup | Pattern | Action |
| --- | --- | --- | --- |
| `VimLeavePre` | `images.autocmds` | — | Clears a displayed image before Neovim quits. Registered once, at `setup()`. |
| `FileType` | `images.keymaps` | `keymaps.filetypes` | Registers the buffer-local keymaps. Registered once, at `setup()`. |
| `display.clear_events` (default: `CursorMoved`, `CursorMovedI`, `InsertEnter`, `BufLeave`, `WinScrolled`) | `images.clear` | — | Clears the just-shown image. Armed dynamically each time an image is shown, `once = true`. |
| `WinResized`, `VimResized` | `images.zen` | — | Redraws the zen image so it follows the window's size. Armed dynamically on `:Image zen`. |
| `WinClosed` | `images.zen` | zen `winid` | Clears the image when the zen window closes. Armed dynamically on `:Image zen`, `once = true`. |
| `WinClosed` | `images.hover_float` | hover `winid` | Clears the image and resets state when the hover float closes. Armed dynamically on hover, `once = true`. |
| `WinClosed` | `images.ascii` | ascii `winid` | Resets state when the ASCII-fallback window closes. Armed dynamically, `once = true`. |
| `WinClosed` | `images.redact` | redact `winid` | Clears the image and resets state when the redact window closes. Armed dynamically on `:Image redact`, `once = true`. |

## Notes

- **`images.clear` is scoped to the image's lifetime, not permanent**: it is
  (re-)armed in `arm_clear()` right after a successful draw and consumed
  (`once`) on the next matching event. `:Image pin` skips arming it and
  deletes an already-armed group (`nvim_del_augroup_by_name`), so a pinned
  image survives cursor movement.
- **`images.zen`'s two augroup entries share one augroup**, created fresh
  (`clear = true`) on every `:Image zen` call — a second call replaces the
  window (`M.close()` first) rather than stacking autocmds.
- No autocmd runs permanently in the background beyond `images.autocmds`
  (a single cheap `VimLeavePre` cleanup) and `images.keymaps` (`FileType`,
  needed to lazily bind per-buffer) — the actual clear/redraw logic is
  entirely event-armed, per the module doc comment in
  `bindings/autocmds.lua`.
- **`images.hover_float`/`images.ascii`/`images.redact` share the same
  shape** as `images.zen`'s `WinClosed` entry: a fresh augroup per open,
  `once = true`, buffer/window-`pattern`-scoped cleanup — one recurring
  pattern across every module that opens its own window, not four
  independent designs.

## Changelog

- 2026-08-06: created as part of the checklist rollout — this file did not
  exist before, even though `docs/BINDINGS.md` in the repo itself already
  documented all five entries correctly.
- 2026-08-07: table reordered to `Event(s) | Augroup | Pattern | Action`
  (per `docs/NOTES/BINDINGS-FORMAT.md`) and brought back in sync with the
  source — `images.hover_float`/`images.ascii`/`images.redact` had grown
  their own `WinClosed` cleanup autocmds since the last pass and were
  missing here entirely.
