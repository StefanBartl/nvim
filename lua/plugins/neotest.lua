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
    -- The test-file trigger is an autocmd of its own instead of `event`: lazy's
    -- event handler has no "after VimEnter" condition, so a test file that is a
    -- command-line argument (or comes back with a session) loaded neotest inside
    -- BufReadPost, ~190 ms before the first frame, and its auto-attach then ran
    -- before the buffer's tests were discovered ("No tests found"). Opened later
    -- the load is immediate; opened as part of startup it waits for VeryLazy.
    init = function()
      vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
        group = vim.api.nvim_create_augroup("neotest_on_test_file", { clear = true }),
        pattern = TEST_FILES,
        once = true,
        callback = function(ev)
          -- With neotest's own separator: its lib.files.parent splits on "\" and
          -- finds no parent for a path with "/" (a session's `edit E:/...`), so
          -- the project root of that file would never be registered.
          local file = (vim.fn.fnamemodify(ev.file, ":p"):gsub("/", package.config:sub(1, 1)))
          local function load(deferred)
            require("lazy").load({ plugins = { "neotest" } })
            if deferred then
              -- The auto-attach that starts neotest's client (it discovers the
              -- tests and places the signs) is a BufEnter autocmd, and the
              -- BufEnter of the startup buffers has passed by now: without this
              -- a test buffer that is open but not current (a restored session)
              -- gets no signs until it is visited. Asking for the file's tree
              -- starts the client; its discovery then covers the open buffers
              -- under the current directory's project (a buffer of another
              -- project gets its signs when it is visited).
              -- `get_tree_from_args` is neotest-internal, hence the pcall: if it
              -- ever changes, the signs come with the next BufEnter again.
              -- Two properties of the client start itself, both neotest's own:
              -- it opens an unauthenticated `serverstart("localhost:0")` listener
              -- for its parse subprocess (any local process can then run Lua in
              -- this session; here the subprocess cannot start, because lib.nvim's
              -- rpc_pipe exports NVIM_LISTEN_ADDRESS to children, so the listener
              -- stays open unused -- it has always opened on the first visit to a
              -- test buffer); and for 100+ test files the BufEnter attach can beat
              -- the discovery and say "No tests found" where it used to say "No
              -- running process found".
              require("nio").run(function()
                pcall(function()
                  require("neotest").run.get_tree_from_args({ file }, false)
                end)
              end)
            end
          end
          if vim.v.vim_did_enter == 1 then
            load(false)
          else
            vim.api.nvim_create_autocmd("User", {
              pattern = "VeryLazy",
              once = true,
              callback = function()
                load(true)
              end,
            })
          end
        end,
      })
    end,
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
    -- to exist before the first press, so it cannot wait for this plugin's
    -- config. `add_group` queues until which-key loads. The `init` above could
    -- do it too -- lib.nvim is on the rtp from the init.lua bootstrap, as the
    -- `keys` function relies on -- but that would run inside lazy.setup, before
    -- the first frame, instead of in the UIReady mappings phase.)

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
