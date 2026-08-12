# spotlight.nvim — Keymaps Cheatsheet

Source: `lua/spotlight/bindings/keymaps.lua`, `lua/spotlight/bindings/which_key.lua`
Bridge: `lua/spotlight/util/lib.lua`'s `lib.map()` — prefers `lib.nvim.map`, falls
back to `vim.keymap.set`. Every mapping sets `silent = true` and a `desc`.

Cross-reference: `docs/BINDINGS.md` in the repo is the plugin-side source of
truth and is kept in sync with `lua/spotlight/bindings/` — verified current.

Gated by the top-level switch `keymaps.preset` (default **on**, unlike
cascade.nvim). Each `lhs` is additionally its own config value under `keymaps.*`;
setting one to `false` frees that key while keeping the rest of the preset.

## Preset (`keymaps.preset == true`, the default)

| lhs | mode | config key | action |
| --- | --- | --- | --- |
| `<leader>mk` | n | `keymaps.toggle_here` | Toggle a spotlight on **only this occurrence** of the token under the cursor — pinned to that exact line/column, not every place the text appears |
| `<leader>mk` | x | `keymaps.toggle_here` | Toggle a spotlight on **only this occurrence** of the exact visual selection |
| `<leader>mK` | n | `keymaps.toggle` | Toggle a spotlight on **every occurrence** of the resolved token under the cursor (UUID / timestamp / IP / hex / … / `<cword>`) |
| `<leader>mK` | x | `keymaps.toggle` | Toggle a spotlight on **every occurrence** of the exact visual selection, taken literally |
| `<leader>mL` | n | `keymaps.list` | Open the spotlight list: color swatch + token + match count → jump |
| `<leader>mC` | n | `keymaps.clear` | Remove every spotlight |
| `<leader>mq` | n | `keymaps.quickfix` | Every line matching any spotlight → quickfix list |
| `]k` | n | `keymaps.next` | Next occurrence (of the token under the cursor, if on one; else of any). `3]k` jumps 3 occurrences (`vim.v.count1`, since 2026-07-31), stopping early rather than erroring if fewer remain |
| `[k` | n | `keymaps.prev` | Previous occurrence. Same count support as `]k` |

`<leader>mk`/`<leader>mK` is the pair the plugin is organized around, same key
shifted for the wider action — see `docs/FEATURES.md` (section "Toggle a
spotlight on only this occurrence") in the `spotlight.nvim` repo (`C:\repos\spotlight.nvim`)
for the mechanism: a position-anchored `matchadd()` pattern, rendered only in
windows showing the origin buffer, excluded from persistence.
`<leader>mL`/`<leader>mC` moved off `<leader>mK`/`<leader>m<C-k>` (2026-08-12)
to free the shifted key for "every occurrence".

## Collision check

Verified against every other personal plugin in this folder and against the
config's own `<leader>m*` group.

**Existing `<leader>m*` claims** — none overlap:

| lhs | Owner |
| --- | --- |
| `<leader>man` | config, `bindings/mappings/fzf.lua` (FzfLua man pages) |
| `<leader>ms` | mdview.nvim (`MDView sync toggle`); filetree.nvim (buffer-local, marked-paths list) |
| `<leader>mv` | mdview.nvim (`MDView start`) |
| `<leader>mc` | config, neotree keymaps (`noop`, buffer-local) |
| `<leader>mnf` / `<leader>mng` / `<leader>mns` | pickers.nvim (notes picker) |
| `<leader>mlf` / `<leader>mlg` | pickers.nvim |
| `<leader>mvf` / `<leader>mvg` | pickers.nvim |

`<leader>mL` and `<leader>mC` (both capitalized) are distinct from the
lowercase `<leader>ml*`/`<leader>mc` claims above — Vim keys are
case-sensitive, so neither collides nor prefixes the other.

**Bracket motions** — `]k`/`[k` are unclaimed. Taken elsewhere: `]q`/`]l`/`]d`/`]w`
(config: trouble, lsp diagnostics), `]m`/`[m` (filetree.nvim, buffer-local),
`]f`/`[f`, `]F`/`[F`, `]R`/`[R`, `]a`/`[a`, `]s`.

## Prefix-wait analysis

**No `lhs` in the preset is a prefix of another one.** This is a deliberate
design constraint, not luck: a mapping that is also the prefix of a longer one
costs a full `'timeoutlen'` pause on *every* press of the short one. That is why
clear-all is `<leader>mC` and list is `<leader>mL` rather than `<leader>mkc`/
`<leader>mkl`.

`<leader>mk` vs `<leader>mK` is fine — different keys (`k`/`K` diverge at that
very character), neither a prefix of the other.

One external prefix relationship remains and is unavoidable: `<leader>m` itself is
a shared group prefix (`<leader>man`, `<leader>ms`, `<leader>mn*`, …), so
`<leader>mk` waits for `'timeoutlen'` only in the sense that *every* member of
that group does. No new wait is introduced.

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

- A "this occurrence only" spotlight (`<leader>mk`) is session-only: excluded
  from the persisted snapshot, and dropped automatically if its buffer is
  wiped or a window switches away from it. See the repo's `docs/FEATURES.md`.

## Changelog

- 2026-08-12: `<leader>mk`/`<leader>mK` swapped roles. `<leader>mk` now toggles
  only the occurrence under the cursor/selection (new `keymaps.toggle_here`,
  position-anchored `matchadd()`, session-only); `<leader>mK` took over the
  previous `<leader>mk` behavior (every occurrence). `list` moved from
  `<leader>mK` to `<leader>mL`; `clear` moved from `<leader>m<C-k>` to
  `<leader>mC`.
