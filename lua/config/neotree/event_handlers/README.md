# config.neotree.event_handlers

Neo-tree event handlers table, passed into `neo-tree.setup({ event_handlers = ... })`.

Currently defines a single handler:

- **`neo_tree_preview_buffer_enter`** — resets the cursor to line 1, column 0
  whenever a new preview buffer is entered, so every previewed file starts
  scrolled to the top.

The cursor-hide and layout_guard handlers this module used to own were
migrated to filetree.nvim (`ui/cursor_hide`, `nav/layout_guard`) and removed
here — see the comments in `init.lua`.
