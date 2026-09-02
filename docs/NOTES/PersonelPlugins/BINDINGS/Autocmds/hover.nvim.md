# hover.nvim — Autocmds Cheatsheet

New repository, 2026-09-01, extracted from `lib.nvim.hover`.

Source: `lua/hover/bindings/autocmds.lua`
Docs: `docs/BINDINGS.md`

Installed by `require("hover").enable()` — called from this config's
`lua/plugins/personal/init.lua` (`lazy = false`, `priority = 900`). Two
augroups, both cleared and rebuilt on every call, which is what makes
`enable()` idempotent.

## Groups and events

| Group | Event | Scope | Action |
| --- | --- | --- | --- |
| `HoverEnable` | `FileType` | `filetypes` pattern (default `*`) | attach to this buffer |
| `HoverBuf<n>` | `CursorHold` | one buffer | trigger (default trigger) |
| `HoverBuf<n>` | `CursorMoved` | one buffer | trigger, under `trigger = { "cursor" }` or `{ "mouse" }` |
| `HoverBuf<n>` | `BufLeave`, `InsertEnter` | one buffer | `hide_unless_pinned()` — **not** `hide()`: leaving the buffer and entering insert are exactly the moments someone pinned a float *for* |

## Three reasons a per-buffer group is never created

- **`'buftype' ~= ""`.** A picker, a file tree, a terminal or a dashboard has
  no document to hover in. One check catches all of them; a filetype blocklist
  could not keep up.
- **Nothing that could answer.** `anything_to_show()` asks three questions,
  not two: bare paths on, *or* a registered source, *or* a registered
  **position** preview with the `positions` switch on. Otherwise no
  `CursorHold` is installed at all, rather than one that wakes on every
  trigger to discover there is nothing it can say.

  The third question is easy to forget and expensive to get wrong in both
  directions. Leaving it out means the whole position-preview kind silently
  does nothing in exactly the configuration someone would build to try it
  out. Counting too much means the opposite: a contribution registered as
  `on_request` deliberately does **not** count, because a trigger that wakes,
  asks nobody and sleeps again is pure cost. hover.nvim shipped that gap in
  the other direction once — `show_position` used the same predicate as a
  guard ahead of its `force` check, which made a request-only contribution
  unreachable by any route (fixed 2026-09-02, `836a15a`).
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

`trigger = { "mouse" }` installs a second `CursorMoved` for hovering with the
pointer. It needs `'mousemoveevent'`, which is a **global user setting the
plugin deliberately does not set** — without it the autocmd is installed and
simply never fires, which is the one case here that looks like a bug and is
not.

## Formerly

`lib.nvim.hover` installed `LibNvimHoverEnable` / `LibNvimHover<n>` for the
same events. That module is **deleted** as of 2026-09-01 (lib.nvim
`5450dd4`), so those group names cannot come back by accident — before that
they merely had nothing calling `enable()`.

## Changelog

- 2026-09-02: the "nothing that could answer" rule had gained a third
  question since this file was written — a registered **position** preview
  with the `positions` switch on also earns a buffer its trigger. The entry
  below explicitly claimed the opposite, which was true when written and
  stopped being true with hover.nvim `1b4cc8d`. Also: `BufLeave`/
  `InsertEnter` call `hide_unless_pinned()` rather than `hide()` since
  `8d26756`, and the `mouse` trigger is now described.
- 2026-09-01: no change to the groups or events from hover.nvim `b2b4b2c`.
  The new `paths code` switch is read inside the trigger's handler, not by an
  autocmd; the "nothing that could answer" rule below still keys on
  `paths.enabled` and a registered source alone, because a buffer where the
  position gate happens to refuse everything is not a buffer where nothing
  *could* answer.
- 2026-09-01: `lib.nvim.hover`'s augroups are gone for good — the module was
  deleted rather than merely left uncalled.
