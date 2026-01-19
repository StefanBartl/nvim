---@module 'chadrc'
--- Thin wrapper for WkdNvChad configuration.
--- Delegates all logic to wkdnvchad.config.chadrc

-- statusline feature flag
local normal = true
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
