---@module 'plugins.neotest'

local notify = require("lib.notify").create("[plugins.neotest]")

return {
  {
    "nvim-neotest/neotest",
    lazy = true,
    dependencies = require("config.neotest.init.dependencies"),
    cmd = require("config.neotest.init.cmd"),

    config = function()
      local neotest = require("neotest")
      local utils = require("config.neotest.init.utils")

      -- Build adapters
      local adapters = utils.build_adapters()

      -- Log adapter count
      notify.info(string.format("Loaded %d adapters", #adapters))

      for i = 1, #adapters do
        local adapter = adapters[i]
        local name = adapter.name or tostring(adapter)
        notify.info(string.format("  [%d] %s", i, name))
      end

      -- CRITICAL: Consumer muss Funktion sein, nicht table
      local neotree_consumer = nil
      local ok_consumer, consumer_mod = pcall(require, "neotest.consumers.neotree")
      if ok_consumer then
        if type(consumer_mod) == "function" then
          neotree_consumer = consumer_mod
        elseif type(consumer_mod) == "table" and consumer_mod.setup then
          neotree_consumer = consumer_mod.setup
        end
      end

      local opts = {
        adapters = adapters,

        consumers = neotree_consumer and {
          neotree = neotree_consumer,
        } or {},

        discovery = {
          enabled = true,
          concurrent = 1,
          -- CRITICAL: Nur in CWD suchen
          filter_dir = function(name, rel_path, root)
            if name == "node_modules" or name == ".git" then
              return false
            end

            -- Nur innerhalb von CWD
            local cwd = vim.fn.getcwd()
            local full_path = root .. "/" .. rel_path
            return full_path:match("^" .. vim.pesc(cwd)) ~= nil
          end,
        },

        running = {
          concurrent = true,
        },

        diagnostic = {
          enabled = true,
          severity = vim.diagnostic.severity.ERROR,
        },

        status = {
          enabled = true,
          signs = true,
          virtual_text = false,
        },

        output = {
          enabled = true,
          open_on_run = false,
        },

        quickfix = {
          enabled = false,
        },

        floating = {
          border = "rounded",
          max_height = 0.8,
          max_width = 0.8,
        },

        icons = require("config.neotest.init.icons")("devicons"),

        highlights = {
          passed = "NeotestPassed",
          running = "NeotestRunning",
          failed = "NeotestFailed",
          skipped = "NeotestSkipped",
          test = "NeotestTest",
          namespace = "NeotestNamespace",
          focused = "NeotestFocused",
          file = "NeotestFile",
          dir = "NeotestDir",
          border = "NeotestBorder",
          indent = "NeotestIndent",
          expand_marker = "NeotestExpandMarker",
          adapter_name = "NeotestAdapterName",
          select_win = "NeotestWinSelect",
          marked = "NeotestMarked",
          target = "NeotestTarget",
          unknown = "NeotestUnknown",
        },
      }

      neotest.setup(opts)

      -- Post-setup
      require("config.neotest.highlights").setup()
      require("config.neotest.commands").setup()
      require("config.neotest.keymaps").setup()
      require("config.neotest.whichkey").setup()
      require("config.neotest.debug").setup_all()
      require("config.neotest.utils.validate_consumer").setup_command()

      local ok_core, core = pcall(require, "config.neotest.core")
      if ok_core and type(core.setup) == "function" then
        core.setup()
      end

      -- Final verification
      vim.defer_fn(function()
        local adapter_ids = neotest.state.adapter_ids()
        notify.info(string.format("Neotest started with %d adapter instances", #adapter_ids))
      end, 1000)
    end,
  },
}



 -- neotest.autocmds.auto_discovery").attach()
