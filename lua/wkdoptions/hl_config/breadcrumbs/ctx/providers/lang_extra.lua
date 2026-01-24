---@module 'wkdoptions.hl_config.breadcrumbs.ctx.providers.lang_extra'
---@brief Language-specific fallback provider
---
--- Extracts owner from literals/member access when no symbol found
--- Priority: 40

local M = {}

---@nodiscard
function M.enabled(cfg)
  return cfg.use_lang_specific == true
end

---@nodiscard
---@diagnostic disable-next-line: unused-local
function M.extract(node, _cfg)
  if not node then
    return nil
  end

  local ft = vim.bo.filetype

  -- Try to load language module
  local ok, lang = pcall(
    require,
    "wkdoptions.hl_config.breadcrumbs.ctx.lang." .. ft
  )

  if not ok or type(lang.extract_owner) ~= "function" then
    return nil
  end

  -- Extract owner
  return lang.extract_owner(node)
end

return M
