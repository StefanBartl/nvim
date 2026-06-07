---@module 'config.neotree.event_handlers'
---@brief Neo-tree unified event handlers configuration

---@type table[] Cfg.NeoTree.EventHandler[]
return {
  -- Cursor unsichtbar machen, wenn Neo-tree-Fenster betreten wird
  {
    event = "neo_tree_buffer_enter",
    handler = function()
      -- Effekt: der Cursor ist im Neo-tree-Fenster unsichtbar, obwohl das Fenster fokussiert ist
      vim.cmd("highlight! Cursor blend=100")
    end,
  },

  -- Cursor wieder sichtbar machen, wenn Neo-tree-Fenster verlassen wird
  {
    event = "neo_tree_buffer_leave",
    handler = function()
      vim.cmd("highlight! Cursor guibg=#5f87af blend=0")
    end,
  },

  -- Sicherstellen, dass Neo-tree nicht als einziges normales Fenster übrig bleibt.
  {
    event = "neo_tree_window_after_open",
    handler = function()
      require("config.neotree.layout_guard").ensure_editor_window_deferred()
    end,
  },

  -- Bei neuen Preview Window cursor zum Start zurücksetzen
  {
    event = "neo_tree_preview_buffer_enter",
    handler = function(_)
      -- Get the current window ID where the preview buffer is displayed.
      -- The preview buffer is already the current buffer at this point.
      local win = vim.api.nvim_get_current_win()

      -- Explicitly move the cursor to the first line and first column.
      -- This resets the scroll position for every newly previewed file.
      vim.api.nvim_win_set_cursor(win, { 1, 0 })
    end,
  },
}
