# spotlight.nvim — `:Spotlight <subcommand>` Cheatsheet

One command, built via `lib.nvim.usercmd.composer` (`<Tab>` completion, argument
typing and validation, Markdown docgen — all from the same route tree). No flat
`:SpotlightToggle`/`:SpotlightClear` family ever existed.

Source: `lua/spotlight/bindings/usrcmds.lua`
Docs: `docs/BINDINGS.md`, `docs/FEATURES.md`, `README.md`, `doc/spotlight.txt`

`lib.nvim.usercmd.composer` is a **hard** dependency here: without it the command
layer fails to load. `:checkhealth spotlight` reports it as an error, not a warning.

| Command | Args | Range | Effect |
| --- | --- | --- | --- |
| `:Spotlight` | — | no | **Default route**: toggle every occurrence of the token under the cursor |
| `:Spotlight toggle [text]` | `STRING?` | yes | Every occurrence: cursor token, a `'<,'>` range selection, or the explicit `text` |
| `:Spotlight here` | — | yes | Only this occurrence: cursor token, or a `'<,'>` range selection — the `:Spotlight here` counterpart of `<leader>sk` |
| `:Spotlight add {text}` | `STRING` | no | Add a spotlight for the literal `text` |
| `:Spotlight remove {text}` | `STRING` | no | Remove the spotlight matching `text` exactly |
| `:Spotlight clear` | — | no | Remove every spotlight |
| `:Spotlight list [jump\|remove\|lock\|line]` | enum? | no | Open the list; `remove` deletes on select, `lock` toggles the palette-slot lock, `line` toggles whole-line rendering |
| `:Spotlight next` | — | no | Jump to the next occurrence |
| `:Spotlight prev` | — | no | Jump to the previous occurrence |
| `:Spotlight qf [text]` | `STRING?` | no | Matching lines in the **current buffer** → quickfix (all spotlights, or just `text`'s) |
| `:Spotlight qf all [text]` | `STRING?` | no | Same, across **every loaded** ordinary file buffer, merged into one list |
| `:Spotlight yank [text]` | `STRING?` | no | Matching lines → unnamed register, one per line |
| `:Spotlight line [text]` | `STRING?` | no | Toggle **whole-line rendering** for a spotlight (`text`, or the cursor token) |
| `:Spotlight lock [text]` | `STRING?` | no | Toggle whether a spotlight keeps its palette slot permanently (`text`, or the cursor token) |
| `:Spotlight map [text]` | `STRING?` | no | One-shot occurrence density: a sign per matching line in the current buffer, in that spotlight's own color |
| `:Spotlight map clear` | — | no | Clear the sign-column occurrence map in the current buffer |
| `:Spotlight sets save {name}` | `STRING` | no | Save the active spotlights as a named set (overwrites an existing one) |
| `:Spotlight sets switch {name}` | `SPOTLIGHT_SET_NAME` | no | Clear the active spotlights and restore the saved set — destructive, not additive |
| `:Spotlight sets delete {name}` | `SPOTLIGHT_SET_NAME` | no | Delete a saved set; never touches the active spotlights |
| `:Spotlight sets list` | — | no | List every saved set and how many spotlights it holds |
| `:Spotlight winopt [on\|off\|toggle\|status]` | enum? | no | Per-**window** opt-out ("do not spotlight in this window"); no arg = `toggle` |
| `:Spotlight persist [on\|off\|default\|status]` | enum? | no | Per-**file** persistence override; no arg = `status` |
| `:Spotlight refresh` | — | no | Redefine the palette + re-apply every match to every window |

No bang on any route: nothing here has a natural inverse that `!` would express
(unlike cascade's `sort`/`sort!`).

`SPOTLIGHT_SET_NAME` is a **custom composer arg type** registered in `M.setup()`
(`composer.register_type`), so `:Spotlight sets switch <Tab>` / `delete <Tab>`
complete from whatever sets currently exist, read fresh on every press. It
validates everything — a set name is free-form; the type exists for the
completion source, not for rejection. `sets save` deliberately takes a plain
`STRING` instead: completing it would only ever suggest the sets you are about
to overwrite.

## Range handling

`toggle` and `here` are the range-aware routes. `:'<,'>Spotlight toggle` (or
`here`) reads the selection from the `'<`/`'>` marks, **not** from the live
cursor positions the way the visual-mode keymap does.

That difference is not an inconsistency — it is required. By the time a `:`
command runs, Visual mode has already ended, which is exactly when `'<`/`'>`
become valid and exactly when the live-position approach in
`spotlight.cursor.selection()` stops working. The two paths read the selection
from whichever source is correct at their own moment.

**Updated 2026-07-31**: `range_text()` no longer queries `vim.fn.col("'<"/"'>")`
itself — it reads `ctx.range.col1`/`col2`, which lib.nvim's composer computes
off the same marks (one source for the geometry instead of two that could
disagree). The route also declares `visual = { "charwise" }`
(lib.nvim commit `84737e1`): a linewise or blockwise selection is now refused
by composer itself, with its own error message, *before* reaching
`range_text` — a spotlight is a piece of text within one line, so neither
shape carries anything usable (linewise has no columns to read, blockwise
spans several lines by definition).

Multi-line ranges are refused with a message rather than joined: a pattern
containing a newline cannot match anything `matchadd()` sees, so accepting one
would silently produce a spotlight that highlights nothing. (This is
`range_text`'s own single-line check, still needed for a multi-line *charwise*
range — `visual = { "charwise" }` alone doesn't rule that out.)

## The `persist` route in detail

Three-state, which is the part worth remembering:

| Arg | Effect |
| --- | --- |
| `on` | Sets an **explicit** `true` override for this file |
| `off` | Sets an **explicit** `false` override for this file |
| `default` | **Clears** the override — the file follows `persist.default` again |
| `status` (or no arg) | Reports what applies here and *why* (override vs. default) |

`on` sets an explicit true rather than clearing the override, so it also works in
the inverted model (`persist.default = false`, opt in per file). `default` is the
route that clears — without it, "back to the global default" would be
unexpressible once an override existed.

An override is keyed by **project-relative file path**, so it survives closing and
reopening the file. Buffers with no file on disk are refused with a message —
there is no stable identity to hang an override on.

## Notes

- **`:Spotlight qf`** refuses to run from inside the quickfix window (it would
  filter the list into itself). With `quickfix.open = true` focus is handed back to
  the source window after `:copen`, so a second invocation still targets the log.
- **`:Spotlight list`** opens `lib.nvim.ui.kit.select` with *rich items* (per-row
  highlight spans for the color swatch). It deliberately does **not** set
  `respect_override`, so a `vim.ui.select` replacement (telescope-ui-select,
  fzf-lua, dressing) is bypassed — a foreign picker only understands plain strings
  and would drop the colors that are the point of the list.
- **`:Spotlight refresh`** is the escape hatch for the one thing `matchadd()`
  cannot do: update in place. Also the fix if another plugin has cleared the
  current window's matches with `clearmatches()`.
- **`:Spotlight toggle {text}`** with explicit text dispatches to add/remove by
  exact-text lookup, so it is idempotent in the same way the keymap is.
- **`:Spotlight here`** toggles by exact buffer position (`registry.find_at`),
  not by text — pressing it twice on the *same* occurrence removes it, but a
  different occurrence of the same text is a separate spotlight. Session-only:
  never written to the persisted snapshot, and dropped if its buffer is wiped
  or a window switches away from it.
- **`:Spotlight qf all`** shares one global cap with `qf` (`quickfix.max_entries`,
  default 10000) rather than giving each buffer its own: every buffer gets
  whatever budget is left after the earlier ones, and the buffer loop itself
  stops the moment one buffer's scan reports truncation.
- **`:Spotlight yank`** is `qf`'s register-shaped sibling — same scan, same cap,
  result into the unnamed register one line per match instead of into a list.
- **`:Spotlight lock`** pins a spotlight's palette slot so round-robin never
  hands that color to a different spotlight, even once all 8 slots are in use.
  Only bookkeeping: locking does not reassign the current color. Persisted.
- **`:Spotlight map`** is deliberately **one-shot and explicit** — it scans once,
  places the signs, and then reacts to nothing. Editing the buffer afterwards
  leaves the marks where they were; run it again to refresh. A density map that
  stayed current would need exactly the invalidation `matchadd()` was chosen to
  avoid. Per-buffer, and it adds **zero autocmds**: Neovim drops a wiped
  buffer's extmarks with it. This is also why it has no default keymap.
- **`:Spotlight sets switch`** is destructive by design: the current state is
  discarded, not merged. The notification says so explicitly rather than leaving
  it to be discovered — save the current set first if you want it back.
- **`:Spotlight winopt`** is per *window*, not per buffer: the flag lives on
  `vim.w[win].spotlight_disabled`, so it survives that window later showing a
  different file. Turning it off strips the window's matches immediately rather
  than only gating future fills. Session-only — a window id means nothing after
  a restart.
- **`:Spotlight line`** toggles a *rendering* flag on an existing spotlight, not
  a new kind of spotlight: `item.pattern` stays the token pattern (so counts,
  quickfix, yank and the occurrence map keep their meaning) and only the string
  handed to `matchadd()` is widened to the whole line, registered one priority
  below `match.priority` so it cannot swallow the other spotlights' token
  colors. The highlight ends where the line's text ends — running it to the
  window edge would need an extmark, i.e. a stored position, which is exactly
  what this plugin does not store. Persisted; tagged `(whole line)` in the
  list. A `:Spotlight here` spotlight has no text identity, so its line mode is
  reached with `:Spotlight list line` rather than `:Spotlight line {text}`.

Every subcommand has a facade function (`require("spotlight").<action>`) and, for
the common ones, a preset keymap — see
[Keymaps/spotlight.nvim.md](../Keymaps/spotlight.nvim.md).

## Changelog

- 2026-08-17: Added `:Spotlight line [text]` and the `line` action on
  `:Spotlight list` (the only way to reach a `:Spotlight here` spotlight's line
  mode — it has no text identity to name it by). Key: `<leader>sW`.
- 2026-08-17: Caught the route table up with the source. `qf all`, `yank`,
  `lock`, `map` / `map clear`, `sets save|switch|delete|list` and `winopt` had
  all shipped since this note was last touched and were missing here, as was
  the `lock` action on `:Spotlight list`. Added a note on the
  `SPOTLIGHT_SET_NAME` custom composer arg type (dynamic `<Tab>` completion for
  `sets switch`/`delete`).

- 2026-08-12: Added `:Spotlight here` (range-aware, mirrors `toggle`) for
  "this occurrence only" spotlights — the `:Spotlight` counterpart of the new
  `<leader>sk` behavior. `toggle`/`:Spotlight` bare default unchanged (still
  every occurrence).

- 2026-08: Keymap prefix moved from `<leader>m` to `<leader>s` (letters
  unchanged). The `:Spotlight` command surface itself is unaffected — this
  file's `<leader>*` mentions are updated to current notation. See
  [Keymaps/spotlight.nvim.md](../Keymaps/spotlight.nvim.md) for the collision
  check that motivated it.

## `!` on next/prev, and the list filter (2026-08-24)

| command | change |
| --- | --- |
| `:Spotlight[!] next` / `[!] prev` | `!` ignores `nav.scope` and searches every spotlight for that jump |
| `:Spotlight list [action] [filter]` | `filter` narrows the list before it opens |

**The bang is per call, not a mode.** With `nav.scope = "auto"` the point of
`]k` is that it follows the token under the cursor — right until you want the
opposite, and the only way out was editing the config and reloading. The
override is a parameter threaded to `nav_pattern`, not stored state, so
there is nothing to reset and nothing that leaks into a later jump.

**The filter is one argument, not `--color`/`--origin`.** The fields never
collide in practice — a slot is a number, an origin is a path, the text is
neither — so one token answers both questions the audit asked. It matches
slot, highlight group, origin path and text.

A **numeric** query is only a slot query, with no substring fallback:
otherwise `1` would also match slot 10, via the `1` in its own highlight
group name `Spotlight10`, undoing the exact test it just passed. (That was a
real bug in the first version, caught by the runtime check.)

The count-support audit's entry for this plugin was **stale** — `]k`/`[k`
have read `vim.v.count1` since 2026-07-31, as the keymaps sheet already
recorded. Verified rather than assumed.
