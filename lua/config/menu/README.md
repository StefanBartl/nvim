# config.menu

The general (non-tree) context menu: `<A-b>` at the cursor, `<RightMouse>`
at the pointer.

```lua
require("config.menu").setup({ renderer = "kit", enable_git_section = true })
```

Set up from init.lua's `UIReady` startup phase.

`lib.nvim.contextmenu` itself sets `'mousemodel' = "extend"` by default,
turning off Neovim's own built-in right-click PopUp menu — which otherwise
pops up natively on any click a mapping doesn't cover (a blank filetree line
past the last node, insert mode, …) and reads, from the user's chair, as "a
different menu sometimes appears". `native_popup` passes straight through
this `setup()` unforced; pass `native_popup = true` to restore vanilla
Neovim behaviour.

## Layout

| File | Role |
|---|---|
| `init.lua` | picks the renderer, passes options on, binds the triggers |
| `mappings.lua` | the two keymaps, and the `CONTRIBUTORS` list that composes plugin sections |
| `custom_menu/init.lua` | the general sections (Code, Clipboard, Delete, Tools) |
| `git.lua` | the Git fly-out (Hunks, Blame, Diff), gated on gitsigns.nvim |
| `icons.lua` | the glyphs the icon column draws, resolved once for every section |

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

1. **One fly-out per applicable plugin**, under an `Integrations` heading.
   `mappings.lua`'s `CONTRIBUTORS` list names every "Pattern B" plugin — one
   that ships only `<plugin>.integrations.menu` and no trigger of its own.
   Each contributes its own top-level entry; `applies(buf)` is the cheap
   pre-check that skips the `require()` entirely when the buffer obviously
   doesn't qualify. The shared heading is presentation only — still one entry
   per plugin, still no nesting under a common parent.
2. **The general sections** — `Code` (Format, Code Actions, Inspect),
   `Clipboard`, `Delete`, `Tools` — rebuilt on every open, because several
   entries depend on the live visual selection and buffer.

## How it looks

Every section names itself, and the kit renderer draws a named section as a
titled frame:

```
 ╭─ Integrations ──────────────────────────────╮
 │  Markdown                   →              │
 │  Open                       →              │
 ╰─────────────────────────────────────────────╯
 ╭─ Clipboard ─────────────────────────────────╮
 │  Copy All (Buffer)                   <C-a> │
 │ 󰆏 Copy Marked/Selected                <C-c> │
 ╰─────────────────────────────────────────────╯
```

Three things that are deliberate:

- **The icon is a column, not a prefix.** `icons.lua` resolves the set once
  and every section draws from it; entries pass it as `{ icon = … }`, never
  glued onto the label. That is what makes the plugin fly-outs line up with
  the general entries — the bug that started this was eight contributors
  shipping `"  Open"`, two spaces where a glyph was meant to go.
- **The section title is a `heading(...)` marker**, so gating reaches it: a
  section whose every entry is switched off drops its title with it.
- **The fly-out marker `→` has a column of its own**, in the theme accent.
  The column follows the *label*, not the row: pushed to the right edge the
  arrow sits far from the text it belongs to and starts reading as part of
  the frame, so it is parked just past the longest label — about two thirds
  of the way across — and the keymap hints keep the right edge, where a key
  is looked for.

`contextmenu.open`'s `group_style` picks the drawing: `"box"` (the default),
`"header"` (a titled rule, no frame) or `"plain"` (the old divider look).

Neo-tree is **not** handled here: filetree.nvim binds its own buffer-local
`<RightMouse>` on the tree buffer, which shadows the global mapping.
