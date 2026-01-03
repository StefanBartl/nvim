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

local function build_consumers()
  local consumers = {}

  local ok, tests_source = pcall(require, "neo-tree.sources.tests")
  if ok and tests_source then
    if type(tests_source.setup) == "function" then
      consumers.neotree = tests_source.setup
    elseif type(tests_source) == "function" then
      consumers.neotree = tests_source
    else
      -- Fallback: wrap in function
      consumers.neotree = function(_)
        return tests_source
      end
    end
  end

  return consumers
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
      "TimCreasman/neo-tree-tests-source.nvim",

      -- Language adapters (lazy-loaded per filetype)
      { "nvim-neotest/neotest-plenary", ft = "lua" },
      { "nvim-neotest/neotest-vim-test", ft = { "vim", "lua", "sh", "bash", "zsh", "asm" } },
      { "nvim-neotest/neotest-go", ft = "go" },
      { "nvim-neotest/neotest-python", ft = "python" },
      { "rouge8/neotest-rust", ft = "rust" },
      { "nvim-neotest/neotest-jest", ft = { "javascript", "typescript", "javascriptreact", "typescriptreact" } },
      { "marilari88/neotest-vitest", ft = { "javascript", "typescript", "javascriptreact", "typescriptreact" } },
    },

    cmd = {
      "NeotestActions",
      "NeotestRunNearest",
      "NeotestRunFile",
      "NeotestRunAll",
      "NeotestDebugNearest",
      "NeotestSummaryToggle",
      "NeotestOutput",
      "NeotestOutputPanelToggle",
      "NeotestStop",
      "NeotestWatchToggle",
    },
    keys = {
      "<leader>ntt",
      "<leader>ntf",
      "<leader>nta",
      "<leader>ntd",
      "<leader>nts",
      "<leader>nto",
      "<leader>ntO",
      "<leader>ntS",
      "<leader>ntw",
    },

    lazy = true,
    opts = function()
      return {
        adapters = build_adapters(),
        consumers = build_consumers(),

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

      require("config.neotest.commands").setup()
      require("config.neotest.keymaps").setup()
      require("config.neotest.whichkey").setup()

      -- Setup language-specific configurations
      local ok_core, core_cfg = pcall(require, "config.neotest.core")
      if ok_core and type(core_cfg.setup) == "function" then
        core_cfg.setup()
      end
    end,
  },
}
