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
      "StefanBartl/ui.nvim",
      -- "j-hui/fidget.nvim"
    },
    opts = {
      -- Picker UI: "fzf" | "telescope" | "auto". "telescope" instead of the
      -- default "auto" (fzf-lua first) so the pickers always open in telescope.
      -- Default: "auto".
      engine = "telescope",
      -- Search backend: "ripgrep" | "vimgrep" | "auto" (ripgrep when available,
      -- else the native scanner).
      -- search_engine = "auto",
      -- Progress indicator: "auto" | "notify" | "statusline" | "fidget" | "float" | "kit"
      -- (needs lib.nvim, silently skipped otherwise). "statusline" pins the
      -- style instead of letting "auto" choose.
      -- Default: "auto".
      progress_style = "statusline",

      -- Write applied changes to disk (false = leave them as unsaved buffers).
      -- write_changes = true,
      -- Ask before applying ALL matches.
      -- confirm_all = true,
      -- Also ask when the scope is wide.
      -- confirm_wide_scope = false,
      -- Context lines shown around a hit in the preview.
      -- preview_context = 3,
      -- Search hidden files.
      -- hidden = true,
      -- Never search inside .git.
      -- exclude_git_dir = true,
      -- Default search mode: literal text instead of regex (flags override per run).
      -- literal = true,
      -- Case-insensitive unless the pattern has uppercase.
      -- smart_case = true,
      -- "%", "cwd", "." or an explicit path.
      -- default_scope = "%",
      -- Keep a match's own leading/trailing whitespace around the replacement.
      -- preserve_whitespace = false,
      -- Re-case the replacement to each match's case style (foo->bar, Foo->Bar, FOO->BAR).
      -- case_preserve = false,
      -- Keep only whole-word matches.
      -- word_boundary = false,
      -- Skip matches inside strings/comments (Tree-sitter, best effort).
      -- code_only = false,
      -- Skip read-only / oversized / binary files; max_file_size and
      -- skip_binary only apply once this is on.
      -- safe_mode = false,
      -- Size limit in bytes (5 MiB) enforced by safe_mode.
      -- max_file_size = 5 * 1024 * 1024,
      -- Skip binary files (enforced by safe_mode).
      -- skip_binary = true,
      -- ALL-mode: ask All/Skip/Only-some/Quit per file instead of one global
      -- confirmation (supersedes confirm_all/confirm_wide_scope).
      -- confirm_per_file = false,
      -- ALL-mode: snapshot every file before applying so :ReplaceUndo can restore it.
      -- checkpoint = false,
      -- Callbacks around the apply pipeline; each key takes a function or a list.
      -- hooks = {}, -- { before_apply?, after_apply?, before_write?, after_write? }
      -- Overrides for the message templates (string.format), merged key by key
      -- over the built-in ones; the defaults are shown below.
      -- messages = {
      --   confirm_all = "Apply ALL %d spot(s) across %d file(s)?",
      --   confirm_all_short = "Apply replacement to ALL %d spot(s)?",
      --   cancelled = "cancelled",
      --   result = "%d spot(s) in %d file(s)",
      --   no_matches = "no matches found",
      --   surround_prompt = "Surround with: ",
      --   surround_cancelled = "Surround: cancelled (no delimiter)",
      -- },
      -- Suppress routine info-level notifications (warnings/errors always show).
      -- quiet = false,
      -- Use an LSP rename for identifier-shaped matches when the buffer has a
      -- capable client (falls back to a plain edit).
      -- lsp = false,
      -- Parse ripgrep's output incrementally for smoother progress.
      -- stream = false,
      -- How many past searches :ReplaceHistory keeps (0 disables history).
      -- history_max_entries = 50,
      -- Minimum time between progress redraws while streaming, in ms.
      -- progress_throttle_ms = 100,
      -- One-time popup listing the CLI tools the plugin wants (via lib.nvim.deps).
      -- deps_popup = true,

      -- Filters, also overridable per run via command flags.
      -- file_types = {}, -- string[]; ripgrep --type values, e.g. { "lua", "md" }
      -- globs = {}, -- string[]; include globs, e.g. { "*.lua" }
      -- exclude = {}, -- string[]; paths/globs to exclude, e.g. { "node_modules", "*.min.js" }

      -- Picker window sizes, merged over the defaults.
      -- fzf = { winopts = { width = 0.85, height = 0.7 } },
      -- telescope = { layout_config = { width = 0.85, height = 0.7 } },
      -- Respect .gitignore.
      -- git_ignore = true,

      -- Buffer-local keymaps inside the picker window.
      -- keymaps = {
      --   -- Multi-select and move to the next entry.
      --   toggle_select = "<Tab>",
      --   -- Multi-select and move to the previous entry.
      --   toggle_select_prev = "<S-Tab>",
      --   -- Replace ALL matches (respects confirm_all).
      --   apply_all = "<C-a>",
      --   -- Close the picker.
      --   quit = "<Esc>",
      --   -- Apply the entry under the cursor and reopen with the rest.
      --   replace_and_reopen = "<C-r>",
      --   -- Open the stacked filter prompt (needs pickers.nvim).
      --   filter = "<C-f>",
      -- },
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
    opts = {
      -- json / yaml / xml: default indent width for `pretty`/`sort`, and path
      -- separator for `lines`/`keys`.
      -- json = { indent = 2, sep = "." },
      -- yaml = { indent = 2, sep = "." },
      -- xml = { indent = 2, sep = "." },

      -- fenced_scope = {
      --   -- Inside a matching ```json/```yaml/```xml fence, act on the block
      --   -- instead of the whole buffer (needs color_my_ascii.nvim).
      --   enable = true,
      -- },

      -- register = {
      --   -- Register a bare `--reg` reads from ("+" = system clipboard).
      --   default = "+",
      -- },

      -- target = {
      --   -- Where `--split` opens its scratch window: "above" | "below" |
      --   -- "left" | "right", or "auto" for a plain :new honoring
      --   -- 'splitbelow'/'splitright'.
      --   split = "right",
      -- },

      -- preview = {
      --   -- Show a diff.nvim before/after preview and ask before an in-place
      --   -- `filter` replaces its scope (--preview/--no-preview override per run).
      --   filter = false,
      --   -- diff.nvim view: "inline" | "float" | "vsplit" | "split" | "tab".
      --   view = "inline",
      -- },

      -- keymaps = {
      --   -- Reserved for a future keymap preset; no effect today.
      --   preset = false,
      -- },
    },
  },
}
