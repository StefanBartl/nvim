---@module 'uv_doc.cache'
---@brief Session-scoped caching with explicit invalidation

local M = {}

-- Create notify instance with proper API
local notify = require("lib.notify").create("uv_doc")

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

  -- Clear memo cache if available
  local ok, memo = pcall(require, "lib.memo")
  if ok and memo and type(memo.clear) == "function" then
    memo.clear()
  end

  notify("cache cleared", vim.log.levels.INFO)
end

return M
