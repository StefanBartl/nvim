---@module 'plugins.neotest'
---@brief Neotest: Testrunner-Framework für Neovim mit Neo-tree-Integration

local notify = require("lib.notify").create("[plugins.neotest]")
local neotest_init_utils = require("config.neotest.init.utils")

return {
  {
    "nvim-neotest/neotest",
    lazy = true,
    dependencies = require("config.neotest.init.dependencies"),
    cmd = require("config.neotest.init.cmd"),

    config = function()
      local neotest = require("neotest")
      local opts = {
        adapters = neotest_init_utils.build_adapters(),
        -- consumers = neotest_init_utils.build_consumers(),
        consumers = {
          neotree = require("neotest.consumers.neotree"),
        },
        discovery = {
          enabled = true,
          concurrent = 1,
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
          options = {},
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

      require("config.neotest.highlights").setup()
      require("config.neotest.commands").setup()
      require("config.neotest.keymaps").setup()
      require("config.neotest.whichkey").setup()
      require("config.neotest.debug").setup_all()
      require("config.neotest.utils.validate_consumer").setup_command()
      -- require("config.neotest.autocmds.auto_discovery").attach()
      require("config.neotest.highlights").setup()

      -- check wieviele adapter erfolgreich implementiert wurden
      --require("config.neotest.init.checks.adapter")(opts.adapters, neotree_consumer)

      local ok_core, core = pcall(require, "config.neotest.core")
      if ok_core and type(core.setup) == "function" then
        core.setup()
      end

      -- notify.info(string.format("Neotest initialized with %d adapters %s", adapter_count, consumer_status))
    end,
  },
}
-- neotest.autocmds.auto_discovery").attach()
-- require("config.neotest.utils.validate_consumer").setup_command()
