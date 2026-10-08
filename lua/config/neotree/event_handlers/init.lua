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
    -- A tree has nothing to fold, but its window is split off the editor window
    -- and inherits that window's 'foldmethod'/'foldexpr' (neo-tree sets
    -- cursorline, wrap, signcolumn, ... for its windows, never the fold
    -- options). With 'foldmethod' = "expr" every buffer change then evaluates
    -- the expression once per line -- fine for a small tree, a freeze for a
    -- directory with thousands of entries (%TEMP%: 5400 lines, ~35 s, the cost
    -- being whatever the inherited expression costs per call). 'foldmethod'
    -- "manual" takes the tree out of the automatic fold update altogether,
    -- whatever the expression is. ('foldenable' off alone does NOT: measured
    -- with the expression still set, the update ran anyway -- 36 s -- while
    -- "manual" renders the same tree in under 2 s.) 'foldenable' goes off too,
    -- so zc/zM cannot fold the tree by hand. The window is open but not yet
    -- rendered when this fires.
    --
    -- [0] = :setlocal, on purpose: a plain vim.wo[win].<opt> has :set semantics
    -- (these options are not global-local) and would also rewrite the window's
    -- default value. Everything first shown in that window afterwards (a file
    -- opened into a `position = "current"` tree window) and every window split
    -- off the focused tree (:tabnew, :new, :vsplit) would then start with
    -- manual folding and 'foldenable' off -- treesitter files lose their folds.
    event = "neo_tree_window_after_open",
    handler = function(args)
      local win = args and args.winid
      if win and vim.api.nvim_win_is_valid(win) then
        vim.wo[win][0].foldmethod = "manual"
        vim.wo[win][0].foldenable = false
      end
    end,
  },

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
