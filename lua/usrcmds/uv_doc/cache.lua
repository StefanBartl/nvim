---@module 'uv_doc.cache'
---@brief Session-scoped caching with explicit invalidation

local M = {}

local memo = require("lib.memo")
local notify = require("lib.notify")

---@type string|nil
local genindex_html = nil

---@type string[]|nil
local index_symbols = nil

--- Gets cached genindex HTML
---@nodiscard
---@return string|nil
function M.get_genindex()
  return genindex_html
end

--- Sets genindex HTML cache
---@param html string
function M.set_genindex(html)
  genindex_html = html
end

--- Gets cached symbol list
---@nodiscard
---@return string[]|nil
function M.get_symbols()
  return index_symbols
end

--- Sets symbol list cache
---@param symbols string[]
function M.set_symbols(symbols)
  index_symbols = symbols
end

--- Clears all caches
function M.clear_all()
  genindex_html = nil
  index_symbols = nil
  memo.clear()
  notify.info("cache cleared")
end

return M
