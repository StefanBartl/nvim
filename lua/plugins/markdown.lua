-- markdown.lua
return {

  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown" },
    cmd = { "RenderMarkdown", "MarkdownRender" },
    opts = {
      enabled = false,
    },
    config = function(opts)
      require("render-markdown").setup(opts)
      require("config.markdown_render").setup()
    end
  },
  {
    "iamcco/markdown-preview.nvim",
    -- Wir fügen deine Wrapper-Befehle hier hinzu, damit Lazy-Loading auch auf sie anspringt
    cmd = {
      "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop",
      "MarkdownPreviewWrapper", "MarkdownPreviewStopWrapper", "MarkdownPreviewToggleWrapper"
    },
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
    config = function()
      -- Ruft deine init.lua auf, um die Wrapper-Befehle und Autocommands zu registrieren
      require("config.markdown_preview").setup()
    end,
  },
}
