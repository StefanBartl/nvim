# spotlight.nvim — `:Spotlight <subcommand>` Cheatsheet

One command, built via `lib.nvim.usercmd.composer` (`<Tab>` completion, argument
typing and validation, Markdown docgen — all from the same route tree). No flat
`:SpotlightToggle`/`:SpotlightClear` family ever existed.

Source: `lua/spotlight/bindings/usrcmds.lua`
Docs: `docs/BINDINGS.md`, `README.md`, `doc/spotlight.txt`

`lib.nvim.usercmd.composer` is a **hard** dependency here: without it the command
layer fails to load. `:checkhealth spotlight` reports it as an error, not a warning.

| Command | Args | Range | Effect |
| --- | --- | --- | --- |
| `:Spotlight` | — | no | **Default route**: toggle the token under the cursor |
| `:Spotlight toggle [text]` | `STRING?` | yes | Cursor token, a `'<,'>` range selection, or the explicit `text` |
| `:Spotlight add {text}` | `STRING` | no | Add a spotlight for the literal `text` |
| `:Spotlight remove {text}` | `STRING` | no | Remove the spotlight matching `text` exactly |
| `:Spotlight clear` | — | no | Remove every spotlight |
| `:Spotlight list [jump\|remove]` | enum? | no | Open the list; `remove` makes selection delete instead of jump |
| `:Spotlight next` | — | no | Jump to the next occurrence |
| `:Spotlight prev` | — | no | Jump to the previous occurrence |
| `:Spotlight qf [text]` | `STRING?` | no | Matching lines → quickfix (all spotlights, or just `text`'s) |
| `:Spotlight persist [on\|off\|default\|status]` | enum? | no | Per-file persistence override; no arg = `status` |
| `:Spotlight refresh` | — | no | Redefine the palette + re-apply every match to every window |

No bang on any route: nothing here has a natural inverse that `!` would express
(unlike cascade's `sort`/`sort!`).

## Range handling

`toggle` is the only range-aware route. `:'<,'>Spotlight toggle` reads the
selection from the `'<`/`'>` marks, **not** from the live cursor positions the way
the visual-mode keymap does.

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

Every subcommand has a facade function (`require("spotlight").<action>`) and, for
the common ones, a preset keymap — see
[Keymaps/spotlight.nvim.md](../Keymaps/spotlight.nvim.md).
