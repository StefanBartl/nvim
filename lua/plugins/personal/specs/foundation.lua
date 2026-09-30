---@module 'plugins.personal.specs.foundation'
--- Foundation -- personal plugin specs (The shared library and the option/highlight/diagnostics layer everything else stands on.)
---
--- Category names follow the plugin website's registry
--- (wkd/src/data/registry.json). Source control -- local vs. remote vs.
--- disabled -- is NOT decided here but in plugins.personal.source; this
--- file only declares the specs. Registered from plugins/personal/init.lua.

---@type LazyPluginSpec[]
return {
  {
    "StefanBartl/lib.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      -- NOTE: helptags could be generated generically and the usrcmds set up
      -- as normal user config instead of this dedicated setup() call.
      require("lib.nvim_usrcmds").setup({
        helptags = true,
        cwd_here = true,
        powershell_profile = true,
      })

      require("lib.nvim.lastcmd").setup({ experimental = true })

      -- Global default: every lib.nvim.notify consumer (~30 plugins, none
      -- touched) now shows a non-focus-stealing corner toast instead of the
      -- plain `vim.notify` more-prompt. `toast_min_level` keeps chatty
      -- INFO-level plugins (e.g. lsp.nvim, 60+ call sites) from spamming the
      -- corner -- below it, a message still lands in the popup's own history,
      -- it just never becomes a toast. Since 2026-09-29 that history is also
      -- the one place a message's full text is guaranteed to be: `messages`
      -- (write to REAL `:messages`, always briefly echoing as it does -- see
      -- lib.nvim.notify.popup's own doc comment) defaults to false now, so a
      -- toast is never followed by that echo flashing at the bottom too. No
      -- keymap for `expand_last()`/`toggle_full()`: `:Lib notify
      -- last|history|clear` cover it, and the history buffer's own
      -- buffer-local `<C-s>` (see lib.nvim's docs/BINDINGS.md) toggles
      -- collapsed/full there.
      require("lib.nvim.notify").setup({ popup = true })
      require("lib.nvim.notify.popup").setup({
        toast_min_level = vim.log.levels.INFO,
      })
    end,
  },

  {
    -- The declarative option set, the highlight features, the editor-option
    -- toggles, italic keywords and per-filetype indentation.
    --
    -- PRIVATE repo, unlike every other entry here. See source.lua's mode entry
    -- for what that means on a machine that resolves to "remote".
    --
    -- No `opts`/`config` on purpose, for the same reason as lsp.nvim above:
    -- init.lua calls setup() inside startup.now("my", ...) because the
    -- highlight groups must land before the first paint and
    -- vim.diagnostic.config() before the first LSP attach. A lazy opts block
    -- would hand that ordering to the plugin manager. `lazy = false` only
    -- guarantees the module is on the runtimepath by then.
    "StefanBartl/my.nvim",
    lazy = false,
    priority = 900,
    dependencies = { "StefanBartl/lib.nvim" },
  },
}
