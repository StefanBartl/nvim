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
      -- Explicitly sets the editor command for Neovim's sub-processes
      vim.g.lazygit_use_neovim_remote = 1 -- uses the internal nvim-remote feature if available

      require("config.lazygit").setup()
    end,
  },

  -- Gitsigns: Git hunks, blame, stage/unstage in signcolumn
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
  -- :Git, :Gstatus (via :Git), :Gblame, :Gbrowse (with rhubarb)
  --
  -- `<leader>gd` used to be `:Gdiffsplit` here. It is diff.nvim's
  -- `:Diff target=git:HEAD` now (plugins/personal/init.lua) -- the same
  -- file-vs-HEAD diff, in the plugin that already owns every other diff
  -- view in this config. Blame is the one fugitive feature left in use.
  {
    "tpope/vim-fugitive",
    event = "VeryLazy", -- or load on Git buffers: "BufReadPost"
    keys = {
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
    -- Conflict markers live in a buffer's text, so there is nothing to detect
    -- before one is read. BufReadPost is also early enough for the first
    -- buffer: the plugin's own scan hangs off BufEnter, which fires *after*
    -- BufReadPost, so the file opened on the command line is still seen.
    event = { "BufReadPost", "BufNewFile" },
  },
}
