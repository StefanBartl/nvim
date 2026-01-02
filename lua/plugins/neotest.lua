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

--- Resolve language-specific config module
---@param lang string Language identifier
---@return table|nil config Language configuration or nil if not found
local function get_lang_config(lang)
  local ok, cfg = pcall(require, "config.neotest.adapters." .. lang)
  if not ok then
    return nil
  end
  return cfg
end

--- Build adapter list based on available configs
---@return table[] adapters List of initialized neotest adapters
local function build_adapters()
  local adapters = {}

  local languages = {
    "lua",
    "typescript",
    "javascript",
    "go",
    "bash",
    "rust",
    "c_cpp",
    "zig",
    "assembly",
    "python",
    "wasm",
  }

  for i = 1, #languages do
    local lang = languages[i]
    local cfg = get_lang_config(lang)
    if cfg and cfg.adapter then
      adapters[#adapters + 1] = cfg.adapter
    end
  end

  return adapters
end

---@type LazyPluginSpec[]
return {
  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-neotest/nvim-nio",
      "nvim-lua/plenary.nvim",
      "antoinemadec/FixCursorHold.nvim",
      "nvim-treesitter/nvim-treesitter",

      -- Neo-tree integration
      "olimorris/neotest-neo-tree-source.nvim",

      -- Language adapters (lazy-loaded per filetype)
      { "nvim-neotest/neotest-plenary", ft = "lua" },
      { "nvim-neotest/neotest-vim-test", ft = { "vim", "lua", "sh", "bash", "zsh", "asm" } },
      { "nvim-neotest/neotest-go", ft = "go" },
      { "nvim-neotest/neotest-python", ft = "python" },
      { "rouge8/neotest-rust", ft = "rust" },
      { "nvim-neotest/neotest-jest", ft = { "javascript", "typescript", "javascriptreact", "typescriptreact" } },
      { "marilari88/neotest-vitest", ft = { "javascript", "typescript", "javascriptreact", "typescriptreact" } },
    },

    lazy = true,

    keys = {
      { "<leader>ntt", function() require("neotest").run.run() end, desc = "Run nearest test" },
      { "<leader>ntf", function() require("neotest").run.run(vim.fn.expand("%")) end, desc = "Run file tests" },
      { "<leader>nta", function() require("neotest").run.run(vim.fn.getcwd()) end, desc = "Run all tests" },
      { "<leader>ntd", function() require("neotest").run.run({ strategy = "dap" }) end, desc = "Debug nearest test" },
      { "<leader>nts", function() require("neotest").summary.toggle() end, desc = "Toggle summary" },
      { "<leader>nto", function() require("neotest").output.open({ enter = true }) end, desc = "Show output" },
      { "<leader>ntO", function() require("neotest").output_panel.toggle() end, desc = "Toggle output panel" },
      { "<leader>ntS", function() require("neotest").run.stop() end, desc = "Stop test" },
      { "<leader>ntw", function() require("neotest").watch.toggle() end, desc = "Toggle watch mode" },
    },

    opts = function()
      return {
        adapters = build_adapters(),

        consumers = {
          neotree = require("neo-tree.sources.tests"),
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

        floating = {
          border = "rounded",
          max_height = 0.8,
          max_width = 0.8,
          options = {},
        },

        icons = {
          passed = "✓",
          running = "●",
          failed = "✗",
          skipped = "○",
          unknown = "?",
          watching = "👁",
        },

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

      -- Setup language-specific configurations
      local ok_core, core_cfg = pcall(require, "config.neotest.core")
      if ok_core and type(core_cfg.setup) == "function" then
        core_cfg.setup()
      end
    end,
  },
}
