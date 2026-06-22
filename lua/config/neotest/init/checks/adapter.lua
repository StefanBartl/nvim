---@module 'config.neotest.init.checks.adapter'

local notify = require("lib.nvim.notify").create("[plugins.neotest]")

-- Implementieren in plugin/neotest require("config.neotest.init.checks.adapter")(opts.adapters, neotree_consumer_m)
return function(adapters, neotree_consumer_m)
  local ok, core = pcall(require, "config.neotest.core")
  if ok and type(core.setup) == "function" then
    core.setup()
  end

  -- Log initialisierte Adapter
  local adapter_count = #adapters
  notify.info(string.format("Neotest initialized with %d adapters", adapter_count))

  if neotree_consumer_m then
    notify.info("Neo-tree tests consumer registered")
  end
end
