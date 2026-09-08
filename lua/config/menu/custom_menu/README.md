# config.menu.custom_menu

The general section of the context menu: format, code actions, copy, paste,
delete (selection / buffer / file), terminal, colour picker, unicode table,
and the Git fly-out.

`require("config.menu.custom_menu")(opts)` returns the item list **for the
current buffer** — it is a function, not a table, because entries like "Copy
Marked/Selected" and "Delete File" depend on the live visual selection and
buffer name. `config.menu.mappings` calls it on every open.

Entries are built with `lib.nvim.contextmenu`'s `entry`/`group`, so each one
is gated where it is written and the separators fall out of the grouping.
Which component draws the result is `config.menu`'s decision — see the
[README there](../README.md).

## Icons

The last group and the Git fly-out carry Nerd Font glyphs; the rest of the
list is deliberately plain. Until 2026-09-08 those four labels started with
**two literal spaces and no glyph at all** -- they had never carried one,
going back to the file's first commit -- which looked exactly like a font
that was failing to render them. The trash can moved from the emoji to the
Nerd Font glyph at the same time: an emoji is two columns wide, and the menu
aligns its `rtxt` column by display width.

## Two things that used to be here and aren't

- **nvzone/menu's `menus.default`** was loaded, appended to a local table,
  and then never returned — dead since the section was rewritten, and a
  duplicate of half the entries below it. Removed.
- **The "Lsp Actions" fly-out** now comes from `lsp.nvim`'s own
  `integrations.menu` (via `CONTRIBUTORS`), which mirrors the resolved keymap
  catalogue instead of a hand-written list.
