---@module 'plugins.markdown'
--- Markdown support including syntax highlighting and browser preview.

---@type LazyPluginSpec[]
return {

  ---@type LazyPluginSpec
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown" },
    cmd = { "RenderMarkdown" },
    opts = {
      enabled = false,
    },
  },

  {
    "ellisonleao/glow.nvim",
    cmd = "Glow",
    ft = { "markdown", "md" },
    config = function()
      ---@diagnostic disable-next-line "incomplete setup"
      require("glow").setup({
        glow_path = vim.fn.exepath("glow"), -- auto-detect from PATH
        border = "shadow",
        style = "dark",
        width = 120,
      })
    end,
  },

  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    ft = { "markdown" },
    -- build = function() vim.fn["mkdp#util#install"]() end, -- without yarn
    -- with yarn (only method tha work in Windows)
    build = "cd app && yarn install",
    init = function()
      vim.g.mkdp_filetypes = { "markdown" }
    end,
    config = function()
      require("config.markdown_preview").setup()
    end,
  },
}
