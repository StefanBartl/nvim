---@module 'config.neotree.checkhealth.utils'
---@brief Utility module health checks

local M = {}

function M.check()
  vim.health.start("Utility Modules")

  -- General utils
  local ok_utils = pcall(require, "config.neotree.utils")
  if ok_utils then
    vim.health.ok("General utilities loaded")
  else
    vim.health.error("General utilities not loadable")
  end

  -- Node utils
  local ok_node = pcall(require, "config.neotree.utils.node")
  if ok_node then
    vim.health.ok("Node utilities loaded")
  else
    vim.health.error("Node utilities not loadable")
  end

  -- Buffer utils
  local ok_buf, _ = pcall(require, "config.neotree.utils.buffer")
  if ok_buf then
    vim.health.ok("Buffer utilities loaded")
    vim.health.info("Buffer validation cache active")
  else
    vim.health.error("Buffer utilities not loadable")
  end

  -- Tree utils
  local ok_tree = pcall(require, "config.neotree.utils.tree")
  if ok_tree then
    vim.health.ok("Tree utilities loaded")
  else
    vim.health.error("Tree utilities not loadable")
  end

  -- Platform utils
  local ok_platform, platform = pcall(require, "config.neotree.utils.platform")
  if ok_platform then
    vim.health.ok("Platform utilities loaded")

    vim.health.info("Platform detection:")
    vim.health.info("  Windows: " .. tostring(platform.is_windows()))
    vim.health.info("  WSL: " .. tostring(platform.is_wsl()))
    vim.health.info("  macOS: " .. tostring(platform.is_macos()))
    vim.health.info("  Unix: " .. tostring(platform.is_unix()))
  else
    vim.health.warn("Platform utilities not loaded")
  end
end

return M
