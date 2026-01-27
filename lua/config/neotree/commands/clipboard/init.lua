---@module 'config.neotree.commands.clipboard'
--- Enhanced clipboard operations with mark support

local notify = require("lib.notify").create("[neotree.commands.clipboard]")
local node_utils = require("config.neotree.utils.node")

local M = {}

--- Get nodes from marks or current
---@param state Cfg.NeoTree.State
---@return Cfg.NeoTree.Node[]
local function get_target_nodes(state)
  local marks = state.explicitly_marked_node_ids or {}
  local nodes = {}

  -- Marked nodes
  if next(marks) then
    local tree = state.tree
    if tree and tree.get_node then
      for node_id, _ in pairs(marks) do
        local node = tree:get_node(node_id)
        if node then
          table.insert(nodes, node)
        end
      end
    end

    if #nodes > 0 then
      return nodes
    end
  end

  -- Fallback: current node
  local current = node_utils.get_current(state)
  if current then
    return { current }
  end

  return {}
end

--- Copy marked/current nodes to clipboard
---@param state Cfg.NeoTree.State
---@return nil
function M.copy_to_clipboard(state)
  local nodes = get_target_nodes(state)

  if #nodes == 0 then
    notify.warn("No nodes to copy")
    return
  end

  -- Store in Neo-tree's clipboard
  local clipboard = {
    action = "copy",
    nodes = {},
  }

  for _, node in ipairs(nodes) do
    local path = node.path or node.uri or node:get_id()
    if path then
      table.insert(clipboard.nodes, {
        id = node.id,
        path = path,
        name = node.name,
        type = node.type,
      })
    end
  end

  state.clipboard = clipboard

  notify.info(string.format("📋 Copied %d item%s", #nodes, #nodes > 1 and "s" or ""))
end

--- Cut marked/current nodes to clipboard
---@param state Cfg.NeoTree.State
---@return nil
function M.cut_to_clipboard(state)
  local nodes = get_target_nodes(state)

  if #nodes == 0 then
    notify.warn("No nodes to cut")
    return
  end

  -- Store in Neo-tree's clipboard
  local clipboard = {
    action = "move",
    nodes = {},
  }

  for _, node in ipairs(nodes) do
    local path = node.path or node.uri or node:get_id()
    if path then
      table.insert(clipboard.nodes, {
        id = node.id,
        path = path,
        name = node.name,
        type = node.type,
      })
    end
  end

  state.clipboard = clipboard

  notify.info(string.format("✂️ Cut %d item%s", #nodes, #nodes > 1 and "s" or ""))
end

--- Paste from clipboard to current directory
---@param state Cfg.NeoTree.State
---@return nil
function M.paste_from_clipboard(state)
  local clipboard = state.clipboard

  if not clipboard or not clipboard.nodes or #clipboard.nodes == 0 then
    notify.warn("Clipboard is empty")
    return
  end

  local current = node_utils.get_current(state)
  if not current then
    notify.warn("No target directory")
    return
  end

  -- Determine target directory
  local target_dir
  if current.type == "directory" then
    target_dir = current.path or current:get_id()
  else
    -- Use parent directory
    local parent_id = current:get_parent_id()
    if parent_id and state.tree then
      local parent = state.tree:get_node(parent_id)
      if parent then
        target_dir = parent.path or parent:get_id()
      end
    end
  end

  if not target_dir then
    notify.warn("Could not determine target directory")
    return
  end

  local action = clipboard.action
  local count = #clipboard.nodes
  local success = 0
  local failed = 0

  -- Execute copy or move
  local uv = vim.loop

  for _, item in ipairs(clipboard.nodes) do
    local source = item.path
    local basename = vim.fn.fnamemodify(source, ":t")
    local dest = target_dir .. "/" .. basename

    -- Check if destination exists
    if uv.fs_stat(dest) then
      notify.warn(string.format("Skipped (exists): %s", basename))
      failed = failed + 1
      goto continue
    end

    local ok, err
    if action == "copy" then
      -- Copy file/directory
      ok, err = pcall(function()
        if vim.fn.isdirectory(source) == 1 then
          -- Directory: use recursive copy
          vim.fn.system({ "cp", "-r", source, dest })
          return vim.v.shell_error == 0
        else
          -- File: direct copy
          uv.fs_copyfile(source, dest)
          return true
        end
      end)
    else -- move
      -- Move file/directory
      ok = os.rename(source, dest)
      if not ok then
        err = "rename failed"
      end
    end

    if ok then
      success = success + 1
    else
      notify.warn(string.format("Failed %s: %s - %s", action, basename, tostring(err)))
      failed = failed + 1
    end

    ::continue::
  end

  -- Clear clipboard after move
  if action == "move" and success > 0 then
    state.clipboard = nil
  end

  -- Clear marks
  if state.explicitly_marked_node_ids then
    state.explicitly_marked_node_ids = {}
  end

  -- Refresh tree
  vim.schedule(function()
    local ok_mgr, manager = pcall(require, "neo-tree.sources.manager")
    if ok_mgr then
      pcall(manager.refresh, state.name or "filesystem")
    end
  end)

  -- Final notification
  local verb = action == "copy" and "Copied" or "Moved"
  if success > 0 then
    notify.info(string.format("✓ %s %d/%d items", verb, success, count))
  end
  if failed > 0 then
    notify.warn(string.format("✗ Failed: %d items", failed))
  end
end

return M
