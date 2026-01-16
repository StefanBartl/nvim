---@module 'neo-tree-updir'
--- Up-one-level mapping for Neo-tree that works correctly in float/current/sidebars.
--- It updates the tree root in-place and adjusts the CWD (window-local for float/current).

local node_utils = require("config.neotree.utils.node")

local M = {}

---@param state Cfg.NeoTree.State
---@return nil
function M.up_one_level(state)
  -- Pause cwd sync if module exists
  local ok_sync, sync = pcall(require, "config.neotree.cwd_sync")
  if ok_sync and sync.pause_sync then
    sync.pause_sync(3000) -- 3s pause
  end

  -- 1) Resolve current root
  local current_root = state.path
  if not current_root or current_root == "" then
    local tree = state.tree
    if not tree then
      return
    end

    local node = node_utils.get_current(state)
    if not node then
      vim.notify("no node under cursor", vim.log.levels.WARN)
      return
    end

    local path, _ = node_utils.get_path(node)
    if path == "" then
      vim.notify("no path under cursor", vim.log.levels.WARN)
      return
    end
    current_root = (vim.fn.isdirectory(path) == 1) and path or vim.fn.fnamemodify(path, ":h")
  end

  -- 2) Parent directory
  local parent = vim.fn.fnamemodify(current_root, ":h")
  if parent == current_root or parent == "" then
    vim.notify("already at top-level directory", vim.log.levels.WARN)
    return
  end

  -- 3) Determine command based on window type (optional)
  local position = (state.window and state.window.position) or require("config.neotree").get_default_position()
  local cd_cmd = (position == "current" or position == "float") and "lcd" or "cd"
  local esc = vim.fn.fnameescape(parent)

  local ok_cd, cd_err = pcall(function()
    vim.cmd(string.format("%s %s", cd_cmd, esc))
  end)
  if not ok_cd then
    vim.notify(("cwd change failed: %s"):format(tostring(cd_err)), vim.log.levels.ERROR)
    return
  end

  -- 4) Save old path
  local old_path = current_root

  -- 5) Navigate tree root
  if state.commands and state.commands.navigate_up then
    state.commands.navigate_up(state)
  elseif state.commands and state.commands.set_root then
    state.commands.set_root(state, parent)
  else
    local ok_mgr, manager = pcall(require, "neo-tree.sources.manager")
    if ok_mgr then
      manager.navigate(state, parent)
    else
      vim.notify("neo-tree: no suitable command to change root", vim.log.levels.ERROR)
      return
    end
  end

  -- 6) Restore selection after delay
  vim.defer_fn(function()
    local tree = state.tree
    if not tree then
      return
    end

    local parent_node = state.current_node
    if parent_node and parent_node.children then
      for _, child in ipairs(parent_node.children) do
        local child_path, _ = node_utils.get_path(child)
        if child_path == old_path then
          -- Focus old directory if set_selection exists
          if tree.set_selection then
            pcall(tree.set_selection, tree, child_path)
          end
          break
        end
      end
    end
  end, 100)

  -- 7) Optional refresher
  local ok_mod, refresher = pcall(require, "config.neotree.refresh_adapter")
  if ok_mod then
    refresher.refresh(state)
  end

  vim.notify(("cwd → %s"):format(parent), vim.log.levels.INFO)
end

return M
