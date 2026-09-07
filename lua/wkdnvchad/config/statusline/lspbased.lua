---@module 'wkdnvchad.config.statusline.lspbased'
--- LSP-aware statusline with breadcrumbs and enhanced modules

local notify = require("lib.nvim.notify").create("[wkdnvchad.config.statusline.lspbased]")

local M = {}

---Setup function called after config assembly
---@param config table
function M.setup(config)
  --- CDX: `wkdnvchad.config.chadrc` does not exist (no chadrc.lua under
  --- wkdnvchad/config/). `register_statusline_modules` lives in
  --- `wkdnvchad.config.statusline.custom_light`. As-is this variant always
  --- hits the notify.error path and registers no statusline modules.
  local ok, chadrc_module = pcall(require, "wkdnvchad.config.chadrc")
  if not ok then
    notify.error("[statusline.lspbased] Failed to load chadrc module: " .. tostring(chadrc_module))
    return
  end

  -- Register statusline modules
  if config.ui and config.ui.statusline then
    chadrc_module.register_statusline_modules(config.ui.statusline)
  end
end

M.ui = {
  statusline = {
    order = {
      "mode",
      "git",
      "%=",
      "breadcrumbs",
      "%=",
      "diagnostics",
      "lsp",
      "cursor",
      "progress",
      "cwd",
    },

    -- Modules will be registered by setup() function above
    modules = {},
  },
}

return M
