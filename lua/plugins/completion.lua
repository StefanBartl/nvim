---@module 'plugins.completion'
--- What this config contributes to the completion menu.
---
--- nvim-cmp itself is installed and configured by lsp.nvim's pack
--- (`lsp.pack.completion`), and lazy merges `opts` across every spec for the
--- same plugin -- so this file only has to add what is specific to *this*
--- config and would be wrong to ship inside a plugin.
---
--- This used to be `plugins/lsp.lua`. The name outlived its contents: the
--- lazydev, conform, lspsaga, lensline, inc-rename, workspace-diagnostics and
--- trouble specs it once held now live in `lsp.pack.{core,ui}`, and what was
--- left had no more to do with LSP than any other cmp source does.

---@type LazyPluginSpec[]
return {
  {
    "hrsh7th/nvim-cmp",
    opts = function(_, opts)
      opts.sources = opts.sources or {}

      -- Completes this config's personal StefanBartl/*.nvim plugin names
      -- ("documentation.nvim", not just "documentation") as one atomic
      -- candidate each, ranked by persisted use frequency. See that module's
      -- doc comment for how it composes with cmp's own default sorting.
      --
      -- The plugin list is this config's data, so it is handed over rather
      -- than reached for: lsp.nvim's completion source takes a reader. That
      -- inversion is the whole reason this fragment can stay here while the
      -- source itself lives in the plugin.
      table.insert(opts.sources, { name = "personal_names", priority = 100 })
    end,
  },

  -- blink.cmp keymap: a personal preference, so it lives here rather than in
  -- lsp.nvim's pack, exactly like the nvim-cmp source above. None of blink's
  -- four built-in presets bind Tab to "next item" -- `default` only uses it
  -- for snippet-jump/fallback, `super-tab` uses it to accept immediately --
  -- so this overrides just those two keys on top of `default` rather than
  -- replacing the whole keymap (an unnamed `keymap` table with no `preset`
  -- assigns nothing else at all).
  {
    "saghen/blink.cmp",
    opts = function(_, opts)
      opts.keymap = vim.tbl_deep_extend("force", opts.keymap or {}, {
        preset = "default",
        ["<Tab>"] = { "select_next", "snippet_forward", "fallback" },
        ["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
      })
    end,
  },
}
