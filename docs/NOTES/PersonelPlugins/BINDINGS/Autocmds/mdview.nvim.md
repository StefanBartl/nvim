# mdview.nvim — Autocmds Cheatsheet

Sources: `lua/mdview/bindings/autocmds/init.lua` (`M.attach()`/`M.teardown()`), `bufenter.lua`, `buffer_switch.lua`, `live_push.lua`, `scroll_sync.lua`, `vim_leave.lua`, `preview_tab_sync.lua`
Cross-reference: `docs/BINDINGS.md` — thorough and accurate, the best-maintained of all audited repos; no corrections needed.

All attached/torn down together by `:MDView start`/`stop` (**not** by
`setup()`), single augroup **`MdviewAutocmds`** (`clear=true`, created
directly rather than through lib.nvim's cached augroup helper, since that
helper would hand back a stale/deleted id after a prior `teardown()`).

| File | Event(s) | Pattern | Action |
| --- | --- | --- | --- |
| `bufenter.lua` | `BufEnter` | `defaults.ft_pattern` | Snapshots buffer content into `session` if not already stored |
| `buffer_switch.lua` | `BufEnter` | `defaults.ft_pattern` | Applies `browser.behavior` ("reuse"/"new_tab"/"manual") when switching markdown buffers during an active session; no-ops if `open_preview_tab` is set |
| `live_push.lua` | `TextChanged`,`TextChangedI` | `defaults.ft_pattern` | Waits for the websocket relay to be ready, pushes the FULL buffer (never a diff — the WASM client renderer needs whole-document context) |
| `live_push.lua` | `BufWritePost` | `defaults.ft_pattern` | Same push, forced `full=true` — a cheap resync point that reseeds the relay's LastPayload and heals any diff desync |
| `scroll_sync.lua` | `CursorMoved`,`CursorMovedI` | `defaults.ft_pattern` | Throttled (150ms default) send of cursor line/total-lines to the relay for browser scroll-follow; suppressed briefly after a programmatic reverse-scroll move to avoid an echo loop. Condition: `defaults.scroll_sync` (default on) — skipped entirely (not even registered) if off |
| `vim_leave.lua` | `VimLeavePre` | none (deliberately global) | Stops the relay process, sending a close signal to the browser tab first — a pattern restriction here previously orphaned the relay when Neovim quit from a non-markdown buffer, explicitly fixed |

## Dormant, not attached (module docstrings say so explicitly)

- `on_text_change.lua` — `{TextChanged,TextChangedI}`, diff-only push; superseded by `live_push.lua`.
- `bufwrite.lua` — `BufWritePost`, full push; superseded by `live_push.lua`.

## Independent lifecycle — `preview_tab_sync.lua`

Augroup **`MdviewPreviewTabSync`**, created lazily and only once per Neovim
session (the first time `:MDView preview-tab` opens a tab preview);
decoupled from `MdviewAutocmds`/`:MDView start`/`stop`.

| Event(s) | Action |
| --- | --- |
| `TextChanged`,`TextChangedI`,`BufWritePost` | If a tab preview is open for that buffer, sync it |
| `BufEnter`,`BufWinEnter`,`FileType` | Closes a tab preview when a file/explorer takes over its tab |

## Events mdview *fires*

None currently. A `User MDViewSessionEnded` event was briefly added (2026-07-26)
to auto-quit the detached background nvim, but it was removed together with
`:MDView detach` — the background path is now `:MDView standalone` (relay watches
the file on disk, no nvim to quit). See `Usercmds/mdview.nvim.md` for why detach
was cut.

## Notes

- `docs/templates/autocmds.lua`/`usercmds.lua` are scaffolding/boilerplate under `docs/templates/`, not `lua/` — not wired into anything, don't mistake these for live registrations.
