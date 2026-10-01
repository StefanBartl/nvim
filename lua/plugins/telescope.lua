---@module 'plugins.telescope'
---@brief Telescope plugin configuration.
---@description History is owned by pickers.nvim (StefanBartl/pickers.nvim,
---history.fzf_scope = "patch"), which patches telescope's defaults.history itself.

return {
  ------------------------------------------------------------------------------
  -- Telescope core
  ------------------------------------------------------------------------------
  {
    "nvim-telescope/telescope.nvim",
    cmd = "Telescope",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",

      -- Optional GitHub extension
      { "nvim-telescope/telescope-github.nvim", lazy = true },
    },

    opts = function(_, opts)
      return require("config.telescope").setup(opts)
    end,
  },

  ------------------------------------------------------------------------------
  -- fzf-native: compiled sorter
  ------------------------------------------------------------------------------
  {
    "nvim-telescope/telescope-fzf-native.nvim",
    build = (function()
      if vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
        return table.concat({
          "cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release",
          "cmake --build build --config Release",
          "cmake --install build --prefix build",
        }, " && ")
      else
        return "make"
      end
    end)(),
    lazy = true,
  },

  ------------------------------------------------------------------------------
  -- Telescope File Browser extension
  ------------------------------------------------------------------------------
  {
    "nvim-telescope/telescope-file-browser.nvim",
    dependencies = {
      "nvim-telescope/telescope.nvim",
      "nvim-lua/plenary.nvim",
    },
    lazy = true,
  },

  -- search.nvim (tabbed UI) left on 2026-10-01: pickers.nvim's `tabs` is the
  -- replacement (`<leader>s` -> `:Pickers tabs default`, groups in
  -- plugins/personal/specs/navigate.lua), engine-neutral instead of telescope-only.
}
