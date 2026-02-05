---@module 'config.neotest.init.utils'

local M = {}

--- Build deduplicated adapter list
---@return table[]
function M.build_adapters()
  local factory = require("config.neotest.adapters.factory")
  return factory.get_all()
end

--- Build consumers with deferred initialization
---@return table<string, function>
function M.build_consumers()
  return {
    -- Wrapper prevents race conditions by deferring consumer creation
    neotree = require("config.neotest.consumers.neotree_wrapper"),
  }
end

return M
