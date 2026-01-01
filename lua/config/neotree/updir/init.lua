---@module 'neo-tree-updir'
--- Up-one-level mapping for Neo-tree that works correctly in float/current/sidebars.
--- It updates the tree root in-place and adjusts the CWD (window-local for float/current).

local M = {}

---@param state table
---@return nil
function M.up_one_level(state)
  -- ✅ Signalisiere: User navigiert manuell
  local ok_sync, sync = pcall(require, "config.neotree.cwd_sync")
  if ok_sync and sync.pause_sync then
    sync.pause_sync(3000) -- Pause 3s
  end

  local current_root = state.path
  if not current_root or current_root == "" then
    local node = state.tree:get_node()
    local path = node and (node.path or node:get_id()) or ""
    if path == "" then
      vim.notify("no path under cursor", vim.log.levels.WARN)
      return
    end
    current_root = (vim.fn.isdirectory(path) == 1) and path or vim.fn.fnamemodify(path, ":h")
  end

  local parent = vim.fn.fnamemodify(current_root, ":h")
  if parent == current_root or parent == "" then
    vim.notify("already at top-level directory", vim.log.levels.WARN)
    return
  end

  local position = (state.window and state.window.position) or "left"
  local cd_cmd = (position == "current" or position == "float") and "lcd" or "cd"
  local esc = vim.fn.fnameescape(parent)

  local ok_cd, cd_err = pcall(function()
    vim.cmd(string.format("%s %s", cd_cmd, esc))
  end)

  if not ok_cd then
    vim.notify(("cwd change failed: %s"):format(tostring(cd_err)), vim.log.levels.ERROR)
    return
  end

  -- ✅ Merke alte Position für Wiederauswahl
  local old_path = current_root

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

  -- ✅ Selektiere alte Position nach kurzer Verzögerung
  vim.defer_fn(function()
    local tree = state.tree
    if not tree then
      return
    end

    local parent_node = tree:get_node()
    if parent_node and parent_node.children then
      for _, child in ipairs(parent_node.children) do
        local child_path = child.path or child:get_id()
        if child_path == old_path then
          -- Focus the old directory in parent
          pcall(tree.set_selection, tree, child:get_id())
          break
        end
      end
    end
  end, 100)

  local ok_mod, refresher = pcall(require, "config.neotree.refresh_adapter")
  if ok_mod then
    refresher.refresh(state)
  end

  vim.notify(("cwd → %s"):format(parent), vim.log.levels.INFO)
end

return M
