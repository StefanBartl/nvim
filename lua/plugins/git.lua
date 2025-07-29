---@module 'plugins.git'
--- Git integration via LazyGit, Gitsigns, and visual diff tools.

---@type LazyPluginSpec[]
return {

  -- LazyGit: External Git TUI (via `lazygit`)
  {
    "kdheepak/lazygit.nvim",
    lazy = true,
    cmd = {
      "LazyGit", "LazyGitConfig", "LazyGitCurrentFile",
      "LazyGitFilter", "LazyGitFilterCurrentFile",
    },
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>lg", "<cmd>LazyGit<cr>", desc = "[LazyGit] Open UI" },
    },
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
    requires = { "nvim-lua/plenary.nvim" },
    lazy = false,
    config = true,
  },

}

