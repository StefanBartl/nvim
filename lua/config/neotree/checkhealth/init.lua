---@module 'config.neotree.checkhealth'
---@brief Aggregated checkhealth entry point for neotree config

local M = {}

--- Run all health checks
---@return nil
function M.check()
  vim.health.start("Neo-tree Configuration")

  -- Check if neo-tree is installed
  local ok_neo = pcall(require, "neo-tree")
  if ok_neo then
    vim.health.ok("neo-tree.nvim is installed")
  else
    vim.health.error("neo-tree.nvim is not installed")
    return
  end

  -- Check window controller
  local ok_controller = pcall(require, "config.neotree.open.window.controller")
  if ok_controller then
    vim.health.ok("window controller loaded")
  else
    vim.health.error("window controller not loadable")
  end

  -- Check state modules
  local ok_win_state = pcall(require, "config.neotree.state.windows")
  local ok_tree_state = pcall(require, "config.neotree.state.tree")

  if ok_win_state and ok_tree_state then
    vim.health.ok("state modules loaded")
  else
    vim.health.error("state modules not loadable")
  end

  -- Check trash system
  local ok_trash = pcall(require, "config.neotree.trash")
  if ok_trash then
    vim.health.ok("trash system loaded")
  else
    vim.health.warn("trash system not loaded (optional)")
  end

  -- Check current_hl
  local ok_hl = pcall(require, "config.neotree.current_hl")
  if ok_hl then
    vim.health.ok("current_hl module loaded")
  else
    vim.health.warn("current_hl not loaded (optional)")
  end

  -- Check cwd_sync
  local ok_sync = pcall(require, "config.neotree.cwd_sync")
  if ok_sync then
    vim.health.ok("cwd_sync module loaded")
  else
    vim.health.warn("cwd_sync not loaded (optional)")
  end

  -- Check configuration
  local cfg = require("config.neotree")
  if cfg.options then
    vim.health.ok("configuration loaded")

    vim.health.info("Active options:")
    vim.health.info("  restore_last_position: " .. tostring(cfg.options.restore_last_position))
    vim.health.info("  debug: " .. tostring(cfg.options.debug))
  else
    vim.health.error("configuration not initialized")
  end
end

return M
