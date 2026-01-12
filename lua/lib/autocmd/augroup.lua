---@module 'lib.autocmd.augroup'
-- =========================================================
-- Augroup registry.
--
-- Centralized augroup creation with optional prefixing
-- and deduplication.
-- =========================================================

local M = {}

---@type table<string, integer>
local cache = {}

---@param name string
---@param opts { clear?: boolean, prefix?: string }|nil
---@return integer
function M.get(name, opts)
  opts = opts or {}
  local full_name = opts.prefix and (opts.prefix .. "." .. name) or name

  if cache[full_name] == nil then
    cache[full_name] = vim.api.nvim_create_augroup(full_name, {
      clear = opts.clear == true,
    })
  end

  return cache[full_name]
end

return M

