---@module 'plugins.personal'
--- Personal and local development plugins with smart local/remote fallback.

local personal_utils = require("plugins.personal.utils")
local local_dev = personal_utils.local_dev

---@type LazyPluginSpec[]
return {

  -- ==========================================================================
  -- 1. CORE / INFRASTRUCTURE, UTILITIES & SYSTEM
  -- ==========================================================================

  {
    "StefanBartl/lib.nvim",
    dir = local_dev("lib.nvim"),
    lazy = false,
    priority = 1000,
  },

  {
    "StefanBartl/pickers.nvim",
    dir = local_dev("pickers.nvim"),
    lazy = false,
    dependencies = { "StefanBartl/lib.nvim" },
    config = function()
      local repos = personal_utils.repos_path
      require("pickers").setup({
        engine    = "auto",
        repos_dir = repos,
        collections = {
          {
            name = "notes",
            dir  = repos .. "/Notes",
            keys = { files = "<leader>mnf", grep = "<leader>mng" },
          },
          {
            name = "notes_lua",
            dir  = repos .. "/Notes/MyNotes/Lua",
            keys = { files = "<leader>mlf", grep = "<leader>mlg" },
          },
          {
            name = "notes_nvim",
            dir  = repos .. "/Notes/MyNotes/Neovim",
            keys = { files = "<leader>mvf", grep = "<leader>mvg" },
          },
          {
            name = "checklists",
            dir  = repos .. "/Notes/MyNotes/Checklists",
            keys = { files = "<leader>chf", grep = "<leader>chg" },
          },
          {
            name = "spickzettel",
            dir  = repos .. "/Notes/spickzettel",
            keys = { files = "<leader>spf", grep = "<leader>spg" },
          },
          {
            name   = "wkdbooks",
            dir    = repos .. "/WKDBooks",
            prefix = "wkdbook-",
            keys   = { files = "<leader>wkf", grep = "<leader>wkg" },
          },
          {
            name = "wkdbooks_lua",
            dir  = repos .. "/WKDBooks/Development/wkdbook-Lua",
            keys = { files = "<leader>wlf", grep = "<leader>wlg" },
          },
          {
            name = "wkdbooks_nvim",
            dir  = repos .. "/WKDBooks/Development/wkdbook-Neovim",
            keys = { files = "<leader>wvf", grep = "<leader>wvg" },
          },
        },
      })
    end,
  },

  {
    "StefanBartl/buffer-ctx.nvim",
    dir = local_dev("buffer-ctx.nvim"),
    cmd = { "Insert", "Copy" },
    keys = { "<leader>cnl", "<leader>cnm", "<leader>cnf" },
    opts = {
      commands = true,
      keymaps = {
        location_copy = "<leader>cnl",
        module_copy = "<leader>cnm",
        filepath_copy = "<leader>cnf",
      },
    },
    config = function(_, opts)
      require("buffer_ctx").setup(opts)
    end,
  },

  {
    "StefanBartl/open.nvim",
    dir = local_dev("open.nvim"),
    cmd = "Open",
    dependencies = { "StefanBartl/lib.nvim" },
    opts = {},
    config = function(_, opts)
      require("open_nvim").setup(opts)
    end,
  },

  -- {
  --   "StefanBartl/monkeypatch.nvim",
  --   dir = local_dev("monkeypatch.nvim"),
  --   lazy = false,
  --   config = function()
  --     require("monkeypatch").setup({
  --       strategy_order = { "diff", "semantic" },
  --       enabled_strategies = {
  --         diff = true,
  --         semantic = true,
  --         treesitter = false,
  --       },
  --       max_concurrency = 3,
  --       timeout_ms = 30000,
  --       notify = true,
  --       verbose = false,
  --       lazy_update_delay_ms = 1000,
  --       diff_fuzz_factor = 2,
  --       semantic_strict = true,
  --     })
  --   end,
  -- },

  -- {
  --   "StefanBartl/nvim-containers",
  --   dir = local_dev("nvim-containers"),
  --   event = "VeryLazy",
  --   config = function()
  --     require("containers").setup({})
  --   end,
  -- },

  -- ==========================================================================
  -- 2. NAVIGATION, FILE SYSTEM, SEARCH & TREES
  -- ==========================================================================

  {
    "StefanBartl/fileops.nvim",
    dir = local_dev("fileops.nvim"),
    event = "VeryLazy",
    opts = {
      cycle = {
        open_target = "current",
        keep_focus = true,
        include_hidden = false,
        wrap = true,
        follow_symlinks = true,
        root = "buffer_dir",
        confirm_on_modified = true,
        case_insensitive = true,
      },
      keymaps = { cycle = true, delete = true },
      commands = true,
    },
  },

  {
    "StefanBartl/gopath.nvim",
    dir = local_dev("gopath.nvim"),
    event = "VeryLazy",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    opts = {
      mode = "hybrid",
      alternate = {
        enable = true,
        similarity_threshold = 75,
      },
      external = {
        enable = true,
      },
      mappings = {
        open_here = { "gF", "<2-LeftMouse>" },
        open_split = "g|",
        open_vsplit = "g\\",
        open_tab = "g}",
        copy_location = "gY",
        debug = "g?",
      },
    },
  },

  {
    "StefanBartl/replacer",
    dir = local_dev("replacer"),
    cmd = { "Replace" },
    dependencies = { "ibhagwan/fzf-lua" },
    config = function()
      require("replacer").setup({
        engine = "telescope",
        default_scope = "%",
      })
    end,
  },

  {
    "StefanBartl/project-insight.nvim",
    dir = local_dev("project-insight.nvim"),
    cmd = "ProjectInsight",
    config = function()
      require("project_insight").setup({})
    end,
  },

  -- {
  --   "StefanBartl/neotree-fs-refactor",
  --   dir = local_dev("neotree-fs-refactor.nvim"),
  --   lazy = false,
  --   config = function()
  --     require("neotree-fs-refactor").setup({
  --       enabled = false,
  --       auto_save = true,
  --       notify_on_refactor = true,
  --       ignore_patterns = require("lib.nvim.fs.ignore.list").as_luals_patterns(),
  --       file_types = {
  --         lua = true,
  --         typescript = true,
  --         javascript = true,
  --         typescriptreact = true,
  --         javascriptreact = true,
  --         python = true,
  --       },
  --       max_file_size = 10 * 1024 * 1024,
  --       debounce_ms = 10,
  --     })
  --   end,
  -- },

  -- {
  --   "StefanBartl/filetreepicker.nvim",
  --   dir = local_dev("filetreepicker.nvim"),
  --   event = "VeryLazy",
  --   dependencies = { "nvim-neo-tree/neo-tree.nvim" },
  --   config = function()
  --     require("filetreepicker").setup({})
  --   end,
  -- },

  -- {
  --   "StefanBartl/reposcope.nvim",
  --   dir = local_dev("reposcope.nvim"),
  --   name = "reposcope",
  --   event = "VeryLazy",
  --   config = function()
  --     require("reposcope.init").setup({})
  --   end,
  -- },

  -- {
  --   "StefanBartl/mygrep.nvim",
  --   dir = local_dev("mygrep.nvim"),
  --   name = "mygrep",
  --   lazy = false,
  --   config = function()
  --     require("mygrep").setup({
  --       tool_picker_style = "ui",
  --     })
  --   end,
  -- },

  -- ==========================================================================
  -- 3. CODE QUALITY, UI, LOGGING & PRODUCTIVITY
  -- ==========================================================================

  {
    "StefanBartl/debugging.nvim",
    dir = local_dev("debugging.nvim"),
    cmd = "Debug",
    dependencies = { "StefanBartl/lib.nvim" },
    opts = {
      features = { neotree = false },
    },
    config = function(_, opts)
      require("debugging").setup(opts)
    end,
  },

  {
    "StefanBartl/diff.nvim",
    dir = local_dev("diff.nvim"),
    cmd = { "Diff", "DiffClear", "DiffOrig", "DiffExit" },
    opts = {
      features = {
        diff = true,
        diff_origin = true,
        diff_exit = true,
      },
    },
    config = function(_, opts)
      require("diff_nvim").setup(opts)
    end,
  },

  {
    "StefanBartl/nvim-cmdlog",
    dir = local_dev("nvim-cmdlog"),
    lazy = false,
    cmd = { "CmdlogOpen", "CmdlogSearch" },
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("cmdlog").setup({
        picker = "telescope",
      })
    end,
  },

  {
    "StefanBartl/telescope-selected-index",
    dir = local_dev("telescope-selected-index"),
    event = "VeryLazy",
    opts = {
      position = "right_align",
      highlight = {
        preset = "error",
      },
    },
    config = function(_, opts)
      require("telescope_selected_index").setup(opts)
    end,
  },

  {
    "StefanBartl/emojis.nvim",
    dir = local_dev("emojis.nvim"),
    cmd = "Emojis",
    opts = {
      default_scope = "%",
    },
    config = function(_, opts)
      require("emojis").setup(opts)
    end,
  },

  -- {
  --   "StefanBartl/github_stats.nvim",
  --   dir = local_dev("github_stats.nvim"),
  --   lazy = false,
  --   config = function()
  --     require("github_stats").setup({
  --       notify_fetch = false,
  --       config_dir = vim.fn.stdpath("config") .. "/lua/plugins/github-stats",
  --       data_dir = vim.fn.stdpath("config") .. "/lua/plugins/github-stats/data"
  --     })
  --   end,
  -- },

  -- {
  --   "StefanBartl/learn-cli.nvim",
  --   dir = local_dev("learn-cli.nvim"),
  --   lazy = false,
  --   config = function()
  --     require("learn_cli").setup({
  --       exercises_dir = vim.fs.joinpath(vim.fn.stdpath("config"), "lua", "plugins", "learn-cli.nvim", "exercises"),
  --     })
  --   end,
  -- },

  -- ==========================================================================
  -- 4. FILE TYPES (MARKDOWN & DOCUMENTS)
  -- ==========================================================================

  {
    "StefanBartl/pdfport.nvim",
    dir = local_dev("pdfport.nvim"),
    cmd = {
      "PdfPort",
      "PdfPortText",
      "PdfPortFloat",
      "PdfPortSystem",
      "PdfPortTerminal",
      "PdfPortHealth",
    },
    opts = {
      default_backend = "auto",
      fallback_chain = { "pdftotext", "pdfplumber", "marker", "docling", "ollama", "claude" },
      extract_opts = { max_pages = nil, timeout_ms = 30000 },
      render_opts = { mode = "buffer", split = "current", focus = true },
      claude_api_key = nil,
      ollama_host = "http://localhost:11434",
      ollama_model = "qwen2.5-coder:7b",
      debug = false,
    },
  },

  {
    "StefanBartl/markdown.nvim",
    dir = local_dev("markdown.nvim"),
    ft = { "markdown", "mdx", "md" },
    config = function()
      require("markdown_nvim").setup()
    end,
  },

  {
    "StefanBartl/mdlinks",
    dir = local_dev("mdlinks"),
    ft = "*",
    config = function()
      require("mdlinks.config").setup({
        debug = true,
        open_url_cmd = { "cmd.exe", "/c", "start", "" },
        open_cmd = { "cmd.exe", "/c", "start", "" },
        anchor_levels = { 1, 2, 3, 4, 5, 6 },
      })
    end,
  },

  {
    "StefanBartl/color_my_ascii.nvim",
    dir = local_dev("color_my_ascii.nvim"),
    ft = "markdown",
    config = function()
      require("color_my_ascii").setup({
        debug_enabled = false,
        debug_verbose = false,
        scheme = "default",
        enable_keywords = true,
        enable_language_detection = true,
        language_detection_threshold = 2,
        enable_function_names = true,
        enable_bracket_highlighting = true,
        treat_empty_fence_as_ascii = true,
        enable_inline_code = true,
      })
    end,
  },

  {
    "StefanBartl/recommender.nvim",
    dir = local_dev("recommender.nvim"),
    ft = { "lua" },
    cmd = { "Recommender" },
    config = function()
      require("recommender_nvim").setup()
    end,
  },

  -- {
  --   "StefanBartl/mdview.nvim",
  --   dir = local_dev("mdview.nvim"),
  --   name = "mdview.nvim",
  --   lazy = false,
  --   cmd = { "MarkdownViewStart", "MarkdownViewStop" },
  --   config = function()
  --     if pcall(require, "mdview") then
  --       require("mdview").setup()
  --     else
  --       vim.notify("mdview.nvim: module not found after loading plugin files", vim.log.levels.ERROR)
  --     end
  --   end,
  -- },
}
