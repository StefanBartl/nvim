# debugging.nvim — Keymaps Cheatsheet

Source: `lua/debugging/bindings/keymaps.lua`, `lua/debugging/bindings/autocmds.lua`, `lua/debugging/commands.lua`
Cross-reference: `docs/BINDINGS.md` in this repo — verified accurate for the static table below.

## Static, config-driven

Gated by `cfg.features.views` (default on) and `km.enable` (default on).
Prefix `km.prefix` defaults to `<lt>` (the literal `<` key).

| lhs | mode | action | desc |
| --- | --- | --- | --- |
| `<lt>m` | n | Open/refresh the `:messages` capture view | "[Debug] Messages view" |
| `<lt>n` | n | Open/refresh a view of all Noice messages | "[Debug] Noice all" |
| `<lt>e` | n | `:Noice errors` | "[Debug] Noice errors" |
| `<lt>c` | n | Capture `:messages` to a file + clipboard | "[Debug] Capture to file+clipboard" |
| `<lt>f` | n | Capture `:messages` to a file only | "[Debug] Capture to file only" |
| `<lt>y` | n | Capture `:messages` to the clipboard only | "[Debug] Capture to clipboard only" |
| `<lt>x` | n | Close all open debug view windows | "[Debug] Clear all windows" |

## Dynamic, buffer-local (not in the static table above)

| lhs | mode | Where registered | action |
| --- | --- | --- | --- |
| `q` / `<Esc>` | n | Inside the `FileType` autocmd (pattern `messages`/`noice`) — see [Autocmds cheatsheet](../Autocmds/debugging.nvim.md) | Closes the debug window showing that buffer |
| `q` / `<Esc>` | n | `commands.lua`'s `overview_float()` (bare `:Debug` when `config.overview == "float"`, the default) | Closes the floating overview window — a **separate** close-keymap site from the one above, no `desc` given here |

## which-key

`bindings/which_key.lua`, `M.setup(prefix)` — registers a single group
label ("Debug views") for the configured `km.prefix` (default `<lt>`),
soft-guarded (`pcall(require, "which-key")`, no-op if absent). Individual
keys already carry their own `desc`; only the shared-prefix group needs
explicit labeling. Handles both which-key v3 (`wk.add`) and v2
(`wk.register`) APIs.

## Notes

- All static keymaps use `km.map` (resolved as `vim.keymap.set`, or a no-op if `vim.keymap` is unavailable).
- `docs/BINDINGS.md`'s FileType-autocmd row description ("Bind q / `<Esc>` to close the debug window") gestures at the dynamic keymap but doesn't list it as its own line item; the `overview_float` close keys aren't mentioned there at all.

**Capture sinks (added 2026-08-24):** `capture_messages` always took
`save_file`/`clipboard`, but only the both-at-once default was bound —
choosing one sink meant calling the Lua API by hand. Three distinct keys
rather than a prefix tree: `<lt>c` then waiting to see whether an `f`
follows would delay the common case for the sake of the two rare ones.
`<lt>c`'s behaviour and `desc` are unchanged.
