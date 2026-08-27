---@module 'config.neotree.checkhealth.core'
---@brief Core module health checks

local M = {}

function M.check()
  vim.health.start("Neo-tree Core Modules")

  -- Neo-tree plugin
  local ok_neo, _ = pcall(require, "neo-tree")
  if ok_neo then
    vim.health.ok("neo-tree.nvim installed")
  else
    vim.health.error("neo-tree.nvim not installed")
    return
  end

  -- Main config
  local ok_cfg, cfg = pcall(require, "config.neotree")
  if ok_cfg then
    vim.health.ok("Main configuration loaded")

    -- Check options
    if cfg.options then
      vim.health.info("Configuration:")
      vim.health.info("  restore_last_position: " .. tostring(cfg.options.restore_last_position))
      vim.health.info("  default_position: " .. tostring(cfg.options.default_position))
      vim.health.info("  debug: " .. tostring(cfg.options.debug))
    end
  else
    vim.health.error("Main configuration not loadable")
  end

  -- Keymaps
  local ok_keymaps = pcall(require, "config.neotree.keymaps")
  if ok_keymaps then
    vim.health.ok("Keymap registry loaded")
  else
    vim.health.warn("Keymap registry not loaded")
  end

  -- Event handlers
  local ok_events = pcall(require, "config.neotree.event_handlers")
  if ok_events then
    vim.health.ok("Event handlers loaded")
  else
    vim.health.warn("Event handlers not loaded")
  end
end

return M
