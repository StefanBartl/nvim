---@module 'plugins.git'
--- Git integration via Gitsigns and visual diff tools -- gitsuite.nvim's own
--- command tree (plugins/personal/init.lua) owns everything else that used
--- to live here.

---@type LazyPluginSpec[]
return {

  -- kdheepak/lazygit.nvim removed: gitsuite.nvim's `:Git ui lazygit`
  -- (plugins/personal/init.lua) opens the same real `lazygit` binary in its
  -- own floating terminal now, plus the nvr O/<C-o> bridge this plugin's
  -- config used to own (ported to gitsuite.nvim's
  -- features/ui/lazygit/{badd,replace}.lua -- lua/config/lazygit/ removed).

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
