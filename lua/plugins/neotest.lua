---@module 'plugins.neotest'
---@brief Neotest: Testrunner-Framework für Neovim mit Neo-tree-Integration
---@description
--- Vollständige Multi-Language-Test-Integration mit folgenden Adaptern:
---   - Lua (plenary, vim-test)
---   - TypeScript/JavaScript (vitest, jest)
---   - Go (go test)
---   - Python (pytest, unittest, nose)
---   - Rust (cargo test)
---   - C/C++ (gtest, catch2, ctest)
---   - Bash/Shell (bats, shunit2)
---   - Zig (zig test)
---   - Assembly (custom frameworks)
---   - WebAssembly (wasm-pack, jest)

local notify = require("lib.notify").create("[plugins.neotest]")
local neotest_init_utils = require("config.neotest.init.utils")

----------------------------------------------------------------------
-- Plugin-Spezifikation
----------------------------------------------------------------------

---@type LazyPluginSpec[]
return {
  {
    "nvim-neotest/neotest",
    lazy = true,
    dependencies = require("config.neotest.init.dependencies"),
    cmd = require("config.neotest.init.cmd"),

    config = function()
      -- KRITISCH: Consumer VOR setup() laden und validieren
      local consumer_ok, neotree_consumer = pcall(require, "neotest.consumers.neotree")

      if not consumer_ok then
        notify.warn("Neo-tree tests consumer not available")
        neotree_consumer = nil
      end

      -- Validiere Consumer-Typ
      if neotree_consumer and type(neotree_consumer) ~= "function" then
        notify.warn("Neo-tree consumer has unexpected type: " .. type(neotree_consumer))
        neotree_consumer = nil
      end

      -- Setup-Optionen
      local opts = {
        adapters = neotest_init_utils.build_adapters(),

        -- KRITISCH: Consumer nur registrieren wenn verfügbar UND Funktion
        consumers = neotree_consumer and {
          neotree = neotree_consumer,
        } or {},

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

      -- Setup ausführen
      local neotest = require("neotest")
      neotest.setup(opts)

      -- Post-Setup-Initialisierung
      require("config.neotest.commands").setup()
      require("config.neotest.keymaps").setup()
      require("config.neotest.whichkey").setup()
      require("config.neotest.debug").setup_all()
      require("config.neotest.utils.validate_consumer").setup_command()
      -- require("config.neotest.autocmds.auto_discovery").attach()

      -- check wieviele adapter erfolgreich implementiert wurden
      --require("config.neotest.init.checks.adapter")(opts.adapters, neotree_consumer)
    end,
  },
}
