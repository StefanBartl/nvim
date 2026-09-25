---@module 'plugins.snacks'
---@brief Lazy-spec for folke/snacks.nvim: explicit per-module enablement, picker wired to pickers.nvim.
---@description
--- This module registers Snacks.nvim as a Lazy plugin with a hardening focus:
--- - Single point of configuration with pcall guards (no hard crashes on API shifts).
--- - Explicit module enablement (opt-in) for predictable behavior.
--- - Picker is the engine behind pickers.nvim (`engine = "snacks"`); its
---   in-picker keys are patched in by pickers.nvim, not from a snacks-only copy.
--- - Keymaps use a safe dispatcher to avoid runtime errors when submodules change.
---
--- No dashboard: snacks.dashboard is left at its default (off), and the former
--- `config.snacks.custom_dashboard` module tree (sessions section, autocmds,
--- :SnacksOpen) has been removed. Startup shows no dashboard at all.

---@type table
return {

  -- No startup dashboard at all: snacks' dashboard stays off (see @description).
  -- Used to also disable NvChad's own nvdash here (an `optional = true`
  -- fragment merged into "nvchad/ui"'s opts, back when that plugin was
  -- installed) -- NvChad is gone now (ui.nvim roadmap step 7), and with it
  -- nvdash, so there is nothing left to disable.
  {
    "folke/snacks.nvim",
    lazy = false,
    priority = 1000,
    ---@param _ any
    ---@return Plugins.Snacks.Setup|table
    opts = function(_)
      ---@type Plugins.Snacks.Setup
      local cfg = {
        debug = { enabled = true },
        dim = { enabled = false },
        profiler = { enabled = false },
        quickfile = { enabled = true },
        scope = { enabled = false },
        scratch = { enabled = false },
        toggle = { enabled = false },
        words = { enabled = false },
        -- In-terminal image rendering, off: snacks.image draws through the
        -- Kitty graphics protocol, and Kitty sequences sent from native
        -- Windows Neovim in WezTerm are never drawn -- no error, nothing on
        -- screen (images.nvim's docs/scope.md records the finding; that
        -- plugin exists because of it and draws through iTerm2 OSC 1337
        -- instead). Enabled, this module loaded and rendered nothing next
        -- to the path that works. Flip it back only on a terminal where
        -- Kitty graphics have been seen to render from inside nvim.
        image = { enabled = false },
        bigfile = { enabled = false },
        notifier = { enabled = false },

        -- In-picker keys/actions come from pickers.nvim, which patches them
        -- into Snacks.config.picker itself (pickers.entry_actions.patch).
        -- No line wrapping in the preview (like Telescope): this belongs on
        -- the preview WINDOW's `wo`, not on `picker.preview` (the previewer).
        picker = { enabled = true, win = { preview = { wo = { wrap = false } } } },
      }
      return cfg
    end,

    keys = require("config.snacks.mappings").get_all_keys(),

    -- No `config` function on purpose: lazy.nvim then runs the default
    -- `require("snacks").setup(opts)` for us. An explicit `config` would
    -- REPLACE that call, so a stub here silently drops every option above —
    -- including `picker.win.keys` (the pickers.nvim in-picker bindings such as
    -- <PageUp>/<PageDown> for preview scroll), which only reach Snacks through
    -- setup().
    --
    -- config.snacks.usrcmds removed: every command it exposed now has an
    -- engine-agnostic equivalent in pickers.builtins, reached via
    -- `:Pickers builtin <name>` (see pickers.nvim's docs/BUILTINS.md).
  },
}
