# config.neotree.event_handlers

Neo-tree event handlers table, passed into `neo-tree.setup({ event_handlers = ... })`.

Currently defines two handlers:

- **`neo_tree_window_after_open`** — sets `'foldmethod'` to `manual` (and
  `'foldenable'` off) in the tree window. The window is split off the editor
  window and inherits its `'foldmethod'`/`'foldexpr'`; with `expr` folding,
  rendering a big directory evaluates the expression once per line (opening
  `%TEMP%`, ~5400 lines, froze Neovim for ~35 s while the inherited expression
  pointed at a function that no longer exists). `'foldenable'` off alone does
  not stop that update, `manual` does.
- **`neo_tree_preview_buffer_enter`** — resets the cursor to line 1, column 0
  whenever a new preview buffer is entered, so every previewed file starts
  scrolled to the top.

The cursor-hide and layout_guard handlers this module used to own were
migrated to filetree.nvim (`ui/cursor_hide`, `nav/layout_guard`) and removed
here — see the comments in `init.lua`.
