---@module 'config.neotree.commands'
-- Commands exposed to Neo-tree
-- register via opts.commands = commands.attach()

local notify = require("lib.nvim.notify").create("[config.neotree.commands]")

local getTelescopeOpts = require("config.neotree.commands.get_telescope_opts")
local diff_files_mod = require("config.neotree.commands.diff_files")
local mark_mod = require("config.neotree.commands.mark")
local node_utils = require("config.neotree.utils.node")
local add_mod = require("config.neotree.commands.add")
local markdown_bridge = require("config.neotree.commands.markdown.links")

local api, fn = vim.api, vim.fn

---@return table<string, fun(state: Cfg.NeoTree.State)>
return {
  --- Custom add command with clipboard integration
  custom_add = add_mod.custom_add,

  --- Open the selected file into the buffer list without leaving Neo-tree
  open_badd = function(state)
    local node = node_utils.get_current(state)
    if not node then
      notify.warn("no node under cursor")
      return
    end

    if node.type ~= "file" then
      state.commands.toggle_node(state)
      return
    end

    local path, _ = node_utils.get_path(node)
    if path == "" then
      notify.warn("No path under cursor")
      return
    end

    local bufnr = fn.bufadd(path)
    pcall(fn.bufload, bufnr)
    pcall(function()
      vim.bo[bufnr].buflisted = true
    end)

    notify.info(("Buffered: %s"):format(fn.fnamemodify(path, ":t")))
  end,

  --- Open file in a window but keep focus in Neo-tree
  open_keep_focus = function(state)
    local node = node_utils.get_current(state)
    if not node then
      notify.warn("no node under cursor")
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
        local ok = pcall(api.nvim_set_current_win, win)
        if not ok then
          notify.debug("set_current_win failed")
        end
      end
    end)
  end,

  --- Prime ":" command with full path of the chosen node
  run_command = function(state)
    local node = node_utils.get_current(state)
    if not node then
      notify.warn("no node under cursor")
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
      notify.warn("no node under cursor")
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
      notify.warn("no node under cursor")
      return
    end

    local path, _ = node_utils.get_path(node)
    if path == "" then
      return
    end

    require("telescope.builtin").live_grep(getTelescopeOpts(state, path))
  end,

  --- Generate markdown links from current node (file→single link, dir→all files)
  markdown_links = markdown_bridge.from_node,
  --- Generate markdown links recursively from current node
  markdown_links_recursive = markdown_bridge.from_node_recursive,
  --- Generate markdown links for all marked nodes (falls back to current node)
  markdown_links_from_marked = markdown_bridge.from_marked_nodes,

  -- Diff & mark modules
  diff_files = diff_files_mod,
  mark = mark_mod,
}
