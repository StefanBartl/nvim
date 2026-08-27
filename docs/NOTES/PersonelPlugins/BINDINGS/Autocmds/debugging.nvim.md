# debugging.nvim — Autocmds Cheatsheet

Source: `lua/debugging/bindings/autocmds.lua`, `M.setup(ac, timings)`
Cross-reference: `docs/BINDINGS.md` — verified accurate.

No-op unless `ac.enable` (`config.views.autocmds.enable`, default on). Augroup
`DebugViewsAuto` (default name) created directly via `nvim_create_augroup(...,
{clear=true})` rather than `lib.nvim.bindings.autocmd.group()` — deliberately, per the
module comment: that helper caches by name and skips the clear on repeat
calls, which would stack duplicate autocmds every time `setup()` re-runs.
Clearing on each setup is what makes reloading the config without restarting
Neovim work.

| Event | Pattern | Condition | Action |
| --- | --- | --- | --- |
| `WinEnter` | none | `ac.auto_refresh` (default on) | Gets the window's debug-view tag; if tagged, refreshes that log view after a 30ms defer (if still valid/current) |
| `BufWinEnter` | none | same | Same idea, keyed off the buffer entering a window instead of window focus |
| `FileType` | `{"messages", "noice"}` | unconditional once `ac.enable` | Registers the buffer-local `q`/`<Esc>` close keymaps |

All three are created through `lib.nvim.bindings.autocmd`'s `create`, which pcalls the
callback and notifies on error — an autocmd that throws would otherwise fail
silently on every `WinEnter`.
