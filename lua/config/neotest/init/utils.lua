---@module 'config.neotest.init.utils'

local M = {}

--- Build deduplicated adapter list
---@return table[]
function M.build_adapters()
  local factory = require("config.neotest.adapters.factory")
  return factory.get_all()
end

--- Build consumers
---@return table<string, function>
function M.build_consumers()
  local consumers = {}

  local ok, neotree = pcall(require, "neotest.consumers.neotree")
  if ok and type(neotree) == "function" then
    consumers.neotree = neotree
  end

  return consumers
end

return M
