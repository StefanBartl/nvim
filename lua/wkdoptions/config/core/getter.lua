---@module 'wkdoptions.config.core.getter'
--- Safe configuration getters and key collection.

local lazy = require("lib.lua.lazy")
local split = lazy.require("lib.lua.strings.core").split

local M = {}

--- Get value from nested table using dot path.
---@nodiscard
---@param t table
---@param path string
---@return any|nil
function M.get_by_path(t, path)
  if type(t) ~= "table" then
    return nil
  end

  if type(path) ~= "string" or path == "" then
    return nil
  end

  local parts = split(path, ".")
  if #parts == 0 then
    return nil
  end

  local node = t
  for i = 1, #parts do
    if type(node) ~= "table" then
      return nil
    end
    node = node[parts[i]]
  end

  return node
end

--- Recursively collect all leaf keys from a table (dot paths).
---@param root table
---@param prefix string|nil
---@param out string[]
---@return nil
function M.collect_keys(root, prefix, out)
  prefix = prefix or ""

  for k, v in pairs(root) do
    local path = (prefix == "" and tostring(k)) or (prefix .. "." .. tostring(k))

    if type(v) == "table" then
      M.collect_keys(v, path, out)
    else
      out[#out + 1] = path
    end
  end
end

return M
