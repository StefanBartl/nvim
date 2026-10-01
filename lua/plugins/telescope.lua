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

  -- telescope-file-browser.nvim left on 2026-10-01: its only user, <leader>,
  -- (bindings/mappings/telescope.lua), was never actually used and got
  -- dropped; pickers.builtins' "explorer" entry on the telescope engine
  -- already degrades gracefully (notify.error) without it installed.

  -- search.nvim (tabbed UI) left on 2026-10-01: pickers.nvim's `tabs` is the
  -- replacement (`<leader>s` -> `:Pickers tabs default`, groups in
  -- plugins/personal/specs/navigate.lua), engine-neutral instead of telescope-only.
}
