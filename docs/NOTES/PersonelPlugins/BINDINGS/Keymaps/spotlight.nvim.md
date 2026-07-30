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
| `<leader>mk` | n | `keymaps.toggle` | Toggle a spotlight on the resolved token under the cursor (UUID / timestamp / IP / hex / … / `<cword>`) |
| `<leader>mk` | x | `keymaps.toggle` | Toggle a spotlight on the exact visual selection, taken literally |
| `<leader>mK` | n | `keymaps.list` | Open the spotlight list: color swatch + token + match count → jump |
| `<leader>m<C-k>` | n | `keymaps.clear` | Remove every spotlight |
| `<leader>mq` | n | `keymaps.quickfix` | Every line matching any spotlight → quickfix list |
| `]k` | n | `keymaps.next` | Next occurrence (of the token under the cursor, if on one; else of any) |
| `[k` | n | `keymaps.prev` | Previous occurrence |

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

**Bracket motions** — `]k`/`[k` are unclaimed. Taken elsewhere: `]q`/`]l`/`]d`/`]w`
(config: trouble, lsp diagnostics), `]m`/`[m` (filetree.nvim, buffer-local),
`]f`/`[f`, `]F`/`[F`, `]R`/`[R`, `]a`/`[a`, `]s`.

## Prefix-wait analysis

**No `lhs` in the preset is a prefix of another one.** This is a deliberate
design constraint, not luck: a mapping that is also the prefix of a longer one
costs a full `'timeoutlen'` pause on *every* press of the short one. That is why
clear-all is `<leader>m<C-k>` and not `<leader>mkc`, and why the concept's
`<leader>mk`/`<leader>mK` pair was kept while the remaining actions were moved
off that prefix entirely.

`<leader>mk` vs `<leader>mK` is fine — different keys, neither a prefix of the
other. `<leader>m<C-k>` is `<leader>m` + `<C-k>`, so it does not extend
`<leader>mk` either.

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
    toggle = "<leader>hh",
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
vim.keymap.set("n", "<leader>hh", spotlight.toggle, { desc = "spotlight: toggle" })
vim.keymap.set("x", "<leader>hh", spotlight.toggle_selection, { desc = "spotlight: toggle selection" })
```

Every keymap action also exists as a `:Spotlight` subcommand (see
[Usercmds/spotlight.nvim.md](../Usercmds/spotlight.nvim.md)) — there is no feature
reachable only by key.
