---@module 'config.neotree.commands.clipboard'
---@brief Enhanced clipboard operations with mark support.
--- Cross-platform clipboard operations for Neo-tree using native libuv APIs.

local notify = require("lib.notify").create("[neotree.commands.clipboard]")
local node_utils = require("config.neotree.utils.node")

local M = {}

local uv = vim.uv

---Get nodes from marks or current node.
---@param state Cfg.NeoTree.State
---@return Cfg.NeoTree.Node[]
local function get_target_nodes(state)
  local marks = state.explicitly_marked_node_ids or {}
  ---@type Cfg.NeoTree.Node[]
  local nodes = {}

  -- Use marked nodes first
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

  -- Fallback to current node
  local current = node_utils.get_current(state)

  if current then
    return { current }
  end

  return {}
end

---Recursively copy files and directories.
---@param src string Source path
---@param dest string Destination path
---@return boolean success
---@return string? err
local function copy_recursive(src, dest)
  local stat = uv.fs_stat(src)

  if not stat then
    return false, "Source does not exist"
  end

  -- Handle regular files
  if stat.type == "file" then
    local ok, err = uv.fs_copyfile(src, dest)

    if not ok then
      return false, tostring(err)
    end

    return true
  end

  -- Handle directories recursively
  if stat.type == "directory" then
    local mkdir_ok = vim.fn.mkdir(dest, "p")

    if mkdir_ok == 0 then
      return false, "Failed to create directory"
    end

    local handle = uv.fs_scandir(src)

    if not handle then
      return false, "Failed to scan directory"
    end

    while true do
      local name = uv.fs_scandir_next(handle)

      if not name then
        break
      end

      local child_src = vim.fs.joinpath(src, name)
      local child_dest = vim.fs.joinpath(dest, name)

      local ok, err = copy_recursive(child_src, child_dest)

      if not ok then
        return false, err
      end
    end

    return true
  end

  return false, "Unsupported file type: " .. stat.type
end

---Copy marked/current nodes to clipboard.
---@param state Cfg.NeoTree.State
---@return nil
function M.copy_to_clipboard(state)
  local nodes = get_target_nodes(state)

  if #nodes == 0 then
    notify.warn("No nodes to copy")
    return
  end

  ---@type table
  local clipboard = {
    action = "copy",
    nodes = {},
  }

  for _, node in ipairs(nodes) do
    local path = node.path or node:get_id()

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

  notify.info(
    string.format(
      "📋 Copied %d item%s",
      #nodes,
      #nodes > 1 and "s" or ""
    )
  )
end

---Cut marked/current nodes to clipboard.
---@param state Cfg.NeoTree.State
---@return nil
function M.cut_to_clipboard(state)
  local nodes = get_target_nodes(state)

  if #nodes == 0 then
    notify.warn("No nodes to cut")
    return
  end

  ---@type table
  local clipboard = {
    action = "move",
    nodes = {},
  }

  for _, node in ipairs(nodes) do
    local path = node.path or node:get_id()

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

  notify.info(
    string.format(
      "✂️ Cut %d item%s",
      #nodes,
      #nodes > 1 and "s" or ""
    )
  )
end

---Paste clipboard contents into current directory.
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

  ---@type string?
  local target_dir

  -- Use current directory directly
  if current.type == "directory" then
    target_dir = current.path or current:get_id()
  else
    -- Use parent directory if current node is a file
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

  for _, item in ipairs(clipboard.nodes) do
    local source = item.path
    local basename = vim.fn.fnamemodify(source, ":t")
    local dest = vim.fs.joinpath(target_dir, basename)

    -- Prevent overwriting existing targets
    if uv.fs_stat(dest) then
      notify.warn(string.format("Skipped (exists): %s", basename))
      failed = failed + 1
      goto continue
    end

    local ok, err

    -- Copy operation
    if action == "copy" then
      ok, err = copy_recursive(source, dest)

    -- Move operation
    else
      ok, err = uv.fs_rename(source, dest)

      if not ok and not err then
        err = "Rename failed"
      end
    end

    if ok then
      success = success + 1
    else
      notify.warn(
        string.format(
          "Failed %s: %s - %s",
          action,
          basename,
          tostring(err)
        )
      )

      failed = failed + 1
    end

    ::continue::
  end

  -- Clear clipboard after successful move
  if action == "move" and success > 0 then
    state.clipboard = nil
  end

  -- Clear marks after operation
  if state.explicitly_marked_node_ids then
    state.explicitly_marked_node_ids = {}
  end

  -- Refresh Neo-tree
  vim.schedule(function()
    local ok_mgr, manager = pcall(
      require,
      "neo-tree.sources.manager"
    )

    if ok_mgr then
      pcall(manager.refresh, state.name or "filesystem")
    end
  end)

  -- Final notifications
  local verb = action == "copy" and "Copied" or "Moved"

  if success > 0 then
    notify.info(
      string.format(
        "✓ %s %d/%d items",
        verb,
        success,
        count
      )
    )
  end

  if failed > 0 then
    notify.warn(string.format("✗ Failed: %d items", failed))
  end
end

return M
