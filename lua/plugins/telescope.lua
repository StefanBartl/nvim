---@module 'plugins.telescope'
---@brief Telescope plugin configuration with modular history backend support.

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

      {
        "nvim-telescope/telescope-smart-history.nvim",
        dependencies = {
          "3rd/sqlite.nvim",
        },
      },

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

  ------------------------------------------------------------------------------
  -- search.nvim (Tabbed UI wrapper)
  ------------------------------------------------------------------------------
  {
    "FabianWirth/search.nvim",
    dependencies = { "nvim-telescope/telescope.nvim" },
    keys = {
      {
        "<leader>s",
        function()
          require("search").open()
        end,
        desc = "Search (tabbed UI)",
      },
    },
    config = function()
      require("config.search").setup()
    end,
  },
}
