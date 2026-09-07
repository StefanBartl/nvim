---@module 'config.neotree.event_handlers'
---@brief Neo-tree unified event handlers configuration

---@type table[] Cfg.NeoTree.EventHandler[]
return {
  -- (cursor-hide removed: filetree.nvim's ui/cursor_hide feature now does this
  -- adapter-agnostically via winhighlight - confirmed working in real
  -- interactive use.)

  -- (layout_guard removed: filetree.nvim's nav/layout_guard keeps an editor
  -- window open per adapter whenever the tree would be the last window.)

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
