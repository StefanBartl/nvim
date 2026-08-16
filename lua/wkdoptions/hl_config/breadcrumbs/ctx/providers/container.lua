---@module 'wkdoptions.hl_config.breadcrumbs.ctx.providers.container'
---@brief Container chain provider (prefix owner/class)
---
--- Wraps base symbol with container: M.run() → M
--- Priority: 60

local lazy = require("lib.lua.lazy")
local txt = lazy.require("wkdoptions.hl_config.breadcrumbs.ctx.utils.text_utils")

local M = {}

---@param cfg WKDOptionsBreadcrumbsCtx
---@nodiscard
function M.enabled(cfg)
  return cfg.use_container_chain == true
end

---@param node TSNode|nil
---@param cfg WKDOptionsBreadcrumbsCtx
---@nodiscard
function M.extract(node, cfg)
  -- Base symbol must be provided via cfg._base_symbol
  local base_symbol = cfg._base_symbol

  if not base_symbol or base_symbol == "" then
    return nil
  end

  if not node then
    return base_symbol
  end

  local ft = vim.bo.filetype
  local join = cfg.container_join or "."
  local max_depth = tonumber(cfg.container_max_depth or 2) or 2

  -- Try to load language module
  local ok, lang = pcall(
    require,
    "wkdoptions.hl_config.breadcrumbs.ctx.lang." .. ft
  )

  if not ok or type(lang.extract_container) ~= "function" then
    return base_symbol
  end

  -- Extract container
  local container = lang.extract_container(node, max_depth)

  if not container or container == "" then
    return base_symbol
  end

  -- Avoid duplication: if base already starts with container, skip
  local esc = txt.escape_pattern(container .. join)
  if base_symbol:match("^" .. esc) then
    return base_symbol
  end

  -- Dedupe if enabled
  if cfg.dedupe_containers then
    local parts = { container, base_symbol }
    parts = txt.dedupe_consecutive(parts)
    return table.concat(parts, join)
  end

  return container .. join .. base_symbol
end

return M
