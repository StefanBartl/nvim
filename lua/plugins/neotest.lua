---@module 'plugins.neotest'

local notify = require("lib.notify").create("[plugins.neotest]")
local neotest_init_utils = require("config.neotest.init.utils")

return {
  {
    "nvim-neotest/neotest",
    lazy = true,
    dependencies = require("config.neotest.init.dependencies"),
    cmd = require("config.neotest.init.cmd"),
    opts = function()
      return {
        adapters = neotest_init_utils.build_adapters(),
        consumers = neotest_init_utils.build_consumers(),

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
    end,

    config = function(_, opts)
      local neotest = require("neotest")
      neotest.setup(opts)

      require("config.neotest.commands").setup()
      require("config.neotest.keymaps").setup()
      require("config.neotest.whichkey").setup()

      local ok, core = pcall(require, "config.neotest.core")
      if ok and type(core.setup) == "function" then
        core.setup()
      end

      notify.info("Neotest initialized with " .. tostring(#opts.adapters) .. " adapters")
    end,
  },
}
