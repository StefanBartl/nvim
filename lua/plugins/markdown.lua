---@module 'plugins.markdown'
--- Markdown support including syntax highlighting and browser preview.

---@type LazyPluginSpec[]
return {

  ---@type LazyPluginSpec
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown" },
    opts = {
      theme = "dark", -- optional
    },
    config = function(_, opts)
      require("render-markdown").setup(opts)
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "markdown",
        callback = function()
          require("render-markdown").enable()
        end,
      })
    end,
  },

  ---@type LazyPluginSpec
  {
    'brianhuster/live-preview.nvim',
    dependencies = {
      'ibhagwan/fzf-lua',
    },
    lazy = false,
  },

}
