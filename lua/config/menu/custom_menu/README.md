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

## Two things that used to be here and aren't

- **nvzone/menu's `menus.default`** was loaded, appended to a local table,
  and then never returned — dead since the section was rewritten, and a
  duplicate of half the entries below it. Removed.
- **The "Lsp Actions" fly-out** now comes from `lsp.nvim`'s own
  `integrations.menu` (via `CONTRIBUTORS`), which mirrors the resolved keymap
  catalogue instead of a hand-written list.
