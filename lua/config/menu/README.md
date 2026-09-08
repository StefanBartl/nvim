# config.menu

The general (non-tree) context menu: `<A-b>` at the cursor, `<RightMouse>`
at the pointer.

```lua
require("config.menu").setup({ renderer = "kit", enable_git_section = true })
```

Set up from init.lua's `UIReady` startup phase.

## Layout

| File | Role |
|---|---|
| `init.lua` | picks the renderer, passes options on, binds the triggers |
| `mappings.lua` | the two keymaps, and the `CONTRIBUTORS` list that composes plugin sections |
| `custom_menu/init.lua` | the general section (format, copy, paste, delete, tools) |
| `git.lua` | the Git section, gated on gitsigns.nvim |

## Who draws it

Rendering goes through [`lib.nvim.contextmenu`](https://github.com/StefanBartl/lib.nvim),
which owns the item builders (`entry`/`group`/`submenu`) and a renderer
switch. Nothing in this directory calls a renderer itself.

- `renderer = "kit"` (what init.lua sets) — `lib.nvim.ui.kit.menu`. No
  third-party dependency, kit theming, and nested entries **drill down** in
  place with `<BS>` to go back.
- `renderer = "nvzone"` — nvzone/menu, the previous implementation, with
  side-by-side fly-outs. **Not installed any more**
  (`lua/plugins/nvchad.lua` disables NvChad's spec for it), so this setting
  now falls back to the kit with one notify; putting it back means
  re-enabling that spec too.

Nothing registers itself under nvzone/menu's `menus.*` namespace any more,
and the Git section is this config's own item list (`git.lua`) rather than
nvzone/menu's `menus.gitsigns`.

## What lands in the menu

1. **One fly-out per applicable plugin.** `mappings.lua`'s `CONTRIBUTORS`
   list names every "Pattern B" plugin — one that ships only
   `<plugin>.integrations.menu` and no trigger of its own. Each contributes
   its own top-level entry; `applies(buf)` is the cheap pre-check that skips
   the `require()` entirely when the buffer obviously doesn't qualify.
2. **The general section**, beneath a divider — rebuilt on every open, because
   several entries depend on the live visual selection and buffer.

Neo-tree is **not** handled here: filetree.nvim binds its own buffer-local
`<RightMouse>` on the tree buffer, which shadows the global mapping.
