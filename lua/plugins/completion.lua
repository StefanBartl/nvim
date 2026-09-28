---@module 'plugins.completion'
--- What this config contributes to the completion menu.
---
--- nvim-cmp itself is installed and configured by lsp.nvim's pack
--- (`lsp.pack.completion`), and lazy merges `opts` across every spec for the
--- same plugin -- so this file only has to add what is specific to *this*
--- config and would be wrong to ship inside a plugin.
---
--- This used to be `plugins/lsp.lua`. The name outlived its contents: the
--- lazydev, conform, lensline, inc-rename, workspace-diagnostics and
--- trouble specs it once held now live in `lsp.pack.{core,ui}`, and what was
--- left had no more to do with LSP than any other cmp source does.
---
--- Both engines are configured here, not just the one that happens to be
--- installed. `vim.g.lsp_nvim.pack.completion` decides which of the two specs
--- resolves `enabled`, and the accept/dismiss keys are supposed to survive
--- that switch -- so <CR>, <C-y> and <C-x> are spelled out twice, once in
--- each engine's own vocabulary. Everything else about the two fragments is
--- unrelated: they do not share a code path, only an intent.

---@type LazyPluginSpec[]
return {
  -- nvim-cmp is not installed right now: `vim.g.lsp_nvim.pack.completion`
  -- defaults to "blink" and this config never sets it, so lsp.nvim's cmp spec
  -- resolves `enabled = false` (NvChad used to ship a second nvim-cmp entry
  -- of its own here too, disabled the same way; gone entirely along with
  -- NvChad itself as of roadmap step 7). The keymap below is here anyway, so
  -- that flipping that one option moves the accept/dismiss keys with it
  -- instead of silently leaving half of them behind. It is the only part of
  -- this file that has never been exercised -- there is no cmp on disk to
  -- run it against, so it is deliberately built out of cmp's own documented
  -- mapping helpers rather than hand-rolled closures.
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

      -- The same three keys the blink fragment below claims, in cmp's terms.
      -- Each helper already carries the "only while the menu is open" rule:
      -- they call `fallback()` when there is nothing to confirm or abort, and
      -- cmp's fallback runs the mapping the key had before cmp took it -- the
      -- same contract blink's `fallback` command gives.
      --
      --   `confirm{ select = false }`  == blink `accept`
      --   `confirm{ select = true }`   == blink `select_and_accept`
      --   `abort()`                    == blink `cancel` (undoes the preview;
      --                                   `close()`, what NvChad puts on <C-e>,
      --                                   would keep it)
      --
      -- `ConfirmBehavior.Insert` rather than `Replace` follows NvChad's own
      -- cmp config, which is what supplies the rest of the mapping table here.
      local cmp = require("cmp")
      local insert = cmp.ConfirmBehavior.Insert
      opts.mapping = opts.mapping or {}
      opts.mapping["<CR>"] = cmp.mapping.confirm({ behavior = insert, select = false })
      opts.mapping["<C-y>"] = cmp.mapping.confirm({ behavior = insert, select = true })
      opts.mapping["<C-x>"] = cmp.mapping.abort()
    end,
  },

  -- blink.cmp keymap: only the keys this config has an opinion about.
  --
  -- None of blink's four presets binds Tab to "next item" -- `default` uses it
  -- for snippet-jump/fallback, `super-tab` uses it to accept immediately -- so
  -- Tab/S-Tab are overridden on top of whichever preset is active.
  --
  -- The preset itself is deliberately *not* set here. Forcing
  -- `preset = "default"` once silently pinned accept back to <C-y> and made
  -- lsp.nvim's `completion_accept` option look broken. A `keymap` table
  -- without a `preset` assigns nothing else at all, which is fine precisely
  -- because lsp.nvim's spec always contributes one for lazy to merge under.
  --
  -- Every list below ends in `fallback`, and that is the whole reason these
  -- keys are safe to claim: blink's commands return false when the menu is
  -- closed, so the list falls through to `fallback`, which runs the first
  -- *non-blink* mapping for that key -- buffer-local before global -- and
  -- feeds the raw key through when there is none. Nothing here is live
  -- outside an open completion menu. Concretely: <CR> still reaches
  -- nvim-autopairs' pair-expanding Enter, <C-y> still copies the character
  -- from the line above, <C-x> still opens Vim's own ins-completion prefix.
  -- The keymaps are buffer-local and applied on InsertEnter, and blink's own
  -- `config.enabled()` additionally refuses `buftype = "prompt"`, so the
  -- telescope pickers that bind <C-x>/<CR> in insert mode never see them.
  --
  -- Deliberately *not* claimed here: `<Right>` in insert mode. It used to
  -- double as an accept key (`select_and_accept`), which made plain cursor
  -- movement through an open completion menu indistinguishable from accepting
  -- it -- the same confusion the lsp.nvim `auto_insert = false` fix (see
  -- `lsp.pack.completion_blink`) was chasing from the other side. None of
  -- blink's insert-mode presets (`default`/`enter`/`super-tab`, the only ones
  -- `completion_accept` ever selects) bind `<Right>` themselves -- only the
  -- unrelated `cmdline` preset does -- so leaving it unclaimed here means
  -- plain cursor motion, full stop; only <CR>/<C-y> and their cmp equivalents
  -- ever commit a completion. lsp.nvim exposes this as an opt-in pack option
  -- (`completion_arrow_accept`) for anyone who wants that habit back, rather
  -- than this config hard-wiring it.
  --
  -- Cmdline's own `<Right>` override below is a different problem, not a
  -- reappearance of this one: see that comment.
  --
  -- <CR> and <C-y> differ on purpose, each keeping the meaning its own
  -- preset gives it:
  --   - `accept` takes what is *selected*. With blink's default
  --     `completion.list.selection.preselect`, that is the first item from the
  --     moment the menu opens -- so Enter accepts the first suggestion -- but
  --     with nothing selected it declines and Enter is just a newline again.
  --   - `select_and_accept` selects the top item first when there is no
  --     selection, so <C-y> is the one that always takes a suggestion.
  --
  -- Binding <CR> here does make `vim.g.lsp_nvim.pack.completion_accept` inert
  -- for this config: both keys accept now, whichever preset the option picks.
  -- That is the point of the request this implements, not an oversight.
  --
  -- <C-x> is `cancel`, not `hide`, and it is an addition to the preset's
  -- <C-e> rather than a replacement. `cancel` also undoes any `auto_insert`
  -- preview text before closing the menu, which `hide` alone would leave
  -- behind; lsp.nvim's own spec sets `auto_insert = false` so there is
  -- usually nothing to undo, but `cancel` is harmless when there is not and
  -- correct if that option ever changes.
  {
    "saghen/blink.cmp",
    opts = function(_, opts)
      opts.keymap = vim.tbl_deep_extend("force", opts.keymap or {}, {
        ["<Tab>"] = { "select_next", "snippet_forward", "fallback" },
        ["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
        ["<CR>"] = { "accept", "fallback" },
        ["<C-y>"] = { "select_and_accept", "fallback" },
        ["<C-x>"] = { "cancel", "fallback" },
      })

      -- Cmdline (`:`) is a separate keymap namespace from insert mode --
      -- `config.cmdline.keymap`, not `config.keymap` -- so the override above
      -- never reaches it, and removing insert mode's `<Right>` override does
      -- not revert this one. Its own preset ("cmdline", blink's default
      -- there) binds `<Right>`/`<Left>` to `select_next`/`select_prev`; with
      -- only one candidate and the cursor at end-of-line that is a no-op in
      -- both directions, which is what made `<Right>` look dead right after
      -- typing e.g. `:Lazy sy` with its ghost-text preview of `nc`. Unlike
      -- insert mode, there is no `auto_insert`/preview distinction to
      -- confuse here -- cmdline completion only ever shows ghost text, never
      -- writes it into the command line -- so `select_and_accept` has no
      -- "looks accepted but wasn't" failure mode to reintroduce. `<C-n>`/
      -- `<C-p>`/`<Tab>` stay on the preset for cycling multiple candidates,
      -- so only `<Right>` changes meaning here.
      opts.cmdline = vim.tbl_deep_extend("force", opts.cmdline or {}, {
        keymap = {
          ["<Right>"] = { "select_and_accept", "fallback" },
        },
      })
    end,
  },
}
