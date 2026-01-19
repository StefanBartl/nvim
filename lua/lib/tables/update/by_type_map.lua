---@module 'lib.table.update.by_type_map'
-- ============================================================================
-- Generic config updater using an explicit type map
--
-- Concept:
-- * cfg contains the actual data
-- * types table defines the expected runtime type per key
-- * stricter and independent of current cfg values
-- ============================================================================

local M = {}

--- Update a table using an explicit type map.
--- Unknown keys are ignored.
--- Type mismatches are rejected.
---
---@param cfg table<string, any>
---@param patch table<string, any>
---@param types table<string, string>
---@return boolean ok
function M.update(cfg, patch, types)
  for key, value in pairs(patch) do
    local expected_type = types[key]

    -- Ignore unknown keys
    if expected_type ~= nil then
      if value == nil or type(value) == expected_type then
        cfg[key] = value
      else
        vim.notify(
          ("Config update rejected: field '%s' expects %s, got %s")
            :format(key, expected_type, type(value)),
          vim.log.levels.WARN
        )
        return false
      end
    end
  end

  return true
end

return M


