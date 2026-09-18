---@module 'plugins.markdown'
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
  -- markdown-preview.nvim replaced by mdview.nvim (see
  -- lua/plugins/personal/init.lua) — `:Markdown preview` now drives it
  -- directly, no node/yarn toolchain needed. See
  -- docs/ROADMAP/reports/Externe-Plugins-Nachbau-Analyse.md, B3.
}
