---@module 'config.neotree.commands'
-- Commands exposed to Neo-tree
-- register via opts.commands = commands.attach()

--- Commands table for Neo-tree's `opts.commands`.
---@return table<string, fun(state: table)>
return {

  --- Open the selected file into the buffer list without leaving Neo-tree.
  --- * Files: :badd + bufload + buflisted=true
  ---@param state table
  open_badd = function(state)
    local node = state.tree:get_node()
    if not node then
      return
    end

    if node.type ~= "file" then
      -- Keep directory UX consistent (expand/collapse) and stay in Neo-tree
      state.commands.toggle_node(state)
      return
    end

    local path = node.path or node:get_id()
    if not path or path == "" then
      vim.notify("No path under cursor", vim.log.levels.WARN)
      return
    end

    -- Add buffer silently and load it so it shows up in buffer pickers immediately
    local bufnr = vim.fn.bufadd(path) -- creates buffer if needed, does not display it
    pcall(vim.fn.bufload, bufnr) -- read file into the buffer
    pcall(function()
      vim.bo[bufnr].buflisted = true
    end)

    -- Optional: small notification (can be removed)
    vim.notify(("Buffered: %s"):format(vim.fn.fnamemodify(path, ":t")), vim.log.levels.INFO)
  end,

  --- Open file in a window but immediately jump focus back to Neo-tree.
  --- Use this variant if man wants the file to be shown in its window, yet keep the tree focused.
  ---@param state table
  open_keep_focus = function(state)
    local node = state.tree:get_node()
    if not node then
      return
    end
    if node.type ~= "file" then
      state.commands.toggle_node(state)
      return
    end
    local win = state.winid or vim.api.nvim_get_current_win()
    if pcall(require, "window-picker") then
      state.commands.open_with_window_picker(state)
    else
      state.commands.open(state)
    end
    vim.schedule(function()
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_set_current_win(win) -- return focus to Neo-tree window
      end
    end)
  end,
}
