---@module 'plugins.avante'
---
--- Lazy.nvim specification for Avante.
--- The complete provider configuration is located in plugins.ai.

return {
  "yetone/avante.nvim",
  event = "VeryLazy",
  version = false,
  build = "make",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    "echasnovski/mini.pick",
    "nvim-treesitter/nvim-treesitter",
    "stevearc/dressing.nvim",
    "ibhagwan/fzf-lua",
    "zbirenbaum/copilot.lua",
    "MeanderingProgrammer/render-markdown.nvim",
  },

  config = function()
    local avante_opts = require("config.ai.anthropic")
    require("avante").setup(avante_opts)
  end,
}
