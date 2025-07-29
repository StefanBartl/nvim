---@module 'plugins.markdown'
--- Markdown support including syntax highlighting and browser preview.

---@type LazyPluginSpec[]
return {

  -- Markdown Preview: Opens Markdown files in the browser
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    ft = { "markdown" },
    build = function()
      vim.fn["mkdp#util#install"]()
    end,
  },

  -- Vim-Markdown: Enhanced Markdown syntax highlighting and checkboxes
  {
    "preservim/vim-markdown",
    ft = { "markdown" },
  },

}

