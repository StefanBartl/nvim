-- markdown.lua
return {

  -- render-markdown.nvim: installed disabled; toggled via `:Markdown render`
  -- (markdown.nvim owns the toggle command).
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown" },
    cmd = { "RenderMarkdown" },
    config = function()
      require("render-markdown").setup({ enabled = false })
    end,
  },
  -- markdown-preview.nvim: configured via vim.g; controlled via
  -- `:Markdown preview` (markdown.nvim owns the toggle/auto-refresh logic).
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    ft = { "markdown" },
    build = "cd app && yarn install",
    init = function()
      vim.g.mkdp_filetypes = { "markdown" }

      vim.g.mkdp_auto_start = 0
      vim.g.mkdp_auto_close = 1
      vim.g.mkdp_combine_preview = 1
      vim.g.mkdp_combine_preview_auto_refresh = 1

      -- Browser-Erkennung direkt in die init verschieben:
      local chrome_path = "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe"
      if vim.g.is_windows then
        vim.g.mkdp_browser = chrome_path
      elseif vim.g.is_wsl then
        vim.g.mkdp_browser = "/mnt/c/Program Files/Google/Chrome/Application/chrome.exe"
      end
    end,
  },
}
