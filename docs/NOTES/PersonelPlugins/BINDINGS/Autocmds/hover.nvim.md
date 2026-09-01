# hover.nvim — Autocmds Cheatsheet

New repository, 2026-09-01, extracted from `lib.nvim.hover`.

Source: `lua/hover/bindings/autocmds.lua`
Docs: `docs/BINDINGS.md`

Installed by `require("hover").enable()` — called from this config's
`lua/plugins/personal/init.lua` (`lazy = false`, `priority = 900`). Two
augroups, both cleared and rebuilt on every call, which is what makes
`enable()` idempotent.

| Group | Event | Scope | Action |
| --- | --- | --- | --- |
| `HoverEnable` | `FileType` | `filetypes` pattern (default `*`) | attach to this buffer |
| `HoverBuf<n>` | `CursorHold` | one buffer | trigger (default trigger) |
| `HoverBuf<n>` | `CursorMoved` | one buffer | trigger, under `trigger = { "cursor" }` or `{ "mouse" }` |
| `HoverBuf<n>` | `BufLeave`, `InsertEnter` | one buffer | hide the float |

## Three reasons a per-buffer group is never created

- **`'buftype' ~= ""`.** A picker, a file tree, a terminal or a dashboard has
  no document to hover in. One check catches all of them; a filetype blocklist
  could not keep up.
- **Nothing that could answer.** With `paths.enabled = false` and no
  registered source there is nothing to say, so no `CursorHold` is installed
  rather than one that wakes on every trigger to discover that.
- **`mode = "manual"`.** The hide autocmds are installed, the trigger is not.
  That is the whole mode.

## Timing note

Under `CursorHold` the effective latency is `'updatetime'` **plus**
`delay_ms` — 200 + 250 = ~450 ms in this config. `CursorHold` also fires after
any keystroke followed by quiet, cursor movement or not, which is why the
dismissal has to *suppress* rather than close.

`trigger = { "cursor" }` is the alternative: `CursorMoved` plus the plugin's
own debounce, so `delay_ms` is absolute and nothing fires while the cursor
stands still. Not the default (see the plugin's `docs/ROADMAP.md`).

## Formerly

`lib.nvim.hover` installed `LibNvimHoverEnable` / `LibNvimHover<n>` for the
same events. Nothing calls its `enable()` any more, so those groups no longer
exist in a live session.
