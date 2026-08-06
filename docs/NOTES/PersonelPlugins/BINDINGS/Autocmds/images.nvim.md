# images.nvim — Autocmds Cheatsheet

Sources: `lua/images/bindings/autocmds.lua`, `lua/images/init.lua`, `lua/images/zen.lua`
Cross-reference: `docs/BINDINGS.md` (current, includes keymaps/usercmds too).

| Augroup (clear) | Event(s) | Registered | Action |
| --- | --- | --- | --- |
| `images.autocmds` | `VimLeavePre` | Once, at `setup()` | Clears a displayed image before Neovim quits |
| `images.keymaps` | `FileType` | Once, at `setup()` | Registers the buffer-local keymaps for `keymaps.filetypes` |
| `images.clear` | `display.clear_events` (default: `CursorMoved`, `CursorMovedI`, `InsertEnter`, `BufLeave`, `WinScrolled`) | Dynamically, each time an image is shown; `once = true` | Clears the just-shown image |
| `images.zen` | `WinResized`, `VimResized` | Dynamically, on `:Image zen` | Redraws the zen image so it follows the window's size |
| `images.zen` | `WinClosed` | Dynamically, on `:Image zen`; `once = true` | Clears the image when the zen window closes |

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

2026-08-06: created as part of the checklist rollout — this file did not
exist before, even though `docs/BINDINGS.md` in the repo itself already
documented all five entries correctly.
