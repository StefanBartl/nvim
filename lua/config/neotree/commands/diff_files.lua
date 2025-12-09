---@module 'config.neotree.commands.diff_files'
-- Module-level locals to avoid accidental globals and lsp warnings.
local diff_node = nil
local diff_name = nil

--- You can mark two files to diff them.
---@param state table
return function(state)
  -- retrieve the current node under cursor/selection
  local node = state.tree:get_node()
  local log = require("neo-tree.log")

  -- Ensure clipboard table exists
  state.clipboard = state.clipboard or {}

  -- If a diff source already exists and it's different from current node
  if diff_node and diff_node ~= tostring(node.id) then
    -- open the diff source file and run a vertical diff against current
    local current_diff = node.id

    -- call open_file with `nil` for open options if not needed
    -- adjust the third parameter if neo-tree's `open_file` expects a specific open spec
    require("neo-tree.utils").open_file(state, diff_node, nil)

    -- run vertical diff; keep user's original command (may be `vert diffs` or `vert diffsplit` depending on environment)
    vim.cmd("vert diffs " .. current_diff)

    log.info("Diffing " .. (diff_name or "<unknown>") .. " against " .. (node.name or "<unknown>"))

    -- reset diff state
    diff_node = nil
    current_diff = nil
    state.clipboard = {}
    require("neo-tree.ui.renderer").redraw(state)
  else
    -- toggle mark / add as diff source
    local existing = state.clipboard[node.id]
    if existing and existing.action == "diff" then
      state.clipboard[node.id] = nil
      diff_node = nil
      require("neo-tree.ui.renderer").redraw(state)
    else
      state.clipboard[node.id] = { action = "diff", node = node }
      diff_name = state.clipboard[node.id].node.name
      diff_node = tostring(state.clipboard[node.id].node.id)
      log.info("Diff source file " .. (diff_name or "<unknown>"))
      require("neo-tree.ui.renderer").redraw(state)
    end
  end
end
