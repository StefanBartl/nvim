---@module 'plugins.snacks'
---@brief Lazy-spec for folke/snacks.nvim: explicit per-module enablement, picker wired to pickers.nvim.
---@description
--- This module registers Snacks.nvim as a Lazy plugin with a hardening focus:
--- - Single point of configuration with pcall guards (no hard crashes on API shifts).
--- - Explicit module enablement (opt-in) for predictable behavior.
--- - Picker is the engine behind pickers.nvim (`engine = "snacks"`); its
---   in-picker keys come from `config.snacks.picker`, not from a snacks-only copy.
--- - Keymaps use a safe dispatcher to avoid runtime errors when submodules change.
---
--- No dashboard: snacks.dashboard is left at its default (off), and the former
--- `config.snacks.custom_dashboard` module tree (sessions section, autocmds,
--- :SnacksOpen) has been removed. Startup shows no dashboard at all.

local picker_config = require("config.snacks.picker")

---@type table
return {

  -- No startup dashboard at all: snacks' dashboard stays off (see @description)
  -- and nvchad's nvdash is disabled here so it doesn't take over the empty
  -- startup buffer instead.
  {
    "nvchad/ui",
    optional = true,
    ---@param _ any
    ---@param opts table
    opts = function(_, opts)
      opts = opts or {}
      opts.nvdash = opts.nvdash or {}
      opts.nvdash.load_on_startup = false
      opts.nvdash.enabled = false
      return opts
    end,
  },

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
        -- In-terminal image rendering (kitty graphics protocol).
        -- Requires nvim to run inside a graphics-capable terminal (WezTerm on
        -- Windows) and the `magick` CLI in PATH for png/webp/svg conversion.
        -- Defaults already enable doc.inline + doc.float for markdown.
        image = { enabled = true },
        bigfile = { enabled = false },
        notifier = { enabled = false },

        picker = picker_config.get_config(),
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
