---@module 'chadrc'
--- Thin wrapper for WkdNvChad configuration.
--- Delegates all logic to wkdnvchad.config.chadrc

-- ============================================================================
-- CRITICAL: Setup wkdnvchad FIRST, before config
-- ============================================================================
local wkdnvc_ok, wkdnvc_err = pcall(function()
  local wkdnvc = require("wkdnvchad")
  wkdnvc.setup({ all = true })
end)

if not wkdnvc_ok then
  vim.notify(
    "[chadrc] wkdnvchad setup failed: " .. tostring(wkdnvc_err),
    vim.log.levels.ERROR
  )
end

-- ============================================================================
-- Statusline Config
-- ============================================================================

-- statusline feature flag
local normal = false
if normal then
  return require("wkdnvchad.config.normal")

end

local base = false
if base then
  return require("wkdnvchad.config.base")
end

-- Try to load custom statusline module with proper error handling
local ok, config = pcall(function()
  return require("wkdnvchad.config.chadrc").setup({
    base46 = {
      transparency = false,
      theme_toggle = { "vim_default", "rosepine" },
      theme = "tokyonight",
    },
  })
end)

if not ok then
  vim.notify(
    "Failed to load Custom NVChad statusline utilities; using default config.\nError: " .. tostring(config),
    vim.log.levels.WARN
  )
  return require("wkdnvchad.config.base")
end

return config
