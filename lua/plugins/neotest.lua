---@module 'plugins.neotest'
---@brief Neotest: test runner framework for Neovim with Neo-tree integration

local neotest_init_utils = require("config.neotest.init.utils")

--- File names `config.neotest.core` treats as test files (its `is_test_file`),
--- as autocmd patterns: opening one loads neotest, which is what makes its
--- status signs, diagnostics and the auto-attach appear there.
local TEST_FILES = {
  "*_test.lua",
  "*_spec.lua",
  "*.test.ts",
  "*.test.tsx",
  "*.spec.ts",
  "*.spec.tsx",
  "*.test.js",
  "*.spec.js",
  "*_test.go",
  "*_test.py",
  "test_*.py",
  "*.test.rs",
  "test_*.c",
  "test_*.cpp",
}

---@return string[]
local function test_file_events()
  local events = {}
  for _, pattern in ipairs(TEST_FILES) do
    events[#events + 1] = "BufReadPost " .. pattern
    events[#events + 1] = "BufNewFile " .. pattern
  end
  return events
end

return {
  {
    "nvim-neotest/neotest",
    -- Loaded by what uses it, not by every start. It used to ride in as a
    -- dependency of neo-tree, which filetree.nvim loads on VeryLazy: ~150 ms
    -- (adapters, vim-test, nio) right after the first frame of every session,
    -- tests or not. Now: its commands, its `<leader>nt` keys, a test file, or
    -- neo-tree's `tests` source (config.neotest.neotree.load_with_tests_source).
    lazy = true,
    dependencies = require("config.neotest.init.dependencies"),
    cmd = require("config.neotest.init.cmd"),
    event = test_file_events(),
    -- Stubs: lazy binds these at startup, the first press loads neotest and
    -- replays the key into the real mapping its config sets (same list, so
    -- the two cannot drift).
    keys = function()
      local keys = {}
      for _, km in ipairs(require("config.neotest.keymaps").keymaps) do
        keys[#keys + 1] = { km[2], mode = km[1], desc = km[4] }
      end
      return keys
    end,
    -- (The `<leader>nt` group label is registered by bindings.mappings: it has
    -- to be there before the first press, too, and an `init` here would
    -- require lib.nvim before lazy has loaded it as a start plugin.)

    config = function()
      local neotest = require("neotest")

      -- CRITICAL: Use wrapped consumer to prevent initialization race
      local opts = {
        -- CDX: parked -- hardcoded to plenary/vitest/go, bypasses
        -- config.neotest.adapters.factory (python/rust/typescript installed
        -- but never activated). Adapter split-brain:
        -- docs/ROADMAP/CDX/config-cdx-triage.md §3, docs/ROADMAP/IDEAS/test.md §2.1.
        adapters = {
          require("neotest-plenary"),
          require("neotest-vitest"),
          require("neotest-go"),
        },
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

      -- Setup Neotest (this initializes consumers with client)
      neotest.setup(opts)

      -- Post-setup configuration
      require("config.neotest.highlights").setup()
      require("config.neotest.commands").setup()
      require("config.neotest.keymaps").setup()
      -- The adapter diagnostics that used to be `config.neotest.debug`
      -- (`:NeotestDebug*`) are debugging.nvim's `:Debug neotest
      -- adapters|state|file|root|framework|discover` since 2026-09-19.
      require("config.neotest.utils.validate_consumer").setup_command()
      -- require("config.neotest.autocmds.auto_discovery").attach()

      -- CDX: parked -- adapter-count check, part of the factory.lua
      -- consolidation (docs/ROADMAP/CDX/config-cdx-triage.md §3).
      --require("config.neotest.init.checks.adapter")(opts.adapters, neotree_consumer)

      -- Core config (optional)
      local ok_core, core = pcall(require, "config.neotest.core")
      if ok_core and type(core.setup) == "function" then
        core.setup()
      end
    end,
  },
}
