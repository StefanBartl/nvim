---@module 'plugins.markdown'
--- Markdown support including syntax highlighting and browser preview.

---@type LazyPluginSpec[]
return {


--[[
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
  ]]--

{
  "iamcco/markdown-preview.nvim",
  cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
  build = "cd app && yarn install",
  init = function()
    vim.g.mkdp_filetypes = { "markdown" }
  end,
  ft = { "markdown" },
},

}
