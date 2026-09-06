---@module 'config.neotest.init.utils'
--- `build_adapters()`/`build_consumers()`: assembles neotest's `opts.adapters`
--- from the adapter factory and its consumer table, deferring each
--- consumer's own initialization to avoid a race at setup time.
--
--- CDX: M.build_adapters() is never called -- plugins/neotest.lua hardcodes
--- opts.adapters to { neotest-plenary, neotest-vitest, neotest-go } directly
--- and never calls this function or adapters/factory.lua, so python/rust/
--- typescript(vitest-vs-jest detection) never actually activate despite
--- being installed. Root of the "adapter split-brain" fully analyzed in
--- docs/ROADMAP/IDEAS/test.md §2.1 -- a planned test.nvim extraction is meant
--- to consolidate this, so left tagged rather than rewired here.

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
