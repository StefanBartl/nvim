---@module 'plugins.personal'
--- Personal and local development plugins (myterm, mygrep, cmdlog, etc.)

if not vim.env.REPOS_DIR then
  vim.notify(
    "[PLUGINS PERSONAL] Environment variable 'REPOS_DIR' not set. Personal plugins not available.",
    5
  )
  return {}
end

-- local plugins_folder = vim.fn.stdpath("config") .. "/lua/plugins"

---@type LazyPluginSpec[]
return {

  -- lib.nvim is bootstrapped early in init.lua (it is required already during
  -- the plugin spec-import phase). This spec only lets lazy manage updates;
  -- lazy = false because it is effectively always loaded.
  {
    -- "StefanBartl/lib.nvim",
    dir = vim.env.REPOS_DIR .. "/lib.nvim",
    lazy = false,
    priority = 1000,
  },

  {
    -- "StefanBartl/pdfport.nvim",
    dir = vim.env.REPOS_DIR .. "/pdfport.nvim",
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
    -- "StefanBartl/pickers.nvim",
    dir = vim.env.REPOS_DIR .. "/pickers.nvim",
    lazy = false,
    dependencies = { "StefanBartl/lib.nvim" },
    config = function()
      require("pickers").setup({
        engine = "auto",
        repos_dir = vim.env.REPOS_DIR,
      })
    end,
  },

  {
    -- "StefanBartl/project-insight.nvim",
    dir = vim.env.REPOS_DIR .. "/project-insight.nvim",
    cmd = "ProjectInsight",
    config = function()
      require("project_insight").setup({
        -- symbols.use_treesitter_for_lua = true,  -- optionale TS-Variante für Lua
      })
    end,
  },

  {
    -- "StefanBartl/fileops.nvim",
    dir = vim.env.REPOS_DIR .. "/fileops.nvim",
    event = "VeryLazy",
    opts = {
      cycle = {
        open_target         = "current",
        keep_focus          = true,
        include_hidden      = false,
        wrap                = true,
        follow_symlinks     = true,
        root                = "buffer_dir",
        confirm_on_modified = true,
        case_insensitive    = true,
      },
      keymaps   = { cycle = true, delete = true },
      commands  = true,
    },
  },

  {
    -- "StefanBartl/buffer-ctx.nvim"
    dir = vim.env.REPOS_DIR .. "/buffer-ctx.nvim",
    cmd = { "Insert", "Copy" },
    keys = { "<leader>cnl", "<leader>cnm", "<leader>cnf" },
    opts = {
      commands = true,
      keymaps = {
        location_copy = "<leader>cnl",
        module_copy   = "<leader>cnm",
        filepath_copy = "<leader>cnf",
      },
    },
    config = function(_, opts)
      require("buffer_ctx").setup(opts)
    end,
  },

  {
    -- "StefanBartl/diff.nvim"
    dir = vim.env.REPOS_DIR .. "/diff.nvim",
    cmd = { "Diff", "DiffClear", "DiffOrig", "DiffExit" },
    opts = {
      features = {
        diff        = true,
        diff_origin = true,
        diff_exit   = true,
      },
    },
    config = function(_, opts)
      require("diff_nvim").setup(opts)
    end,
  },

  {
    -- "StefanBartl/emojis.nvim"
    dir = vim.env.REPOS_DIR .. "/emojis.nvim",
    cmd = "Emojis",
    opts = {
      default_scope = "%",
    },
    config = function(_, opts)
      require("emojis").setup(opts)
    end,
  },

  {
    -- "StefanBartl/debugging.nvim"
    dir = vim.env.REPOS_DIR .. "/debugging.nvim",
    cmd = "Debug",
    dependencies = { "StefanBartl/lib.nvim" },
    opts = {
      -- neotree stays opt-in; flip to true if the config.neotree.* layer is present
      features = { neotree = false },
    },
    config = function(_, opts)
      require("debugging").setup(opts)
    end,
  },

  {
    -- "StefanBartl/markdown.nvim",
    dir = vim.env.REPOS_DIR .. "/markdown.nvim",
    ft = { "markdown", "mdx", "md" },
    config = function()
      require("markdown_nvim").setup()
    end,
  },
  {
    -- "StefanBartl/recommender.nvim",
    dir = vim.env.REPOS_DIR .. "/recommender.nvim",
    ft = { "lua" },
    cmd = { "Recommender" },
    config = function()
      require("recommender_nvim").setup()
    end,
  },

  {
    "StefanBartl/nvim-cmdlog",
    dir = vim.env.REPOS_DIR .. "/nvim-cmdlog",
    lazy = false,
    cmd = { "CmdlogOpen", "CmdlogSearch" }, -- or map keys
    -- keys = {
    -- 	{ "<leader>cl", "<cmd>CmdlogOpen<cr>", desc = "Cmdlog: Open" },
    -- },
    dependencies = {
      "nvim-lua/plenary.nvim",
      -- do NOT hard-depend on telescope if you also support fzf-lua
      -- load whichever backend on demand in your code
      -- { "nvim-telescope/telescope.nvim" },
      -- { "ibhagwan/fzf-lua",             optional = true },
    },
    config = function()
      require("cmdlog").setup({
        -- defer backend require until actually used
        picker = "telescope",
        -- picker = "fzf",
      })
    end,
  },

  {
    dir = vim.fn.expand(vim.env.REPOS_DIR .. "/replacer"),
    -- "StefanBartl/replacer",
    cmd = { "Replace" },
    dependencies = {
      -- wähle je nach Engine:
      "ibhagwan/fzf-lua", -- für engine="fzf"
      -- "nvim-telescope/telescope.nvim", -- für engine="telescope"
    },
    config = function()
      require("replacer").setup({
        engine = "telescope",
        -- engine = "telescope",
        default_scope = "%",
      })
    end,
  },

  {
    dir = vim.env.REPOS_DIR .. "/gopath.nvim",
    -- "StefanBartl/gopath.nvim",
    event = "VeryLazy",
    dependencies = {
      "nvim-treesitter/nvim-treesitter", -- Optional but recommended
    },
    opts = {
      mode = "hybrid", -- "hybrid" | "lsp" | "treesitter" | "builtin"

      -- Fuzzy alternate resolution
      alternate = {
        enable = true,
        similarity_threshold = 75, -- 0-100
      },

      -- External file opening
      external = {
        enable = true,
      },

      -- -- Custom keymaps (optional - defaults shown)
      mappings = {
        open_here = { "gF", "<2-LeftMouse>" },
        --   open_here = "gP", -- Open in current window
        open_split = "g|", -- Open in horizontal split
        open_vsplit = "g\\", -- Open in vertical split
        open_tab = "g}", -- Open in new tab
        copy_location = "gY", -- Copy path:line:col
        debug = "g?", -- Debug resolution
      },
      --
      -- -- User commands (optional)
      -- commands = {
      --   resolve = true, -- :GopathResolve
      --   open = true, -- :GopathOpen [edit|window|vsplit|tab]
      --   copy = true, -- :GopathCopy
      --   debug = true, -- :GopathDebug
      -- },
    },
  },

  {
    -- dir = vim.fn.expand(vim.env.REPOS_DIR .. "/mdlinks"),
    "StefanBartl/mdlinks",
    ft = "*",
    config = function()
      require("mdlinks.config").setup({
        debug = true,
        open_url_cmd = { "cmd.exe", "/c", "start", "" },
        open_cmd = { "cmd.exe", "/c", "start", "" },
        anchor_levels = { 1, 2, 3, 4, 5, 6 }, -- ATX levels to match
      })
    end,
  },

  {
    "StefanBartl/color_my_ascii.nvim",
    dir = vim.fn.expand(vim.env.REPOS_DIR .. "/color_my_ascii.nvim"),
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
    "StefanBartl/telescope-selected-index",
    -- dir = vim.env.REPOS_DIR .. "/telescope-selected-index",
    event = "VeryLazy",
    opts = {
      position = "right_align", -- Position: "overlay" | "right_align" | "eol" | "top" | "down"
      highlight = {
        preset = "error",
        ---| "default"      # Default Telescope style (fg from TelescopeResultsFunction)
        ---| "subtle"       # Muted gray, low contrast
        ---| "bold"         # Bold white on dark background
        ---| "accent"       # Bright accent color (cyan/blue)
        ---| "minimal"      # Minimal styling, inherits most from buffer
        ---| "error"        # Red/warning style
        ---| "success"      # Green/success style
        ---| "custom"       # User provides complete HighlightSpec
        -- fully custom only when preset = "custom"
        -- custom = {
        --     fg = "#89dceb",
        --     bold = true,
        --     italic = true,
        -- },

        -- gruvbox
        -- preset = "custom",
        -- custom = {
        -- fg = "#fe8019",  -- Orange
        -- bg = "#3c3836",  -- Dark gray
        -- bold = true,
        -- },

        -- catpuccin mocha
        -- custom = {
        -- fg = "#f5c2e7",  -- Pink
        -- bold = true,
        -- italic = true,
        -- },
      },
    },

    config = function(_, opts)
      require("telescope_selected_index").setup(opts)
    end,
  },

  -- {
  -- -- "StefanBartl/neotree-fs-refactor",
  -- dir = vim.fn.expand(vim.env.REPOS_DIR .. "/neotree-fs-refactor.nvim"),
  -- lazy = false,
  -- config = function()
  -- -- require("neotree-fs-refactor").setup()
  -- require("neotree-fs-refactor").setup({
  -- enabled = false,
  -- auto_save = true, -- Enble auto-save for testing
  -- notify_on_refactor = true,

  -- -- Use minimal ignore patterns for testing
  -- ignore_patterns = require("lib.nvim.fs.ignore.list").as_luals_patterns(),

  -- -- Enable all file types
  -- file_types = {
  -- lua = true,
  -- typescript = true,
  -- javascript = true,
  -- typescriptreact = true,
  -- javascriptreact = true,
  -- python = true,
  -- },

  -- max_file_size = 10 * 1024 * 1024, -- 10MB for testing
  -- debounce_ms = 10, -- Shorter debounce for faster testing
  -- })
  -- end,
  -- },

  -- {
  --   "StefanBartl/github_stats.nvim",
  --  lazy = false,
  --  config = function()
  --    require("github_stats").setup({
  --      notify_fetch = false,
  --      config_dir = vim.fn.stdpath("config") .. "/lua/plugins/github-stats",
  --     data_dir = vim.fn.stdpath("config") .. "/lua/plugins/github-stats/data"
  --   })
  -- end,
  --},

  -- {
  --   -- 'StefanBartl/learn-cli.nvim',
  --   dir = vim.fn.expand(vim.env.REPOS_DIR .. "/learn-cli.nvim"),
  --   lazy = false,
  --   config = function()
  --     require("learn_cli").setup({
  --       exercises_dir = plugins_folder .. "learn-cli.nvim/exercises", FIX:
  --     })
  --   end,
  -- },

  -- {
  --   dir = vim.fn.expand(vim.env.REPOS_DIR .. "/monkeypatch.nvim"),
  --   lazy = false,
  --   config = function()
  --     require("monkeypatch").setup({
  --       -- Strategy execution order (first to last)
  --       strategy_order = { "diff", "semantic" },
  --
  --       -- Which strategies are enabled
  --       enabled_strategies = {
  --         diff = true,
  --         semantic = true,
  --         treesitter = false, -- Experimental
  --       },
  --
  --       -- Parallel patch operations
  --       max_concurrency = 3,
  --
  --       -- Per-patch timeout
  --       timeout_ms = 30000,
  --
  --       -- Show notifications
  --       notify = true,
  --
  --       -- Debug logging
  --       verbose = false,
  --
  --       -- Delay after LazyUpdate event
  --       lazy_update_delay_ms = 1000,
  --
  --       -- Diff fuzz factor (0-3)
  --       diff_fuzz_factor = 2,
  --
  --       -- Semantic mode: strict (reject on hash mismatch) or permissive (warn)
  --       semantic_strict = true,
  --     })
  --   end,
  -- },

  -- {
  --   -- Verwendung
  --   -- <leader>;    → Reveal current file
  --   -- 2<leader>;   → Reveal with 2 parent levels up
  --   -- <leader>:    → Open at cwd
  --   -- Im Picker: s → split mode, 05 → öffnet Index 05 im split
  --   "StefanBartl/filetreepicker.nvim",
  --   dir = vim.fn.expand(vim.env.REPOS_DIR .. "/filetreepicker.nvim"),
  --   event = "VeryLazy",
  --   dependencies = { "nvim-neo-tree/neo-tree.nvim" },
  --   config = function()
  --     require("filetreepicker").setup({})
  --   end,
  -- },

  -- {
  --   dir = vim.fn.expand(vim.env.REPOS_DIR .. "/mdview.nvim"),
  --   name = "mdview.nvim",
  --   lazy = false,
  --   -- do not automatically run setup; the plugin exposes :MarkdownViewStart / :MarkdownViewStop
  --   config = function()
  --     -- optional: expose server port if different than default
  --     -- vim.g.mdview_server_port = 43219
  --     -- minimal setup placeholder (future: require('mdview').setup({...}))
  --     if pcall(require, "mdview") then
  --       require("mdview").setup()
  --     else
  --       vim.notify("mdview.nvim: module not found after loading plugin files", vim.log.levels.ERROR)
  --     end
  --   end,
  --   -- make the commands discoverable to lazy if desired
  --   cmd = { "MarkdownViewStart", "MarkdownViewStop" },
  -- },

  -- nvim-containers: Manage container engines from Neovim
  -- {
  --    dir = vim.fs.joinpath(vim.env.REPOS_DIR, "/nvim-containers"),
  --   event = "VeryLazy",
  --   config = function()
  --     require("containers").setup({})
  --   end,
  -- },

  -- reposcope.nvim: GitHub repo explorer
  -- {
  -- dir = repo("reposcope.nvim"),
  -- cond = exists(repo("reposcope.nvim")),
  -- name = "reposcope",
  -- event = "VeryLazy",
  -- config = function()
  -- require("reposcope.init").setup({})
  -- end,
  -- },

  -- mygrep.nvim: Grep interface with memory, history, favorites
  -- {
  --   dir = repo("mygrep.nvim"),
  --   cond = exists(repo("mygrep.nvim")),
  --   name = "mygrep",
  --   lazy = false,
  --   config = function()
  --     require("mygrep").setup({
  --       tool_picker_style = "ui",
  --     })
  --   end,
  -- },
}
