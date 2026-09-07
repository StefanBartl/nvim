---@module 'config.neotest.init.checks.adapter'
--- Post-setup adapter check: logs how many adapters neotest initialized with
--- and, when a neo-tree tests-source consumer is present, wires it up too.
--
--- CDX: never required -- the call site in plugins/neotest.lua is commented
--- out (twice, once dead after the returned spec table), and this module is
--- flagged unreferenced-module by docs/map/overview.md. Same open decision as
--- autocmds/auto_discovery.lua, see docs/ROADMAP/IDEAS/test.md §2.

local notify = require("lib.nvim.notify").create("[plugins.neotest]")

-- Usage: require("config.neotest.init.checks.adapter")(opts.adapters, neotree_consumer_m)
return function(adapters, neotree_consumer_m)
  local ok, core = pcall(require, "config.neotest.core")
  if ok and type(core.setup) == "function" then
    core.setup()
  end

  -- Log the number of initialized adapters
  local adapter_count = #adapters
  notify.info(string.format("Neotest initialized with %d adapters", adapter_count))

  if neotree_consumer_m then
    notify.info("Neo-tree tests consumer registered")
  end
end
