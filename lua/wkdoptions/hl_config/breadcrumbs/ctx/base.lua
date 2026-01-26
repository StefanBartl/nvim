---@module 'wkdoptions.hl_config.breadcrumbs.ctx.base'
---@brief Base token extraction - returns concise identifier under cursor
---
--- This is the fallback when no provider yields a result.
--- Returns the most relevant identifier from the node under cursor.

local lazy = require("lib.lazy")
local ts = lazy.require("wkdoptions.hl_config.breadcrumbs.ctx.utils.ts_helpers")
local txt = lazy.require("wkdoptions.hl_config.breadcrumbs.ctx.utils.text_utils")

local M = {}

--- Language module cache (lazy-loaded)
---@type table<string, Breadcrumbs.LangModule|false>
local LANG_CACHE = {}

--- Get language module (lazy-loaded, cached)
---@nodiscard
---@param ft string
---@return Breadcrumbs.LangModule|nil
local function get_lang_module(ft)
  if LANG_CACHE[ft] ~= nil then
    return LANG_CACHE[ft] or nil
  end

  -- Try to load language module
  local ok, mod = pcall(require, "wkdoptions.hl_config.breadcrumbs.ctx.lang." .. ft)

  if ok and type(mod) == "table" and type(mod.extract_base) == "function" then
    -- Validate that it's a complete LangModule before caching
    local is_valid_module = type(mod.detect_literal_field) == "function"
      and type(mod.extract_owner) == "function"
      and type(mod.extract_container) == "function"
      and type(mod.extract_base) == "function"

    if is_valid_module then
      ---@cast mod Breadcrumbs.LangModule
      LANG_CACHE[ft] = mod
      return mod
    end
  end

  -- Mark as unavailable
  LANG_CACHE[ft] = false
  return nil
end

--- Extract base token from node
--- Delegates to language module if available, fallback to generic extraction
---@nodiscard
---@param node TSNode|nil
---@param ft string
---@return string|nil
function M.extract(node, ft)
  if not node then
    -- Fallback to <cword>
    local w = vim.fn.expand("<cword>")
    return (type(w) == "string" and #w >= 1) and w or nil
  end

  ft = ft or vim.bo.filetype

  -- Try language-specific extraction first
  local lang = get_lang_module(ft)
  if lang then
    local ok, result = pcall(lang.extract_base, node)
    if ok and result and result ~= "" then
      return result
    end
  end

  -- Generic fallback: try common patterns
  local node_type = node:type()
  local text = ts.node_text(node)

  -- Common identifier nodes
  local identifier_types = {
    identifier = true,
    name = true,
    property_identifier = true,
    field_identifier = true,
    type_identifier = true,
  }

  if identifier_types[node_type] then
    if text and #text > 0 then
      return text
    end
  end

  -- Generic pattern extraction
  local extracted = txt.extract_identifier(text, ft)
  if extracted and #extracted > 0 then
    return extracted
  end

  -- Last resort: <cword>
  local w = vim.fn.expand("<cword>")
  return (type(w) == "string" and #w >= 2) and w or nil
end

--- Invalidate language cache (for testing/reload)
---@return nil
function M.clear_cache()
  LANG_CACHE = {}
end

return M
