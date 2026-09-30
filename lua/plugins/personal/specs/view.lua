---@module 'plugins.personal.specs.view'
--- View & render -- personal plugin specs (Statusline/theme, pictures, video, PDF and markdown rendering.)
---
--- Category names follow the plugin website's registry
--- (wkd/src/data/registry.json). Source control -- local vs. remote vs.
--- disabled -- is NOT decided here but in plugins.personal.core.source; this
--- file only declares the specs. Registered from plugins/personal/init.lua.

---@type LazyPluginSpec[]
return {
  {
    -- Statusline/tabline/theme -- needs neither NvChad nor base46. The host's
    -- own statusline is wired into it by config/ui_statusline/init.lua at
    -- UIReady.
    --
    -- No `opts`/`config` on purpose, same reason as my.nvim: the setup()
    -- calls run from a startup phase (UIReady), and `opts` alone would make
    -- lazy run `require("ui").setup(opts)` at plugin-load time, well before
    -- that.
    --
    -- `keymaps` below is a custom field, not a lazy option: config/ui_statusline
    -- reads it through `require("lazy.core.config").plugins["ui.nvim"].keymaps`
    -- and passes it on to `ui.setup({ keymaps = ... })` unchanged. `true`
    -- (or leaving the field out) binds every shipped default, `false` binds
    -- none, a table (`{ next = "<C-Right>", close = false }`, see ui.nvim's
    -- docs/BINDINGS.md) remaps or drops single actions. Set to `true`
    -- explicitly so this line documents that the keymaps are wanted; the
    -- value equals the fallback.
    "StefanBartl/ui.nvim",
    lazy = false,
    priority = 900,
    dependencies = { "StefanBartl/lib.nvim" },
    keymaps = true,
    --
    -- OPTION REFERENCE (comment only, nothing here is executed).
    -- ui.nvim has two entry points; both are called from
    -- lua/config/ui_statusline/init.lua, not from this spec.
    --
    -- Part 1 -- arguments of require("ui").setup({...}): which submodules exist
    -- at all. Nothing is on by default except the contextmenu renderer.
    -- Currently set in config/ui_statusline/init.lua: usrcmds, keymaps (from the
    -- `keymaps` field above), sticky, menu. (ui.config.DEFAULTS lists the flat
    -- flags below as its `modules` table.)
    --
    -- {
    --   -- Shorthand for keymaps + usrcmds. Does NOT switch on sticky/context,
    --   -- notify or the menu table (those are explicit-only).
    --   -- all = false,
    --
    --   -- Buffer/tab keymaps. true = every default, false = none, a table
    --   -- remaps single actions (false = leave that one unbound).
    --   -- Set in config/ui_statusline/init.lua from the `keymaps` spec field
    --   -- (`true` there).
    --   -- keymaps = false,
    --   -- keymaps = {
    --   --   next = "<Tab>", -- next buffer
    --   --   prev = "<S-Tab>", -- previous buffer
    --   --   close = "<leader>bc", -- close buffer(s), count-aware
    --   --   close_all = "<leader>bq", -- close every listed buffer in the tab
    --   --   toggle_pin = "<leader>bp", -- pin/unpin the current tab
    --   --   reopen_closed = "<leader>bu", -- reopen the last closed tab
    --   --   move_right = "<leader>tr", -- move the buffer right in vim.t.bufs
    --   --   move_left = "<leader>tl", -- move the buffer left in vim.t.bufs
    --   --   move_to_tab = "<leader>tt", -- move the buffer to a new tab
    --   --   toggle_theme = "<leader>ut", -- swap between the two toggle themes
    --   --   theme_picker = "<leader>uP", -- visual theme picker with live preview
    --   --   toggle_sticky = { "<M-p>", "<leader>us" }, -- same switch as :UI sticky
    --   -- },
    --
    --   -- The `:UI` command family (theme, transparency, variant, sticky, ...).
    --   -- Set in config/ui_statusline/init.lua.
    --   usrcmds = true,
    --
    --   -- vim.notify rendered as toasts with a history. Explicit-only: it
    --   -- replaces the host's current handler. true = shipped tunables.
    --   -- notify = false,
    --   -- notify = {
    --   --   history_size = 200, -- entries kept for the history
    --   --   min_level = vim.log.levels.INFO, -- below this: recorded, not shown
    --   --   -- ms per level (0 = stays until cleared); merged per level.
    --   --   timeouts = {
    --   --     [vim.log.levels.TRACE] = 2000,
    --   --     [vim.log.levels.DEBUG] = 2000,
    --   --     [vim.log.levels.INFO] = 3000,
    --   --     [vim.log.levels.WARN] = 5000,
    --   --     [vim.log.levels.ERROR] = 8000,
    --   --     [vim.log.levels.OFF] = 0,
    --   --   },
    --   --   -- Toast title per level.
    --   --   titles = {
    --   --     [vim.log.levels.TRACE] = "Trace",
    --   --     [vim.log.levels.DEBUG] = "Debug",
    --   --     [vim.log.levels.INFO] = "Info",
    --   --     [vim.log.levels.WARN] = "Warning",
    --   --     [vim.log.levels.ERROR] = "Error",
    --   --   },
    --   -- },
    --
    --   -- Sticky code-context overlay (ui.context): the enclosing scopes, or in
    --   -- Markdown the heading chain, pinned over the window's first rows.
    --   -- Explicit-only (neither `all` nor absence turns it on). true = shipped
    --   -- tunables; `context` is the same switch under an older name, `sticky`
    --   -- wins when both are given. Set in config/ui_statusline/init.lua; the
    --   -- values shown active are the ones set there, the rest are defaults.
    --   -- context = false, -- same switch as `sticky` (older name)
    --   -- sticky = false,
    --   sticky = {
    --     -- Rows the overlay may take (0 = unlimited): one number, or a table
    --     -- keyed by filetype (else Tree-sitter language) with a `default` entry.
    --     max_lines = { default = 3, markdown = 6 },
    --     -- Which lines to drop past max_lines: "outer" | "inner".
    --     -- trim = "outer",
    --     -- A window shorter than this shows no context.
    --     -- min_window_height = 6,
    --     -- Refresh delay after a scroll/edit, in ms (0 = at once).
    --     -- debounce_ms = 30,
    --     -- Source line numbers in the gutter when 'number' is on.
    --     -- line_numbers = true,
    --     -- Lua patterns; a node type matching one is a scope. `^name$` names one
    --     -- exact type the excludes cannot veto. A list given here REPLACES the
    --     -- shipped one (see lua/ui/context/init.lua for the full default).
    --     -- node_types = { "function", "method", "^class", "^struct", "^if_statement$", "^for", "^while", ... },
    --     -- Lua patterns; a matching type is not a scope. Replaces the shipped list.
    --     -- exclude_node_types = { "call", "invocation", "argument", "parameter", "_type$", "^type", "declarator", "_expression$", "^string" },
    --     -- Filetypes that never get an overlay. Replaces the shipped list.
    --     -- exclude_filetypes = { "help", "qf", "neo-tree", "TelescopePrompt", "snacks_picker_input", "lazy", "mason" },
    --     -- Float zindex.
    --     -- zindex = 20,
    --     -- How Markdown headings are drawn; false = raw source lines.
    --     headings = {
    --       -- enable = true,
    --       max_level = 6, -- deepest heading level that is pinned (1..6)
    --       -- icons = {}, -- one glyph per level 1..6 (default: nf-md numeric boxes); false keeps the `#`s
    --     },
    --     -- Keep what `:UI sticky depth|lines` set across restarts.
    --     persist = true,
    --     -- Where it is kept; `~`/`$VAR` expanded, relative to the cwd at setup.
    --     -- state_file = nil, -- string; default stdpath("state") .. "/ui.nvim/sticky.json"
    --     -- Replaced as a whole table, not merged: an anchor-only call drops an
    --     -- earlier row/col.
    --     position = {
    --       -- top | bottom (full width) | top-left | top-right | top-center |
    --       -- bottom-left | bottom-right | bottom-center (compact box). Default "top".
    --       anchor = "top-right",
    --       -- row = nil, -- integer; exact row (0-based in the window), overrides the anchor
    --       -- col = nil, -- integer; exact column (0-based in the window), overrides the anchor
    --     },
    --     -- "mimic" = full-width rows that read like buffer lines; "chips" =
    --     -- coloured chips sized to their content. Default "mimic".
    --     style = "chips",
    --     -- Only read when style = "chips".
    --     chips = {
    --       layout = "stack", -- "row" (default) = one shared line | "stack" = one chip per line
    --       -- shape = "rounded_chip", -- "rounded_chip" (caps) | "chip" (flat) | "classic" (no background); "rounded"/"rect" still accepted
    --     },
    --   },
    --
    --   -- Right-click menu. false = disable the contextmenu renderer/trigger (the
    --   -- only opt-out here); true = default, binds nothing; a table configures
    --   -- AND binds ui.menu (takes over <RightMouse>). Set in
    --   -- config/ui_statusline/init.lua as below; `entries`/`hints` merge per key,
    --   -- `extra`/`contributors` replace.
    --   -- menu = true,
    --   menu = {
    --     -- mouse = true, -- bind <RightMouse>
    --     -- Also bind this key to the same menu at the cursor. Default false: no global key is taken unasked.
    --     key = "<A-b>",
    --     -- prewarm = true, -- load the sister plugins' menu modules in idle slices after startup
    --     -- renderer = "kit", -- needs no third-party menu plugin
    --     -- native_popup = false, -- keep Neovim's own right-click popup
    --     -- sections = { code = true, clipboard = true, file = true, delete = true, tools = true },
    --     entries = {
    --       -- format = true,
    --       -- code_actions = true,
    --       -- inspect = true,
    --       -- copy_all = true,
    --       -- copy_marked = true,
    --       -- paste = true,
    --       -- save = true,
    --       -- save_all = true,
    --       -- delete_marked = true,
    --       delete_all = true, -- destructive: default false
    --       delete_file = true, -- destructive: default false
    --       -- terminal = true,
    --       -- color_picker = true,
    --       -- unicode_table = true,
    --       -- git = true,
    --     },
    --     -- Right-aligned text per general entry (a mapping to show). Default {}.
    --     hints = {
    --       format = "<leader>fm",
    --       code_actions = "<leader>ca",
    --       copy_all = "<C-a>",
    --       copy_marked = "<C-c>",
    --       paste = "<C-v>",
    --       delete_marked = "dm",
    --       delete_all = "da",
    --       delete_file = "df",
    --       unicode_table = "uni",
    --     },
    --     -- Sister-plugin contributions: false = none, or per name ({ lsp = false }).
    --     -- integrations = true,
    --     -- More `<plugin>.integrations.menu`-style modules: { name, module, icon?, ft?, applies?, lazy? }[]
    --     -- contributors = {},
    --     -- Your own rows: { label, cmd|keys, section?, plugin?, ft?, when?, icon?, hint?, enabled? }[]
    --     -- extra = {},
    --   },
    -- }
    --
    -- Part 2 -- arguments of require("ui.config").setup({...}): what the frame
    -- looks like. Only these three keys are read; anything else warns and is
    -- ignored. Currently set in config/ui_statusline/init.lua: variant.
    --
    -- {
    --   -- Statusline preset: "default" | "minimal" | "lsp" | "blocks", a name
    --   -- registered via `require("ui.config.variants").register()`, or a fully
    --   -- built variant table. An unknown name falls back to "default" with a
    --   -- notification. Set there to "personal", this host's own variant
    --   -- (config/ui_statusline/variant.lua, registered just before).
    --   -- (ui.config.DEFAULTS: statusline.variant.)
    --   variant = "personal",
    --
    --   -- Theme toggling (`:UI toggle`, `:UI transparency`). Merged per key.
    --   -- theme = {
    --   --   theme_toggle = { "default", "tokyonight" }, -- the pair `:UI toggle` swaps between (real :colorscheme names)
    --   --   transparency = false,
    --   -- },
    --
    --   -- Tabline. Merged per key; `order` and `modules` replace.
    --   -- tabline = {
    --   --   order = { "tree_offset", "buffers", "tabs", "btns" }, -- segments, left to right
    --   --   tree_offset_ft = "filetree", -- filetype of the tree window the tree_offset module reserves space for
    --   --   modules = nil, -- table<string, fun(cfg): string>; per-key override of a built-in segment
    --   --   bufwidth = nil, -- integer; fixed chip width (unset = computed from the free space and buffer count)
    --   --   bufwidth_min = 12, -- lower clamp of the computed width (ignored when bufwidth is set)
    --   --   bufwidth_max = 24, -- upper clamp of the computed width (ignored when bufwidth is set)
    --   --   style = "rounded_chip", -- chip boundaries: "rounded_chip" | "chip" | "divider" | a name from ui.tabline.styles.register(); "rounded"/"square" still accepted
    --   --   context_menu = true, -- right-click on a chip opens its tab menu
    --   --   drag = true, -- press-and-drag a chip to reorder it
    --   --   middle_click_close = true, -- middle-click on a chip closes it
    --   -- },
    -- }
  },

  {
    "StefanBartl/color_my_ascii.nvim",
    ft = "markdown",
    dependencies = { "StefanBartl/lib.nvim" }, -- optional, enables graceful keymap/notify integration
    -- Typing `opts` as ColorMyAscii.Config makes lua_ls offer value completion
    -- inside the config (e.g. `preset = "…"` suggests the fence-line presets).
    -- Requires the plugin's types on the LSP path (lazydev/neodev or workspace lib).
    opts = {
      -- Every option of setup(); only `treesitter.block_detection` is set here.
      -- Name-keyed maps (`groups`, `keywords`, `languages`, `overrides`,
      -- `fence_language_map`, `fence_export.ext_map`, `fence_run.runners`,
      -- `fence_format.formatters`) are merged key by key over the defaults;
      -- lists (`comment_ascii.filetypes`) replace them.

      -- Toggle debug mode.
      -- debug_enabled = false,
      -- Also write debug logs to a file.
      -- debug_verbose = false,

      -- Colour scheme: "default" | "matrix" | "nord" | "gruvbox" | "dracula" |
      -- "catppuccin" | "onedark" | "solarized" | "tokyonight" | "monokai".
      -- scheme = "default",
      -- Named character groups: { [name] = { chars = "...", hl = <hl-group|attrs> } }.
      -- Populated from the shipped groups/ at setup; yours merge on top.
      -- groups = {},
      -- Per-language keyword definitions: { [lang] = { words, unique_words?, hl } }.
      -- Populated from the shipped languages/ at setup; usually left alone in
      -- favour of `languages`.
      -- keywords = {},
      -- Your own languages, same entry shape as `keywords`; a name matching a
      -- built-in overrides it. Malformed entries are skipped with a warning.
      -- languages = {},
      -- Single character -> highlight group (hl-group name or attrs); highest priority.
      -- overrides = {},
      -- Highlight for characters matching no rule (hl-group name or attrs).
      -- default_hl = "Normal",
      -- Highlight for normal text inside blocks; nil = leave it alone.
      -- default_text_hl = nil, -- string|table (hl-group name or attrs)

      -- Highlight keywords inside ASCII blocks.
      -- enable_keywords = true,
      -- Guess a block's language from its keywords.
      -- enable_language_detection = true,
      -- Minimum unique keyword matches for that guess (number >= 0).
      -- language_detection_threshold = 2,
      -- Treat a fence without a language tag as an ASCII block.
      -- treat_empty_fence_as_ascii = true,
      -- Highlight inline code spans.
      -- enable_inline_code = true,
      -- Heuristic function-name detection.
      -- enable_function_names = true,
      -- Highlight brackets/parentheses.
      -- enable_bracket_highlighting = true,

      -- Treesitter-based block detection and syntax highlighting. Both fall
      -- back to the heuristics when the parser is missing.
      treesitter = {
        -- Master switch for both sub-features.
        -- enabled = true,
        -- Force the CommonMark-correct heuristic scanner for fence detection
        -- (false): the installed markdown grammar differs between machines
        -- (no lockfile pinning) and some versions mis-parse a shorter fence
        -- nested in a longer one as its own block, giving spurious fence-line
        -- highlights. Default: true (treesitter).
        block_detection = false,
        -- Treesitter syntax highlighting inside fenced blocks.
        -- syntax_highlight = true,
      },

      -- ASCII blocks marked inside code comments of non-markdown files
      -- (`-- ascii` ... `-- /ascii`). Highlighting only; enabling it activates
      -- the plugin on those filetypes.
      -- comment_ascii = {
      --   enable = false,
      --   filetypes = { -- replaces the list
      --     "lua", "python", "javascript", "typescript", "go", "rust", "c", "cpp",
      --     "sh", "bash", "zsh", "ruby", "java", "kotlin", "scala", "swift", "dart",
      --     "elixir", "haskell", "perl", "r", "clojure", "groovy", "php", "csharp",
      --   },
      -- },

      -- Fence language tag -> plugin language. Fences whose tag is listed
      -- are treated as ASCII blocks and highlighted with that language.
      -- Additive: list only what you add or change.
      -- fence_language_map = {
      --   vim = "vim", vimscript = "vim", viml = "vim",
      --   bash = "bash", sh = "bash", shell = "bash", zsh = "bash",
      --   c = "c", cpp = "cpp", ["c++"] = "cpp",
      --   csharp = "csharp", ["c#"] = "csharp", cs = "csharp",
      --   lua = "lua",
      --   python = "python", py = "python",
      --   ruby = "ruby", rb = "ruby",
      --   php = "php",
      --   perl = "perl", pl = "perl",
      --   java = "java",
      --   kotlin = "kotlin", kt = "kotlin",
      --   scala = "scala",
      --   groovy = "groovy",
      --   clojure = "clojure", clj = "clojure",
      --   javascript = "javascript", js = "javascript",
      --   typescript = "typescript", ts = "typescript",
      --   html = "html",
      --   css = "css",
      --   json = "json",
      --   go = "go", golang = "go",
      --   rust = "rust", rs = "rust",
      --   zig = "zig",
      --   swift = "swift",
      --   dart = "dart",
      --   elixir = "elixir", ex = "elixir",
      --   haskell = "haskell", hs = "haskell",
      --   r = "r",
      --   sql = "sql",
      --   powershell = "powershell", ps1 = "powershell",
      --   llvm = "llvm",
      -- },

      -- Full-line highlight of the fence delimiter lines.
      -- fence_line_highlight = {
      --   enable = true,
      --   -- "auto" (match the colourscheme) | "subtle" | "accent" | "underline" | "bar" | <theme name>
      --   preset = "auto",
      --   -- Per-delimiter override: hl-group name or attrs table (nvim_set_hl).
      --   open = nil, -- string|table
      --   close = nil, -- string|table
      --   -- Which blocks get it: "all" | "ascii".
      --   apply_to = "all",
      --   -- Start at the block's own indent column instead of column 0.
      --   respect_indent = true,
      --   -- Columns held off the window's right edge (0-20).
      --   right_pad = 1,
      -- },

      -- Background tint of a fenced block's interior, so it reads as one region.
      -- fence_content_highlight = {
      --   enable = true,
      --   -- nil follows fence_line_highlight.preset; else the same values.
      --   preset = nil, -- string
      --   -- Explicit override (hl-group name or attrs); skips shading.
      --   hl = nil, -- string|table
      --   -- Shade of the resolved colour: "auto" | "darken" | "lighten" | "none".
      --   shade = "auto",
      --   -- Shade strength in percent (0-100).
      --   amount = 6,
      --   -- Which blocks get it: "all" | "ascii".
      --   apply_to = "all",
      --   -- Same as fence_line_highlight.respect_indent / .right_pad.
      --   respect_indent = true,
      --   right_pad = 1,
      -- },

      -- `:Fence export`.
      -- fence_export = {
      --   default_dir = "buffer", -- suggested path: "buffer" dir | "cwd"
      --   open_after = false, -- open the exported file afterwards
      --   open_cmd = "vsplit", -- "edit" | "split" | "vsplit" | "tabedit"
      --   replace = false, -- swap the block for a link to the file
      --   replace_format = "[%s](%s)", -- link format, args: (filename, relpath)
      --   ext_map = {}, -- language tag -> file extension, on top of the built-ins
      -- },

      -- `:Fence run`: interpreter per language tag (string or string[]); the
      -- temp file is appended as the last argument. Merged over the built-ins.
      -- fence_run = { runners = {} },

      -- `:Fence format`: stdin/stdout formatter per language tag (string[]).
      -- Merged over the built-ins (stylua, black, prettier, gofmt, ...).
      -- fence_format = { formatters = {} },

      -- Default keymaps; off so the plugin claims no global mapping unasked.
      -- false binds nothing, a table maps action name -> lhs (see docs/BINDINGS.md).
      -- keymaps = false,
      -- keymaps = {
      --   highlight = "<leader>ah",
      --   toggle = "<leader>at",
      --   toggle_buffer = "<leader>ab",
      --   schemes = "<leader>as",
      --   ensure_blank_lines = "<leader>af",
      --   show_config = "<leader>ac",
      --   debug = "<leader>ad",
      --   check_fences = "<leader>ax",
      --   fence_jump = "%",
      --   hover = "<leader>ai",
      --   fence_yank = "<leader>fy",
      --   fence_open = "<leader>fo",
      --   fence_run = "<leader>fr",
      --   fence_format = "<leader>fi",
      --   fence_select = "<leader>fv",
      --   fence_wrap = "<leader>fw",
      --   fence_unwrap = "<leader>fu",
      --   fence_align = "<leader>fg",
      --   fence_export = "<leader>fx",
      -- },

      -- Parse-cache tuning; nil = built-in values.
      -- cache = nil,
      -- cache = {
      --   timeout = 5000, -- validity of an entry, ms
      --   max_size = 50, -- buffers kept
      --   enable_stats = false, -- collect hit/miss statistics
      -- },
      -- Debounce tuning (line-count tiers); nil = built-in values.
      -- debounce = nil,
      -- debounce = {
      --   small_file_threshold = 500, -- lines
      --   medium_file_threshold = 2000, -- lines
      --   small_delay = 100, -- ms
      --   medium_delay = 200, -- ms
      --   large_delay = 500, -- ms
      --   min_delay = 50, -- ms
      --   max_delay = 1000, -- ms
      -- },

      -- Right-click menu entries (nvzone/menu is a soft dependency; `false`
      -- only stops M.items()/M.submenu() from returning entries).
      -- menu = { enable = true },
      -- Which hosts may drive the plugin: `ui_menu = false` keeps ui.nvim's
      -- right-click menu from composing the ASCII fly-out.
      -- integrations = { ui_menu = true },
    },
  },

  {
    "StefanBartl/images.nvim",
    -- Replaces snacks.image, which cannot work here in principle: it only
    -- sends Kitty APC, and WezTerm never draws that when Neovim is the
    -- sender. images.nvim uses OSC 1337 instead.
    --
    -- Both names are needed: `:Image` covers the command, the filetypes
    -- make sure <leader>im and the double-click are set in Markdown buffers
    -- even without a prior command call.
    cmd = { "Image" },
    ft = { "markdown", "vimwiki", "norg", "text" },
    dependencies = { "StefanBartl/lib.nvim" },
    opts = {
      -- Every option of setup(). Set here: display.cell_aspect, ocr.lang.
      -- Tables merge key by key over the defaults (and over the stored
      -- `:Image calibrate` result); lists replace the default list.

      -- Name of the user command.
      -- command = "Image",
      -- Extensions treated as images. svg is converted to PNG first (needs
      -- ImageMagick; WezTerm cannot decode SVG itself). Replaces the list.
      -- extensions = { "png", "jpg", "jpeg", "gif", "webp", "bmp", "svg" },

      display = {
        -- Maximum image size in terminal cells (OSC 1337 scales by itself, so
        -- no cell measurement is needed).
        -- max_cols = 60,
        -- max_rows = 25,
        -- Pixel aspect ratio (width/height) of one terminal cell; 0 = the 0.5
        -- assumption from images.scale, which leaves an empty strip below
        -- the image when the real cell is narrower. Set to the ratio measured
        -- for this WezTerm setup. Like terminal_padding, an explicit value
        -- overrides what `:Image calibrate` stored.
        -- Default: 0.
        cell_aspect = 0.46,
        -- Margin in cells kept free all round, so a fractional-cell window
        -- padding does not make the image spill past its frame. 0 = flush.
        -- draw_inset = 1,
        -- Fixed row/column offset in whole cells, for terminals whose OSC 1337
        -- placement ignores their own window padding. Deliberately NOT set
        -- here: `:Image calibrate` measures and stores it
        -- (stdpath("data")/images.nvim), and an explicit value here would
        -- silently override that calibration. draw_inset absorbs the
        -- sub-cell remainder.
        -- terminal_padding = { row = 0, col = 0 },
        -- Cells between gallery tiles.
        -- gallery_gap = 1,
        -- "overlay" draws over the text (gone on cursor movement); "float"
        -- opens a small unfocused window under the cursor. Only for
        -- `:Image show`/hover, not the gallery.
        -- hover_mode = "overlay",
        -- Skip terminal detection (terminal speaks OSC 1337 but is not
        -- recognised). Only silences the warning.
        -- assume_supported = false,
        -- Events that clear a drawn image. Replaces the list.
        -- clear_events = { "CursorMoved", "CursorMovedI", "InsertEnter", "BufLeave", "WinScrolled" },
        -- Directory names `:Image pickers` skips (".git" is always skipped).
        -- browse_exclude = { ".deps", "node_modules" },
        -- Upper bound on entries that scan visits; found results are still shown.
        -- browse_max_entries = 20000,
        -- `:Image zen` window size, as a fraction of the editor.
        -- zen = { width = 0.9, height = 0.85 },
        -- Remote images (`:Image show <url>`/hover only). Off so hovering a
        -- link never fires a network request unasked.
        -- remote = {
        --   enabled = false,
        --   timeout_ms = 10000,
        --   max_bytes = 20 * 1024 * 1024,
        --   cache_ttl_s = 24 * 60 * 60, -- how long a cached download is served
        -- },
        -- Windows only: `:Image screenshot` polls for the target file.
        -- screenshot = {
        --   windows_timeout_ms = 60000,
        --   windows_poll_interval_ms = 600,
        -- },
        -- `:Image redact`: safety margin around each marked box, in cells.
        -- redact = { padding_cells = 1 },
        -- Coloured block graphics via extmarks for terminals without OSC 1337
        -- (SSH, tmux without passthrough). Needs ImageMagick; single image only.
        -- ascii_fallback = {
        --   enabled = true,
        --   levels = 8, -- steps per colour channel (bounds the highlight groups used)
        --   cells = "sextant", -- "sextant" (2x3) | "quadrant" (2x2) | "half" (1x2); quadrant if sextants render as boxes
        -- },
        -- When the cursor sits on a bare filesystem path (no Markdown link),
        -- ask gopath.nvim (if installed) before falling back to <cfile>.
        -- gopath_fallback = true,
      },

      -- `:Image paste`.
      -- paste = {
      --   -- Directory next to the document; "" puts the image beside it.
      --   dir = "assets",
      --   -- An existing folder with one of these names (case-insensitive)
      --   -- is used instead of `dir`. Empty list disables the detection.
      --   existing_dir_names = { "Resources", "Ressourcen" },
      --   -- File name template, args: (document stem, os.time()).
      --   name_template = "%s-%d.png",
      --   -- Link inserted into the document, arg: (path).
      --   link_template = "![](%s)",
      --   -- Ask for alt text / a file name before inserting.
      --   ask_alt_text = false,
      --   -- Link used when alt text was asked for, args: (alt, path).
      --   alt_link_template = "![%s](%s)",
      --   ask_filename = false,
      --   -- How the link's path is spelled: "relative" | "absolute" | "repos"
      --   -- ($REPOS_DIR-rooted) | a custom prefix such as "/static/img" |
      --   -- false (ask every time). Never changes where the file is written.
      --   default_path_mode = "relative",
      --   -- Windows only: hang limit of one clipboard read on the PowerShell helper.
      --   windows_clipboard_timeout_ms = 20000,
      --   -- Windows only: keep one PowerShell process alive across pastes.
      --   windows_persistent_helper = true,
      -- },

      -- `:Image ocr` (tesseract).
      ocr = {
        -- Passed to tesseract's `-l`. `:Image ocr` and `:Case ocr` read
        -- customer screenshots that are German or English depending on the
        -- system that produced them; tesseract takes both at once in this
        -- form. `:checkhealth images` checks each language file separately.
        -- Default: "eng".
        lang = "deu+eng",
        -- Extra tesseract arguments, appended verbatim (e.g. { "--psm", "6" }).
        -- args = {},
        -- Absolute path to the tesseract binary; nil = PATH, then the usual
        -- Windows install directories.
        -- bin = nil, -- string
      },

      -- One-off popup listing the CLI tools the plugin wants, on the first
      -- setup() after installation (via lib.nvim.deps).
      -- deps_popup = true,

      -- PDF page drawn as a picture in a foreign picker's preview (needs
      -- pdfport.nvim and poppler's `pdftoppm`; otherwise the host keeps its
      -- own preview).
      -- pdf = {
      --   enabled = true,
      --   page = 1, -- which page (1-based)
      --   dpi = 120, -- rasterization resolution
      -- },

      -- Right-click menu entries (nvzone/menu is a soft dependency; `false`
      -- only stops M.items()/M.submenu() from returning entries).
      -- menu = { enable = true },
      -- Which hosts may drive the plugin: `ui_menu = false` keeps ui.nvim's
      -- right-click menu from composing the Images fly-out.
      -- integrations = { ui_menu = true },

      -- Buffer-local keymaps for `filetypes`; each accepts `false` to drop it.
      -- keymaps = {
      --   show = "<leader>im",
      --   gallery = "<leader>ig",
      --   next = "<leader>in",
      --   prev = "<leader>ip",
      --   paste = "<leader>iv",
      --   screenshot = "<leader>is",
      --   double_click = true, -- <2-LeftMouse> on a Markdown link shows the image
      --   filetypes = { "markdown", "vimwiki", "norg", "text" }, -- replaces the list
      -- },
    },
  },

  {
    "StefanBartl/mdview.nvim",
    dependencies = { "StefanBartl/lib.nvim" },
    build = "npm ci && npm run build:go && npm run build",
    ft = { "markdown" },
    cmd = { "MDView" },
    config = function()
      -- Every option of setup(). Set here: browser.highlighter/focus/
      -- cursor_marker and experimental.line_diff/click_navigate/reverse_scroll.
      -- Tables merge key by key over the defaults; lists replace them.
      require("mdview").setup({
        -- Filetype/glob patterns mdview's autocmds attach to (globs, not bare
        -- extensions). Replaces the list; `any_file` overrides it with "*".
        -- ft_pattern = { "*.md", "*.markdown", "*.mdx" },
        -- Preview any normal text buffer, not just Markdown: non-Markdown
        -- files render as a read-only syntax-highlighted code view, scroll
        -- sync falls back to proportional.
        -- any_file = false,

        -- Preferred port of the relay server.
        -- server_port = 43219,
        -- Working directory of the relay process; nil = default.
        -- server_cwd = nil, -- string
        -- Developer-only flag.
        -- dev_local = true,
        -- Echo the relay's stdout/stderr into Neovim (debugging only).
        -- debug = false,
        -- Scratch buffer name of that log.
        -- log_buffer_name = "mdview://logs",
        -- Write the relay's stdout to a persistent log file (`:MDView file-log`
        -- toggles it at runtime); nothing touches the disk when off.
        -- file_log = false,
        -- Where that file goes; nil = stdpath("log")/mdview/relay-<timestamp>.log.
        -- file_log_path = nil, -- string
        -- Plugin-internal debug notifications.
        -- debug_plugin = false,
        -- Notify on every live push (i.e. per keystroke).
        -- debug_preview = false,
        -- Vite dev-server port of the client (dev workflow only).
        -- dev_server_port = 43220,
        -- Minimum time between full-buffer pushes while typing, in ms; rapid
        -- edits coalesce into one trailing push. Saving is never throttled.
        -- live_push_throttle_ms = 150,

        -- Timing against the relay: how patient to be with a slow relay (a
        -- first-run binary under antivirus scan, a busy box). Raising the
        -- retry count without the timeout retries inside an expired window.
        -- transport = {
        --   health_poll_ms = 200, -- how often the relay is polled while it comes up
        --   health_timeout_ms = 15000, -- total wait for it to become healthy
        --   max_retries = 5, -- retries per message
        --   base_retry_ms = 150, -- first retry delay, backs off exponentially
        --   inbound_poll_ms = 250, -- how often the browser is polled for checkbox/field/navigate events
        -- },

        -- Send the cursor position so the browser preview follows (nvim -> browser).
        -- scroll_sync = true,
        -- Minimum time between those pings, in ms.
        -- scroll_sync_throttle_ms = 150,
        -- Where the cursor line lands in the browser viewport: "top" (near
        -- the top) | "cursor" (same relative height as in the nvim window).
        -- scroll_sync_mode = "top",
        -- In "top" mode: fraction (0..1) down from the viewport top (0 = glued).
        -- scroll_sync_top_offset = 0.08,
        -- Record session breadcrumbs (document + heading section over time)
        -- for `:MDView breadcrumbs`.
        -- breadcrumbs = true,
        -- Ticking a task-list checkbox in the preview writes back to the
        -- source; false keeps them read-only and stops the browser->nvim poll.
        -- sync_checkboxes = true,
        -- Same for editing a raw-HTML `<input name=...>`/`<textarea name=...>`
        -- field (matched by its `name` attribute).
        -- sync_fields = true,
        -- `:MDView start` opens an nvim-tab preview (Treesitter mirror, no
        -- browser/relay HTML) instead of the browser.
        -- open_preview_tab = false,
        -- One-off popup listing the CLI tools the plugin wants, on the first
        -- setup() after installation (via lib.nvim.deps).
        -- deps_popup = true,

        browser = {
          -- "default" = your normal browser as a new tab (no programmatic
          -- close); "isolated" = a separate mdview browser profile/window
          -- (auto-close works, no extensions).
          -- open_mode = "default",
          -- Locate a browser automatically (isolated mode only).
          -- autodetect_browser = true,
          -- Friendly name such as "chrome" or "firefox" (isolated mode only).
          -- browser = "",
          -- Absolute path of the executable to force (isolated mode only).
          -- browser_cmd = "",
          -- `:MDView stop` closes the controlled browser (isolated mode only).
          -- browser_autoclose = true,
          -- Open the browser automatically on start.
          -- browser_autostart = true,
          -- Extra CLI args for the resolved browser executable (isolated mode only).
          -- browser_args = nil, -- string[]
          -- Static URL used instead of the computed key/token URL.
          -- open_url = nil, -- string
          -- Do not auto-open a browser without a GUI/DISPLAY.
          -- require_display = true,
          -- Run `:MDView stop` when the opened browser exits (isolated mode only).
          -- stop_on_browser_exit = true,
          -- Preview theme: "github" | "dark-dimmed" | "plain" | "tokyonight" |
          -- "catppuccin", optionally suffixed "-light"/"-dark".
          -- theme = "github",
          -- What happens when you switch Markdown buffers: "reuse" (one tab
          -- follows the active buffer) | "new_tab" | "manual".
          -- behavior = "reuse",
          -- Code-fence highlighter: "hljs" (highlight.js) | "shiki" (exact
          -- VSCode themes, heavier) | "nvim" (Neovim's own colours via
          -- color_my_ascii.nvim) | "none". shiki mis-highlights some fences,
          -- hence hljs until that is fixed upstream; "hljs" equals the
          -- default, set explicitly to pin it.
          highlighter = "hljs",
          -- Whether the opened tab may take keyboard focus: "browser" | "nvim"
          -- (focus stays in Neovim; clean on macOS, best effort on Windows).
          -- Default: "browser".
          focus = "nvim",
          -- External links (http/mailto/absolute): "new_tab" keeps the
          -- preview tab | "same_tab".
          -- external_links = "new_tab",
          -- Neovim cursor in the preview: "line" (gutter marker) | "caret"
          -- (exact column) | "section" (spotlight on the heading section) |
          -- "off". Rides the scroll-sync ping, so needs scroll_sync.
          -- Default: "line".
          cursor_marker = "caret",
          -- Font-size zoom factor (1.0 = 100%); `:MDView zoom` changes it live.
          -- zoom = 1.0,
          -- Overlays that start enabled (`:MDView overlay`); for presenting.
          -- overlays = { toc = false },
          -- Show every blank line as extra vertical space instead of one
          -- paragraph gap (`:MDView blanklines`).
          -- preserve_blank_lines = false,
          -- Mirror the visual selection into the preview while presenting
          -- (`:MDView selection` toggles it).
          -- selection_sync = false,
        },

        -- Initial-push strategy of `:MDView start`.
        -- start = {
        --   push_strategy = "launcher", -- "launcher" | "try_push"
        --   try_push_opts = nil, -- table; forwarded to try_push
        --   wait_timeout_ms = nil, -- integer; forwarded to launcher.wait_ready
        -- },

        -- Where the relay release is downloaded from; pin another release by
        -- changing `version`.
        -- install = {
        --   repo = "StefanBartl/mdview.nvim", -- owner/repo; override for a fork
        --   version = "v0.3.0",
        -- },

        -- Relay binary and client bundle of `:MDView start`; nil = the release
        -- `install` manages (GitHub Releases, no toolchain needed). Set both to
        -- test a locally built relay (see mdview.nvim/docs/development.md;
        -- `npm run build:go` writes `mdview-server` without .exe on Windows).
        -- Falls back to $MDVIEW_DEV_BINARY / $MDVIEW_DEV_WEB_ROOT.
        -- dev = {
        --   binary_path = nil, -- e.g. vim.env.REPOS_DIR .. "/mdview.nvim/native/server/mdview-server"
        --   web_root = nil, -- e.g. vim.env.REPOS_DIR .. "/mdview.nvim/dist/client"
        -- },

        -- Relay binary of `:MDView standalone` (needs --watch support, v0.3.0+);
        -- nil = the one `install` manages.
        -- standalone = {
        --   binary_path = nil, -- e.g. vim.env.REPOS_DIR .. "/mdview.nvim/native/server/mdview-server"
        -- },

        experimental = {
          -- WebTransport (HTTP/3) client transport; falls back to WebSocket.
          -- No benefit on loopback.
          -- webtransport = false,
          -- Send only the changed lines per edit instead of the whole document.
          -- Default: false.
          line_diff = true,
          -- Clicking a relative link in the preview opens the document in
          -- nvim. Equals the default, set explicitly to keep it on.
          click_navigate = true,
          -- Scrolling the preview moves the nvim cursor (polled, slightly lagged).
          -- Default: false.
          reverse_scroll = true,
          -- any_file = nil, -- boolean; deprecated alias of the top-level `any_file`
        },
      })
    end,
  },

  {
    "StefanBartl/media.nvim",
    -- `VeryLazy` rather than `cmd = "Media"`: the four `<leader>M` keys have to
    -- exist before one is pressed, and a cmd trigger cannot bind them. The
    -- plugin file itself registers nothing at startup, so the cost is one
    -- require.
    --
    -- hover.nvim consumes this by name (`pcall(require, "media")`) for its
    -- video previews; it is listed as a dependency there rather than here, and
    -- neither plugin needs the other to load first.
    event = "VeryLazy",
    dependencies = { "StefanBartl/lib.nvim" },
    opts = {
      -- Every option of setup(). Set here: frame, sheet, player,
      -- keymaps.preset. Tables merge key by key over the defaults; lists
      -- replace them. See docs/configuration.md for the reasoning behind
      -- each number.

      -- Explicit binary paths, for a tool that is installed but not on PATH
      -- (the Windows winget/scoop shim-directory case: a terminal started
      -- before the install lacks the directory). `core.bin` probes the usual
      -- locations itself; this is the escape hatch for what it misses.
      -- `:checkhealth media` reports what was found.
      -- bin = {
      --   ffmpeg = nil, -- string
      --   ffprobe = nil, -- string
      --   -- Audio player behind `media.audio`; without it playback is silent,
      --   -- nothing else fails.
      --   mpv = nil, -- string
      --   -- whisper.cpp CLI behind `media.transcribe`; the only feature that needs it.
      --   ["whisper-cli"] = nil, -- string
      -- },

      -- Hard ceiling on one ffmpeg/ffprobe run, in ms: the backstop for a
      -- stalled network mount or a truncated download, where ffmpeg waits
      -- forever instead of failing.
      -- timeout_ms = 15000,

      -- The poster frame (`media.frame` / `:Media frame`). Both values equal
      -- the defaults, written out so they can be tuned here.
      frame = {
        -- Seconds, "10%" of the duration, or an ffmpeg timestamp. A percentage
        -- because frame one of a real video is usually black or a logo.
        at = "10%",
        -- Pixel width the still is scaled to (height follows).
        width = 800,
      },

      -- A run of stills at a fixed rate (`media.frames`): what hover.nvim's
      -- inline transport draws as moving picture.
      -- frames = {
      --   from = nil, -- number|string; nil starts at the beginning
      --   fps = 12, -- stills per second of source sampled (not the playback rate)
      --   count = 24, -- stills per run: two seconds at fps = 12
      --   width = 320, -- pixel width before sampling down to cells
      -- },

      -- The contact sheet (`media.sheet` / `:Media sheet`): one picture of the
      -- whole file. All values equal the defaults, written out for tuning.
      sheet = {
        rows = 3,
        cols = 4,
        -- Width of the finished sheet, not one tile.
        width = 1200,
        -- margin = 4, -- gap between tiles, in pixels
        -- A sheet is a pass over the whole file, not a seek: own ceiling, in ms.
        -- timeout_ms = 120000,
      },

      -- Waveform/spectrogram picture of an audio file or a video's soundtrack.
      -- waveform = {
      --   width = 1200, -- pixels
      --   height = 300, -- pixels
      --   -- `showwavespic` colour (ignored by the spectrogram); always passed
      --   -- because ffmpeg's white default vanishes on a light background.
      --   colors = "#9cdcfe",
      --   timeout_ms = 120000, -- whole-file pass, own ceiling
      -- },

      -- Transcription (`:Media transcribe`).
      -- transcribe = {
      --   engine = "whisper_cpp", -- registered engine tried first
      --   fallback = {}, -- engines tried in order when `engine` is unavailable
      --   lang = nil, -- string; ISO 639-1 code, nil lets the engine detect it
      --   task = "transcribe", -- "transcribe" keeps the language | "translate" gives English
      --   -- Where a finished transcript goes: "buffer" | "sidecar"
      --   -- (.transcript.md beside the source) | "srt" | "vtt".
      --   output = "buffer",
      --   cache = true, -- cross-session cache, keyed by the source's mtime plus engine/lang/task
      --   timeout_ms = 0, -- ceiling on the transcription call; 0 = none (real runs take minutes)
      --   normalize_timeout_ms = 120000, -- ceiling on the WAV extraction before the engine runs
      --   whisper_cpp = {
      --     -- Absolute path to a GGML model file (e.g. ggml-base.en.bin); the
      --     -- plugin never guesses or downloads one.
      --     model = nil, -- string
      --   },
      -- },

      -- Where rendered stills live: on disk, outliving the session (keyed by
      -- the source file's mtime, so a kept file is safe to serve forever).
      -- cache = {
      --   enabled = true,
      --   dir = nil, -- string; default stdpath("cache") .. "/media.nvim"
      -- },

      -- How many ffmpeg renders may run at once. A bound on a storm (a held
      -- paging key in a video hover reached 30 processes), not a throughput
      -- knob. A playback window jumps the queue regardless.
      -- render_concurrency = 4,

      -- The dashboard (`:Media`, `:Media dashboard`).
      -- hub = {
      --   -- Directory names a scan skips, besides `.git` and `node_modules`
      --   -- (always skipped). Replaces the list.
      --   exclude = { ".venv", "target", "dist", "build", ".cache" },
      --   -- Upper bound on entries one scan visits; hitting it stops quietly.
      --   max_entries = 20000,
      -- },

      -- How `:Media transcribe` shows progress (lib.nvim.progress styles):
      -- "auto" | "notify" | "statusline" | "fidget" | "float" | "kit".
      -- Only "float" has a cancel key (<Esc> in normal mode stops the whole
      -- pipeline).
      -- progress_style = "auto",

      -- What `media.play` / `:Media play` launches, and what hover.nvim's
      -- system-player fallback uses when there is no mpv (or
      -- `video.use_mpv = false`). nil hands the file to the system's default
      -- handler, which on Windows opens *behind* the terminal: only the
      -- process owning the foreground may raise a window, and inside a
      -- terminal that is the terminal host, not nvim.exe. A string or argv
      -- list ("mpv", { "mpv", "--loop-file=no" }) overrides it.
      -- Default: nil (equals the default, set explicitly).
      player = nil,

      -- The windowed mpv player (`media.play_window` / `:Media window` /
      -- hover.nvim's `<CR>`). Always mpv, unlike `player`: a controllable
      -- window needs the same binary every time.
      --
      -- No static `window.args = { "--screen=1" }` on purpose: hover.nvim's
      -- `<CR>` detects the terminal's monitor and passes a per-call `screen`
      -- to `play_window`. A static `--screen=1` would be appended after it,
      -- win, and pin the window to one monitor whatever nvim's position.
      -- Only add it if the dynamic detection is turned off.
      -- window = {
      --   autofit = "80%x80%", -- mpv's --autofit-larger; "" leaves the size to mpv
      --   ontop = true, -- stay above the terminal regardless of focus
      --   args = {}, -- extra mpv flags, appended before the file
      -- },

      -- `<leader>M` group; each key accepts a string, a list, or false.
      keymaps = {
        -- false binds nothing at all. Equals the default, set explicitly.
        preset = true,
        -- probe = "<leader>Mp",
        -- frame = "<leader>Mf",
        -- sheet = "<leader>Ms",
        -- play = "<leader>Mo",
        -- Which-key group registration: true | false | a table of group options.
        -- which_key = true,
      },
    },
  },

  {
    "StefanBartl/pdfport.nvim",
    -- Only ":PdfPort <sub>" is ever registered (composer.verb, see
    -- lua/pdfport/bindings/usrcmds.lua); the plugin has no separate
    -- PdfPortText/Float/System/Terminal/Health commands.
    cmd = "PdfPort",
    opts = {
      -- Every option of setup(). Set here: default_backend, fallback_chain,
      -- extract_opts, render_opts.mode/split/focus, claude_api_key,
      -- progress_style, ollama_host, ollama_model, debug. Tables merge key by
      -- key over the defaults; lists (chains) replace them.

      -- Backend `:PdfPort` extracts with: "auto" (walk `fallback_chain`) or a
      -- backend id. Equals the default, set explicitly.
      default_backend = "auto",
      -- Order tried under "auto". REPLACES the default
      -- { "pdftotext", "pdfplumber", "marker", "docling", "ollama", "tesseract", "claude", "gemini" }:
      -- here without "tesseract" and "gemini". A registered backend missing
      -- from the list is still reachable under "auto" (appended after the
      -- chain); the list decides order, not membership.
      fallback_chain = { "pdftotext", "pdfplumber", "marker", "docling", "ollama", "claude" },
      extract_opts = {
        -- Pages to extract; nil = all.
        -- pages = nil, -- integer[]
        -- Extract at most this many pages; nil = all. Equals the default.
        max_pages = nil,
        -- Backend-specific model and prompt for the AI backends; nil = the backend's own.
        -- model = nil, -- string
        -- prompt = nil, -- string
        -- Ceiling on one extraction, in ms (backends may raise it to 120 s).
        -- Equals the default, set explicitly.
        timeout_ms = 30000,
        -- Cache successful extractions across sessions (keyed by path +
        -- backend + page range, invalidated by mtime).
        -- cache = true,
      },
      render_opts = {
        -- "buffer" | "float" | "terminal" | "system". Equals the default.
        mode = "buffer",
        -- Where the buffer mode opens: "current" replaces the window instead of
        -- the default "vsplit" (right) | "split" (below) | "tab".
        split = "current",
        -- Focus the result window. Equals the default.
        focus = true,
        -- Terminal mode: image tool "chafa" | "kitty" | "imgcat"; nil = auto-detected.
        -- terminal_tool = nil, -- string
        -- Terminal mode: pdftoppm rasterization DPI (positive number).
        -- terminal_dpi = 216,
        -- Terminal mode: fraction of the editor size the image uses, each in (0, 1].
        -- terminal_size_ratio = { width = 0.9, height = 0.8 },
        -- Float mode: extra nvim_open_win options.
        -- float_opts = nil, -- table
      },
      -- Producers for `pdfport.create()`.
      -- create_opts = {
      --   page_size = "A4",
      --   margin = "20mm",
      --   dpi = 300, -- image path only
      --   fit = "contain", -- "contain" | "fill" | "native"
      --   timeout_ms = 60000, -- creation can outlast extraction
      -- },
      -- Producer fallback chain per input kind; a kind you name replaces that
      -- kind's list.
      -- create_chain = {
      --   image = { "img2pdf", "magick" },
      --   markdown = { "pandoc" },
      --   text = { "pandoc" },
      --   html = { "weasyprint", "chromium" },
      --   office = { "soffice" },
      --   pdf = { "qpdf", "pdftk", "ghostscript" }, -- the merge chain of pdfport.merge()
      -- },
      -- pandoc's `--pdf-engine` preference: "auto" (tectonic, typst, xelatex,
      -- lualatex, pdflatex) or one of them.
      -- pdf_engine = "auto",
      -- Anthropic key, handed to ai.nvim per request (never exported). nil
      -- falls back to $ANTHROPIC_API_KEY, so nothing is stored here.
      claude_api_key = nil,
      -- Same for the gemini backend; nil falls back to $GEMINI_API_KEY.
      -- gemini_api_key = nil, -- string
      -- Indicator while a backend extracts: "auto" | "notify" | "statusline" |
      -- "fidget" | "float" | "kit". OCR/AI backends run for minutes on a large
      -- PDF and the indicator cannot cancel them (see pdfport's docs), so a
      -- non-interactive style only. Default: "auto".
      progress_style = "statusline",
      -- ollama host, handed to ai.nvim per request. Equals the default.
      ollama_host = "http://localhost:11434",
      -- Model the ollama backend uses. Default: "llava".
      ollama_model = "qwen2.5-coder:7b",
      -- Opt-in BufReadCmd for *.pdf: `:e file.pdf` opens the mode picker.
      -- auto_open_on_read = false,
      -- One-off popup listing the CLI tools the plugin wants, on the first
      -- setup() after installation (via lib.nvim.deps).
      -- deps_popup = true,
      -- Equals the default, set explicitly.
      debug = false,
    },
  },
}
