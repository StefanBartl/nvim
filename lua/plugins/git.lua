---@module 'plugins.git'
--- Git integration via LazyGit, Gitsigns, and visual diff tools.

---@type LazyPluginSpec[]
return {

  -- LazyGit: External Git TUI (via `lazygit`)
  {
    "kdheepak/lazygit.nvim",
    lazy = true,
    cmd = {
      "LazyGit",
      "LazyGitConfig",
      "LazyGitCurrentFile",
      "LazyGitFilter",
      "LazyGitFilterCurrentFile",
      "LazyGitLog",
    },
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>lg", "<cmd>LazyGit<cr>", desc = "[LazyGit] Open UI" },
    },
    config = function()
      -- Setzt den Editor-Befehl explizit für die Sub-Prozesse von Neovim
      vim.g.lazygit_use_neovim_remote = 1 -- Nutzt das interne nvim-remote Feature falls verfügbar

      require("config.lazygit").setup()
    end,
  },

  -- -- Gitsigns: Git hunks, blame, stage/unstage in signcolumn
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    config = true,
  },

  -- Diffview: Side-by-side Git diffs
  {
    "sindrets/diffview.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    cmd = {
      "DiffviewOpen",
      "DiffviewClose",
      "DiffviewToggleFiles",
      "DiffviewFocusFiles",
      "DiffviewFileHistory",
    },
    -- lazy = true,
    config = true,
  },

  -- Neogit: Magit-like UI, integrates well with Diffview
  {
    "NeogitOrg/neogit",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "sindrets/diffview.nvim", -- optional but recommended
    },
    cmd = "Neogit",
    keys = {
      { "<leader>gg", "<cmd>Neogit kind=split<cr>", desc = "Neogit (split)" },
    },
    opts = {
      kind = "split",
      integrations = { diffview = true }, -- use Diffview for diffs
    },
  },

  -- Fugitive: lightweight, CLI-oriented Git inside Neovim
  -- :Git, :Gstatus (via :Git), :Gdiffsplit, :Gblame, :Gbrowse (mit rhubarb)
  {
    "tpope/vim-fugitive",
    event = "VeryLazy", -- or load on Git buffers: "BufReadPost"
    keys = {
      -- Diff current file vs HEAD
      { "<leader>gd", "<cmd>Gdiffsplit<cr>", desc = "Git diff split" },
      -- Blame
      { "<leader>gb", "<cmd>Git blame<cr>", desc = "Git blame" },
    },
  },
  {
    -- Optional: :Gbrowse to open current file/selection in hosting provider
    "tpope/vim-rhubarb",
    event = "VeryLazy",
    dependencies = { "tpope/vim-fugitive" },
  },

  {
    "akinsho/git-conflict.nvim",
    version = "*",
    config = true,
    lazy = false,
  },
}
