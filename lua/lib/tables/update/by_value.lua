---@module 'lib.table.update.by_value_type'
-- ============================================================================
-- Generic config updater using runtime type inference from current values
--
-- Concept:
-- * cfg defines the source of truth
-- * types are inferred from existing cfg values via type()
-- * suitable for small/medium configs without external metadata
-- ============================================================================

local M = {}

--- Update a table using runtime type checks derived from existing values.
--- Unknown keys are ignored.
--- Type mismatches are rejected.
---
---@param cfg table<string, any>
---@param patch table<string, any>
---@return boolean ok
function M.update(cfg, patch)
  for key, value in pairs(patch) do
    local current = cfg[key]

    -- Ignore unknown keys
    if current ~= nil then
      local current_type = type(current)
      local value_type = type(value)

      -- Explicit nil is always allowed
      if value == nil then
        cfg[key] = nil
      elseif current_type == value_type then
        cfg[key] = value
      else
        vim.notify(
          ("Config update rejected: field '%s' expects %s, got %s")
            :format(key, current_type, value_type),
          vim.log.levels.WARN
        )
        return false
      end
    end
  end

  return true
end

return M

