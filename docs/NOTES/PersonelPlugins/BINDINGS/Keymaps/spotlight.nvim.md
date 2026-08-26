# spotlight.nvim — Keymaps Cheatsheet

Source: `lua/spotlight/bindings/keymaps.lua`, `lua/spotlight/bindings/which_key.lua`
Bridge: `lua/spotlight/util/lib.lua`'s `lib.map()` — prefers `lib.nvim.bindings.keymap`, falls
back to `vim.keymap.set`. Every mapping sets `silent = true` and a `desc`.

Cross-reference: `docs/BINDINGS.md` in the repo is the plugin-side source of
truth and is kept in sync with `lua/spotlight/bindings/` — verified current.

Gated by the top-level switch `keymaps.preset` (default **on**, unlike
cascade.nvim). Each `lhs` is additionally its own config value under `keymaps.*`;
setting one to `false` frees that key while keeping the rest of the preset.

## Preset (`keymaps.preset == true`, the default)

| lhs | mode | config key | action |
| --- | --- | --- | --- |
| `<leader>sk` | n | `keymaps.toggle_here` | Toggle a spotlight on **only this occurrence** of the token under the cursor — pinned to that exact line/column, not every place the text appears |
| `<leader>sk` | x | `keymaps.toggle_here` | Toggle a spotlight on **only this occurrence** of the exact visual selection |
| `<leader>sK` | n | `keymaps.toggle` | Toggle a spotlight on **every occurrence** of the resolved token under the cursor (UUID / timestamp / IP / hex / … / `<cword>`) |
| `<leader>sK` | x | `keymaps.toggle` | Toggle a spotlight on **every occurrence** of the exact visual selection, taken literally |
| `<leader>sL` | n | `keymaps.list` | Open the spotlight list: color swatch + token + match count → jump |
| `<leader>sC` | n | `keymaps.clear` | Remove every spotlight |
| `<leader>sq` | n | `keymaps.quickfix` | Every line matching any spotlight → quickfix list |
| `<leader>sW` | n | `keymaps.line` | Toggle **whole-line rendering** for the spotlight the cursor token belongs to (2026-08-17). Refused if that token has no spotlight yet — line mode is a property of one that already exists |
| `]k` | n | `keymaps.next` | Next occurrence (of the token under the cursor, if on one; else of any). `3]k` jumps 3 occurrences (`vim.v.count1`, since 2026-07-31), stopping early rather than erroring if fewer remain |
| `[k` | n | `keymaps.prev` | Previous occurrence. Same count support as `]k` |

`<leader>sk`/`<leader>sK` is the pair the plugin is organized around, same key
shifted for the wider action — see `docs/FEATURES.md` (section "Toggle a
spotlight on only this occurrence") in the `spotlight.nvim` repo (`C:\repos\spotlight.nvim`)
for the mechanism: a position-anchored `matchadd()` pattern, rendered only in
windows showing the origin buffer, excluded from persistence.
`<leader>sL`/`<leader>sC` moved off `<leader>sK`/`<leader>s<C-k>` (2026-08-12)
to free the shifted key for "every occurrence".

## Collision check

Verified against every other personal plugin in this folder, against the
config's own `<leader>s*` group, and directly against every sibling plugin
repo's source (not just this cheatsheet folder — a naive text search over the
cheatsheets also matches commented-out example code and inflates the taken
list; checked here against what is actually registered).

**Prefix moved from `<leader>m` to `<leader>s` (2026-08)** — the six letters
(`k`/`K`/`L`/`C`/`q`/`W`) are unchanged, only the group changed. `<leader>m` had
almost nothing under it; `<leader>s` is far busier, so this needed a real check
rather than a glance.

**Real (non-commented) `<leader>s*` bindings found**, config-wide:

| lhs | Owner | Note |
| --- | --- | --- |
| `<leader>s` (bare) | `search.nvim` (`plugins/telescope.lua`) | Tabbed search UI. A real leaf binding, not a group — see the timeout note below. |
| `<leader>sh` | snacks.lua (`snacks.picker.help()`) | |
| `<leader>sM` | snacks.lua + `config/snacks/mappings/standard.lua` (two definitions) | |
| `<leader>sS` | snacks.lua + `config/snacks/mappings/standard.lua` (two definitions) | |
| `<leader>sT` | `plugins/workflow.lua` | |
| `<leader>sp` (+`f`/`g`) | pickers.nvim, via `plugins/personal/init.lua` (`keys = { files = "<leader>spf", grep = "<leader>spg" }`) | Two-level prefix — `sp` itself has no leaf action. |
| `<leader>sm` | filetree.nvim (`open_with`, `scope = "tree"`) | **Buffer-local to the tree window only.** Does not collide globally; a global spotlight `sm` would simply be inactive while that window has focus — moot here since spotlight doesn't use `sm`. |

None of these overlap `sk`/`sK`/`sL`/`sC`/`sq`/`sW`.

**Commented-out (inactive) `<leader>s*` slots** — not currently bound, so not a
live conflict, but worth knowing before ever finishing that part of the config:
`snacks.lua` has a near-complete alphabet of commented `snacks.picker.*`
entries (`sa`, `sb`/`sB`, `sc`/`sC`, `sd`/`sD`, `sg`, `sH`, `si`, `sj`, `sk`,
`sl`, `sm`, `sq`, `sR`, `sw`). **Three collide with spotlight's letters
exactly:**

| Commented slot | Would-be action |
| --- | --- |
| `<leader>sk` | `snacks.picker.keymaps()` |
| `<leader>sq` | `snacks.picker.qflist()` |
| `<leader>sC` | `snacks.picker.commands()` |

Uncommenting any of those three later will collide with spotlight (last
`vim.keymap.set` wins, so whichever loads second silently shadows the other) —
pick different letters for those three snacks pickers if that block is ever
finished, rather than reworking spotlight's scheme again.

**Also checked (`pickers.nvim`'s `config_smart` = `<leader>sc`)** — documented
as configurable in `pickers.nvim`'s own README/cheatsheet but `nil` by default
and not set in `plugins/personal/init.lua`; not actually bound. Distinct chord
from spotlight's `sC` anyway (case-sensitive), so moot either way.

`<leader>sL` and `<leader>sC` (both capitalized) are distinct from any
lowercase `sl`/`sc` claim — Vim keys are case-sensitive, so neither collides
nor prefixes the other. `<leader>sW` is unclaimed in either case; the
lowercase `<leader>sw` is left free rather than given the inverse meaning,
since "token only" is not a separate action but this one toggled off — and
it happens to be the fourth commented `snacks.lua` slot, so staying off it
keeps that one clear too.

**Bracket motions** — `]k`/`[k` are unclaimed. Taken elsewhere: `]q`/`]l`/`]d`/`]w`
(config: trouble, lsp diagnostics), `]m`/`[m` (filetree.nvim, buffer-local),
`]f`/`[f`, `]F`/`[F`, `]R`/`[R`, `]a`/`[a`, `]s`.

## Prefix-wait analysis

**No `lhs` in the preset is a prefix of another one.** This is a deliberate
design constraint, not luck: a mapping that is also the prefix of a longer one
costs a full `'timeoutlen'` pause on *every* press of the short one. That is why
clear-all is `<leader>sC` and list is `<leader>sL` rather than `<leader>skc`/
`<leader>skl`.

`<leader>sk` vs `<leader>sK` is fine — different keys (`k`/`K` diverge at that
very character), neither a prefix of the other.

**`<leader>s` itself is a real, bare leaf binding** (`search.nvim`'s tabbed
UI) — unlike the old `<leader>m` prefix, which had no bare action. This means
*every* `<leader>s*` mapping in the whole config, spotlight's included, waits
out `'timeoutlen'` after pressing `s` before Neovim commits to it, in case the
user meant the bare prefix and paused. That tradeoff already existed for the
~7 real `<leader>s*` bindings enumerated above before spotlight moved here —
this move does not introduce it, only joins it.

## which-key

Soft dependency (`lua/spotlight/bindings/which_key.lua`). When installed, the
prefix is registered as a group labelled **Spotlight** for modes `n` and `x`.
Supports both v3 (`wk.add`) and v2 (`wk.register`).

The prefix is **derived from `keymaps.toggle`** rather than hard-coded: it matches
`^(<leader>.)%a$`, so moving the preset to `<leader>hh` labels `<leader>h`
instead. A user who relocates the preset gets the label where they actually use
it. Returns `false` (no-op) when which-key is absent or when `keymaps.toggle` was
set to a shape the pattern cannot read.

Per-key labels come from each mapping's own `desc` — individual keys are not
registered with which-key.

## Rebinding

Two supported ways.

Change the config values:

```lua
require("spotlight").setup({
  keymaps = {
    toggle_here = "<leader>hh",
    toggle = "<leader>hH",
    list = "<leader>hl",
    next = false,          -- leave ]k alone
  },
})
```

Or turn the preset off and bind the facade actions directly — they are plain
functions, so this loses nothing:

```lua
require("spotlight").setup({ keymaps = { preset = false } })

local spotlight = require("spotlight")
vim.keymap.set("n", "<leader>hh", spotlight.toggle_here, { desc = "spotlight: toggle this occurrence" })
vim.keymap.set("x", "<leader>hh", spotlight.toggle_here_selection, { desc = "spotlight: toggle this selection" })
vim.keymap.set("n", "<leader>hH", spotlight.toggle, { desc = "spotlight: toggle every occurrence" })
vim.keymap.set("x", "<leader>hH", spotlight.toggle_selection, { desc = "spotlight: toggle every occurrence (selection)" })
```

Every keymap action also exists as a `:Spotlight` subcommand (see
[Usercmds/spotlight.nvim.md](../Usercmds/spotlight.nvim.md)) — there is no feature
reachable only by key.

## Notes

- `<leader>sW` (whole-line rendering) follows the same lowercase/uppercase rule
  as `sk`/`sK`: the wider, louder way of showing a spotlight takes the shifted
  key. It has **no visual-mode counterpart** — the action needs a spotlight
  that already exists, which a selection cannot resolve to. A buffer-scoped
  ("this occurrence only") spotlight has no text identity, so its line mode is
  reached via `:Spotlight list line` instead.

- A "this occurrence only" spotlight (`<leader>sk`) is session-only: excluded
  from the persisted snapshot, and dropped automatically if its buffer is
  wiped or a window switches away from it. See the repo's `docs/FEATURES.md`.

## Changelog

- 2026-08: Prefix moved from `<leader>m` to `<leader>s` (letters unchanged:
  `k`/`K`/`L`/`C`/`q`/`W`). Re-verified against the whole config and every
  sibling plugin repo directly, since `<leader>s` is a much busier prefix than
  `<leader>m` was (a real bare leaf binding via `search.nvim`, plus `sh`/`sM`/
  `sS`/`sT`/`sp*` and filetree.nvim's buffer-local `sm`) — see the Collision
  check section above, including three commented-but-not-yet-active
  `snacks.lua` slots (`sk`, `sq`, `sC`) that would collide if ever
  uncommented.

- 2026-08-17: Added `<leader>sW` (`keymaps.line` → `line_toggle`) for whole-line
  rendering. Implemented as a rendering flag on the item: `item.pattern` stays
  the token pattern and only the string handed to `matchadd()` is widened, one
  priority below `match.priority` so a line highlight does not swallow the other
  spotlights' token colors. See `docs/FEATURES.md` ("Whole-line highlighting")
  and `:help spotlight-line` in the repo.

- 2026-08-12: `<leader>sk`/`<leader>sK` swapped
  roles. Lowercase now toggles only the occurrence under the cursor/selection
  (new `keymaps.toggle_here`, position-anchored `matchadd()`, session-only);
  uppercase took over the previous lowercase behavior (every occurrence).
  `list` moved from the uppercase key to `L`; `clear` moved from a `<C-k>`
  chord to `C`.
