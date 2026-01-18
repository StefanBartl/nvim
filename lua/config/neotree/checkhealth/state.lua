---@module 'config.neotree.checkhealth.state'
---@brief State module health checks

local M = {}

function M.check()
  vim.health.start("State Management")

  -- Window state
  local ok_win, win_state = pcall(require, "config.neotree.state.windows")
  if ok_win then
    vim.health.ok("Window state module loaded")

    local state = win_state.get_state()
    vim.health.info("Current state:")
    vim.health.info("  open: " .. tostring(state.open))
    vim.health.info("  position: " .. tostring(state.position or "nil"))
    vim.health.info("  source: " .. tostring(state.source or "nil"))

    -- Test snapshot cache
    local s1 = win_state.get_state()
    local s2 = win_state.get_state()
    if s1 == s2 then
      vim.health.ok("Snapshot cache working")
    else
      vim.health.warn("Snapshot cache not working (new instance each call)")
    end
  else
    vim.health.error("Window state module not loadable")
  end

  -- Tree state
  local ok_tree, tree_state = pcall(require, "config.neotree.state.tree")
  if ok_tree then
    vim.health.ok("Tree state module loaded")

    local node_id = tree_state.get_node()
    local expanded = tree_state.get_expanded()

    vim.health.info("Tree state:")
    vim.health.info("  last node: " .. tostring(node_id or "nil"))
    vim.health.info("  expanded nodes: " .. tostring(vim.tbl_count(expanded)))
  else
    vim.health.error("Tree state module not loadable")
  end
end

return M
