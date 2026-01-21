---@module 'chadrc'
--- Simplified chadrc that delegates to wkdnvchad.config

-- ============================================================================
-- CRITICAL: Setup wkdnvchad FIRST, before config
-- ============================================================================
local wkdnvc_ok, wkdnvc_err = pcall(function()
  local wkdnvc = require("wkdnvchad")
  wkdnvc.setup({ all = true })
end)

if not wkdnvc_ok then
  vim.notify("[chadrc] wkdnvchad setup failed: " .. tostring(wkdnvc_err), vim.log.levels.ERROR)
end

-- ============================================================================
-- Load Configuration
-- ============================================================================
-- All configuration is now managed in wkdnvchad.config
-- Change statusline variant in: lua/wkdnvchad/config/init.lua
-- Change base46 settings in: lua/wkdnvchad/config/base46.lua
-- ============================================================================

local ok, config = pcall(function()
  return require("wkdnvchad.config").setup()
end)

if ok then
  return {
    base46 = config.base46 or require("wkdnvchad.config.base46"),
    ui = config.ui or {
      statusline = config,
    },
  }
else
  vim.notify("[chadrc] Failed to load wkdnvchad.config: " .. tostring(config), vim.log.levels.ERROR)

  -- Fallback to minimal config
  return {
    base46 = require("wkdnvchad.config.base46"),
    ui = {
      statusline = {
        order = nil,
      },
    },
  }
end
