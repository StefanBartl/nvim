---@module 'wkdoptions.hl_config.breadcrumbs.ctx'
---@brief Breadcrumb context orchestrator - delegates to provider pipeline
---
--- Architecture:
---   1. Get node at cursor (cached per tick)
---   2. Execute providers in configured order
---   3. First non-nil result wins
---   4. Fallback to base token extraction
---
--- Provider order (default):
---   lsp_func → ts_symbol → container → lang_extra → word

local lazy = require("lib.lazy")
local C = lazy.require("wkdoptions.config")

-- Core modules
local ts_helpers = lazy.require("wkdoptions.hl_config.breadcrumbs.ctx.utils.ts_helpers")
local base = lazy.require("wkdoptions.hl_config.breadcrumbs.ctx.base")

-- Provider modules (lazy-loaded on demand)
local providers = {
  lsp_func = nil,
  ts_symbol = nil,
  container = nil,
  lang_extra = nil,
  word = nil,
}

--- Get provider module (lazy-load once)
---@nodiscard
---@param name string
---@return table|nil
local function get_provider(name)
  if providers[name] ~= nil then
    return providers[name] or nil
  end

  local ok, mod = pcall(require, "wkdoptions.hl_config.breadcrumbs.ctx.providers." .. name)

  if ok and type(mod) == "table" and type(mod.extract) == "function" then
    providers[name] = mod
    return mod
  end

  -- Mark as unavailable
  providers[name] = false
  return nil
end

local M = {}

-----------------------------------------------------------
-- Backward Compatibility Exports (delegate to providers)
-----------------------------------------------------------

--- LSP function name (legacy export)
---@nodiscard
---@return string|nil
function M._ctx_lsp_func()
  local prov = get_provider("lsp_func")
  if not prov then
    return nil
  end

  local cfg = C.get_cfg().highlight.breadcrumbs_ctx or {}
  return prov.extract(nil, cfg)
end

--- TreeSitter symbol (legacy export)
---@nodiscard
---@return string|nil
function M._ctx_ts_symbol()
  local prov = get_provider("ts_symbol")
  if not prov then
    return nil
  end

  local node = ts_helpers.node_at_cursor()
  local cfg = C.get_cfg().highlight.breadcrumbs_ctx or {}
  return prov.extract(node, cfg)
end

--- Container chain (legacy export)
---@nodiscard
---@param base_symbol string|nil
---@return string|nil
function M._ctx_with_container(base_symbol)
  local prov = get_provider("container")
  if not prov then
    return base_symbol
  end

  local node = ts_helpers.node_at_cursor()
  local cfg = C.get_cfg().highlight.breadcrumbs_ctx or {}
  cfg._base_symbol = base_symbol -- Pass as context

  return prov.extract(node, cfg)
end

--- Language-specific extras (legacy export)
---@nodiscard
---@return string|nil
function M._ctx_lang_extra()
  local prov = get_provider("lang_extra")
  if not prov then
    return nil
  end

  local node = ts_helpers.node_at_cursor()
  local cfg = C.get_cfg().highlight.breadcrumbs_ctx or {}
  return prov.extract(node, cfg)
end

--- Word fallback (legacy export)
---@nodiscard
---@return string|nil
function M._ctx_word_fallback()
  local prov = get_provider("word")
  if not prov then
    return nil
  end

  local cfg = C.get_cfg().highlight.breadcrumbs_ctx or {}
  return prov.extract(nil, cfg)
end

--- Base token (legacy export)
---@nodiscard
---@return string|nil
function M._ctx_base_token()
  local node = ts_helpers.node_at_cursor()
  local ft = vim.bo.filetype
  return base.extract(node, ft)
end

-----------------------------------------------------------
-- Main Context Builder
-----------------------------------------------------------

--- Build complete context via provider pipeline
--- Executes providers in order until one returns non-nil
---@nodiscard
---@return string|nil
function M._build_context()
  local cfg = C.get_cfg().highlight.breadcrumbs_ctx or {}

  -- Get node once (cached)
  local node = ts_helpers.node_at_cursor()
  local ft = vim.bo.filetype

  -- Default provider order
  local order = cfg.providers_order
    or { "lsp_func", "ts_symbol", "container", "lang_extra", "word" }

  -- Execute provider chain
  for _, name in ipairs(order) do
    local prov = get_provider(name)

    -- Skip unavailable providers
    if not prov then
      goto continue
    end

    -- Check if enabled
    if type(prov.enabled) == "function" then
      local ok_check, is_enabled = pcall(prov.enabled, cfg)
      if not ok_check or not is_enabled then
        goto continue
      end
    end

    -- Execute provider
    local ok_extract, result = pcall(prov.extract, node, cfg)

    if ok_extract and result and result ~= "" then
      return result
    end

    ::continue::
  end

  -- Final fallback: base token
  return base.extract(node, ft)
end

-----------------------------------------------------------
-- Cache Invalidation
-----------------------------------------------------------

--- Invalidate all caches (call on BufEnter/config change)
---@return nil
function M.invalidate_caches()
  ts_helpers.invalidate_tick()
  base.clear_cache()
  -- Providers manage their own caches
end

return M
