---@module 'config.neotree.commands'
-- Commands exposed to Neo-tree
-- register via opts.commands = commands.attach()

local getTelescopeOpts = require("config.neotree.commands.get_telescope_opts")
local diff_files_mod = require("config.neotree.commands.diff_files")

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

  ---Similar to the '.' command in nvim-tree. Primes the ":" command with the full path of the chosen node.
  ---@param state table
  run_command = function(state)
    local node = state.tree:get_node()
    local path = node:get_id()
    vim.api.nvim_input(": " .. path .. "<Home>")
  end,

  -- Find with telescope
  -- Find/grep for a file under the current node using Telescope and select it.
  telescope_find = function(state)
    local node = state.tree:get_node()
    local path = node:get_id()
    require("telescope.builtin").find_files(getTelescopeOpts(state, path))
  end,
  telescope_grep = function(state)
    local node = state.tree:get_node()
    local path = node:get_id()
    require("telescope.builtin").live_grep(getTelescopeOpts(state, path))
  end,

  -- Diff files
  -- You can mark two files to diff them.
  diff_files = diff_files_mod,
}
