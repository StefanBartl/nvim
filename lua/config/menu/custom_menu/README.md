# config.menu.custom_menu

The general part of the context menu, in four named sections: `Code`
(format, code actions), `Clipboard` (copy, copy selection, paste), `Delete`
(selection / buffer / file) and `Tools` (terminal, colour picker, unicode
table, and the Git fly-out).

`require("config.menu.custom_menu")(opts)` returns the item list **for the
current buffer** — it is a function, not a table, because entries like "Copy
Marked/Selected" and "Delete File" depend on the live visual selection and
buffer name. `config.menu.mappings` calls it on every open.

Entries are built with `lib.nvim.contextmenu`'s `entry`/`group`/`heading`, so
each one is gated where it is written and the sections fall out of the
grouping. Which component draws the result is `config.menu`'s decision — see
the [README there](../README.md).

`Git Actions` sits inside `Tools` rather than in a section of its own: a named
section holding one entry is a frame around a single row, which reads as a
fault rather than as structure.

## Icons

Every entry carries one, and none of them is part of a label. The glyphs come
from [`config.menu.icons`](../icons.lua), which resolves the whole set once
through `lib.nvim.ui.nerd_font` — declared availability
(`vim.g.have_nerd_font`, set in `init.lua`), an ASCII fallback per glyph, and
a width check that refuses anything wider than one cell.

Two rounds of the same bug got us here, both worth remembering:

- Until 2026-09-08 four labels started with **two literal spaces and no glyph
  at all** — they never had one, going back to the file's first commit —
  which looked exactly like a font failing to render them. Glyphs were added.
- On 2026-09-08 the same thing turned up one level out, in the plugin
  fly-outs: `"  Open"`, `"  Markdown"`, and six more. This time the fix was
  structural rather than another round of glyphs. `icon` is now a **field**
  the renderer measures into a column of its own, so an entry either has a
  glyph or has blank space where one would go — and the labels line up
  either way, whoever supplies them.

The trash can moved from the emoji to the Nerd Font glyph in the first round,
for a related reason: an emoji is two columns wide, and every column here is
aligned by display width.

## Two things that used to be here and aren't

- **nvzone/menu's `menus.default`** was loaded, appended to a local table,
  and then never returned — dead since the section was rewritten, and a
  duplicate of half the entries below it. Removed.
- **The "Lsp Actions" fly-out** now comes from `lsp.nvim`'s own
  `integrations.menu` (via `CONTRIBUTORS`), which mirrors the resolved keymap
  catalogue instead of a hand-written list.
