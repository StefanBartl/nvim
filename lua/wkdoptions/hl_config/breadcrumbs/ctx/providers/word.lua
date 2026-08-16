---@module 'wkdoptions.hl_config.breadcrumbs.ctx.providers.word'
---@brief Word fallback provider (<cword>)
---
--- Last resort: just use word under cursor
--- Priority: 20 (lowest)

local M = {}

---@param cfg WKDOptionsBreadcrumbsCtx
---@nodiscard
function M.enabled(cfg)
  return cfg.fallback_word_when_empty == true
end

---@param _node TSNode|nil # Unused
---@param _cfg WKDOptionsBreadcrumbsCtx # Unused
---@nodiscard
---@diagnostic disable-next-line: unused-local
function M.extract(_node, _cfg)
  -- Skip in insert mode
  if vim.fn.mode():find("i") then
    return nil
  end

  local w = vim.fn.expand("<cword>")

  if type(w) == "string" and #w >= 2 then
    return w
  end

  return nil
end

return M
