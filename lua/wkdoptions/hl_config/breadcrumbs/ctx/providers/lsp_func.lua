---@module 'wkdoptions.hl_config.breadcrumbs.ctx.providers.lsp_func'
---@brief LSP function name provider (b:lsp_current_function)
---
--- Very cheap provider - just reads buffer variable
--- Priority: 100 (highest - prefer LSP when available)

local M = {}

--- Check if provider is enabled
---@nodiscard
---@param cfg WKDOptionsBreadcrumbsCtx
---@return boolean
function M.enabled(cfg)
  return cfg.prefer_lsp_function == true
end

--- Extract LSP function name
---@nodiscard
---@param _node TSNode|nil # Unused
---@param _cfg WKDOptionsBreadcrumbsCtx # Unused
---@return string|nil
---@diagnostic disable-next-line: unused-local
function M.extract(_node, _cfg)
  local s = vim.b.lsp_current_function

  if type(s) == "string" and #s > 0 then
    return s
  end

  return nil
end

return M
