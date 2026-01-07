---@module 'config.neotree.commands'
-- Commands exposed to Neo-tree
-- register via opts.commands = commands.attach()

local getTelescopeOpts = require("config.neotree.commands.get_telescope_opts")
local diff_files_mod = require("config.neotree.commands.diff_files")
local mark_mod = require("config.neotree.commands.mark")
local node_utils = require("config.neotree.utils.node")

local api, fn = vim.api, vim.fn
local notify = vim.notify

---@return table<string, fun(state: Cfg.NeoTree.State)>
return {
  --- Open the selected file into the buffer list without leaving Neo-tree
  open_badd = function(state)
    local node = node_utils.get_current(state)
    if not node then
      notify("no node under cursor", vim.log.levels.WARN)
      return
    end

    if node.type ~= "file" then
      state.commands.toggle_node(state)
      return
    end

    local path, _ = node_utils.get_path(node)
    if path == "" then
      notify("No path under cursor", vim.log.levels.WARN)
      return
    end

    local bufnr = fn.bufadd(path)
    pcall(fn.bufload, bufnr)
    pcall(function()
      vim.bo[bufnr].buflisted = true
    end)

    notify(("Buffered: %s"):format(fn.fnamemodify(path, ":t")), vim.log.levels.INFO)
  end,

  --- Open file in a window but keep focus in Neo-tree
  open_keep_focus = function(state)
    local node = node_utils.get_current(state)
    if not node then
      notify("no node under cursor", vim.log.levels.WARN)
      return
    end

    local cmds = state.commands
    if node.type ~= "file" then
      cmds.toggle_node(state)
      return
    end

    local win = state.winid or api.nvim_get_current_win()
    if pcall(require, "window-picker") then
      cmds.open_with_window_picker(state)
    else
      cmds.open(state)
    end

    vim.schedule(function()
      if api.nvim_win_is_valid(win) then
        api.nvim_set_current_win(win)
      end
    end)
  end,

  --- Prime ":" command with full path of the chosen node
  run_command = function(state)
    local node = node_utils.get_current(state)
    if not node then
      notify("no node under cursor", vim.log.levels.WARN)
      return
    end

    local path, _ = node_utils.get_path(node)
    if path == "" then
      return
    end

    api.nvim_input(": " .. path .. "<Home>")
  end,

  --- Telescope find/grep
  telescope_find = function(state)
    local node = node_utils.get_current(state)
    if not node then
      notify("no node under cursor", vim.log.levels.WARN)
      return
    end

    local path, _ = node_utils.get_path(node)
    if path == "" then
      return
    end

    require("telescope.builtin").find_files(getTelescopeOpts(state, path))
  end,
  telescope_grep = function(state)
    local node = node_utils.get_current(state)
    if not node then
      notify("no node under cursor", vim.log.levels.WARN)
      return
    end

    local path, _ = node_utils.get_path(node)
    if path == "" then
      return
    end

    require("telescope.builtin").live_grep(getTelescopeOpts(state, path))
  end,

  -- Diff & mark modules
  diff_files = diff_files_mod,
  mark = mark_mod,
}
