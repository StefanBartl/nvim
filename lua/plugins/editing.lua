---@module 'plugins.editing'
--- Editing tools: commenting, autotags, templates, quickfix enhancements, TODOs.

---@type LazyPluginSpec[]
return {

  -- Auto Template Strings for JS/TS
  {
    "chrisgrieser/nvim-puppeteer",
    lazy = false,
  },

   -- Treesitter-based HTML tag closing and renaming
  {
    "windwp/nvim-ts-autotag",
    opts = function()
      return {
        enable_close = true,
        enable_rename = true,
        enable_close_on_slash = false,
        per_filetype = {
          html = { enable_close = false },
        },
      }
    end,
    config = function(_, opts)
      require("nvim-ts-autotag").setup(opts)
    end,
  },

   {
     "mg979/vim-visual-multi",
     branch = 'master',
     lazy = false,
   },
}
