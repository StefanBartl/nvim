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

  -- blink.cmp keymap: only the two keys this config has an opinion about.
  -- None of blink's four presets binds Tab to "next item" -- `default` uses it
  -- for snippet-jump/fallback, `super-tab` uses it to accept immediately -- so
  -- these two are overridden on top of whichever preset is active.
  --
  -- The preset itself is deliberately *not* set here any more. It carries the
  -- accept key, and that is now `vim.g.lsp_nvim.pack.completion_accept` in
  -- lsp.nvim (default "cr"). Forcing `preset = "default"` here silently pinned
  -- accept back to <C-y> and made the option look broken. A `keymap` table
  -- without a `preset` assigns nothing else at all, which is fine precisely
  -- because lsp.nvim's spec always contributes one for lazy to merge under.
  {
    "saghen/blink.cmp",
    opts = function(_, opts)
      opts.keymap = vim.tbl_deep_extend("force", opts.keymap or {}, {
        ["<Tab>"] = { "select_next", "snippet_forward", "fallback" },
        ["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
      })
    end,
  },
}
