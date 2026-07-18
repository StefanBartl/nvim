---@module 'config.neotree.event_handlers'
---@brief Neo-tree unified event handlers configuration

---@type table[] Cfg.NeoTree.EventHandler[]
return {
  -- (cursor-hide entfernt: filetree.nvim's ui/cursor_hide-Feature macht das
  -- jetzt adapter-agnostisch per winhighlight - in echter interaktiver
  -- Nutzung bestätigt funktionierend.)

  -- (layout_guard entfernt: filetree.nvim's nav/layout_guard hält per Adapter
  -- ein Editor-Fenster offen, wenn der Baum das letzte Fenster wäre.)

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
