---@module 'plugins.personal'
--- Personal and local development plugins (myterm, mygrep, cmdlog, etc.)

if not vim.env.REPOS_DIR then
  vim.notify("[PLUGINS PERSONAL] Environment variable 'REPOS_DIR' not set. Personal plugins not available.", 3)
  return {}
end

---@type LazyPluginSpec[]
return {

  {
    -- "StefanBartl/color_my_ascii.nvim",
    dir = vim.fn.expand(vim.env.REPOS_DIR .. "/color_my_ascii.nvim"),
    ft = "markdown",
    config = function()
      require("color_my_ascii").setup({
        debug_enabled = true,
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
  --   "StefanBartl/telescope-selected-index",
  --   -- dir = vim.env.REPOS_DIR .. "/telescope-selected-index",
  --   event = "VeryLazy",
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

  {
    -- "StefanBartl/nvim-cmdlog",
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

  -- {
  -- 	dir = [[E:\repos\objtrack]], -- Repo-Root mit lua/ darunter
  -- 	name = "objtrack",
  -- 	main = "objtrack",         -- lädt lua/objtrack/init.lua als Haupteinstieg
  -- 	lazy = false,              -- fürs Debuggen: hart beim Start laden
  -- 	config = function()
  -- 		require("objtrack").setup({
  -- 			view_mode = "float",
  -- 			prefer_telescope = true,
  -- 			auto_rescan = false,
  -- 			border = "rounded",
  -- 			max_preview_lines = 5000,
  -- 			blacklist_filetypes = { "help", "TelescopePrompt", "neo-tree", "lazy" },
  -- 			keymaps = { pick = "<leader>op", rescan = "<leader>os" },
  -- 		})
  -- 	end,
  -- },

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
      ---@diagnostic disable-next-line
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
      -- mappings = {
      --   open_here = "gP", -- Open in current window
      --   open_split = "g|", -- Open in horizontal split
      --   open_vsplit = "g\\", -- Open in vertical split
      --   open_tab = "g}", -- Open in new tab
      --   copy_location = "gY", -- Copy path:line:col
      --   debug = "g?", -- Debug resolution
      --   -- Set any to false to disable
      -- },
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
    dir = vim.fn.expand(vim.env.REPOS_DIR .. "/mdlinks"),
    -- "StefanBartl/mdlinks",
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

  -- nvim-containers: Manage container engines from Neovim
  -- {
  --   dir = vim.fs.joinpath(vim.env.REPOS_DIR, "/nvim-containers"),
  --   event = "VeryLazy",
  --   config = function()
  --     require("containers").setup({})
  --   end,
  -- },
  --
  -- nvim-cmdlog: Command history management (remote plugin)
  -- Optional: local dev version of cmdlog
  -- {
  --   dir = repo("nvim-cmdlog"),
  --   cond = exists(repo("nvim-cmdlog")),
  --   config = function()
  --     require("cmdlog").setup({ picker = "telescope" })
  --   end,
  -- },

  --[[

    -- reposcope.nvim: GitHub repo explorer
    {
      dir = repo("reposcope.nvim"),
      cond = exists(repo("reposcope.nvim")),
      name = "reposcope",
      event = "VeryLazy",
      config = function()
        require("reposcope.init").setup({})
      end,
    },

    ]]
  --

  -- myterm.local: Custom terminal interface with layout switching
  --[[
    {
      name = "myterm.local",
      dir = myterm_local_dir(),
      cond = exists(myterm_local_dir()),
      lazy = false,
      config = function()
        require("custom.myterm")
      end,
    },
    ]]
  --

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
