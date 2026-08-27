# cascade.nvim — `:Cascade <subcommand>` Cheatsheet

One command, built via `lib.nvim.bindings.usercmd.composer` (`<Tab>` completion).
Replaces the old flat `:CascadeRotate`/`:CascadeSort`/… commands (fully
removed, no alongside period).

Source: `lua/cascade/bindings/usrcmds.lua`
Docs: `docs/BINDINGS.md`, `README.md`, `doc/cascade.txt`

All subcommands are `:command-range` aware: without a range they act on the
list block at the cursor; with a range (e.g. visual `:'<,'>`) on the selected
lines.

| Command | Bang | Effect |
| --- | --- | --- |
| `:Cascade rotate [next\|prev]` | yes | Rotate list form forward/backward |
| `:Cascade sort` | yes | Sort list A–Z (`!` = Z–A) |
| `:Cascade reverse` | no | Reverse list order |
| `:Cascade strip` | no | Strip checkboxes |
| `:Cascade indent [n]` | no | Indent (n levels, default 1) + renumber |
| `:Cascade dedent [n]` | no | Dedent (n levels) + renumber |
| `:Cascade renumber [all\|selection]` | no | Renumber block at cursor/range; `all` = whole buffer; `selection` = die Ordinal-Token *innerhalb* der Zeilen (sequence-Domäne) |

## ⚠️ Breaking syntax change: bang position

`!` now attaches to the **verb**, not the subcommand — this is a Vim syntax
constraint (bang always binds to the command name itself), not a choice:

```vim
" OLD (no longer works):
:CascadeRotate!

" NEW:
:Cascade! rotate
```

## Notes

- **lib.nvim policy flip**: cascade.nvim had an explicit "no hard dependency
  on lib.nvim, works fully standalone" architecture rule (`util/lib.lua`,
  `Arch&Coding.md`). Per the new global policy, lib.nvim is now a **required**
  dependency (the `:Cascade` command itself needs
  `lib.nvim.bindings.usercmd.composer`). `lib.map`/`lib.notify` stay soft-guarded.
- **CI fix**: `.github/workflows/ci.yml`'s `tests` job didn't check out
  lib.nvim at all — would have broken on the new hard dependency. Fixed with
  a sibling checkout (`path: lib.nvim`) + `rtp+=.,../lib.nvim`.
- **Composer bug found + fixed** (in lib.nvim itself): `route.range` was
  declared in the type but never actually wired into the real
  `nvim_create_user_command` registration — only verb-level `spec.range`
  worked. Added `wants_range()` (mirrors `wants_bang()`).
- **`:Cascade renumber [all]` added** (was previously only a keymap,
  `<leader>cr`, with no command equivalent). Range-aware like the others:
  no range/arg = block at cursor; explicit range = renumber exactly that
  range as one tree block; `all` = sweep every list block in the buffer
  independently. Implemented via `cascade.run_renumber_command` in
  `lua/cascade/init.lua`, mirroring the existing `run_command`/
  `run_indent_command` helpers.
- **`selection`-Scope ergänzt (2026-08-23)**: `:Cascade renumber selection`
  routet in die neue `sequence`-Domäne (`lua/cascade/sequence/renumber.lua`)
  statt in `lists/renumber.lua` — nummeriert also die Ordinal-Token innerhalb
  der Zeilen neu, egal was davor steht, filetype-unabhängig. Eigener Schalter
  (`sequence.enable`), deshalb vor und getrennt von `lists.enable` gegated.
  Das charwise-Pendant ist bewusst nur die Keymap `<leader>cR` (x-Mode), weil
  Ex-Ranges immer linewise sind.
- **`<leader>cR` deckt jetzt auch mehrzeilige charwise-Selektionen ab
  (Nachtrag 2026-08-23)**: `lib.nvim.selection` bekam `chars_multiline()`/
  `reselect_chars_multiline()`, `sequence/renumber.lua` ein `M.span_multi`.
  `:Cascade renumber selection` selbst bleibt linewise (Ex-Ranges können
  keine Spalten tragen) — betrifft nur den Keymap-Pfad.
- **Previously-noted doc bug now fixed**: `:CascadeRenumber` was referenced in
  README/health.lua/comments/doc but was never a registered command — every
  stale reference has been corrected to `:Cascade renumber`.

## `:Cascade cycle` (2026-08-24)

| command | purpose |
| --- | --- |
| `:Cascade cycle add {a},{b}[,{c}]` | Add a cycle group for this session |
| `:Cascade cycle list` | Show the groups in effect for this buffer |
| `:Cascade cycle remove {value}` | Drop the group containing `{value}` |

`cycle.groups` used to be config-only. `add` appends to the live table
`word_cycle.groups_for` reads on every keypress, so it applies immediately,
and it takes the whole tail rather than one token — values may contain
spaces (`TODO, IN PROGRESS ,DONE`). Refused: fewer than two distinct values,
or duplicates, both of which produce a cycle that cannot cycle.

**Not persisted, on purpose** — session-only, with the config file left as
the source of truth for groups worth keeping.

`list` reports global groups *and* the filetype's, since they are separate
config keys and either one alone answers the wrong question.
