---@module 'config.neotree.commands.diff_files'
-- Module-level locals to avoid accidental globals and lsp warnings.

local node_utils = require("config.neotree.utils.node")
local notify = require("lib.notify").create("[neotree.commands.diff_files] ")


---@type string|nil
local diff_node = nil
---@type string|nil
local diff_name = nil

--- You can mark two files to diff them.
---@param state Cfg.NeoTree.State
return function(state)
  -- Get the currently focused Neo-tree node from the state.
  -- Falls back to nil if state is missing.
  local node = state and state.current_node or nil

  -- Check if a node exists; if not, log a warning and exit early.
  if not node then
    notify.warn("[neo-tree fzf] No node under cursor")
    return
  end

  -- Retrieve the node's filesystem path using the utility function.
  -- The second return value (is_dir) is not needed here, so we discard it with "_".
  local path, _ = node_utils.get_path(node)

  -- Validate that the path is not empty; if it is, log a warning and exit early.
  if path == "" then
    notify.warn("[neo-tree fzf] Node has no path")
    return
  end

  -- Ensure the clipboard table exists in the state; creates it if missing.
  state.clipboard = state.clipboard or {}

  -- Check if a diff source already exists and is different from the current node.
  if diff_node and diff_node ~= tostring(node.id) then
    local current_diff = node.id  -- store the current node id for the diff target

    -- Open the previously marked diff node.
    require("neo-tree.utils").open_file(state, diff_node, nil)

    -- Run a vertical diff between the diff source and the current node.
    vim.cmd("vert diffs " .. current_diff)

    -- Log info about the diff operation.
    notify.info("Diffing " .. (diff_name or "<unknown>") .. " against " .. (node.name or "<unknown>"))

    -- Reset the diff state after performing the diff.
    diff_node = nil
    diff_name = nil
    state.clipboard = {}

    -- Redraw the Neo-tree UI to update marks and highlights.
    require("neo-tree.ui.renderer").redraw(state)
  else
    -- Toggle the mark or set this node as the new diff source.
    local existing = state.clipboard[node.id]

    -- If this node is already marked for diff, unmark it.
    if existing and existing.action == "diff" then
      state.clipboard[node.id] = nil
      diff_node = nil
      diff_name = nil

      -- Refresh the UI after unmarking.
      require("neo-tree.ui.renderer").redraw(state)
    else
      -- Mark the current node as the diff source.
      state.clipboard[node.id] = { action = "diff", node = node }
      diff_name = node.name
      diff_node = tostring(node.id)

      -- Log info about the new diff source.
      notify.info("Diff source file " .. (diff_name or "<unknown>"))

      -- Refresh the UI after marking.
      require("neo-tree.ui.renderer").redraw(state)
    end
  end
end
