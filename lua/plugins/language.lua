---@module 'plugins.language'
--- language.nvim — spell/grammar review (:Spellcheck) and translation
--- (:Translate) in one plugin. Replaces the former config/trouble/spell and
--- config/translate modules and the uga-rosa/translate.nvim dependency.
---
--- Uses the same local-dev resolution as the personal plugin specs: loads from
--- the local repos folder when present, otherwise falls back to the remote.

local personal_utils = require("plugins.personal.utils")

---@type LazyPluginSpec[]
return {
  {
    "StefanBartl/language.nvim",
    dir = personal_utils.local_dev("language.nvim"),
    event = "VeryLazy",
    dependencies = {
      "StefanBartl/lib.nvim",
      "folke/trouble.nvim", -- optional: nicer list; pcall-guarded in the plugin
    },
    config = function()
      require("language").setup({
        spell = {
          -- Panel is the default UI; set view = "quickfix" for the classic
          -- diagnostics + quickfix session flow instead.
          ui = { view = "picker", preview = true },
          programming_dict = true,
        },
      })
    end,
  },
}
