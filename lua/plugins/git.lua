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

  -- vim-fugitive/vim-rhubarb removed (gitsuite.nvim, plugins/personal/init.lua):
  -- both `:Git blame` (`<leader>gb`) and `:Gbrowse` are now gitsuite.nvim's
  -- own `:Git blame full`/`:Git browse *`, and fugitive's own `:Git` command
  -- would collide with gitsuite.nvim's if both were loaded.

  -- akinsho/git-conflict.nvim removed: gitsuite.nvim's `:Git conflict *`
  -- (plugins/personal/init.lua) covers the same nine commands and the same
  -- six buffer-local keys (co/ct/cb/c0/]x/[x) now, with its own
  -- BufReadPost/BufNewFile marker scan -- keeping both installed would have
  -- meant two plugins racing to set the identical buffer-local keys the
  -- moment a conflict is found, an actual behavioural collision, not just a
  -- redundant install.
}
