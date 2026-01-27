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
}
