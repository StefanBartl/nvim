# cascade.nvim — Keymaps Cheatsheet

Source: `lua/cascade/bindings/keymaps.lua`, `lua/cascade/bindings/which_key.lua`
Bridge: `lua/cascade/util/lib.lua`'s `lib.map()` — prefers `lib.nvim.bindings.keymap`, falls
back to `vim.keymap.set`. Every mapping sets `silent = true` and a `desc`.

Cross-reference: `docs/BINDINGS.md` in this repo is kept in sync with source
(explicitly documented as the source of truth) — verified current.

All of the below is gated by the top-level switch `cfg.keymaps.preset`
(default **off**), plus each group's own feature flag.

## Global preset (`cfg.keymaps.preset == true`)

### Cycle/increment (`cfg.cycle.enable and features.word`)

| lhs | mode | action |
| --- | --- | --- |
| `<C-y>` | n | Cycle word/token under cursor forward through configured groups. `N` = N steps |
| `<C-x>` | n | Cycle word/token backward |
| `+` | n | Increment / cycle word / flip an operator (`==`/`&&`/`<`/...) / step an ISO date segment (native line-down otherwise) |
| `-` | n | Decrement / cycle word / flip an operator / step an ISO date segment (native line-up otherwise) |
| `<leader>cp` | n | Pick a cycle-group value via `vim.ui.select` (Telescope-backed if registered) |

### Sequence — Renumbering *innerhalb* der Selektion (`cfg.sequence.enable`)

Eigene Domäne, filetype-unabhängig, kein Listenkontext nötig: nummeriert die
Ordinal-Token (`1.`, `a)`, `II.`) in der Selektion neu, egal was davor steht
(Markdown-Headlines mit Nummer, Inline-Zahlen in Prosa).

| lhs | mode | action |
| --- | --- | --- |
| `<leader>cR` | x | Renumbering der Ordinal-Token in der Selektion. **Nur Visual-Mode**, mit Absicht: eine Ex-Range (`:'<,'>`) ist in Vim immer linewise und würde die Spalten einer mitten in der Zeile liegenden charwise-Selektion verwerfen. Abgrenzung zu `<leader>cr` (ganzer Listenblock am Cursor). |

Charwise (`v`) — einzeilig **und mehrzeilig** — wird in-place geschrieben und
auf den neuen Grenzen reselektiert (Text kann breiter werden, `9.` → `10.`);
Text vor Selektionsstart bzw. nach Selektionsende bleibt auf beiden
Randzeilen unangetastet. Linewise (`V`) bzw. eine Selektion ganz ohne
Spalten-Bounds (blockwise) wird als Zeilen-Range behandelt.

### Indent (`cfg.lists.enable and features.indent`)

| lhs | mode | action |
| --- | --- | --- |
| `<A-Right>` | n | List-aware indent + renumber. No count (or 1): current line + its subtree. `N<A-Right>`: **N lines** starting at cursor, one level each. (native `>>` otherwise) |
| `<A-Left>` | n | List-aware dedent + renumber. Same count-as-lines semantics as `<A-Right>`. |
| `<A-Right>` | x | List-aware indent + renumber the selection |
| `<A-Left>` | x | List-aware dedent + renumber the selection |
| `<leader><A-Right>` | n | Indent the **current line only**, by `N` levels (`N<leader><A-Right>`) — the old count meaning of bare `<A-Right>`, moved here |
| `<leader><A-Left>` | n | Dedent the current line only, by `N` levels |
| `<A-Right>` | i | Native `<C-t>` (indent line) |
| `<A-Left>` | i | Native `<C-d>` (dedent line) |

### Move (`cfg.lists.enable and features.move`)

| lhs | mode | action |
| --- | --- | --- |
| `<A-Up>` | n, x | Move line/selection up |
| `<A-Down>` | n, x | Move line/selection down. `N` = N lines (normal mode) |
| `<A-Up>` | i | `<C-o>:m .-2<CR><C-o>==` |
| `<A-Down>` | i | `<C-o>:m .+1<CR><C-o>==` |

### Transpose (`cfg.transpose.enable`, each row also gated by its own `features.char`/`features.word`)

`N<lhs>` repeats the swap `N` times (drags the char/word/selection `N`
positions over); stops early at a line boundary or when no neighbor is left.

| lhs | mode | feature gate | action |
| --- | --- | --- | --- |
| `<leader><Right>` | n, x | `char` | Swap char/selection with right neighbor char |
| `<leader><Left>` | n, x | `char` | Swap char/selection with left neighbor char |
| `<leader><C-Right>` | n, x | `word` | Swap word/selection with right neighbor word (`'iskeyword'`-based; separator between the two moves as an untouched block) |
| `<leader><C-Left>` | n, x | `word` | Swap word/selection with left neighbor word |

## Buffer-local list keymaps (`cfg.lists.filetypes` buffers only)

Attached via the `FileType` autocmd — see [Autocmds cheatsheet](../Autocmds/cascade.nvim.md).

| lhs | mode | feature gate | action |
| --- | --- | --- | --- |
| `<CR>` | i | `continue` | Continue list item, or fall back to plain newline |
| `o` / `O` | n | `continue` | Open list item below / above |
| `<leader>cx` | n | `checkbox` | Toggle checkbox |
| `<A-->` | n, x | `bullet_toggle` | Toggle bullet point. `N` = the next N lines (normal mode) |
| `<A-*>` | n, x | `bullet_toggle` | Toggle star bullet |
| `<A-0>` | n, x | `number_toggle` | Toggle numbered list |
| `<A-c>` | n, x | `checkbox_toggle` | Toggle checkbox bullet |
| `<leader>ct` / `<leader>cT` | n | `cycle_type` | Cycle list type forward / back |
| `<leader>cr` | n | unconditional (inside preset) | Renumber |
| `<leader>cf` / `<leader>cF` | n, x | `rotate` | Rotate list form forward / back |
| `<leader>cs` | n, x | `sort` | Sort list A–Z |
| `<leader>cv` | n, x | `reverse` | Reverse list order |
| `<leader>cX` | n, x | `strip` | Strip checkboxes |

`<leader>cX` (strip) is deliberately a different key from `<leader>cx` (toggle) to avoid a mapping clash.

## which-key

`<leader>c` is labelled as a group ("Cascade") when which-key.nvim is
installed and preset keymaps are enabled. No-op otherwise.

## Notes

- Every preset keymap is individually gated by its own `cfg.<area>.features.<name>` flag as well as the group-level `cfg.<area>.enable` — disabling a feature drops just that pair of keymaps, not the whole group.
- `docs/BINDINGS.md` in the repo is the maintained source of truth; this file mirrors it.

## Changelog

- 2026-08-23 (Nachtrag): `<leader>cR` deckt jetzt auch mehrzeilige charwise
  (`v`)-Selektionen ab, nicht nur einzeilige — `lib.nvim.selection` bekam
  `chars_multiline()`/`reselect_chars_multiline()`, `sequence/renumber.lua`
  ein `M.span_multi`. Vorher fiel eine mehrzeilige charwise-Selektion auf den
  linewise-Zweig zurück (bewusst zurückgestellt, jetzt nachgezogen).
- 2026-08-23: added `<leader>cR` (`renumber_selection`, x-Mode) — neue
  `sequence`-Domäne (`sequence.enable`/`start`/`types`), plus
  `:Cascade renumber selection` als linewise Ex-Pendant.
- 2026-08-09: added `<leader>cp` (`cycle_pick`, interactive `vim.ui.select`
  over a cycle group's entries); `+`/`-` extended to also flip operator
  groups and step ISO date segments.
- 2026-08-08: added word swap (`<leader><C-Right>`/`<leader><C-Left>`, n+x,
  new `features.word`) and count support (`N<lhs>` = swap N times) on both
  char and word transpose, normal and visual. Written 2026-08-08 from a
  feature branch that wasn't actually merged into cascade.nvim's `main` at
  the time — merged 2026-08-09 (the branch's own count-fix bug was, by
  coincidence, independently rediscovered and fixed the same way while it
  sat unmerged; the two were reconciled into one merge commit).

## Count support extended (2026-08-24)

Indent/dedent had a deliberate count design from the start; cycle, move and
quick-toggle did not — that inconsistency was the count audit's entry. All
three read a count now:

- **Cycle** takes N *steps*, not N places. One rule covers every group kind:
  a 2-state toggle lands on its parity (`2<C-y>` on `true` stays `true`), a
  3-state cycle wraps, an ISO date rolls over months. Both native fallbacks
  re-emit the count rather than swallowing it.
- **Move** goes one line at a time N times, so reindent and renumber stay
  correct at each step; stops at the buffer edge.
- **Quick-toggle** widens the *scope* to N lines instead of repeating —
  repeating a toggle is a no-op for every even count.

Cycle and quick-toggle stash the count before the dot-repeat trampoline (as
`swap_right`/`swap_left` already did), since the trampoline does not carry
`vim.v.count1` through. Move is not wrapped and reads it directly.

No `desc` strings changed.
