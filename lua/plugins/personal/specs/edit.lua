---@module 'plugins.personal.specs.edit'
--- Editing -- personal plugin specs (Text transformation: lists, replace, emoji, spell/translate, markdown, structured data.)
---
--- Category names follow the plugin website's registry
--- (wkd/src/data/registry.json). Source control -- local vs. remote vs.
--- disabled -- is NOT decided here but in plugins.personal.source; this
--- file only declares the specs. Registered from plugins/personal/init.lua.

---@type LazyPluginSpec[]
return {
  {
    "StefanBartl/cascade.nvim",
    ft = { "markdown", "markdown.mdx", "text", "tex", "norg" },
    event = "VeryLazy",
    -- Every other option in this domain is already the plugin's default; only
    -- the keymap preset has to be asked for (cascade ships `preset = false`,
    -- so the opinionated keys are opt-in). The per-feature switches and what
    -- they bind are documented in cascade's own config/DEFAULTS.lua.
    --
    -- Two of cascade's preset keys are moved out of the way of keys this
    -- config already owns in `bindings/mappings/custom.lua`. Both are cascade
    -- losing, not the config: the config's two are long-standing muscle
    -- memory, and moving a plugin default is exactly what `keymaps.globals` /
    -- `keymaps.list` exist for.
    --
    --   <leader>cp  custom.lua: copy the current file path  (global)
    --               vs. cascade `cycle_pick`                (global preset)
    --     An exact duplicate. `bindings.mappings` runs in the UIReady phase,
    --     i.e. AFTER cascade's VeryLazy setup, so custom.lua silently
    --     overwrote cascade's -- the same load-order trap this config has
    --     paid for once before (see the note at the top of
    --     bindings/mappings/init.lua). Nothing was broken for the config, but
    --     cascade's picker was unreachable.
    --
    --   <leader>cs  custom.lua: save a casedesk session      (global)
    --               vs. cascade `sort` (list surface)        (buffer-local)
    --     Cross-scope: cascade's buffer-local key wins inside its
    --     `lists.filetypes` (markdown, markdown.mdx, text, tex, norg) -- which
    --     is precisely where casedesk notes live, so session save was the one
    --     that went missing, in the only buffers it matters.
    opts = {
      keymaps = {
        preset = true, -- bind the opinionated default keys
        globals = { cycle_pick = "<leader>cP" },
        list = { sort = "<leader>cS" },
      },
    },
  },

  {
    "StefanBartl/replacer.nvim",
    cmd = { "Replace", "Replacer", "Surround", "Wrap" },
    dependencies = {
      "ibhagwan/fzf-lua",
      "StefanBartl/lib.nvim",
      -- ui.kit.confirm/select/input (dialogs, root/rename pickers, prompts)
      -- moved out of lib.nvim.ui.kit in the 2026-09 migration.
      "StefanBartl/ui.nvim",
      -- "j-hui/fidget.nvim"
    },
    opts = {
      engine = "telescope", -- plugin default is "auto" (fzf-lua first)
      progress_style = "statusline", -- "auto" | "notify" | "statusline" | "fidget" | "float" (needs lib.nvim)
    },
  },

  {
    "StefanBartl/emojis.nvim",
    cmd = "Emojis",
    -- "uni" was chrisbra/unicode.vim's own default mapping (character info
    -- under the cursor) -- a bare `keys` entry used to lazy-load that
    -- plugin and replay the key into its mapping. unicode.vim is gone (see
    -- plugins/workflow.lua's removed spec); this binds straight to its
    -- emojis.nvim replacement instead.
    keys = {
      { "uni", "<cmd>Emojis unicode name<cr>", desc = "Unicode: character info under cursor" },
    },
    opts = {}, -- default_scope is already "%"
  },

  {
    "StefanBartl/language.nvim",
    event = "VeryLazy",
    dependencies = {
      "StefanBartl/lib.nvim",
      "folke/trouble.nvim", -- optional: nicer list; pcall-guarded in the plugin
      -- Required for the feature, not for the plugin: since `b592b9f`,
      -- language.nvim registers an on_request position contribution with
      -- hover.nvim, so `:Hover show` over a word also shows its translation.
      -- It `pcall`s hover.nvim itself and runs fine without it; listed here
      -- anyway because it fixes the load order rather than borrowing it from
      -- hover.nvim's `lazy = false`.
      "StefanBartl/hover.nvim",
      -- Provides `casedesk.spell_wordlists` (spell.extra_wordlists below).
      "StefanBartl/casedesk.nvim",
    },
    config = function()
      require("language").setup({
        spell = {
          -- Panel is the default UI; set view = "quickfix" for the classic
          -- diagnostics + quickfix session flow instead.
          ui = { view = "picker", preview = true },
          -- Covers general nvim/Lua plugin-dev vocabulary (nvim, buffer,
          -- function, table, bindings, ...) so `:Spellcheck de` stops
          -- flagging it in German notes about plugin development.
          programming_dict = true,
          -- Tricentis/TOSCA support vocabulary, same reasoning — see
          -- casedesk.spell_wordlists (casedesk.nvim). Load unconditionally: a few hundred
          -- `:spellgood!` calls, scheduled off the hot path, is not worth
          -- gating behind machine.is("workstation").
          extra_wordlists = require("casedesk.spell_wordlists"),
        },
        -- The commands (:Translate/:TranslateReplace/...) already work with
        -- zero config (engine = "google", keyless, is the plugin's own
        -- default) — this just claims the motion/visual keymaps, off by
        -- default upstream "to avoid claiming keys". <leader>lt sits next to
        -- this config's other <leader>l* (LSP/language) bindings; <leader>t*
        -- itself is already all tab-navigation here.
        translate = {
          keymaps = { operator = "<leader>lt", visual = "<leader>lt" },
          -- Target language for anything that does not name one explicitly.
          --
          -- **This also changes `<leader>lt`.** Without this value, the
          -- motion/visual maps ask for the language; with it, they translate
          -- straight to German with no prompt. That is the point, but it is
          -- a behaviour change, not a pure addition -- for a one-off run into
          -- a different language, use `translate.keymaps.to.<LANG>` or
          -- `:Translate <lang>`.
          --
          -- Needed by hover: `:Hover show` over a word has nowhere to ask,
          -- and would otherwise fall back to the plugin's `EN` default
          -- (English, since most readers translate into their own language,
          -- and that is not German here).
          default_target = "DE",
        },
      })
    end,
  },

  {
    "StefanBartl/markdown.nvim",
    ft = { "markdown", "mdx", "md" },
    -- Soft dependency: markdown.nvim's fenced_scope feature consumes
    -- color_my_ascii's fence API when present (falls back to a built-in scanner
    -- otherwise). Listing it here just guarantees load order in this config.
    dependencies = { "StefanBartl/color_my_ascii.nvim" },
    opts = {},
  },

  {
    -- JSON/YAML/XML pretty/compact/lines/keys/sort/filter, range-aware
    -- (buffer or visual selection), plus :Data for format auto-detection.
    -- All four commands must be listed here, not just "JSON" -- lazy.nvim
    -- only loads the plugin (and defines a command) for a verb it was told
    -- to trigger on, so a trimmed list leaves e.g. :YAML unavailable until
    -- :JSON has run at least once.
    "StefanBartl/data.nvim",
    cmd = { "JSON", "YAML", "XML", "Data" },
    dependencies = { "StefanBartl/lib.nvim" },
    opts = {},
  },
}
