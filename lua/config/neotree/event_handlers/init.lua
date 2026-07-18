---@module 'config.neotree.event_handlers'
---@brief Neo-tree unified event handlers configuration

---@type table[] Cfg.NeoTree.EventHandler[]
return {
  -- Kept alongside filetree.nvim's ui/cursor_hide feature (also enabled, see
  -- personal/init.lua): its BufEnter/WinEnter-triggered winhighlight override
  -- couldn't be reliably confirmed live in headless testing. This global
  -- Cursor-HL approach is coarser (recolors the Cursor group for the whole
  -- editor, not just the tree window) but proven to work, so it stays as a
  -- fallback until cursor_hide's reliability is confirmed.
  {
    event = "neo_tree_buffer_enter",
    handler = function()
      vim.cmd("highlight! Cursor blend=100")
    end,
  },
  {
    event = "neo_tree_buffer_leave",
    handler = function()
      vim.cmd("highlight! Cursor guibg=#5f87af blend=0")
    end,
  },

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
