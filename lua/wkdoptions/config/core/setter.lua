---@module 'wkdoptions.config.core.setter'
--- Safe configuration setters with type validation.

local lazy = require("lib.lua.lazy")
local split = lazy.require("lib.lua.strings.core").split

local M = {}

--- Validate type compatibility between old and new values.
---@nodiscard
---@param old any
---@param new any
---@param path string
---@param toggle_if_bool boolean
---@return boolean success
---@return string|nil error
---@return any|nil final_value
local function validate_and_resolve(old, new, path, toggle_if_bool)
  local oldt, newt = type(old), type(new)

  -- Boolean handling
  if oldt == "boolean" then
    if newt ~= "boolean" then
      if toggle_if_bool then
        return true, nil, not old
      end
      return false, ("Expected boolean for '%s'"):format(path), nil
    end
    return true, nil, new
  end

  -- Number handling
  if oldt == "number" then
    if newt ~= "number" then
      return false, ("Expected number for '%s'"):format(path), nil
    end
    return true, nil, new
  end

  -- String handling
  if oldt == "string" then
    if newt ~= "string" then
      return false, ("Expected string for '%s'"):format(path), nil
    end
    return true, nil, new
  end

  -- Table handling
  if oldt == "table" then
    return false, ("Set a leaf key within '%s' (e.g. '%s.bg')"):format(path, path), nil
  end

  -- Unknown type - accept as-is
  return true, nil, new
end

--- Set nested key in a table using a dot path.
---@nodiscard
---@param t table
---@param path string
---@param val any
---@param toggle_if_bool boolean
---@return boolean success
---@return string|nil error
function M.set_by_path(t, path, val, toggle_if_bool)
  if type(t) ~= "table" then
    return false, "Root must be a table"
  end

  if type(path) ~= "string" or path == "" then
    return false, "Empty key path"
  end

  local parts = split(path, ".")
  if #parts == 0 then
    return false, "Invalid key path"
  end

  -- Navigate to parent
  local parent = t
  for i = 1, #parts - 1 do
    local seg = parts[i]
    if type(parent[seg]) ~= "table" then
      return false, ("Path segment '%s' is not a table"):format(seg)
    end
    parent = parent[seg]
  end

  -- Validate and set leaf
  local leaf = parts[#parts]
  if parent[leaf] == nil then
    return false, ("Unknown key '%s'"):format(path)
  end

  local ok, err, final = validate_and_resolve(parent[leaf], val, path, toggle_if_bool)
  if not ok then
    return false, err
  end

  parent[leaf] = final
  return true
end

return M
