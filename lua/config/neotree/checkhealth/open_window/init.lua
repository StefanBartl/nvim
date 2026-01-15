---@module 'config.neotree.checkhealth.open_window'
---@brief Health checks for neo-tree window controller

local M = {}

--- Run window controller health checks
---@return nil
function M.check()
  vim.health.start("Neo-tree Window Controller")

  -- Check controller module
  local ok_ctrl, _ = pcall(require, "config.neotree.open.window.controller")
  if ok_ctrl then
    vim.health.ok("controller loaded")
  else
    vim.health.error("controller not loadable")
    return
  end

  -- Check state module
  local ok_state, state = pcall(require, "config.neotree.state.windows")
  if ok_state then
    vim.health.ok("window state module loaded")

    local current_state = state.is_open()
    local current_pos = state.get_position()

    vim.health.info("Current state:")
    vim.health.info("  open: " .. tostring(current_state))
    vim.health.info("  position: " .. tostring(current_pos))
  else
    vim.health.error("window state module not loadable")
  end

  -- Check tree state module
  local ok_tree, tree_state = pcall(require, "config.neotree.state.tree")
  if ok_tree then
    vim.health.ok("tree state module loaded")

    local node_id = tree_state.get_node()
    local expanded = tree_state.get_expanded()

    vim.health.info("Tree state:")
    vim.health.info("  last node: " .. tostring(node_id))
    vim.health.info("  expanded nodes: " .. tostring(vim.tbl_count(expanded)))
  else
    vim.health.error("tree state module not loadable")
  end

  -- Check reveal controller
  local ok_reveal = pcall(require, "config.neotree.open.reveal.controller")
  if ok_reveal then
    vim.health.ok("reveal controller loaded")
  else
    vim.health.error("reveal controller not loadable")
  end

  -- Check float module
  local ok_float = pcall(require, "config.neotree.open.window.float")
  if ok_float then
    vim.health.ok("float module loaded")
  else
    vim.health.error("float module not loadable")
  end
end

return M
