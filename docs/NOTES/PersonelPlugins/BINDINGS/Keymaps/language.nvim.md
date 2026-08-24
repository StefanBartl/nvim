# language.nvim — Keymaps Cheatsheet

Sources: `lua/language/bindings/keymaps/init.lua`, `lua/language/spell/init.lua`, `lua/language/translate/window.lua`
Cross-reference: `docs/BINDINGS.md` — current for the config-driven table below; doesn't mention the translate-window's dynamic keys (noted there as internal UI plumbing).

## Global, config-driven

Local `map()` helper — tries `lib.nvim.map`, falls back to `vim.keymap.set`
(`desc`, `silent=true`, `noremap=true`). Each skipped if its config key isn't
a non-empty string.

| lhs (config key, default) | mode | action | desc |
| --- | --- | --- | --- |
| `spell.keymaps.panel` (`<leader>ss`) | n | Toggle spell session (current buffer) | "[language] Toggle spell session (current buffer)" |
| `translate.keymaps.operator` (default **off**) | n | Translate motion (operator-pending: `<lhs>{motion}`) | "[language] Translate motion" |
| `translate.keymaps.visual` (default **off**) | x | Translate selection | "[language] Translate selection" |
| `translate.keymaps.to.<LANG>` (default **off**) | n, x | Translate motion/selection into that language for one run | "[language] Translate motion to {LANG}" / "[language] Translate selection to {LANG}" |
| `thesaurus.keymap` (default **off**, even though `thesaurus.enable=true`) | n | Synonyms for word under cursor | "[language] Synonyms for word under cursor" |

## Buffer-local, session-scoped (spell)

Attached only while a spell-check session is active on that buffer
(`M.run()`), detached on `M.clear()`/`BufDelete`.

| lhs (config key, default) | mode | action | desc |
| --- | --- | --- | --- |
| `spell.keymaps.fix` (`<leader>z=`) | n | `z=` then (60ms later) refresh diagnostics + jump to next issue | "[language] Correct word & advance" |
| `spell.keymaps.fix1` (`<leader>z1`) | n | `1z=` (accept first suggestion) then refresh + goto_next | "[language] Accept first suggestion & advance" |
| `spell.keymaps.next` (`]s`) | n | Jump to next diagnostic in the `language.spell` namespace | "[language] Next spell error" |

`]s`'s count support (since 2026-07-31): `4]s` jumps 4 spell errors forward
(`goto_next(vim.v.count1)`). `M.goto_prev()` gained the matching `count`
parameter too, but **no keymap calls it** — only `next`/`]s` is bound in this
repo's config defaults, there is no `prev` binding to wire it to.

## Interactive translate window (buffer-local to the ephemeral input float)

Actions are NORMAL-mode keys (press `<Esc>` first) so insert-mode typing
keeps its native keys.

| lhs | mode | action |
| --- | --- | --- |
| `q` / `<Esc>` | n | Close |
| `<C-c>` | i | Close |
| `<C-l>` | n | Open a language picker to retarget |
| `<C-r>` | n | Round-trip: promote translated output into the input, reopen retarget picker |
| `<C-h>` | n | Open translate-history picker, load chosen entry |
| `<C-y>` | n | Copy output to `+`/`"` registers, record history entry, notify |

## which-key

`bindings/which_key/init.lua`, `M.setup(cfg)` — labels the `spell.keymaps.
panel`/`spell.keymaps.fix` prefixes as "Spell"/"Grammar fix" groups (only
the ones actually configured to a non-empty string; skips silently
otherwise). Soft-guarded, no-op if which-key is absent. `translate.keymaps.
*`/`thesaurus.keymap` have no group (single keys, off by default, `desc`
carries them).

## Notes

- Every `kit.select`/`kit.menu` call (spell review panel, per-issue action menu, retarget/history pickers) opens a `lib.nvim.ui.kit` component, which supplies its own `<CR>`/`<C-n>`/`<C-p>`/`<Up>`/`<Down>`/`<Esc>` keys — see [lib.nvim's cheatsheet](./lib.nvim.md) for those.
- `docs/BINDINGS.md` matches source exactly for the config-driven table (including default lhs values cross-checked against `config/DEFAULTS.lua`), but doesn't list the translate-window's dynamic keys as their own entries.

## Added 2026-08-24

**Per-language translate keys.** With `default_target` set the operator
always used it and never asked; without one it always asked. `keymaps.to`
is one key per language, forcing that target for a **single** run — the
force is consumed by the next resolution, so it never leaks into the
following unforced one.

A count could not carry the language: on an operator the count belongs to
the motion (`3<lhs>w` is three words), which is the whole point of an
operator. Hence a key per language. Unset by default.

**Nth synonym.** `3<thesaurus.keymap>` replaces the word with the third
synonym without opening the menu, like `3z=`. `vim.v.count` is read **raw**:
0 must stay distinguishable from 1, since no count opens the menu while `1`
takes the first synonym outright. Out of range is reported, not clamped —
substituting a different word than the one counted would be an edit nobody
asked for.

The existing `desc` strings are unchanged; the new per-language keys carry
their own.
