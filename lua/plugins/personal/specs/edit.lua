---@module 'plugins.personal.specs.edit'
--- Personal plugin specs: Editing.
---
--- Text transformation: lists, replace, emoji, spell/translate, markdown, structured data.
---
--- Category names follow the plugin website's registry
--- (wkd/src/data/registry.json). Source control -- local vs. remote vs.
--- disabled -- is NOT decided here but in plugins.personal.core.source; this
--- file only declares the specs. Registered from plugins/personal/init.lua.

---@type LazyPluginSpec[]
return {
  {
    "StefanBartl/cascade.nvim",
    ft = { "markdown", "markdown.mdx", "text", "tex", "norg" },
    event = "VeryLazy",
    -- Only the keymap preset is asked for (cascade ships `preset = false`, so
    -- the opinionated keys are opt-in); every other option below is listed
    -- commented out with its default. The per-feature switches and what they
    -- bind are documented in cascade's own config/DEFAULTS.lua.
    --
    -- Two preset keys are moved out of the way of keys this config already
    -- owns in `bindings/mappings/custom.lua`; cascade yields, since
    -- `keymaps.globals` / `keymaps.list` exist for exactly that:
    --
    --   <leader>cp  custom.lua: copy the current file path  (global)
    --               vs. cascade `cycle_pick`                (global preset)
    --     An exact duplicate. `bindings.mappings` runs in the UIReady phase,
    --     i.e. after cascade's VeryLazy setup, so custom.lua would silently
    --     overwrite cascade's map and leave its picker unreachable.
    --
    --   <leader>cs  custom.lua: save a casedesk session      (global)
    --               vs. cascade `sort` (list surface)        (buffer-local)
    --     Cross-scope: cascade's buffer-local key wins inside its
    --     `lists.filetypes`, which is exactly where casedesk notes live, so
    --     session save would be the one that goes missing.
    opts = {
      -- Debug logging at cascade's decision points (detect -> advance -> fallback).
      -- debug = false,

      -- Which hosts may drive this plugin. `ui_menu = false` keeps ui.nvim's
      -- right-click menu from composing the Cascade fly-out.
      -- integrations = {
      --   ui_menu = true,
      -- },

      -- Key bindings. Each key is an individually overridable named action
      -- (`false` drops one); action names: lua/cascade/bindings/keymaps.lua
      -- in the plugin.
      keymaps = {
        -- Bind the opinionated default keys; the preset is opt-in.
        -- Default: false.
        preset = true,
        -- Keys that work everywhere. `cycle_pick` moved off its default
        -- "<leader>cp" (see above).
        -- Default: {}.
        globals = { cycle_pick = "<leader>cP" },
        -- Keys bound inside a buffer whose filetype matched `lists.filetypes`.
        -- `sort` moved off its default "<leader>cs" (see above). The list-form
        -- rotation (`rotate_form_next/prev`) is `<leader>cl` / `<leader>cL` by plugin
        -- default now, because casedesk.nvim owns `<leader>cf` / `cF`.
        -- Default: {}.
        list = { sort = "<leader>cS" },
      },

      -- List domain: continuation, checkbox, marker cycling, rotate/sort/
      -- reverse, indent, move, renumber.
      -- lists = {
      --   enable = true,
      --   -- Per-feature switches. Disabling one stops its keymap action (and the
      --   -- preset stops binding its keys); keys with a native meaning fall back to it.
      --   features = {
      --     continue = true, -- <CR>/o/O continuation + empty-bullet deletion
      --     checkbox = true, -- toggle/cycle checkbox
      --     cycle_type = true, -- cycle a single item's marker shape
      --     rotate = true, -- block/visual form rotation
      --     shift = true, -- <C-y>/<C-x> on an ordered marker shift the item + later siblings (no renumber); <C-S-y>/<C-S-x> / <leader>c+ <leader>c- the whole level
      --     sort = true, -- block/visual A-Z sort
      --     reverse = true, -- block/visual reverse order
      --     strip = true, -- block/visual remove checkboxes
      --     indent = true, -- indent/outdent + level-aware renumber
      --     move = true, -- move line/selection up/down + renumber
      --     bullet_toggle = true, -- quick "-" bullet on/off, no existing marker required
      --     number_toggle = true, -- quick "1." marker on/off, no existing marker required
      --     checkbox_toggle = true, -- quick "- [ ]" insert/cycle/remove, no existing marker required
      --   },
      --   -- Prose / markup filetypes the list features attach to (replaces the list).
      --   -- List actions no-op on lines without a marker, so a broad set is safe.
      --   -- The word/number cycle lives in the `cycle` domain and is global.
      --   filetypes = {
      --     "markdown",
      --     "markdown.mdx",
      --     "mdx",
      --     "text",
      --     "txt",
      --     "tex",
      --     "plaintex",
      --     "latex",
      --     "norg",
      --     "org",
      --     "rst",
      --     "asciidoc",
      --     "asciidoctor",
      --     "typst",
      --     "quarto",
      --     "pandoc",
      --     "vimwiki",
      --     "gitcommit",
      --     "mail",
      --   },
      --   -- Marker kinds recognized when parsing a line, in detection order. Must
      --   -- cover every kind `cycle` below can produce, or a line cycled into an
      --   -- unparsed kind stops being a list item. Roman comes before ascii because
      --   -- "I." is valid in both shapes and the cycle walks the same letter through
      --   -- "a)" then "I.".
      --   types = { "unordered", "digit", "roman", "ascii" },
      --   unordered_markers = { "-", "*", "+" },
      --   -- Custom, non-incrementing marker patterns per filetype, tried before the
      --   -- built-in kinds. Each pattern needs two captures: the marker token, then
      --   -- the rest of the line, e.g. { tex = { "^(\\item)%s(.*)$" } }. Matches
      --   -- count as "unordered" (fixed token, never renumbered).
      --   per_filetype_patterns = {},
      --   -- Marker shapes `cycle_type` steps through (replaces the list).
      --   cycle = { "-", "*", "+", "1.", "a)", "I." },
      --   -- Forms block/visual rotation steps through: shape + optional checkbox.
      --   forms = { "1.", "1. [ ]", "- [ ]", "-" },
      --   checkbox = {
      --     -- Ordered states cycled inside `[ ]`; longer states (e.g. "✅") must
      --     -- be listed here to be recognized on parse.
      --     states = { " ", "x", "~" },
      --   },
      --   continue = {
      --     -- <CR> on an empty bullet removes the bullet instead of continuing.
      --     delete_empty = true,
      --     -- Set buffer-local 'formatlistpat' and add `n` to 'formatoptions' on
      --     -- the list filetypes, so gq/auto-wrap hang-indents a wrapped item.
      --     hanging_indent = true,
      --   },
      --   -- When ordered lists are auto-renumbered.
      --   renumber = {
      --     -- Master switch (false = only manual :Cascade renumber).
      --     enable = true,
      --     -- "edit" (right after indent/move/continue/...) and/or "save"
      --     -- (BufWritePre); "save" also catches pastes and external edits.
      --     on = { "edit", "save" },
      --     -- Consecutive blank lines a list tolerates before they end it; 1 gives
      --     -- the CommonMark "loose list" reading.
      --     blank_break = 0,
      --   },
      --   -- "off" = plain line scan; "treesitter" additionally skips single-cursor
      --   -- list actions inside a skip node (default: a fenced code block).
      --   precision = "off",
      --   -- Per-filetype skip-node overrides for precision = "treesitter".
      --   precision_nodes = {},
      -- },

      -- Word/number cycle domain (<C-y>/<C-x> and friends).
      -- cycle = {
      --   enable = true,
      --   features = {
      --     word = true, -- cycle the word/boolean under the cursor
      --     date = true, -- step the year/month/day segment of an ISO date (YYYY-MM-DD) under the cursor
      --     letter = true, -- cycle a single a-z/A-Z letter through the alphabet (case preserved)
      --     char = true, -- <C-M-y>/<C-M-x>: step the character under the cursor through the alphabet, inside a word too
      --   },
      --   -- Restrict the cycle to these filetypes.
      --   -- filetypes = nil, -- string[]|nil; nil = every filetype
      --   -- Fall back to native <C-y>/<C-x> on numeric tokens.
      --   number_fallback = true,
      --   -- Named bundles of word groups ("en", "de", "es", "fr", "it", "pt", "nl",
      --   -- "ru", "dev"). Order is precedence: the first group a word appears in
      --   -- wins. {} = only your own `groups`.
      --   packs = { "en", "de", "dev" },
      --   -- Your own groups, checked BEFORE the packs (replaces the list); the
      --   -- default carries the language-neutral syntax cycles.
      --   groups = {
      --     { ".", "/", "\\" },
      --     { "==", "!=" },
      --     { "&&", "||" },
      --     { "<", ">" },
      --     { "+", "-" },
      --   },
      --   -- Extra groups merged in per filetype, e.g. { lua = { { "local", "global" } } }.
      --   per_filetype = {},
      -- },

      -- Renumbering inside a selection, independent of filetype (numbered
      -- headlines, inline numbers in prose).
      -- sequence = {
      --   enable = true,
      --   -- "keep" = start from the first hit's value; "one" = always restart at 1/a/i.
      --   start = "keep",
      --   -- Kinds tried, in order, to classify the first hit (which locks the
      --   -- kind). Put "roman" first for i./ii./iii. sequences.
      --   types = { "digit", "ascii", "roman" },
      -- },

      -- Swap the char / word (or same-line selection) with its neighbor.
      -- transpose = {
      --   enable = true,
      --   features = {
      --     char = true, -- swap the char with its left/right neighbor
      --     word = true, -- swap the word with its left/right neighbor word
      --   },
      -- },

      -- Advance a string literal's kind when its contents ask for it
      -- (Tree-sitter based, inactive without a parser).
      -- strings = {
      --   enable = true,
      --   features = {
      --     template = true, -- JS/TS: "…${x}…" <-> `…${x}…`
      --     fstring = true, -- Python: "…{x}…" <-> f"…{x}…"
      --     -- Lua: "%s" -> ("%s"):format(). Off by default: a `%s` is a pattern
      --     -- class as often as a placeholder.
      --     lua_format = false,
      --   },
      --   template_filetypes = {
      --     "javascript",
      --     "typescript",
      --     "javascriptreact",
      --     "typescriptreact",
      --     "vue",
      --     "astro",
      --     "svelte",
      --   },
      --   fstring_filetypes = { "python" },
      --   lua_format_filetypes = { "lua" },
      --   -- A literal longer than this is never rewritten.
      --   max_characters = 200,
      --   -- The quote a template string turns back into: '"' or "'".
      --   quote = '"',
      --   -- Events that trigger a conversion at the cursor; {} = manual only
      --   -- (`:Cascade strings now`).
      --   on = { "InsertLeave", "TextChanged" },
      -- },
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
    -- "uni": character info under the cursor (the mapping chrisbra/unicode.vim
    -- used to provide), bound straight to `:Emojis unicode name`.
    keys = {
      { "uni", "<cmd>Emojis unicode name<cr>", desc = "Unicode: character info under cursor" },
    },
    opts = {
      -- Scope used when none is given: "word"|"line"|"visual"|"%"|"cwd".
      -- default_scope = "%",
      -- Name of the user command.
      -- command = "Emojis",

      -- Insert-picker entries: { glyph, label }. Merged index-wise over the
      -- defaults (a shorter list keeps the default tail). Two of the defaults
      -- shown; full default list: CATALOG in lua/emojis/config/DEFAULTS.lua
      -- in the plugin (also feeds `names`).
      -- picks = {
      --   { "✅", "white_check_mark" },
      --   { "❌", "x" },
      -- },
      -- Codepoint -> :name: used by the `replace`/`unreplace` actions; a free
      -- map of shortcodes, merged key by key over the defaults. Two of the
      -- defaults shown; full default list: CATALOG in
      -- lua/emojis/config/DEFAULTS.lua in the plugin.
      -- names = {
      --   [10004] = ":heavy_check_mark:",
      --   [10024] = ":sparkles:",
      -- },

      -- cwd search (rg).
      -- search = {
      --   -- External search binary.
      --   cmd = "rg",
      --   -- Extra args appended before the pattern.
      --   extra_args = { "--no-heading", "--line-number", "--with-filename", "--color=never" },
      --   -- Pass --no-ignore so rg also searches gitignored files.
      --   no_ignore = false,
      -- },

      -- Opt-in preset keymaps. `preset = false` binds nothing; each action is
      -- also individually overridable by name (`false` drops one); a wrong
      -- name is reported instead of silently binding nothing.
      -- keymaps = {
      --   preset = false,
      --   -- insert = "<C-e>", -- picker
      --   -- overlay = "<leader>ee", -- quick-insert overlay
      --   -- toggle = "<leader>et", -- toggle checkbox (n, x)
      --   -- count = "<leader>ec", -- count buffer
      --   -- list = "<leader>el", -- list buffer
      -- },

      -- Marker the `wrap` action surrounds each emoji with.
      -- wrap = {
      --   prefix = "[[",
      --   suffix = "]]",
      -- },

      -- Opt-in: briefly highlight affected emojis before `clear`/`replace`
      -- mutate the buffer.
      -- preview = {
      --   enable = false,
      --   -- How long the highlight shows before mutating, in ms.
      --   duration_ms = 150,
      --   hl_group = "IncSearch",
      -- },

      -- Insert-picker engine: "auto" tries telescope.nvim then fzf-lua (both
      -- optional), falling back to vim.ui.select; or "telescope" | "fzf-lua" |
      -- "select".
      -- picker = {
      --   engine = "auto",
      -- },

      -- Emoji checkbox cycles (`:Emojis toggle [set]`). Order matters twice: it
      -- is the cycle order within a set, and across sets a glyph in two sets
      -- belongs to the one listed first. The default sets are disjoint; a
      -- redefined set or `order` replaces its default entirely.
      -- checkbox = {
      --   -- Documented as "set `:Emojis toggle` uses with no argument", but no
      --   -- code path reads it today: every set is always searched.
      --   default_set = "",
      --   sets = {
      --     checkbox = { "🔲", "✅" },
      --     status = { "🔴", "🟡", "🟢" },
      --     review = { "👍", "👎" },
      --   },
      --   -- Order in which sets are searched; sets missing here are appended
      --   -- name-sorted, so a new set is never silently disabled.
      --   order = { "checkbox", "status", "review" },
      -- },

      -- Quick-insert overlay (`:Emojis overlay [mode]`).
      -- overlay = {
      --   -- "grid" (hjkl/arrows + <CR>) | "grid_keys" (direct hotkey per cell) |
      --   -- "list" (one per row).
      --   mode = "grid",
      --   -- Curated quick-insert set { glyph, label }, in starting order; replaced
      --   -- wholesale. Two of the defaults shown; full default list:
      --   -- OVERLAY_LABELS in lua/emojis/config/DEFAULTS.lua in the plugin.
      --   picks = {
      --     { "✅", "white_check_mark" },
      --     { "❌", "x" },
      --   },
      --   -- Reorder `picks` by recorded usage (never adds/removes entries).
      --   frecency = true,
      --   -- Cells per row in the grid modes.
      --   columns = 5,
      --   -- Maximum cells shown.
      --   limit = 20,
      --   -- Float title.
      --   title = " Emojis ",
      --   -- Any ui.kit theme arg: preset name or override table.
      --   theme = "rounded",
      -- },
    },
  },

  {
    "StefanBartl/language.nvim",
    event = "VeryLazy",
    dependencies = {
      "StefanBartl/lib.nvim",
      "folke/trouble.nvim", -- optional: nicer list; pcall-guarded in the plugin
      -- Needed for the feature, not for the plugin: language.nvim registers an
      -- on_request position contribution with hover.nvim, so `:Hover show`
      -- over a word also shows its translation. The plugin `pcall`s hover.nvim
      -- and runs fine without it; it is listed here to fix the load order
      -- instead of borrowing it from hover.nvim's `lazy = false`.
      "StefanBartl/hover.nvim",
      -- Provides `casedesk.spell_wordlists` (spell.extra_wordlists below).
      "StefanBartl/casedesk.nvim",
    },
    config = function()
      require("language").setup({
        spell = {
          -- Spelling + grammar providers.
          -- providers = {
          --   -- Provider resolution order.
          --   order = { "native", "lsp", "typos", "cspell", "codespell" },
          --   -- Providers used for buffer/visible scope.
          --   buffer = { "native", "lsp" },
          --   -- Providers used for cwd/path scope (CLI preferred for a tree scan).
          --   cwd = { "typos", "native" },
          --   native = {
          --     -- Language(s) the native checker uses; nil = inherit vim 'spelllang'.
          --     spelllang = nil, -- string|nil
          --   },
          --   lsp = {
          --     enable = true,
          --     servers = { "harper_ls", "ltex" },
          --   },
          --   -- Escape hatch for a spellchecker CLI without a bundled adapter: add
          --   -- "custom" to `providers.cwd` and set cmd/parse. Mirrors translate.custom.
          --   custom = nil, -- { cmd = function(scope, cfg) ... end, parse = function(out, base) ... end }
          -- },
          -- Filetypes the spell session attaches to.
          -- filetypes = { "markdown", "text", "gitcommit", "tex", "rst", "asciidoc", "help" },
          -- Scope used when none is given: buffer|visible|cwd|path.
          -- default_scope = "buffer",
          -- Opt-in live scan.
          -- live = false,
          -- Live scans only within this scope (perf).
          -- live_scope = "visible",
          -- Debounce before a live scan, in ms.
          -- scan_debounce_ms = 400,
          -- Code-identifier splitting: break CamelCase & snake_case into subwords
          -- before checking against the dictionary.
          -- word_split = {
          --   enable = true,
          --   -- Ignore subwords shorter than this.
          --   min_length = 4,
          -- },

          -- Perf/safety caps.
          -- Max highlighted errors per buffer.
          -- max_highlights = 100,
          -- Above this many lines: no auto/live scan.
          -- max_file_lines = 20000,
          -- Do not scan readonly buffers.
          -- skip_readonly = true,
          -- Only check spellable regions (Treesitter @spell / predicate).
          -- regions = {
          --   treesitter_spell = true,
          --   skip_urls = true,
          --   skip_emails = true,
          -- },

          ui = {
            -- Both values equal the default, set explicitly. Use
            -- view = "quickfix" for the classic diagnostics + quickfix session
            -- flow instead of the picker panel.
            -- Default: view = "picker" ("picker"|"select"|"quickfix"), preview = true.
            view = "picker",
            preview = true,
            -- "file"|"none".
            -- group_by = "file",
            -- dedupe = true,
            -- Wait after an LSP code action before re-reading the buffer, in ms.
            -- There is no completion signal to hook, so this guesses the
            -- server's latency -- raise it for a slow one.
            -- lsp_refresh_delay_ms = 500,
          },
          -- Extra technical wordlist, added to the session word list (like
          -- `zG`). Covers general nvim/Lua plugin-dev vocabulary (nvim, buffer,
          -- function, table, bindings, ...) so `:Spellcheck de` stops flagging
          -- it in German notes about plugin development.
          -- Default: false.
          programming_dict = true,
          -- User-supplied session wordlists, applied like programming_dict but
          -- independent of it and of `spelllang`:
          -- { ["my-list"] = { "word1", ... } }. Here: Tricentis/TOSCA support
          -- vocabulary from casedesk.spell_wordlists (casedesk.nvim). Loaded
          -- unconditionally: language.nvim compiles all lists in one go (a few
          -- ms for ~300 words), so gating them behind machine.is("workstation")
          -- buys nothing. That only holds since language.nvim ad355be -- one
          -- `:spellgood!` per word, as before, was 1.2 s of frozen UI per start.
          -- Default: {}.
          extra_wordlists = require("casedesk.spell_wordlists"),
          -- dictionary = {
          --   -- Persistent ignore list.
          --   ignore_file = vim.fn.stdpath("state") .. "/language/spell_ignore.txt",
          --   -- Also write to the nvim spellfile on add-to-dict.
          --   use_spellfile = true,
          --   -- Apply a chosen suggestion to all identical errors in scope.
          --   replace_all = true,
          -- },
          -- Opt-in: abort :w on spelling errors.
          -- guard = { block_write_on_error = false },
          -- Opt-in: mark issues directly in the buffer via extmarks
          -- (LanguageSpellHighlight/LanguageGrammarHighlight groups),
          -- independent of vim.diagnostic config.
          -- highlights = {
          --   enable = false,
          --   -- "underline"|"undercurl".
          --   style = "underline",
          -- },
          -- Each key is one lhs, a list of them, or false to not bind. `panel`
          -- is global; the others are buffer-local during a spell session.
          -- keymaps = {
          --   panel = "<leader>ss", -- toggle the spell session
          --   next = "]s", -- next spell error
          --   fix = "<leader>z=", -- correct word & advance
          --   fix1 = "<leader>z1", -- accept first suggestion & advance
          -- },
        },

        -- Register a position preview with hover.nvim, so `:Hover show` over a
        -- word answers with its translation. It is `on_request` there (the
        -- automatic hover trigger never asks), because every answer is a
        -- network request carrying the word under the cursor. No-op without
        -- hover.nvim; false registers nothing at all.
        -- hover = true,

        -- The commands (:Translate/:TranslateReplace/...) already work with
        -- zero config (engine = "google", keyless); the keymaps below only
        -- claim the motion/visual keys, which are off by default upstream to
        -- avoid claiming keys. <leader>lt sits next to this config's other
        -- <leader>l* (LSP/language) bindings; <leader>t* itself is already all
        -- tab-navigation here.
        translate = {
          -- "google"|"deepl"|"shell"|<custom key>.
          -- engine = "google",
          -- Engine fallback chain (graceful degradation).
          -- fallback = { "google" },
          -- Where the result goes: "popup"|"replace"|"buffer"|"vsplit"|"split"|"tab"|"insert"|"clipboard"|"notify".
          -- default_output = "popup",
          -- Where the text comes from: "selection"|"clipboard"|"input".
          -- default_input = "selection",
          -- default_langs = { "EN", "DE", "FR", "ZH", "JA" },
          -- Opt-in motion/visual keymaps; each is one lhs, a list of them, or false.
          keymaps = {
            -- `<lhs>{motion}` translates the moved-over text (e.g. gtrip).
            -- Default: false.
            operator = "<leader>lt",
            -- `<lhs>` translates the visual selection.
            -- Default: false.
            visual = "<leader>lt",
            -- One key per language, forcing that target for a single run, in
            -- both normal (operator) and visual mode, e.g.
            -- { EN = "<leader>te", DE = "<leader>td" }. A count cannot carry
            -- the language on an operator, hence a key per language.
            -- to = {},
          },
          -- Target language for anything that does not name one explicitly.
          -- "DE" instead of the default nil (= prompt). **This also changes
          -- `<leader>lt`:** the motion/visual maps translate straight to German
          -- with no prompt instead of asking for the language; for a one-off
          -- run into another language use `translate.keymaps.to.<LANG>` or
          -- `:Translate <lang>`. It is also needed by hover: `:Hover show` over
          -- a word has nowhere to ask and would otherwise fall back to the
          -- plugin's `EN` default, which is not the reader's language here.
          -- Default: nil.
          default_target = "DE",
          -- nocode_default = false,
          -- Network timeout per job, in ms.
          -- timeout_ms = 8000,
          -- deepl = {
          --   -- string|nil; or the ENV var DEEPL_API_KEY.
          --   api_key = nil,
          -- },
          -- Custom engine.
          -- custom = nil, -- { cmd = function(text, target) ... end, parse = function(out) ... end }
          -- Recall previous translations (:Translate history picker / window <C-h>).
          -- history = {
          --   enable = true,
          --   -- Ring size.
          --   max = 50,
          --   -- Also save to disk (JSON) across sessions.
          --   persist = false,
          --   file = vim.fn.stdpath("state") .. "/language/translate_history.json",
          -- },
          -- Multi-file translation (:Translate cwd / path=<dir>): pick files
          -- (kit multi-select, <Tab>), then per file; override per call with
          -- `--files=<mode>`.
          -- files = {
          --   -- "suffix" writes a sibling name.<TARGET>.ext (non-destructive);
          --   -- "replace" overwrites in place (asks first); "buffers" opens each
          --   -- translation in a scratch buffer (no disk write).
          --   output = "suffix",
          --   extensions = { "md", "markdown", "txt", "text", "rst", "adoc", "asciidoc", "tex", "org" },
          --   max_kb = 512,
          -- },
        },

        -- Thesaurus / synonyms (writing aid). Default source is the free,
        -- keyless Datamuse API (English); set a `custom` function for another
        -- source/language.
        -- thesaurus = {
        --   enable = true,
        --   -- "datamuse" | "custom".
        --   source = "datamuse",
        --   max = 20,
        --   timeout_ms = 6000,
        --   -- Opt-in: replace the word under the cursor with a synonym
        --   -- (string|string[]|false).
        --   keymap = false,
        --   custom = nil, -- fun(word: string, cb: fun(synonyms: string[])); e.g. function(word, cb) cb({ "syn1", "syn2" }) end
        -- },

        -- Define the user commands (:Translate, :Spellcheck, ...).
        -- commands = true,
        -- which_key = { enable = true },
        -- One-time "which CLI tools does this plugin want, and why" popup on
        -- first setup() after install (via lib.nvim.deps); false disables it.
        -- deps_popup = true,
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
    opts = {
      -- Feature gating; `just_enable` wins over `disable`/`enable`. Gateable
      -- names are listed in docs/configuration.md.
      -- features = {
      --   disable = "all", -- nil; "all" | string[] -- turn gateable features off
      --   enable = {}, -- nil; string[] -- re-enable after `disable`
      --   just_enable = {}, -- nil; string[] -- hard allowlist, only these stay on
      -- },

      -- Progress indicator for scope-wide *.md walks (`:Markdown links show|sanitize cwd`):
      -- "auto" | "notify" | "statusline" | "fidget" | "float" | "kit".
      -- progress_style = "auto",

      -- Map `**` in visual mode to toggle bold.
      -- map_double_asterisk = true,
      -- Map `<leader>[` to wrap the word/selection in a link.
      -- map_wrap_link = true,
      -- After toggling bold, keep the inner text selected.
      -- keep_inner_selection = true,
      -- Protect H1 from being shifted down.
      -- protect_h1 = false,
      -- Override `zf` to fold under the cursor.
      -- use_zf_override = true,
      -- Install the FileType autocmds (keymaps + user commands).
      -- enable_autocmds = true,
      -- Install the buffer-local keymaps (needs enable_autocmds).
      -- enable_keymaps = true,
      -- Only activate for markdown filetypes.
      -- ft_only = true,
      -- TOC refresh also ensures `[blank]---[blank]` between H2+ sections.
      -- ensure_headline_spacing = true,
      -- TOC refresh also reports skipped heading levels (H1 -> H3) and offers a fix.
      -- check_heading_gaps = true,

      -- Underline character of `:MarkdownNvimUnderlineHeadings`.
      -- underline_headings = {
      --   char = "=",
      -- },

      -- nvzone/menu entries; `enable = false` provides none at all.
      -- menu = {
      --   enable = true,
      --   fold = true, -- fold/unfold entries (shown on a heading)
      --   toc = true, -- Insert/Refresh TOC
      --   refs = true, -- Sync References
      -- },

      -- `ui_menu = false` keeps ui.nvim's right-click menu from composing the
      -- Markdown fly-out.
      -- integrations = {
      --   ui_menu = true,
      -- },

      -- Heading navigation (`<C-p>`/`<C-f>`, `[[`/`]]`): also stop on a fenced
      -- block's opening/closing delimiter line. false = headings only.
      -- nav = {
      --   fences = true,
      -- },

      -- Heading text normalization (`:Markdown headings format`, `<leader><C-Left>`/`<C-Right>`).
      -- heading_format = {
      --   -- Strip `**bold**` / `*italic*` / `__x__` / `_x_` / `~~x~~` markers.
      --   strip_emphasis = true,
      --   -- `## Title ##` -> `## Title`.
      --   strip_closing_hashes = true,
      --   -- Runs of spaces/tabs become one space; the ends are trimmed.
      --   collapse_whitespace = true,
      --   -- Drop a trailing `.` `,` `;` `:` (`?` and `!` are never dropped).
      --   strip_trailing_punctuation = false,
      --   -- false | "first" (first letter) | "title" (every word but the stopwords).
      --   capitalize = "first",
      --   -- Words `capitalize = "title"` keeps lowercase mid-heading; replaces the
      --   -- built-in English closed-class list, so give it in full.
      --   -- stopwords = { "a", "an", "and", "as", "at", "but", "by", "for", "from", "in",
      --   --   "into", "nor", "of", "on", "onto", "or", "over", "per", "the", "to", "up",
      --   --   "via", "vs", "with" },
      -- },

      -- Per-binding keymap control by id (see docs/keymaps.md and docs/BINDINGS.lua):
      -- false disables, a string remaps, `{ lhs = ..., mode = ... }` remaps key/mode.
      -- keymaps = {
      --   jump_anchor = false,
      --   toc = "<leader>T",
      --   fold_toggle = { lhs = "<F2>" },
      -- },

      -- `:Markdown table format` defaults (explicit command args override per call).
      -- table = {
      --   header_align = "center", -- "left" | "center" | "right"
      --   entry_align = "center",
      --   -- Per-column overrides on every format; `col` is a 1-based index or a
      --   -- case-insensitive header name, `max`/`min` limit the width.
      --   -- col_overrides = { { col = 1, align = "left" }, { col = "Name", align = "left" } },
      --
      --   -- Width-limited wrapping (`:MDTable*` commands). Off by default: natural widths.
      --   wrap = {
      --     enabled = false, -- also wrap on plain `:Markdown table format`/table mode
      --     auto = false, -- fit column widths to the window instead of a fixed `max`
      --     min = 3, -- minimum column width (chars)
      --     -- max = nil, -- maximum column width; nil = unlimited (still capped by `auto`)
      --     pad = 1, -- cell padding on each side
      --     join = " ", -- `:MDTableUnwrap` continuation join: " " | "<br>"
      --     soft_break_chars = "/._-?,&=#@:", -- extra break points besides whitespace
      --     continuation_marker = "↳", -- gutter hint on continuation rows
      --     flavor = "github", -- "github" (strict GFM) | "loose"
      --     auto_resize = false, -- debounced reflow of auto tables on resize
      --     resize_debounce_ms = 300,
      --     selective_reflow = false, -- BufWritePre: only reflow tables that changed
      --   },
      --
      --   -- Presets for `:MDTableProfile {name}`; merged per profile, add your own.
      --   wrap_profiles = {
      --     compact = { auto = false, min = 4, max = 20, pad = 0 },
      --     docs = { auto = true, min = 10, max = 40, pad = 1 },
      --     wide = { auto = true, min = 15, max = nil, pad = 1 },
      --   },
      -- },

      -- Default style of the floating TableView: "markdown" | "box".
      -- tableview = {
      --   style = "markdown",
      -- },

      -- Link handling.
      -- links = {
      --   -- `:Markdown links show` backend: "hover_select" | "select" | "telescope" | "fzf".
      --   picker = "hover_select",
      --   -- Normalize inline-link targets before every write (backslashes -> `/`, bare
      --   -- relative path gains `./`). Env-rooted targets (`$VAR/x`, `${VAR}/x`,
      --   -- `%VAR%/x`) never get a `./`.
      --   sanitize_on_save = true,
      --   -- Repair a `./` an older version wrote in front of an env-rooted target
      --   -- (`./$REPOS_DIR/x.md` -> `$REPOS_DIR/x.md`), only when the variable is set.
      --   repair_env_prefix = true,
      --   -- Where the cursor goes after the link-wrap keymap: the empty title, else
      --   -- the path, and into insert mode (lib.nvim.markdown.link_cursor).
      --   cursor = {
      --     enable = true, -- false: cursor inside the link, but normal mode
      --     startinsert = true, -- enter insert mode afterwards
      --     path_cursor = "end", -- in a filled path: "end" | "start"
      --   },
      --   -- Dead relative links / duplicate anchors via vim.diagnostic.
      --   diagnostics = {
      --     mode = "off", -- "off" | "save" (also rerun on BufWritePost)
      --   },
      -- },

      -- `:Markdown list` backend; same vocabulary as `links.picker`.
      -- list = {
      --   picker = "hover_select",
      -- },

      -- Link-target preview under the cursor; handed to hover.nvim, which accepts
      -- many more keys (see its spec in navigate.lua).
      -- hover = {
      --   enabled = true,
      --   -- "CursorHold" follows 'updatetime'; "mouse" also needs `:set mousemoveevent`.
      --   trigger = { "CursorHold" },
      --   delay_ms = 250,
      --   -- How long an async preview may take before a "rendering..." placeholder shows.
      --   placeholder_grace_ms = 250,
      --   max_lines = 20,
      --   max_width = 80,
      --   border = "rounded",
      --   -- Also hover a bare path without link syntax (must exist on disk).
      --   bare_paths = true,
      --   -- Buffers that get a hover: "*" or a filetype list.
      --   filetypes = "*",
      --   -- Draw images / rasterized PDF pages into the float (needs images.nvim).
      --   inline_images = true,
      --   url = {
      --     hover = false, -- whether a link hovers at all
      --     fetch = false, -- fetch the page for its status code (discloses links to hosts)
      --     timeout_ms = 2000,
      --   },
      --   -- Office documents: a badge by default; `convert` renders page 1 via LibreOffice.
      --   office = {
      --     convert = false,
      --     timeout_ms = 60000,
      --   },
      -- },

      -- Following an image target (`mi`): "ask" | "preview" (in-Neovim float) | "system".
      -- image = {
      --   preview = "ask",
      -- },

      -- Followed file targets with these extensions launch the system app; others
      -- open via :edit. Replaces the list, so give it in full.
      -- open = {
      --   external_extensions = {
      --     "png", "jpg", "jpeg", "gif", "bmp", "svg", "webp", "ico", "tif", "tiff", "pdf",
      --     "mp4", "mkv", "mov", "avi", "webm", "wmv", "flv", "mp3", "wav", "flac", "ogg", "m4a",
      --     "doc", "docx", "xls", "xlsx", "ppt", "pptx", "odt", "ods", "odp",
      --     "zip", "tar", "gz", "tgz", "7z", "rar", "exe", "msi", "dmg", "app",
      --   },
      -- },

      -- Blockquote colors; a fixed VS Code-style green, independent of the
      -- colorscheme. `false` for marker_fg/text_fg derives them from it instead.
      -- blockquote_hl = {
      --   marker_fg = "#6A9955", -- the `>` token
      --   text_fg = "#7EE787", -- text after `>`
      --   text_bg = "dimm", -- quoted text gets a dimmed bg derived from marker_fg
      --   text_bold = true,
      --   text_italic = false,
      --   -- How far that background reaches: "block" (as wide as the widest line of
      --   -- the contiguous `>` block) | "line" (own text only) | "window" (to the
      --   -- window edge, the former behavior) | <n> (at least n columns).
      --   width = "block",
      -- },

      -- Keep the treesitter underline on inline-link URLs/labels.
      -- link_hl = {
      --   underline = false,
      -- },

      -- TOC defaults for `<leader>toc` / `:Markdown toc`.
      -- toc = {
      --   header = "## Table of content",
      --   marker = "-", -- bullet prefix, e.g. "-" or "*"
      --   min_level = 2,
      --   max_level = 4,
      --   anchor_style = "gfm", -- "gfm" | "keep-case"
      --   anchor_separator = "-",
      -- },

      -- Keep `[text](#anchor)` links and the TOC in sync when headings are renamed.
      -- refs = {
      --   mode = "save", -- automatic runs: "off" | "save" (BufWritePre) | "live" (debounced)
      --   debounce_ms = 2000, -- live-mode debounce
      --   update_toc = true, -- refresh an existing TOC block on sync
      --   orphans = "report", -- "report" | "ignore" links whose #anchor matches no heading
      --   -- toc_header = nil, -- string; TOC header to detect, falls back to `toc.header`
      -- },

      -- Highlights for inline code in fenced blocks.
      -- fenced_fix = {
      --   -- Candidate groups for inline `code`; the first that exists wins.
      --   inline_base_hl = { "DiagnosticWarn", "Special", "Constant", "String" },
      --   inline_style = { italic = false, bold = false },
      --   delimiter_hl = "Comment", -- group for the backtick delimiters
      -- },

      -- Treat markdown-family fenced blocks as their own document scope.
      -- fenced_scope = {
      --   enable = true,
      --   langs = { "markdown", "md", "mdx", "ascii-markdown", "ascii-md" },
      --   provider = "auto", -- "auto" | "color_my_ascii" | "builtin"
      --   operations = {
      --     toc = true,
      --     nav = true,
      --     jump = true,
      --     shift = true,
      --     fold = true, -- scope-aware foldexpr
      --   },
      -- },
    },
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
