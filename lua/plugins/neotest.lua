---@module 'plugins.neotest'
---@brief Neotest: Testrunner-Framework für Neovim mit Neo-tree-Integration

-- local notify = require("lib.notify").create("[plugins.neotest]")
-- local neotest_init_utils = require("config.neotest.init.utils")

return {
  -- {
    -- "nvim-neotest/neotest",
    -- lazy = true,
    -- dependencies = require("config.neotest.init.dependencies"),
    -- cmd = require("config.neotest.init.cmd"),

    -- config = function()
      -- local neotest = require("neotest")

      -- -- CRITICAL: Use wrapped consumer to prevent initialization race
      -- local opts = {
        -- adapters = neotest_init_utils.build_adapters(),
        -- consumers = neotest_init_utils.build_consumers(),

        -- discovery = {
          -- enabled = true,
          -- concurrent = 1,
        -- },

        -- running = {
          -- concurrent = true,
        -- },

        -- diagnostic = {
          -- enabled = true,
          -- severity = vim.diagnostic.severity.ERROR,
        -- },

        -- status = {
          -- enabled = true,
          -- signs = true,
          -- virtual_text = false,
        -- },

        -- output = {
          -- enabled = true,
          -- open_on_run = false,
        -- },

        -- quickfix = {
          -- enabled = false,
        -- },

        -- floating = {
          -- border = "rounded",
          -- max_height = 0.8,
          -- max_width = 0.8,
          -- options = {},
        -- },

        -- icons = require("config.neotest.init.icons")("devicons"),

        -- highlights = {
          -- passed = "NeotestPassed",
          -- running = "NeotestRunning",
          -- failed = "NeotestFailed",
          -- skipped = "NeotestSkipped",
          -- test = "NeotestTest",
          -- namespace = "NeotestNamespace",
          -- focused = "NeotestFocused",
          -- file = "NeotestFile",
          -- dir = "NeotestDir",
          -- border = "NeotestBorder",
          -- indent = "NeotestIndent",
          -- expand_marker = "NeotestExpandMarker",
          -- adapter_name = "NeotestAdapterName",
          -- select_win = "NeotestWinSelect",
          -- marked = "NeotestMarked",
          -- target = "NeotestTarget",
          -- unknown = "NeotestUnknown",
        -- },
      -- }

      -- -- Setup Neotest (this initializes consumers with client)
      -- neotest.setup(opts)

      -- -- Post-setup configuration
      -- require("config.neotest.highlights").setup()
      -- require("config.neotest.commands").setup()
      -- require("config.neotest.keymaps").setup()
      -- require("config.neotest.whichkey").setup()
      -- require("config.neotest.debug").setup_all()
      -- require("config.neotest.utils.validate_consumer").setup_command()

      -- -- Core config (optional)
      -- local ok_core, core = pcall(require, "config.neotest.core")
      -- if ok_core and type(core.setup) == "function" then
        -- core.setup()
      -- end

      -- -- Verify consumer initialization
      -- vim.defer_fn(function()
        -- local ok_validate = pcall(require("config.neotest.utils.validate_consumer").check_consumer)
        -- if ok_validate then
          -- notify.info("Neo-tree consumer verified")
        -- else
          -- notify.warn("Neo-tree consumer validation failed")
        -- end
      -- end, 1000)
    -- end,
  -- },
}
-- check wieviele adapter erfolgreich implementiert wurden
--require("config.neotest.init.checks.adapter")(opts.adapters, neotree_consumer)
-- require("config.neotest.autocmds.auto_discovery").attach()
-- require("config.neotest.utils.validate_consumer").setup_command()
