---@module 'plugins.personal.specs.navigate'
--- Personal plugin specs: Files & navigation.
---
--- Paths, hover previews, pickers, trees, file operations and sessions.
---
--- Category names follow the plugin website's registry
--- (wkd/src/data/registry.json). Source control -- local vs. remote vs.
--- disabled -- is NOT decided here but in plugins.personal.core.source; this
--- file only declares the specs. Registered from plugins/personal/init.lua.

local personal_utils = require("plugins.personal.core.utils")

---@type LazyPluginSpec[]
return {
  {
    "StefanBartl/gopath.nvim",
    event = "VeryLazy",
    -- Optional, not required: every nvim-treesitter call in gopath.nvim
    -- (health.lua's parser check, providers/treesitter.lua's Neovim-0.9
    -- ts_utils fallback) is pcall-guarded; almost everything else runs on
    -- built-in vim.treesitter. Kept here only because telescope.lua already
    -- pulls it in as a hard dep, so listing it costs nothing and documents
    -- the (optional) coupling explicitly.
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    opts = {
      -- Print debug notifies.
      -- dev_mode = false,

      -- Resolution strategy: "hybrid" | "lsp" | "treesitter" | "builtin".
      -- Equals the default, set explicitly so the strategy is visible here:
      -- LSP first, then Treesitter, then the plain builtin resolvers.
      -- Default: "hybrid".
      mode = "hybrid",
      -- Provider order tried in "hybrid" mode. Replaces the list, so give it
      -- in full.
      -- order = { "lsp", "treesitter", "builtin" },
      -- How long the LSP provider may take before the next one is tried, in ms.
      -- lsp_timeout_ms = 200,

      -- Per-filetype resolver configuration. `enable = false` switches the
      -- language resolvers off for that filetype (universal features such as
      -- file paths and help tags keep working). `resolvers` (string[]) is a
      -- whitelist of resolver names for the filetype, `custom_resolvers`
      -- (table|string module name) are user resolvers run BEFORE the built-in
      -- ones; both nil = all built-in resolvers. A partial table merges per key.
      -- languages = {
      --   lua = { enable = true, resolvers = nil, custom_resolvers = nil },
      --   python = { enable = true, resolvers = nil, custom_resolvers = nil },
      --   javascript = { enable = true, resolvers = nil, custom_resolvers = nil },
      --   javascriptreact = { enable = true, resolvers = nil, custom_resolvers = nil },
      --   typescript = { enable = true, resolvers = nil, custom_resolvers = nil },
      --   typescriptreact = { enable = true, resolvers = nil, custom_resolvers = nil },
      --   rust = { enable = true, resolvers = nil, custom_resolvers = nil },
      --   go = { enable = true, resolvers = nil, custom_resolvers = nil },
      --   c = { enable = true, resolvers = nil, custom_resolvers = nil },
      --   cpp = { enable = true, resolvers = nil, custom_resolvers = nil },
      --   cs = { enable = true, resolvers = nil, custom_resolvers = nil },
      --   zig = { enable = true, resolvers = nil, custom_resolvers = nil },
      --   java = { enable = true, resolvers = nil, custom_resolvers = nil },
      -- },

      -- Fuzzy alternate: offer close matches when the resolved file is missing.
      alternate = {
        -- Offer alternates at all. Equals the default, set explicitly.
        enable = true,
        -- Minimum similarity (0-100) for a candidate; higher is stricter.
        -- Equals the default, set explicitly.
        similarity_threshold = 75,
        -- Candidates chosen from the dialog before rise within their
        -- similarity band, so history breaks near-ties but never inverts a
        -- clear winner.
        -- frecency = {
        --   enable = true, -- false records nothing and reorders nothing
        --   max_bonus = 10, -- band size in similarity points; 0 records but no longer reorders
        --   dir = nil, -- string; storage directory, nil = lib.nvim's stdpath("data")/lib.nvim/frecency
        -- },
      },

      -- Open non-text files (images, PDFs, ...) with an external program.
      external = {
        -- Equals the default, set explicitly.
        enable = true,
        -- extensions = nil, -- string[]; extra extensions, EXTENDS the built-in list
        -- PDF handling; only takes effect when pdfport.nvim is installed, else
        -- a PDF always goes to the system viewer.
        -- pdf = {
        --   picker = true, -- false: always open with `default`, no chooser
        --   default = "system", -- mode used when picker = false: "system" | "buffer" | "float" | "terminal"
        -- },
      },

      -- URLs under the cursor open in the browser instead of resolving to a file.
      -- url = {
      --   enable = true,
      --   bare_hosts = true, -- also accept "github.com/x" / "git@github.com:a/b.git"; only after every file resolver missed
      --   schemes = nil, -- string[]; extra URL schemes, EXTENDS the built-in list
      --   tlds = nil, -- string[]; extra TLDs for bare_hosts, EXTENDS the built-in list
      -- },

      -- $VAR / ${VAR} prefix expansion, and the reverse shortening commands.
      -- env_variable_resolution = {
      --   enable = true,
      --   -- Segment name -> env var name, for :GopathToReposDir. Structural:
      --   -- a path whose root segment is "repos" (any drive, any OS) becomes
      --   -- `$REPOS_DIR` whatever $REPOS_DIR resolves to on this machine.
      --   shorten_dirs = { repos = "REPOS_DIR" },
      --   -- Var name -> absolute path or resolver function, for well-known
      --   -- directories: :GopathToNvimDir shortens literal occurrences, and
      --   -- forward resolution falls back to it when no real env var of that
      --   -- name is set (a real one wins).
      --   shorten_known_dirs = {
      --     NVIM_CONFIG_DIR = function()
      --       return vim.fn.stdpath("config")
      --     end,
      --   },
      -- },

      -- Offer to create a resolved-but-missing file instead of erroring
      -- (the `gC` / :GopathCheck key always offers, regardless of `enable`).
      -- create_on_missing = {
      --   enable = true,
      --   confirm = true, -- false: create silently, no dialog
      -- },

      -- Truncated ("...") path resolution via a cache of known files.
      -- truncated = {
      --   enable = true,
      --   use_cache = true,
      --   cache_refresh_interval = 600, -- seconds between automatic refreshes
      --   -- How long the per-runtimepath-entry name index stays valid, in ms.
      --   -- Lower it if you install plugins while Neovim is running.
      --   rtp_index_ttl_ms = 30000,
      --   max_cache_age = 3600, -- seconds before the cache counts as stale
      --   live_search_fallback = true, -- fd/rg/find when the cache misses
      --   similarity_threshold = 75, -- for picking among several matches
      --   cache_roots = nil, -- table; nil = auto-detect drives/stdpaths
      --   max_depth = 6, -- maximum directory depth to scan
      --   excluded_dirs = { ".git", ".github", "node_modules", "target", "build", ".cache", "venv" }, -- replaces the list
      --   watch_patterns = nil, -- string[]; nil = { "*.lua", "*.vim" }
      --   auto_rebuild_on_save = false,
      -- },

      -- Whole-line path extraction.
      -- linepath = {
      --   enable = true, -- scan the whole line for path-like candidates
      --   cascade = true, -- run linepath inside the resolve pipeline
      -- },

      -- Cache + filesystem suffix search for partial paths.
      -- tailsearch = {
      --   enable = true,
      --   max_components = 6, -- longest path suffix, in components, to try
      --   ask_on_ambiguous = true, -- vim.ui.select when several files match
      --   roots = nil, -- string[]; nil = auto (buffer dir, cwd, git root, stdpath dirs)
      --   limit = 100, -- maximum matches collected per search
      -- },

      -- Normal-mode keymaps (`false` disables one; a list binds several lhs;
      -- `mappings = false` disables all).
      mappings = {
        -- Open the path under the cursor in the current window: "gF" instead of
        -- the default "gP", so it replaces Neovim's own `gF`. `<2-LeftMouse>` is
        -- deliberately not bound: gopath maps its lhs globally in normal mode,
        -- so every double-click in any buffer would run a path resolve instead
        -- of selecting the word under the cursor.
        -- Default: "gP".
        open_here = "gF",
        -- Equals the default, set explicitly: open in a horizontal split.
        open_split = "g|",
        -- Equals the default, set explicitly: open in a vertical split.
        open_vsplit = "g\\",
        -- Equals the default, set explicitly: open in a new tab.
        open_tab = "g}",
        -- Reveal in the system file manager instead of opening.
        -- open_explorer = "gM",
        -- Reveal in filetree.nvim instead of opening (soft dependency).
        -- open_filetree = "gT",
        -- Equals the default, set explicitly: copy file:line:col.
        copy_location = "gY",
        -- Equals the default, set explicitly: debug output for the resolution.
        debug = "g?",
        -- Probe keymap (normal and visual mode).
        -- probe = "<leader>pp",
        -- Check the path and offer to create it when missing.
        -- check = "gC",
      },

      -- User commands; `false` skips one, `commands = false` skips all.
      -- commands = {
      --   resolve = true, -- :GopathResolve
      --   open = true, -- :GopathOpen
      --   copy = true, -- :GopathCopy
      --   debug = true, -- :GopathDebug
      --   check = true, -- :GopathCheck
      --   to_repos_dir = true, -- :GopathToReposDir
      --   to_nvim_dir = true, -- :GopathToNvimDir
      -- },

      -- Label the probe keymap via which-key.nvim when it is installed.
      -- which_key = true,

      -- One-time popup listing the CLI tools this plugin wants (lib.nvim.deps),
      -- shown on the first setup() after install.
      -- deps_popup = true,

      -- Which hosts may drive this plugin; `ui_menu = false` keeps ui.nvim's
      -- right-click menu from composing the "Paths" entry.
      -- integrations = {
      --   ui_menu = true,
      -- },
    },
  },

  {
    -- Path/link hover for every filetype. Lives in its own plugin rather than
    -- in lib.nvim because it opens windows, installs autocmds in every
    -- buffer, borrows keymaps, ships usercommands and knows four sibling
    -- plugins by name -- see documentation.nvim/docs/ECOSYSTEM.md for the
    -- rule behind that split.
    --
    -- `lazy = false` because `enable()` must run from something that isn't
    -- itself lazy: markdown.nvim is ft-lazy on Markdown, so a session that
    -- never opens a .md would otherwise get no hover at all -- exactly the
    -- case this feature is meant to cover (paths in .txt, code comments,
    -- :messages). `priority` sits below lib.nvim, a hard dependency.
    --
    -- Only the video playback choices below are set -- every other feature
    -- switch (web links + fetch/shot, office documents via pdfport, zen,
    -- persist, zoom keys, `auto_hover`) runs on hover.nvim's own defaults.
    -- Full behaviour, the two-axis on/auto distinction, and measured costs
    -- (browser start, page render, LibreOffice conversion) are documented in
    -- hover.nvim/docs/configuration.md and docs/FEATURES/*.md; `:Hover why`
    -- / `:Hover status` explain a given switch at runtime.
    "StefanBartl/hover.nvim",
    lazy = false,
    priority = 900,
    dependencies = { "StefanBartl/lib.nvim" },
    config = function()
      -- Every option hover.nvim has, current value active and everything
      -- else commented out with its own default -- see docs/configuration.md
      -- and docs/FEATURES/*.md for the full reasoning behind each one.
      require("hover").setup({
        -- "auto": the trigger opens a float by itself, for the types listed
        -- in auto_hover below. "manual" keeps every preview but the trigger;
        -- "off" (or vim.g.hover_disable) stops everything.
        -- mode = "auto",

        -- Which target *types* the automatic trigger opens for -- gates the
        -- trigger only, `:Hover show` always answers for every type. A table
        -- merges additively (`{ file = true }` adds one type); a list of type
        -- names replaces the whole setting. Default shown in full.
        -- auto_hover = {
        --   image = true, pdf = true,
        --   anchor = false, directory = false, file = false, git = false,
        --   markdown = false, missing = false, office = false, url = false,
        --   video = false, position = false,
        -- },

        -- Write mode/auto_hover/every switch back to disk on exit, so a
        -- runtime `:Hover links web on` survives past this session.
        -- persist = true,

        -- "CursorHold" (follows 'updatetime'), "cursor" (CursorMoved + this
        -- plugin's own debounce), "mouse" (needs 'mousemoveevent' too).
        -- trigger = { "CursorHold" },

        -- Debounce before the float opens, in ms.
        -- delay_ms = 250,

        -- How long an async preview may take before a "rendering..."
        -- placeholder is allowed to interrupt.
        -- placeholder_grace_ms = 250,

        -- Preview line cap / float height.
        -- max_lines = 20,
        -- Float width cap, in columns.
        -- max_width = 80,

        -- Float border style: none/single/double/rounded/solid/shadow, or
        -- this plugin's own heavy/ascii/dashed/block, or an 8-char list.
        -- border = "rounded",

        -- Draw pictures and rasterized PDF pages when a provider can;
        -- degrades to format/dimensions/size as text otherwise.
        -- inline_images = true,

        -- Buffers the hover attaches to (any non-empty 'buftype' is excluded
        -- regardless -- pickers, trees, terminals, dashboards).
        -- filetypes = "*",

        -- Targets written with link syntax (markdown.nvim contributes the
        -- source).
        -- links = {
        --   enabled = true,   -- follow [text](./doc.md)-style links at all
        --   web = false,      -- preview what a URL *is* (host/path/query)
        --   fetch = false,    -- also fetch the URL's response for that preview
        --   timeout_ms = 2000,
        --   pdf = {           -- a link answering application/pdf, as its first page
        --     enabled = false,
        --     max_bytes = 25000000,
        --     timeout_ms = 30000,
        --     cache_days = 7,
        --   },
        --   shot = {          -- a link rendered by a headless browser (JS runs!)
        --     enabled = false,
        --     eager = false,  -- let the *automatic* trigger render one too
        --     timeout_ms = 20000,
        --     width = 1280,
        --     height = 900,
        --     cache_days = 7,
        --     delay_ms = 1000,
        --     command = nil,  -- nil finds a browser on PATH/usual install dirs
        --   },
        -- },

        -- Targets with no link syntax: a path in prose, a comment, :messages.
        -- paths = {
        --   enabled = true,  -- bare paths are targets at all
        --   missing = true,  -- mark a bare path that resolves to nothing
        --   code = false,    -- also look for paths inside executable code,
        --                    -- not just comments/strings (Treesitter-gated)
        --   scope = { prose = {}, code = {} }, -- extra capture families to trust
        -- },

        -- Whether a registered *position* preview (a plugin describing where
        -- the cursor is, not what it points at) may open a float at all.
        -- positions = true,

        -- Office documents (.docx/.xlsx/.pptx/.odt and legacy binary forms).
        -- office = {
        --   convert = false,   -- render page 1 via LibreOffice (seconds, per doc)
        --   timeout_ms = 60000,
        --   cache_days = 7,
        -- },

        -- Video: the still, the paging-key scrub, and what `<CR>` does.
        video = {
          -- Where the first still comes from: seconds, "10%" of the running
          -- time, or an ffmpeg timestamp.
          -- at = "10%",
          -- How far one paging-key press moves. Same shapes as `at`.
          -- step = "10%",
          -- Still's render width in pixels; nil lets media.nvim choose.
          -- width = nil,

          -- What `<CR>` does: "window" (default) opens a real mpv window, or
          -- without mpv the system's own player; "inline" paints block
          -- graphics into the float instead of either.
          -- playback = "window",

          -- Whether "window" may reach for mpv at all. false = "I have mpv,
          -- do not use it" -- skips straight to the system-player fallback
          -- (real video+sound, just not mpv) and silences inline's optional
          -- sound too. Different from playback = "inline", which also gives
          -- up that fallback entirely for silent block graphics.
          -- Default: true (set false here, so the system player is used).
          use_mpv = false,

          -- ---------------------------------------------------------------
          -- EXPERIMENTAL (system-player window positioning) -- nested under
          -- its own key so it reads as clearly separate from ordinary
          -- playback settings above. None of these three do anything when
          -- there is an mpv window (only with no mpv, or use_mpv = false
          -- above), and the second and third only matter at all when the
          -- first is true. Nothing here is load-bearing for ordinary
          -- playback; all three are "best effort, may silently do nothing"
          -- by design -- see docs/FEATURES/VIDEO.md.
          -- ---------------------------------------------------------------
          experimental = {
            -- Best-effort centre whatever window the system-player fallback
            -- opens, on the monitor the terminal is on right now. Whether it
            -- does anything depends on what is registered on the machine (a
            -- UWP handler on Windows historically ignores it; macOS needs
            -- Accessibility permission; Linux needs xdotool/wmctrl and no
            -- Wayland in the way). Never reports failure either way.
            -- Default: false (set true here).
            system_player_align = true,

            -- Only consulted when system_player_align is true. A fullscreen
            -- window defeats alignment before it starts (a player that opens
            -- in its remembered fullscreen state looks the same as
            -- alignment off), so the fallback first tries a known, scriptable
            -- player by name (`vlc --no-fullscreen`, today) before the
            -- system's own handler, giving alignment a non-fullscreen window
            -- to act on. false always goes through the system handler.
            -- Equals the default, set explicitly.
            system_player_prefer_classic = true,

            -- Only consulted when system_player_align is true. A known player
            -- that misses on PATH is tried again against the install
            -- locations Windows actually uses (Program Files / Program Files
            -- (x86)), since a Windows installer routinely does not extend
            -- PATH. false searches PATH only.
            -- Equals the default, set explicitly.
            system_player_search_installs = true,
          },

          -- Whether an *inline* played run may start audio via mpv, when the
          -- file has a track. A "window" playback always has its player's
          -- own sound and ignores this.
          -- sound = true,

          -- Where *playing* starts (not where the still is taken from).
          -- Same three shapes as `at`; a scrubbed still (page 2+) is honoured
          -- regardless and starts there instead.
          -- play_at = 0,
          -- How much larger the playing canvas is than the still's budget,
          -- capped to the editor's own rows/columns. 1 = the still's size.
          -- play_scale = 2.5,
          -- Stills per second in a played (inline) run.
          -- fps = 12,
          -- Stills one decoded (inline) window holds -- two seconds at fps=12.
          -- run = 24,
          -- Pixel width of a run's stills before sampling; nil sizes it from
          -- the canvas.
          -- run_width = nil,
        },

        -- The float on (almost) the whole editor and back -- `:Hover zen`, `F`.
        -- zen = {
        --   pin = true, -- pin the float so the next keystroke does not close it
        -- },

        -- Keys borrowed globally while a hover is on screen, handed back on close.
        -- scroll_keys = { down = { "<M-PageDown>", "<C-Down>" }, up = { "<M-PageUp>", "<C-Up>" } },
        -- resize_keys = {
        --   larger = { "+" }, smaller = { "-" },
        --   wheel_larger = { "<M-ScrollWheelUp>" }, wheel_smaller = { "<M-ScrollWheelDown>" },
        -- },
        -- dismiss_keys = { "q", "<Esc>" },
        -- open_keys = { "gf" }, -- open what the float shows, externally
        -- nav_keys = { left = { "h" }, right = { "l" }, up = { "k" }, down = { "j" } }, -- pan while zoomed; also moves in a directory's mini filetree
        -- dir_keys = { click = { "<LeftMouse>" } }, -- click an entry in a directory hover's mini filetree ({} = no click); a click that misses the float is replayed as a normal click
        -- position_keys = { next = { "<M-n>" } }, -- step to the next position-preview contributor
        -- zoom_keys = { into = { ">" }, out = { "|" }, reset = { "=" } },
        -- zen_keys = { toggle = { "F" } },
        -- transport_keys = { toggle = { "<CR>" }, forward = { "." }, back = { "," } }, -- video play/pause, frame step

        -- Keymaps this plugin sets in the user's own namespace.
        -- keymaps = { show = false }, -- string|string[]|false; a key for `:Hover show`

        -- Your own sources, previews and position previews, registered under
        -- the name "user" (handed to hover.registry, never stored in the
        -- options).
        -- contribute = nil, -- Hover.Contribution

        -- Legacy spellings, still accepted on input and then dropped:
        -- deprecated -- enabled = false is read as mode = "off".
        -- enabled = nil, -- boolean
        -- deprecated -- read as paths.enabled.
        -- bare_paths = nil, -- boolean
        -- deprecated -- folded into links (hover -> web, fetch, timeout_ms).
        -- url = nil, -- { hover?: boolean, fetch?: boolean, timeout_ms?: integer }
      })
      require("hover").enable()
    end,
  },

  {
    "StefanBartl/open.nvim",
    -- All three names are needed: the viewer commands are registered by
    -- open.nvim's setup(), so lazy-loading on "Open" alone would leave
    -- :UrlView / :MDLinksView undefined until something else pulled the
    -- plugin in.
    cmd = { "Open", "UrlView", "MDLinksView" },
    dependencies = { "StefanBartl/lib.nvim" },
    opts = {
      -- User command name.
      -- command = "Open",
      -- Handler keys used when `:Open` gets no explicit target: paths / URLs.
      -- default_filemanager = "filemanager",
      -- default_browser = "browser",
      -- Handler modules to load; also what `:Open` tab-completes. Replaces the
      -- list, so give it in full.
      -- handlers = { "filemanager", "browser", "notepad", "nvim_internal", "default", "terminal", "image" },
      -- Load the built-in scope keywords (shell profiles, git, SSH, ...).
      -- builtin_keywords = true,
      -- User keyword -> path (or `function(): string|nil`) additions/overrides.
      -- keywords = {},
      -- Extra handlers registered after `handlers`; each is { key, desc, run }.
      -- custom_handlers = {},
      -- Keymaps for fixed invocations (none by default): open_default and
      -- open_<handler key> (open_browser, open_split, ...), value is the lhs.
      -- keymaps = {},

      -- `filemanager` handler.
      -- filemanager = {
      --   -- true: select a file in its parent dir; false: just open the parent dir.
      --   reveal = true,
      --   -- command = nil, -- string|string[]; launcher override, path appended as last arg
      -- },

      -- Redirect Office documents to the system app on any read (BufReadCmd).
      -- office_open = {
      --   enabled = true,
      --   extensions = { "doc", "docx", "xls", "xlsx", "ppt", "pptx" },
      -- },

      -- Log every context-gather and dispatch step to :messages.
      -- debug = false,

      -- Show a handler picker for ambiguous no-target `:Open` instead of guessing.
      -- picker = { enabled = false },

      -- Whether nvzone/menu entries are provided at all.
      -- menu = {
      --   enable = true,
      -- },

      -- `ui_menu = false` keeps ui.nvim's right-click menu from composing the
      -- Open fly-out.
      -- integrations = {
      --   ui_menu = true,
      -- },

      -- `:Open viewer [kind]`: list links in a scope.
      -- viewer = {
      --   -- Wrapper command per filter; false skips registering it.
      --   commands = {
      --     urls = "UrlView", -- only browser-openable targets
      --     mdlinks = "MDLinksView", -- only markdown-syntax links
      --     all = false, -- everything; use `:Open viewer` instead
      --   },
      --   sort = "none", -- "none" | "file" | "kind" | "alpha"
      --   output = "picker", -- "picker" | "table" | "clipboard" | "mdlinks" | "csv"
      --   mdlinks_output = "clipboard", -- sink for `out=mdlinks`
      --   open_file = "split", -- handler for a picked local file: "split" | "vsplit" | "tab"
      -- },
    },
  },

  {
    -- Eager: setup() derives roughly twenty keymaps from the `collections`
    -- table below (`<leader>mnf`, `<leader>wkg`, ...). Lazy-loading on `keys`
    -- would mean listing every one of those lhs in the spec as well, kept in
    -- step with the table by hand -- two sources for the same bindings, and
    -- the drift only shows up as a key that silently does nothing.
    "StefanBartl/pickers.nvim",
    lazy = false,
    dependencies = { "StefanBartl/lib.nvim" },
    config = function()
      local repos = personal_utils.repos_path
      require("pickers").setup({
        -- Which picker engine runs. "snacks" instead of the default "auto" so every
        -- collection opens in the same UI regardless of what else is installed.
        -- Values: "auto" | "telescope" | "fzf" | "snacks".
        -- Default: "auto" (first available of telescope, fzf-lua, snacks).
        engine = "snacks",
        -- One-time "which CLI tools does this plugin want" popup on first setup().
        -- deps_popup = true,
        -- Root directory of the git repositories (the "repos" scope and the base
        -- of every collection below). Passed explicitly so it also works through
        -- the local-checkout fallback when $REPOS_DIR is unset.
        -- Default: nil (resolved from $REPOS_DIR via lib.nvim's env snapshot).
        repos_dir = repos,

        -- File-listing behaviour of the built-in file pickers. The `system` scope
        -- builds its own fd command and ignores this table.
        find = {
          -- Show dotfiles.
          -- hidden = true,
          -- Also list files ignored by .gitignore / .ignore.
          -- no_ignore = false,
          -- Follow symlinks.
          -- follow = true,
          -- Extra globs to skip, e.g. { "node_modules", "*.min.js" }.
          -- exclude = nil, -- string[]
          -- One exclude list for every engine (lib.nvim.fs.ignore.list), also
          -- patched onto the native :FzfLua / :Telescope / Snacks pickers.
          -- Default: false.
          ignore_list = true,
          -- Apply `exclude` to the engines' native pickers too (no-op while
          -- `exclude` is empty).
          -- native = true,
        },

        -- Enable the :Pickers user commands and the generated collection commands.
        -- usercmds = { enable = true },

        -- Layout switches patched onto every engine's global config, so native
        -- pickers follow too. All default to nil (the engine keeps its own behaviour).
        display = {
          -- Shorten long paths via the engine's own mechanism.
          -- path_shorten = false,
          -- Wrap around at either end of the list, on every engine.
          -- Default: nil (engine default).
          cycle = true,
          -- Prompt above the results, on every engine.
          -- Default: nil (engine default).
          prompt_top = true,
          -- Preview line wrapping off, on every engine.
          -- Default: nil (engine default).
          preview_wrap = false,
          -- Telescope: shorten paths to the picker width (lib.nvim fs.path_shorten).
          -- Default: nil (off).
          path_adaptive = true,
        },

        -- Image previews via images.nvim (soft dependency, inert without it).
        -- images = {
        --   enabled = true, -- false keeps the engine's text preview
        --   pdf_text = true, -- telescope + pdfport.nvim: undrawable PDFs preview as extracted text
        -- },

        -- filetree.nvim's `f` / `gr` run through this plugin when it is installed.
        -- filetree = { enabled = true }, -- false makes filetree use its own backends

        -- Named scopes; each gets :Pickers <name> files/grep/smart, compat commands
        -- and the listed keymaps. Collection fields:
        --   name      string  unique scope name
        --   dir       string  root directory
        --   prefix    string  nil = `dir` is the search root, "" = pick among all subdirs,
        --                     "xyz-" = only subdirs starting with "xyz-"
        --   keys      table   { files = lhs, grep = lhs, smart = lhs }
        --   only_git  boolean only subdirs containing .git
        --   exclude   string[] subdir basenames to hide (exact match)
        --   find      table   per-collection override of `find`, merged over the global one
        collections = {
          {
            name = "notes",
            dir = repos .. "/Notes",
            keys = { files = "<leader>mnf", grep = "<leader>mng", smart = "<leader>mns" },
          },
          {
            name = "notes_lua",
            dir = repos .. "/WKDBooks/Development/wkdbook-Lua",
            keys = { files = "<leader>mlf", grep = "<leader>mlg" },
          },
          {
            name = "notes_nvim",
            dir = repos .. "/WKDBooks/Development/wkdbook-Neovim",
            keys = { files = "<leader>mvf", grep = "<leader>mvg" },
          },
          {
            name = "checklists",
            dir = repos .. "/WKDBooks/Development/wkdbook-Lua/Checklists",
            keys = { files = "<leader>chf", grep = "<leader>chg" },
          },
          {
            name = "spickzettel",
            dir = repos .. "/WKDBooks/Spickzettel",
            keys = { files = "<leader>spf", grep = "<leader>spg" },
          },
          {
            name = "wkdbooks",
            dir = repos .. "/WKDBooks",
            prefix = "wkdbook-",
            keys = { files = "<leader>wkf", grep = "<leader>wkg", smart = "<leader>wks" },
          },
          {
            name = "wkdbooks_lua",
            dir = repos .. "/WKDBooks/Development/wkdbook-Lua",
            keys = { files = "<leader>wlf", grep = "<leader>wlg" },
          },
          {
            name = "wkdbooks_nvim",
            dir = repos .. "/WKDBooks/Development/wkdbook-Neovim",
            keys = { files = "<leader>wvf", grep = "<leader>wvg" },
          },
          {
            -- prefix = "" lists all immediate subdirs (cascade.nvim, ui.nvim, ...).
            -- These are doc folders mirroring each plugin's name, not the
            -- actual git clones (those live directly under REPOS_DIR), so
            -- only_git can't filter them -- exclude hides the bookkeeping
            -- siblings (ALL/, TEMPLATES/, TOOLS/, _Telemetry/) by name instead.
            -- :PluginsBookFiles/:PluginsBookGrep (pickers.nvim usrcmds) override
            -- the generic Files/Grep compat commands with an [plugin]-arg +
            -- tab-completion variant; :PluginsBookSmart stays generic.
            name = "plugins_book",
            dir = repos .. "/WKDBooks/Development/wkdbook-myplugins",
            prefix = "",
            exclude = { "ALL", "TEMPLATES", "TOOLS", "_Telemetry" },
            keys = { files = "<leader>pbf", grep = "<leader>pbg", smart = "<leader>pbs" },
          },
        },

        -- Named dir aliases for the `dir` navigation picker. Additive: merged over
        -- the four built-ins below, so only list your own or overrides.
        -- depth_aliases = {
        --   cwd = function() return vim.uv.cwd() or vim.fn.getcwd() end,
        --   home = function() return vim.uv.os_homedir() or vim.fn.expand("~") end,
        --   root = function() ... end, -- filesystem root of the cwd
        --   git = function() ... end, -- nearest .git ancestor of the cwd, else the cwd
        --   work = function() return "/home/user/work" end, -- example of your own
        -- },

        -- Fixed keymap fields. Each is an lhs or nil/false (off); `enable = false`
        -- turns the whole table off.
        keymaps = {
          -- enable = true,
          -- cwd_files = nil, -- find files in the cwd
          -- cwd_grep = "<leader>li", -- live grep in the cwd
          -- config_files = "<leader>fc", -- find files in the nvim config
          -- config_grep = "<leader>gc", -- grep in the nvim config
          -- folder_files = "<leader>fb", -- find in an interactively picked folder
          -- dir_pick = "<leader>dp", -- dir navigation picker
          -- explorer = "<leader>.", -- file explorer / browser on the active engine
          -- repos_files = nil, -- pick a repo, then find files
          -- repos_grep = nil, -- pick a repo, then live grep
          -- system_files = nil, -- systemwide fd search (prompts for a query)

          -- Smart action: one picker running grep (content) + find (filenames)
          -- for the same query, merged and ranked by relevance. See
          -- pickers.nvim docs/COMMANDS.md#the-smart-action.
          -- Default: nil (opt-in, unopinionated like cwd_files).
          cwd_smart = "<leader>CW", -- smart grep+find in CWD
          config_smart = "<leader>CF", -- smart grep+find in nvim config
          -- folder_smart = nil, -- smart grep+find in a picked folder
          -- Forces hidden + no_ignore + follow for this one search (= `:Pickers cwd files all`).
          -- Was a direct ":Telescope find_files follow=true no_ignore=true hidden=true"
          -- call in bindings/mappings/telescope.lua; engine-agnostic here instead
          -- (2026-10-01, externe-plugins report §9.2).
          cwd_find_all = "<leader>fa",
        },

        -- Declarative mappings surface: any pickers.builtins name, or any
        -- <scope>_<files|grep|smart|find_all>, each with its own lhs -- the
        -- flexible alternative to the fixed `keymaps` fields above. Entry shape:
        -- { lhs | { lhs, ... }, engine?, desc?, nowait? }; `engine` pins one
        -- entry to "telescope" | "fzf" | "snacks", and a missing engine falls back
        -- to the default one. Default: {} (no mappings).
        -- Collection scopes work too, e.g. `notes_grep = { "<leader>ng", "fzf" }`.
        mappings = {
          -- They dispatch through pickers.builtins / :Pickers, whichever engine is
          -- active. `recent` shows the list form: one picker on two keys.
          command_history = { "<leader>:", desc = "Command History" },
          notifications = { "<leader>N", desc = "Notification History" },
          cwd_files = { "<leader>ff", desc = "Find Files" },
          projects = { "<leader>pro", desc = "Projects" },
          recent = { { "<leader>fo", "<leader>old" }, desc = "Recent Files" },
          git_branches = { "<leader>gB", desc = "Git Branches" },
          git_log = { "<leader>gl", desc = "Git Log" },
          git_log_line = { "<leader>gL", desc = "Git Log Line" },
          git_status = { "<leader>gs", desc = "Git Status" },
          git_stash = { "<leader>gS", desc = "Git Stash" },
          git_diff = { "<leader>gD", desc = "Git Diff (Hunks)" },
          git_log_file = { "<leader>gf", desc = "Git Log File" },
          gh_issue = { "<leader>gi", desc = "GitHub Issues (open)" },
          gh_issue_all = { "<leader>gI", desc = "GitHub Issues (all)" },
          gh_pr = { "<leader>gp", desc = "GitHub Pull Requests (open)" },
          gh_pr_all = { "<leader>gP", desc = "GitHub Pull Requests (all)" },
          lines = { "<leader>cb", desc = "Buffer Lines" },
          grep_buffers = { "<leader>cB", desc = "Grep Open Buffers" },
          cwd_grep = { "<leader><leader>", desc = "Grep" },
          commands = { "<leader>com", desc = "Commands" },
          keymaps = { "<leader>fk", desc = "Keymaps" },
          man = { "<leader>sM", desc = "Man Pages" },
          help = { "<leader>help", desc = "Help Pages" },
          colorschemes = { "<leader>ch", desc = "Colorschemes" },
          -- Were direct ":FzfLua quickfix"/"treesitter" calls in
          -- bindings/mappings/fzf.lua, same lhs kept (2026-10-01, externe-plugins
          -- report §9.2).
          quickfix = { "<leader>fq", desc = "Quickfix" },
          treesitter = { "<leader>ftf", desc = "Search Tree-sitter Symbols" },
          undo = { "<leader>UN", desc = "Undo History" },
          lsp_definitions = { "GD", desc = "Goto Definition" },
          lsp_declarations = { "gD", desc = "Goto Declaration" },
          lsp_references = { "GR", desc = "References", nowait = true },
          lsp_implementations = { "GI", desc = "Goto Implementation" },
          lsp_type_definitions = { "GY", desc = "Goto Type Definition" },
          lsp_incoming_calls = { "GAI", desc = "Calls Incoming" },
          lsp_outgoing_calls = { "GAO", desc = "Calls Outgoing" },
          lsp_symbols = { "<leader>SS", desc = "LSP Symbols" },
          lsp_workspace_symbols = { "<leader>sS", desc = "LSP Workspace Symbols" },
          -- Uncommitted files (staged/unstaged/both, toggle rows at the top of
          -- the list): pickers.nvim's own `git_status_filtered` builtin, NOT the
          -- native `git_status` picker already on <leader>gs above.
          -- <leader>gm because <leader>g{s,S,l,L,B,D,f,i,I,p,P} and bare gb/gd/gg
          -- are all taken across this ecosystem's git keymaps (pickers.nvim,
          -- gitsuite.nvim, neogit, diff.nvim).
          git_status_filtered = { "<leader>gm" },
        },

        -- Native picker history under stdpath("data")/pickers.nvim/history.
        -- Telescope's history is process-wide; snacks has its own and ignores this.
        history = {
          -- Default: false.
          enabled = true,
          -- fzf-lua only: "plugin" (per-provider files, pickers.nvim's own calls) |
          -- "global" (you merge history.fzf_opts() yourself) | "patch" (pickers.nvim
          -- patches fzf-lua's and telescope's setup() itself, so the native pickers
          -- share the history without any other config change).
          -- Default: "plugin".
          fzf_scope = "patch",
          -- dir = nil, -- string; default stdpath("data")/pickers.nvim/history
          -- limit = 200, -- entries kept per history
        },

        -- Unified in-picker keys: preview scroll, history navigation, entry
        -- actions. Each action takes one lhs, a list of lhs, or `false` to unbind it.
        -- fzf-lua binds only the vertical scroll and fixed entry-action keys.
        keys = {
          -- enable = true,
          -- preview_scroll_down = "<PageDown>",
          -- preview_scroll_up = "<PageUp>",
          -- Alt+Left/Right scroll the preview horizontally instead of the default
          -- <C-Left>/<C-Right>.
          -- Default: "<C-Left>" / "<C-Right>".
          preview_scroll_left = "<M-Left>",
          preview_scroll_right = "<M-Right>",
          -- history_back = "<C-p>",
          -- history_forward = "<C-n>",
          -- create_file = "<C-a>",
          -- open_background = { "<S-CR>", "<C-o>" }, -- preload the entry's buffer, keep the picker open
          -- open_background_show = false, -- also display (not focus) it in the window behind the picker
          -- preview_toggle = false, -- telescope only; fzf-lua/snacks ship <F4> / <A-p>
          -- split = "<C-s>",
          -- vsplit = "<C-v>",
          -- tab = "<C-t>",
          -- mouse_confirm = "<2-LeftMouse>", -- double-click opens a result
          -- cheatsheet = { "<C-/>", "<M-?>" }, -- panel listing every bound key
          -- Path-copy entry actions on the marked entries, else the current one.
          -- copy_absolute = { "<C-y>", "[a", "[f" },
          -- copy_dirname = { "<M-y>", "]a" },
          -- copy_env_rooted = { "<M-v>", "[e" }, -- $REPOS_DIR/... form
          -- copy_project_root = { "<M-t>", "[R" },
          -- copy_project_relative = { "<M-e>", "]R" },
          -- copy_buffer_relative = { "<M-j>", "]b" },
          -- markdown_link = { "<M-l>", "ML", "MM" },
          -- Same links, but INSERTED into the window behind the picker (closes the
          -- picker, cursor into the first link, insert mode). See `link_insert` below.
          -- markdown_link_insert = { "<M-n>", "MI" },
          -- Hand the entry to the OS: default application / file manager.
          -- open_system = { "<M-o>", "<leader>sm" },
          -- reveal_in_manager = { "<M-x>", "<leader>fm" },
          -- Switch between the targets of a tab group (telescope + snacks). On
          -- <Tab>/<S-Tab> they only switch while a group is active (`<leader>s`);
          -- in every other picker they keep the engine's own multi-select.
          tab_next = "<Tab>",
          tab_prev = "<S-Tab>",
        },

        -- The "insert Markdown link(s)" entry action (`keys.markdown_link_insert`).
        -- link_insert = {
        --   -- How the link path is spelled: "buffer" (relative to the target buffer,
        --   -- ./x ../x) | "cwd" | "absolute" | "env" ($REPOS_DIR/..., $NVIM_CONFIG_DIR/...;
        --   -- via gopath.nvim's shorten_path when installed, else "buffer").
        --   path = "buffer",
        --   cursor = {
        --     enable = true, -- false: cursor behind the inserted text
        --     startinsert = true, -- insert mode, cursor where the link still needs typing
        --     path_cursor = "end", -- in a filled path: "end" | "start"
        --   },
        -- },

        -- Live result count in the prompt title (telescope only; the others show one natively).
        -- result_count = {
        --   enabled = false,
        --   interval_ms = 150, -- poll interval while a picker is open
        -- },

        -- Smart action: rg (content) + fd (filenames) merged into one ranked list.
        -- smart = {
        --   weights = { filename = 1.0, content = 1.0, both = 25 }, -- `both` = flat bonus for a file matched by name AND content
        --   limit = 2000, -- max merged results kept after ranking
        --   timeout = 3000, -- per-command (rg / fd) wait in ms
        --   frecency = {
        --     enabled = false, -- recency/frequency ranking boost
        --     weight = 1.0,
        --     dir = nil, -- string; default stdpath("data")/pickers.nvim
        --   },
        --   dedup_grep_rows = false, -- collapse several grep hits per file to the best line
        -- },

        -- Tab groups: named lists of `:Pickers` argument strings, cycled with
        -- keys.tab_next/tab_prev. A group given here replaces the default group of
        -- the same name wholesale; `false` drops one.
        -- Replaces search.nvim's tabbed UI (Files / All Files / Grep / Buffers, plus the
        -- `git` collection). `<leader>s` opens `default`; `:Pickers tabs git` the other.
        tabs = {
          groups = {
            default = { "cwd files", "cwd files all", "cwd grep", "builtin buffers" },
            git = { "builtin git_branches", "builtin git_log", "builtin git_stash" },
          },
        },

        -- The quickfix / location window: preview float + refine filter over the list.
        -- quickfix = {
        --   enabled = true,
        --   preview = {
        --     enabled = true,
        --     height = 12, -- rows
        --     context = 4, -- lines shown above the entry's line
        --     border = "rounded",
        --     delay_ms = 40, -- debounce after CursorMoved
        --   },
        --   keys = { -- buffer-local; false unbinds
        --     filter = "zf", -- refine
        --     restore = "zF",
        --     toggle_preview = "p",
        --   },
        -- },
      })
    end,
  },

  -- {
  --   "StefanBartl/neotree-fs-refactor",
  --   lazy = false,
  --   config = function()
  --     require("neotree-fs-refactor").setup({
  --       enabled = false,
  --       auto_save = true,
  --       notify_on_refactor = true,
  --       ignore_patterns = require("lib.nvim.fs.ignore.list").as_luals_patterns(),
  --       file_types = {
  --         lua = true,
  --         typescript = true,
  --         javascript = true,
  --         typescriptreact = true,
  --         javascriptreact = true,
  --         python = true,
  --       },
  --       max_file_size = 10 * 1024 * 1024,
  --       debounce_ms = 10,
  --     })
  --   end,
  -- },

  {
    "StefanBartl/filetree.nvim",
    event = "VeryLazy", -- must load AFTER the tree plugin's config function runs
    dependencies = {
      "StefanBartl/lib.nvim", -- shared helpers (neo-tree node utils, etc.)
      -- ui.kit / ui.contextmenu: the right-click menu (on by default).
      "StefanBartl/ui.nvim",
      -- only ONE tree plugin is needed:
      "nvim-neo-tree/neo-tree.nvim",
      -- or: "nvim-tree/nvim-tree.lua",
    },
    config = function()
      require("filetree").setup({
        -- Which tree plugin filetree drives. Pinned to neo-tree instead of
        -- auto-detection so the backend cannot change when another tree plugin is
        -- installed.
        -- Values: "auto" | "neotree" | "nvimtree" | "netrw" | "oil" | "mini_files".
        -- Default: "auto" (first available, in that order).
        adapter = "neotree",
        -- Show notifier.debug(...) messages (troubleshooting).
        -- debug = false,
        -- Hide common clutter (.git, node_modules, ...) from the tree.
        -- Values: true (built-in list) | false (show everything) | string[] (custom list).
        -- ignore_list = true,
        -- Confirmation prompts for paste / delete / rename_batch. nil keeps each
        -- feature's own default (delete asks, the others do not); true/false sets all
        -- three; a table sets one, e.g. { delete = false }. A feature's own
        -- `confirm` wins over this.
        -- confirmations = nil, -- boolean | { paste?, delete?, rename_batch? }
        -- One-time "which CLI tools does this plugin want" popup on first setup().
        -- deps_popup = true,
        -- Progress indicator for batch operations (trash, paste, ...).
        -- Values: "auto" (fidget if installed, else notify) | "notify" | "statusline" |
        -- "fidget" | "float" | "kit".
        -- progress_style = "auto",
        -- Cap on nodes collected in one walk of the rendered tree (a guard against a
        -- directory expanded with tens of thousands of entries).
        -- max_visible_nodes = 5000,
        -- Global key remap over every feature keymap: { ["<old>"] = "<new>" }, or
        -- { ["<key>"] = false } to drop one.
        -- keymaps = nil, -- table<string, string|false>
        -- Override the adapter's own native keymaps after they are set: false -> <Nop>,
        -- string -> remap target, e.g. { ["i"] = false }.
        -- adapter_keymaps = nil, -- table<string, string|false>
        -- User command name (or { name, aliases }); default "Filetree" plus the alias "Ft".
        -- command = nil, -- string | { name = string, aliases = string[] }
        -- Disable the autocmds of single features: { auto_reveal = false }.
        -- autocmds = nil, -- table<string, false>

        -- Reference engine: keeps markdown links and require()/import statements
        -- pointing at the right file after a rename / move / delete.
        refs = {
          -- enabled = true,
          -- Languages taking part; a third-party provider counts as on unless false.
          -- providers = { markdown = true, lua = true, python = true, ts_js = false },
          -- What happens once references are found: "ask" (chooser) | "auto" (update
          -- everything) | "off" (do not scan).
          -- on_rename = "ask",
          -- on_move = "ask",
          -- on_delete = "ask", -- trash: mark the now-dangling links as REF!
          -- copy = false, -- a copy leaves the original in place, so nothing breaks
          -- Backend of the "Select..." multi-select: "auto" | "telescope" | "fzf-lua" | "quickfix".
          -- picker = "auto",
          -- Skip the textual code providers when an LSP client already applied a
          -- workspace edit for the rename.
          -- prefer_lsp = true,
          -- Also scan [[wiki]]-style links.
          -- wiki_links = false,

          -- Also rewrite bare filesystem paths written as running text
          -- (`see ../Test/Tester.md` in a note) or in code comments, not just paths
          -- inside link/require/import syntax. A token is only rewritten when it
          -- resolves to exactly the file that moved. Opt-in and namespaced under
          -- `experimental` because the config shape may still move.
          experimental = {
            plaintext = {
              -- Default: false.
              enabled = true,
              -- Also scan comment lines in .lua/.py/.ts/... files; false restricts the
              -- scan to prose/text files.
              -- comments = true,
              -- extensions = nil, -- string[]; replaces the built-in prose-extension list
              -- comment_extensions = nil, -- string[]; replaces the built-in comment-extension list
            },
          },
          -- Cascade-delete-assets: when a file is deleted, also detect outgoing links
          -- it holds to asset files (screenshots etc.) under assets/ and offer to
          -- delete those too, once nothing else still references them. Opt-in
          -- upstream; enabled here to exercise it. See
          -- wkdbook-myplugins/filetree.nvim/ROADMAP/IDEAS/Cascade_Delete_Assets.md.
          outgoing_assets = {
            -- Default: false.
            enabled = true,
            -- "ask" | "auto" | "off"; "off" also short-circuits `enabled`.
            -- on_delete = "ask",
            -- roots = nil, -- string[]; default { "assets" }, tried next to the linking file, then at the project root
            -- extensions = nil, -- string[]; allowlist, default image/video shapes (no pdf)
          },
          -- Rewrite the outgoing links inside a moved/renamed/copied file so they
          -- still resolve from its new location.
          -- outgoing_links = {
          --   enabled = false,
          --   mode = nil, -- "ask" | "auto" | "off"; nil inherits on_move / on_rename
          --   env_vars = {}, -- string[]; env var names (no "$") recognised in "$VAR/..." targets
          -- },
          -- scan = {
          --   root = "project", -- "project" (nearest root) | "cwd"
          --   respect_gitignore = true,
          --   max_files = 5000, -- cap for the ripgrep-free fallback walk
          --   timeout_ms = 3000,
          -- },
          -- Keep the replaced lines so `:Filetree refs undo` can put them back.
          -- undo = true,
          -- undo_depth = 10, -- rewrites that stay undoable
        },

        -- nvzone/menu / right-click menu entries. `enable = false` yields no entries;
        -- entries of a disabled feature are omitted automatically.
        -- menu = {
        --   enable = true,
        --   fileops = true, -- create / rename / batch rename / move / template
        --   clipboard = true, -- copy / cut / paste
        --   delete = true, -- trash
        --   open = true, -- vsplit / split / tab / system app / file manager
        --   paths = true, -- copy path / markdown link
        --   search = true, -- find files / grep in dir
        --   info = true, -- node info
        --   marks = true, -- toggle / mark all / unmark all / clear / show marked
        --   window = true, -- open/close the tree itself
        -- },

        -- Sister plugins filetree may hand work to (opt-out, all soft).
        -- integrations = {
        --   pickers = true, -- false keeps find_files / grep_in_dir off pickers.nvim
        --   ui_menu = true, -- false keeps ui.nvim's right-click menu from offering "Open/Close filetree"
        -- },

        -- Every feature is on by default except the few marked "opt-in" below; a
        -- feature table only needs `enabled = false` to switch one off.
        features = {
          -- layout_guard = { enabled = true, delay_ms = 50 },
          -- no_name_guard = { enabled = true }, -- redirect stray [No Name] editor windows to a real buffer
          -- Warn when a just-opened buffer turns out to be a dangling symlink's target.
          -- broken_link_notify = { enabled = true },
          -- Keep the tree in its sidebar: a buffer landing there is moved to an editor
          -- window and the tree put back (neo-tree only).
          -- sidebar_guard = {
          --   enabled = true,
          --   winfixbuf = false, -- refuse with 'winfixbuf' instead of redirecting; also breaks plugins that open files without checking it (E1513)
          -- },

          -- Opt-in (default off): anchor the cwd to the nearest .git ancestor on
          -- buffer switch. `reveal = false` because neo-tree already follows the cwd
          -- (bind_to_cwd + follow_current_file), so cwd_sync only sets the cwd and
          -- lets neo-tree root/reveal instead of the two fighting each other.
          cwd_sync = {
            enabled = true,
            -- debounce_ms = 150,
            -- parent_levels = 0, -- how far the tree-reveal call itself ascends
            -- keep_focus = true, -- stay in the editor window after the reveal
            -- change_dir = true, -- actually chdir, never prompts
            -- Also reveal/root the tree from cwd_sync. Default: true.
            reveal = false,
            -- use_project_root = true, -- target the project root, not the file's dir
            -- root_markers = { ".git" }, -- string[] | false; fallback when cwd_mode is enabled
          },
          -- Root policy in front of cwd_sync. Enabled but inert while mode = "follow";
          -- switch modes at runtime with :Filetree cwd ...
          cwd_mode = {
            -- enabled = true,
            -- mode = "follow", -- "follow" | "project" | "nearest" | "lock" | "manual" | "tree_leads"
            -- scope = "global", -- directory scope: "global" | "tab" | "win"
            -- project = {
            --   markers = { ".git", ".hg", ".svn" }, -- adding package.json / Cargo.toml gives nearest-package (monorepo) behaviour
            --   skip_dirs = { "node_modules", ".venv", "vendor" }, -- names that can never hold a root
            --   max_depth = nil, -- number; levels to walk upward, nil = unbounded
            --   sticky = true, -- keep the current root for a file without one of its own
            -- },
            -- nearest = {
            --   markers = { -- package boundaries for "nearest" mode; replaces the list
            --     "package.json",
            --     "Cargo.toml",
            --     "go.mod",
            --     "pyproject.toml",
            --     "setup.py",
            --     "*.rockspec",
            --     "mix.exs",
            --     "build.zig",
            --     "CMakeLists.txt",
            --     ".git",
            --   },
            -- },
            -- lock = {
            --   enforce = true, -- revert foreign cwd changes
            --   follow_manual_root = true, -- re-rooting the tree by hand moves the lock
            -- },
            -- reveal_outside = "skip", -- file outside the held root: "skip" | "reveal"
            -- persist = false, -- remember mode, scope and lock pin per project
            -- The mode badge is shown in this host's own ui.nvim statusline
            -- (filetree_cwd_mode module) via cwd_mode's external-statusline API
            -- (badge() / component()). The in-tree indicator must stay off, or the mode
            -- shows twice: with laststatus=3 there is no per-window statusline for it,
            -- so it would fall back to a float in the tree window.
            indicator = {
              -- Default: true.
              enabled = false,
              -- mode = "auto", -- "auto" | "statusline" | "float"
              -- align = "left", -- "left" | "center" | "right"
              -- show_path = "lock", -- append the pinned path: "never" | "lock" | "always"
              -- style = "text", -- label set used: "text" | "short" | "numeric" | "icon"
              labels = {
                -- Upstream leaves this "" so the in-tree badge is invisible while no policy
                -- is active; in a shared statusline that reads as a broken component, so
                -- give it a visible label. Default: "".
                follow = "FOLLOW",
                -- project = "PROJECT",
                -- nearest = "PKG",
                -- lock = "LOCK",
                -- manual = "MANUAL",
                -- tree_leads = "TREE",
              },
              -- labels_short = { follow = "", project = "P", nearest = "N", lock = "L", manual = "M", tree_leads = "T" },
              -- labels_numeric = { follow = "0", project = "1", nearest = "2", lock = "3", manual = "4", tree_leads = "5" },
              -- Nerd Font glyphs; swap one if it renders as tofu.
              -- icons = {
              --   follow = "",
              --   project = "",
              --   nearest = "",
              --   lock = "",
              --   manual = "",
              --   tree_leads = "",
              -- },
              -- Highlight group per mode, shared across styles.
              -- hl = {
              --   follow = "Comment",
              --   project = "DiagnosticInfo",
              --   nearest = "DiagnosticInfo",
              --   lock = "DiagnosticWarn",
              --   manual = "Comment",
              --   tree_leads = "DiagnosticHint",
              -- },
            },
            -- cycle = { "follow", "project", "lock" }, -- order of `:Filetree cwd toggle`; replaces the list
            -- keymap_cycle = "L", -- tree-buffer key; "" disables
            -- keymap_lock_here = "gp", -- lock onto the node under the cursor; "" disables
          },
          -- Mark the currently-focused file with a sign-column icon, on top of
          -- neo-tree's own fg colour for all opened files. opened_sync is on by
          -- default and keeps those opened-file colours in sync as buffers
          -- open/close, so it needs no config.
          current_hl = {
            -- Default: false.
            enabled = true,
            -- file_hl = { fg = "#7aa2f7", bold = true }, -- string | table highlight spec
            -- parent_hl = { fg = "#565f89" },
            -- debounce_ms = 100,
            -- Sign-column marker on the current file's line. Default: nil (off).
            icon = "▸",
            -- icon_hl = nil, -- string | table; default the file_hl group
          },
          -- Opt-in (default off): backup API, no keymaps.
          -- safety = {
          --   enabled = false,
          --   backup_dir = nil, -- string; default stdpath("data")/filetree/backups
          --   max_backups = 5, -- per file
          --   dry_run = false, -- log operations without executing them
          -- },
          -- Delete to the OS trash with undo. Equals the default, set explicitly.
          trash = {
            enabled = true,
            -- mode = "trash", -- "trash" (undoable) | "permanent" (fs delete, no undo)
            -- confirm = true, -- ask before trashing (unlike paste / rename_batch)
            -- use_safety = false, -- back up before trashing
            -- dry_run = false,
            -- max_history = 50, -- undoable trash operations; 0 = unlimited
            -- keymap = "d", -- trash the node / all marked
            -- keymap_undo = "U",
            -- keymap_history = "<leader>th",
            -- check_markdown_refs = nil, -- deprecated: use refs.on_delete (false -> "off")
            -- refs_picker_prefer = nil, -- deprecated: use refs.picker
          },
          -- Swallows the neo-tree file-watcher errors caused by a rename/move.
          -- Equals the default, set explicitly.
          watcher_quarantine = {
            enabled = true,
            -- duration_ms = 500,
            -- silent = true, -- no quarantine notifications
            -- patch_neotree_watch = true, -- wrap neo-tree's fs_watch callbacks to swallow EPERM
          },
          -- Opt-in (default off): closes neo-tree's leaked directory-watcher handles
          -- before a rename/move, so the Windows EPERM file-lock cannot happen at the
          -- source (watcher_quarantine only hides the error). neo-tree adapter and
          -- Windows/WSL only, a no-op elsewhere. Inspect with `:Filetree handles`.
          handle_guard = { enabled = true },
          -- context_menu (enabled = true, keymap = "<RightMouse>", or false to unbind) stays
          -- on its defaults: filetree's buffer-local binding is the only right-click
          -- handler inside the tree (it shadows ui.nvim's global RightMouse handler
          -- there); right-click in other buffers still goes through the global one.
          window_style = {
            -- enabled = true,
            -- Blank the tree window's local 'statusline'. Harmless under laststatus=2, but
            -- with laststatus=3 (global statusline, see options.lua) that blank override
            -- becomes the content of the ONE shared statusline whenever the tree is
            -- focused, so it is off here. Default: true.
            statusline = false,
            -- Link the tree's Normal/NormalNC/EndOfBuffer groups to the editor's own.
            -- Default: false.
            highlights_isolate = true,
          },
          -- Source switcher: `"` / `!` cycle the neo-tree sources in place. The extra
          -- global key picks one from a list; plugins/neotree.lua takes the
          -- source_selector names from the same module.
          source_switcher = {
            -- enabled = true,
            -- keymap_next = '"', -- string | string[] | false; tree-buffer key, wraps
            -- keymap_prev = "!",
            -- Global normal-mode key. Default: nil.
            keymap_pick = "<leader>ns",
            -- sources = nil, -- string[]; default neo-tree's configured `sources`
            -- icons = {
            --   family = nil, -- "nerd" | "codicons" | "common"; unset: "nerd" when vim.g.have_nerd_font, else "common"
            --   variant = "v1", -- "v1" | "v2"
            --   length = "long", -- name length: "long" | "short"
            -- },
          },
          -- Opt-in (default off): four global Alt keys toggling the tree, a claim on
          -- the keyboard the user makes. The E95 self-heal lives in the adapter.
          tree_toggle = {
            enabled = true,
            -- reveal = true, -- reveal the current file when opening
            -- reveal_force_cwd = true, -- re-root to the cwd when that file lies outside the tree
            -- keymap_current = "<M-c>", -- string | string[] | false; toggle in the current window
            -- keymap_float = "<M-f>",
            -- keymap_left = "<M-l>",
            -- keymap_right = "<M-r>",
          },
          -- Path-copy family.
          path_copy = {
            -- enabled = true,
            -- keymap_pick = nil, -- opens a format picker
            -- Absolute path. `y` is added as a second key next to the default `[a`.
            -- Default: "[a".
            keymap_abs = { "[a", "y" },
            -- keymap_dirname = "]a", -- absolute parent directory
            -- keymap_name = nil, -- filename only
            -- keymap_project_root = "[R", -- absolute project root
            -- keymap_project_rel = "]R", -- relative to the project root
            -- keymap_buffer_rel = "]b", -- relative to the buffer open in the editor
            -- keymap_env_root = "[e", -- $REPOS_DIR/... form
            -- root_markers = { ".git" }, -- string[] | false (use the cwd)
            -- env_roots = { "REPOS_DIR" }, -- env var names tried by the env-rooted copy, without "$"
            -- nvim_config_root = true, -- also fold in $NVIM_CONFIG_DIR (stdpath("config"))
            -- notify = true,
          },

          -- Further features, all at their defaults.
          -- auto_reveal = {
          --   enabled = true,
          --   debounce_ms = 150,
          --   ignore_ft = { "neo-tree", "NvimTree", "netrw", "TelescopePrompt", "fzf", "lazy", "mason", "trouble", "qf", "help", "man", "terminal", "nofile", "prompt" }, -- replaces the list
          --   only_if_open = true, -- reveal only while the tree window is visible
          --   sync_on_enter = true, -- move the tree cursor onto the current file when the tree is entered
          --   follow_root = true, -- re-root for a file outside the current root
          -- },
          -- Opt-in (default off): automatic width management, fights window_size_cycler.
          -- auto_resize = {
          --   enabled = false,
          --   breakpoints = { { cols = 0, width = 25 }, { cols = 100, width = 30 }, { cols = 140, width = 35 } }, -- { cols = min editor columns, width = tree width }; replaces the list
          --   min_width = 20,
          --   max_width = 60,
          -- },
          -- buffer_cycle = {
          --   enabled = true,
          --   keymap_next = "<C-n>", -- next buffer in the adjacent editor window
          --   keymap_prev = "<C-p>",
          -- },
          -- reveal_alt = { enabled = true, keymap = "B" }, -- reveal the alternate buffer (#) in the tree
          -- tree_traverse = {
          --   enabled = true,
          --   keymap_up = "-", -- navigate to the parent directory
          --   keymap_down = "+", -- set the current dir as root
          --   sync_cwd = false, -- also change Vim's cwd
          -- },
          -- window_size_cycler = {
          --   enabled = true,
          --   keymap = "w",
          --   sizes = { 30, 50, 15 }, -- width presets; replaces the list
          -- },
          -- cursor_hide = {
          --   enabled = true, -- hide the block cursor in the tree window
          --   force_cursorline = true, -- keep 'cursorline' on while the cursor is hidden
          -- },
          -- tree_reset = { enabled = true, keymap = "<Esc>" }, -- clears preview, filter, live search, quarantine and search highlights
          -- preview = {
          --   enabled = true,
          --   mode = "buffer", -- "buffer" (in the editor window) | "float"
          --   highlight = true, -- syntax/treesitter highlighting
          --   cursor_debounce_ms = 80, -- live update while scrolling the tree
          --   keymap = "<Tab>", -- toggle the text preview; dispatch image/PDF
          --   keymap_open = "<CR>", -- dispatch image/PDF; adapter default for other nodes
          --   max_lines = 40, -- float mode
          --   max_width = 80, -- float mode
          --   max_height = 25, -- float mode
          --   wrap = false, -- float mode
          --   keymap_scroll_up = "<C-b>",
          --   keymap_scroll_down = "<C-f>",
          --   keymap_scroll_up10 = "<PageUp>",
          --   keymap_scroll_down10 = "<PageDown>",
          --   image = { backend = "auto" }, -- "auto" | "images.nvim" | "snacks" | "image.nvim" | "system" | false
          --   pdf = { backend = "pdfport" }, -- "pdfport" | "system" | false
          -- },
          -- node_info = {
          --   enabled = true,
          --   keymap = "I",
          --   show_lines = true, -- line count for files
          --   max_lines_size = nil, -- bytes; skip the line count above this, default 5 MB
          --   max_entries = 100000, -- cap of the recursive directory scan behind Items/Size
          -- },
          -- breadcrumbs = {
          --   enabled = true,
          --   mode = "winbar", -- "winbar" | "float" | "statusline"
          --   separator = "  ",
          --   max_depth = 5, -- path segments shown
          --   hl_dir = "Comment",
          --   hl_file = "Normal",
          --   hl_sep = "NonText",
          --   winbar_hl = "WinBar",
          -- },
          -- Opt-in (default off): per-node `du` / `Get-ChildItem` by default, so cosmetic clutter.
          -- size_info = {
          --   enabled = false,
          --   show_files = true,
          --   show_dirs = true,
          --   hl_group = "Comment",
          --   dir_async = true, -- use du / PowerShell for directory sizes
          -- },
          -- link_marker = {
          --   enabled = true,
          --   show_target = false, -- also show the link target after the sign
          --   target_hl = "Comment",
          --   signs = { -- merged per key
          --     symlink = { text = "⇢", hl = "Special" },
          --     broken = { text = "⇢!", hl = "DiagnosticError" }, -- neo-tree only
          --   },
          -- },
          -- opened_sync = { enabled = true, debounce_ms = 60 }, -- re-render delay after a buffer opens/closes
          -- cheatsheet = { enabled = true, keymap = "?" }, -- no-op on the neotree adapter, whose native `?` already covers it
          -- smart_create = {
          --   enabled = true,
          --   keymap = "a",
          --   auto_module_annot = false, -- new .lua files get a `---@module` header
          --   auto_types_template = false, -- files under an @types path get `---@meta` + `---@module`
          --   auto_init_lua = false, -- creating a directory also creates init.lua
          --   ask_clipboard = false, -- offer to paste a non-empty clipboard into the new file
          --   notify_level = "verbose", -- success message: "verbose" | "short" | "off"
          -- },
          -- copy_move = {
          --   enabled = true,
          --   keymaps = { copy = "c", cut = "x", paste = "p", show = "P", clear = "X" },
          --   confirm = false, -- ask before paste
          --   use_safety = true, -- back up before a move
          --   dry_run = false,
          --   check_markdown_refs = nil, -- deprecated: use refs.on_move (false -> "off")
          --   refs_picker_prefer = nil, -- deprecated: use refs.picker
          -- },
          -- move = { enabled = true, keymap = "M", use_safety = true, dry_run = false },
          -- rename_batch = {
          --   enabled = true,
          --   keymap = "<leader>rb",
          --   confirm = false, -- ask before applying the plan
          --   use_safety = true,
          --   dry_run = false,
          --   check_markdown_refs = nil, -- deprecated: use refs.on_rename (false -> "off")
          --   refs_picker_prefer = nil, -- deprecated: use refs.picker
          -- },
          -- smart_rename = {
          --   enabled = true,
          --   keymap = "r",
          --   use_safety = true,
          --   dry_run = false,
          --   update_references = nil, -- deprecated: use refs.providers (false turns the lua/python/ts_js providers off)
          --   check_markdown_refs = nil, -- deprecated: use refs.on_rename (false -> "off")
          --   refs_picker_prefer = nil, -- deprecated: use refs.picker
          -- },
          -- create_from_template = {
          --   enabled = true,
          --   keymap = "A",
          --   template_dir = nil, -- string; default stdpath("data")/filetree/templates
          --   author = nil, -- string; for ${author}, default $USER / $USERNAME
          --   open_after = true, -- open the created file
          --   prefer = "auto", -- template picker: "auto" | "telescope" | "fzf" | "snacks" | "builtin"
          -- },
          -- Symlink / hardlink creation; no default keymap, use `:Filetree symlink`.
          -- link_create = {
          --   enabled = true,
          --   keymap = nil, -- prompt for a link target
          --   keymap_mark = nil, -- mark a link source
          --   keymap_paste = nil, -- paste the marked source as a link
          --   repair_roots = { "$REPOS_DIR" }, -- extra dirs searched for a broken link's moved target; merged by index, so a shorter list does not clear the default
          --   repair_nvim_config_root = true, -- also search stdpath("config")
          --   repair_search_progress = "auto", -- "auto" | "notify" | "statusline" | "fidget" | "float" | "kit" | false
          --   repair_search_slow_hint_ms = 2000, -- number | false; warn when that search takes longer
          -- },
          -- open_replace = {
          --   enabled = true,
          --   keymap = "O", -- open over the editor window, the old buffer stays listed
          --   keymap_swap = "<M-CR>", -- same, and close the old buffer
          --   keymap_swap_alt = "<C-CR>", -- for terminals that send <C-CR> distinctly
          --   close_tree = true, -- close the tree after `keymap`
          --   swap_close_tree = false, -- ... and after a swap
          --   keep_position = true, -- new buffer takes the replaced one's bufferline slot
          -- },
          -- open_variants = {
          --   enabled = true,
          --   keymap_vsplit = "sg",
          --   keymap_split = "sv",
          --   keymap_tabnew = "st",
          --   keymap_badd = "gb", -- add to the buffer list without switching focus
          --   keymap_badd_alt = "<S-CR>",
          -- },
          -- buffer_save = {
          --   enabled = true,
          --   keymap_adjacent = "<C-s>", -- save the last adjacent editor buffer
          --   keymap_node = "<M-s>", -- save the buffer of the node under the cursor
          --   force = true, -- write! instead of update
          -- },
          -- filter = {
          --   enabled = true,
          --   keymap = "/",
          --   keymap_clear = "<C-c>",
          --   case_sensitive = false,
          --   dim_hl_group = "Comment", -- non-matching lines
          --   debounce_ms = 80,
          -- },
          -- live_search = {
          --   enabled = true,
          --   keymap = "gs",
          --   match = "name", -- "name" | "path"
          --   hl_match = "Search",
          --   hl_dim = "Comment",
          --   commit_to_filter = true, -- <CR> pushes the query to the filter feature
          --   debounce_ms = 80,
          -- },
          -- find_files = {
          --   enabled = true,
          --   keymap_tree = "f",
          --   keymap_pickers = "tf", -- force pickers.nvim
          --   keymap_telescope = nil, -- force telescope
          --   keymap_global = nil, -- global normal-mode key
          --   prefer = "auto", -- "auto" | "pickers" | "telescope" | "fzf-lua" | "mini.pick" | "builtin"
          --   reveal_on_open = true, -- reveal the picked file in the tree
          --   hidden = false,
          -- },
          -- grep_in_dir = {
          --   enabled = true,
          --   keymap = "gr",
          --   keymap_cword = nil, -- grep the word under the cursor
          --   keymap_pickers = "tg", -- force pickers.nvim
          --   keymap_telescope = nil, -- force telescope
          --   prefer = "auto", -- "auto" | "pickers" | "telescope" | "fzf-lua" | "builtin"
          --   hidden = false,
          --   extra_args = {}, -- string[]; extra args for rg / grep
          -- },
          -- lua_require_copy = { enabled = true, keymap = "rq" },
          -- copy_file_list = {
          --   enabled = true,
          --   keymap_files_abs = "[f",
          --   keymap_files_rel = "]f",
          --   keymap_dirs_abs = "[F",
          --   keymap_dirs_rel = "]F",
          --   preview_limit = 5, -- max lines shown in the notification
          --   separator = "\n", -- between paths
          -- },
          -- markdown_links = {
          --   enabled = true,
          --   keymap = "ML", -- link for the current node
          --   keymap_recursive = "MR",
          --   keymap_from_marked = "MM",
          --   keymap_insert = "MI", -- INSERT link(s) (marked, else current) into the window you came from
          --   insert_path = "buffer", -- "buffer" (relative to the target buffer) | "cwd" | "absolute" | "env"
          --   env_roots = { "REPOS_DIR" }, -- variables tried for "env"; $NVIM_CONFIG_DIR always is
          --   cursor = {}, -- link_cursor: enable / startinsert / path_cursor
          -- },
          -- git_status = {
          --   enabled = true,
          --   debounce_ms = 300, -- delay between write and re-query
          --   show_ignored = false,
          --   signs = { -- merged per key; { text, hl } per status
          --     modified = { text = "●", hl = "DiagnosticWarn" },
          --     added = { text = "+", hl = "DiagnosticOk" },
          --     deleted = { text = "-", hl = "DiagnosticError" },
          --     renamed = { text = "»", hl = "DiagnosticHint" },
          --     untracked = { text = "?", hl = "Comment" },
          --     ignored = { text = "·", hl = "Comment" },
          --     conflict = { text = "✗", hl = "DiagnosticError" },
          --   },
          -- },
          -- marks = {
          --   enabled = true,
          --   indicator = "✓", -- shown before marked nodes
          --   hl_group = "DiagnosticOk",
          --   keymap = "m", -- toggle the mark
          --   keymap_all = "]m",
          --   keymap_unmark_all = "[m",
          --   keymap_clear = "<leader>mc",
          --   keymap_show = "<leader>ms",
          --   keymap_goto = "gm", -- count-prefixed
          --   keymap_next = "]M",
          --   keymap_prev = "[M",
          --   auto_clear_ms = 60000, -- clear all marks after this idle time; 0 disables
          -- },
          -- session = {
          --   enabled = true,
          --   auto_save = true, -- on VimLeavePre and tree BufHidden
          --   auto_restore = true, -- on the first neo-tree / NvimTree FileType
          --   max_sessions = 50,
          -- },
          -- open_in_fm = {
          --   enabled = true,
          --   keymap = "<leader>fm", -- show the node in the system file manager
          --   command = nil, -- string; launcher override, auto-detected per OS
          --   reveal = true, -- select a file node; false opens the containing directory
          --   debug = false, -- log every launch attempt
          --   reuse_existing = false, -- Windows: navigate an open Explorer window instead of spawning one
          -- },
          -- open_with = {
          --   enabled = true,
          --   keymap = "<leader>sm", -- system default application
          --   apps = {}, -- { name, cmd, args?, keymap? }[]; custom application entries
          -- },
          -- shell_run = {
          --   enabled = true,
          --   keymap = "i", -- prompt for a command, run it in the node's directory
          --   close_on_ok = true, -- close the terminal when the command exits 0
          --   split = "split", -- "split" | "vsplit"
          --   height = 12, -- terminal height for a horizontal split
          -- },
          -- pdf_open = {
          --   enabled = true,
          --   default_mode = "buffer", -- mode of keymap_open: "buffer" | "float" | "terminal" | "system" | "picker"
          --   keymap_open = "go",
          --   keymap_text = false, -- force text extraction into a buffer
          --   keymap_system = false, -- force the OS viewer
          --   keymap_terminal = false, -- force pdfport's terminal mode
          --   keymap_picker = false, -- ask how to open it
          -- },
          -- pdf_create = {
          --   enabled = true,
          --   keymap = "gP", -- create a PDF from the node / marks / folder
          --   on_conflict = "suffix", -- "overwrite" | "suffix" | "error"
          --   confirm = true,
          -- },
          -- lsp_diagnostics = {
          --   enabled = true,
          --   show_errors = true,
          --   show_warnings = true,
          --   show_hints = false,
          --   show_info = false,
          --   format = nil, -- fun(counts): string?; default renders the non-zero counts like "E:1 W:2", nil hides the row
          --   debounce_ms = 300,
          -- },
          -- diff = {
          --   enabled = true,
          --   split = "vsplit", -- "vsplit" | "split"
          --   keymap = "D",
          -- },
          -- ignore_list = {
          --   enabled = true,
          --   names = nil, -- string[]; nil = built-in list (or lib.nvim's)
          -- },
          -- project_root = {
          --   enabled = true,
          --   markers = { ".git", ".hg", ".svn", "package.json", "package-lock.json", "yarn.lock", "pnpm-lock.yaml", "Cargo.toml", "go.mod", "pyproject.toml", "setup.py", "setup.cfg", "Makefile", "CMakeLists.txt", "*.rockspec", ".luarc.json", "selene.toml", "mix.exs", "build.zig" }, -- replaces the list
          --   fallback = "parent", -- when no marker is found: "parent" (the file's dir) | "cwd"
          --   cache = true, -- cache resolved roots per directory
          --   max_cache_entries = 1000, -- directories held before the cache is cleared
          -- },
          -- file_watcher = {
          --   enabled = true,
          --   debounce_ms = 500,
          --   watch_recursive = true,
          --   ignore_events = {}, -- string[]; uv event types to ignore
          -- },
          -- hooks_api = { enabled = true },
          -- tree_integrity = {
          --   enabled = true, -- keep neo-tree's node index from being corrupted by a re-set subtree
          --   silent = true, -- false: debug note whenever a corrupt subtree is healed
          -- },
        },
      })
    end,
  },

  -- {
  --   "StefanBartl/filetreepicker.nvim",
  --   event = "VeryLazy",
  --   dependencies = { "nvim-neo-tree/neo-tree.nvim" },
  --   config = function()
  --     require("filetreepicker").setup({})
  --   end,
  -- },

  -- {
  --   "StefanBartl/mygrep.nvim",
  --   name = "mygrep",
  --   lazy = false,
  --   config = function()
  --     require("mygrep").setup({
  --       tool_picker_style = "ui",
  --     })
  --   end,
  -- },

  {
    "StefanBartl/fileops.nvim",
    event = "VeryLazy",
    opts = {
      -- `:File next` / `:File prev` (file cycling in the buffer's directory).
      cycle = {
        -- Where the next/prev file opens: "replace" | "current" | "split" |
        -- "vsplit" | "tab" | "background". "current" loads it into the current
        -- window. Default: "replace".
        open_target = "current",
        -- Return focus to the origin window after split/vsplit.
        -- keep_focus = true,
        -- Include dot-files.
        -- include_hidden = false,
        -- Wrap around at the directory boundary.
        -- wrap = true,
        -- Resolve symlinks for comparisons.
        -- follow_symlinks = true,
        -- Directory to list: "buffer_dir" | "cwd" | "buffer_dir_recursive" | "cwd_recursive".
        -- root = "buffer_dir",
        -- Ask (via ui.kit) before leaving a modified buffer.
        -- confirm_on_modified = true,
        -- Case-insensitive sort and comparison.
        -- case_insensitive = true,
        -- pattern = nil, -- string; glob filter such as "*.lua" (also the `:File next [glob]` arg)
      },

      -- `:File cd`.
      -- cd = {
      --   scope = "window", -- "window" (:lcd) | "tab" (:tcd) | "global" (:cd)
      --   refresh_explorers = true, -- refresh neo-tree/nvim-tree/netrw after cd
      -- },

      -- Refresh tree explorers after a file op (a `User FileopsChanged` fires either way).
      -- explorer = {
      --   refresh_on_change = true,
      -- },

      -- `:File[!] delete`.
      -- delete = {
      --   mode = "trash", -- "trash" (OS trash, recoverable) | "permanent" (no undo)
      --   -- on_before_delete = nil, -- fun(path: string): boolean|nil; return false to abort
      -- },

      -- Git-tracked-file awareness for rename/move/duplicate/copy/delete.
      -- git_aware = {
      --   enable = false, -- master switch; opt-in because it shells out to git
      --   warn_only = true, -- true: only note tracked-ness; false: use `git mv`/`git rm`
      --   git_cmd = "git",
      -- },

      -- Retry a transient sharing violation (EBUSY/EPERM/EACCES). Default
      -- attempts is 6 on Windows and 1 elsewhere; backoff doubles each round.
      -- retry = {
      --   attempts = 6,
      --   backoff_ms = 60,
      -- },

      -- `ui_menu = false` keeps ui.nvim's right-click menu from composing the
      -- File fly-out.
      -- integrations = {
      --   ui_menu = true,
      -- },

      -- After rename/move, resave the active `:mksession` session.
      -- session_compat = {
      --   enable = true,
      -- },

      -- Keymaps; the two switches gate whole families, `lhs` overrides single keys
      -- (false disables one, another string remaps it).
      -- keymaps = {
      --   cycle = true, -- <leader>nf / <leader>pf family
      --   delete = true, -- <leader>dcf
      --   lhs = {
      --     next_replace = "<leader>nf",
      --     prev_replace = "<leader>pf",
      --     next_current = "<leader>nfn",
      --     prev_current = "<leader>pfn",
      --     next_background = "<leader>nF",
      --     prev_background = "<leader>pF",
      --     next_vsplit = "<leader>NF",
      --     prev_vsplit = "<leader>PF",
      --     delete = "<leader>dcf",
      --     -- Unset by default; bound only when named:
      --     -- next_filtered = "<leader>nfg", -- prompt for a glob, then cycle within it
      --     -- prev_filtered = "<leader>pfg",
      --     -- delete_force = "<leader>dcF", -- the `:File! delete` form
      --     -- path = "<leader>fp",
      --     -- cd = "<leader>fd",
      --     -- info = "<leader>fi",
      --     -- lockinfo = "<leader>fl",
      --     -- bulk_rename = "<leader>fR", -- prompts for pattern + replacement
      --   },
      -- },

      -- Register the `:File` command.
      -- commands = true,

      -- Create missing parent directories on save (BufWritePre).
      -- auto_mkdir = {
      --   enable = true,
      --   skip_remote = true, -- leave remote buffers alone
      --   detect_remote_pattern = "^%w%w+:[\\/][\\/]", -- Lua pattern, e.g. "ssh://", "http://"
      -- },

      -- Ambient CursorHold preview of the line's previous text (opt-in).
      -- on_hold = {
      --   enable = false,
      --   modes = "n", -- "n" | "v" | "i" (any combination) or a list; nil = n+v
      --   delay = 3000, -- extra debounce in ms beyond 'updatetime'
      --   throttle_ms = 1200, -- min ms between triggers per window
      --   git_cmd = "git",
      --   ignore_buftypes = { "nofile", "prompt", "terminal" },
      --   only_tracked = true, -- skip files not tracked by git
      --   require_clean_buffer = false, -- skip if the buffer has unsaved changes
      --   prefix = "previous: ", -- prefix of the fallback EOL preview text
      --   right_align = false, -- right-aligned virt_text instead of eol
      --   max_len = 160, -- truncate the fallback preview to this many chars
      --   hl_prev = "Comment", -- highlight group of the fallback preview
      --   virt_priority = 1000, -- extmark virt_text priority
      --   prefer_inline = true, -- prefer gitsigns.preview_hunk_inline() when available
      --   restore_view = true, -- save/restore winsaveview() to avoid scroll jumps
      --   -- events_override = nil, -- string[]; fully replaces the auto-mapped events
      -- },

      -- Highlight git conflict markers.
      -- conflict_marks = {
      --   enable = true,
      --   hl_a = "DiffDelete", -- "<<<<<<<" lines
      --   hl_b = "DiffChange", -- "=======" separator
      --   hl_c = "DiffAdd", -- ">>>>>>>" lines
      -- },

      -- Refresh explorers on gitsuite.nvim's branch-switch/conflict-resolved events.
      -- gitsuite_events = {
      --   enable = true,
      -- },
    },
  },

  {
    -- Eager: setup() registers the VimEnter autoload and the VimLeavePre
    -- autosave. Both are startup/shutdown events, so a lazy trigger would have
    -- to fire before VimEnter to be of any use -- which is what `lazy = false`
    -- means.
    "stefanbartl/sessions.nvim",
    lazy = false,
    dependencies = { "stefanbartl/lib.nvim" },
    -- A function: `config.marks.defaults` asks the machine module, and a
    -- table literal would do that at spec-import time for every start.
    opts = function()
      return {
        -- Root directory for session files.
        -- root = vim.fn.stdpath("data") .. "/sessions",

        -- Session name used when auto-resolution yields nothing.
        -- default_name = "last",

        -- Append the current git branch to the auto-resolved name.
        -- branch_aware = true,

        -- Prefix the auto-resolved name with the detected project root's basename.
        -- project_aware = true,

        -- Files searched upward from the cwd to detect a project root. Replaces
        -- the list, so give it in full.
        -- project_markers = { ".git", "pyproject.toml", "package.json", "Makefile", "Cargo.toml", "go.mod" },

        -- Passed to 'sessionoptions' before every save/load.
        -- sessionoptions = "buffers,curdir,tabpages,winsize,help,folds",

        -- Rewrite the saved cwd to a portable placeholder, re-anchored to the
        -- cwd on load (see docs/portability.md).
        -- relative_paths = false,

        -- Old root -> new root path prefixes translated on load, for
        -- cross-OS / cross-machine sync (see docs/portability.md).
        -- root_remap = {},

        -- Load the contextual session on VimEnter when Neovim starts without
        -- file args: true | false | "ask" (confirm float first). A bare `nvim`
        -- then resumes the last-loaded session -- see
        -- docs/ROADMAP/casedesk/SESSIONS.md §4.3.
        -- autoload = false,

        -- Save the session on VimLeavePre.
        -- autosave = true,

        -- Autosave target: true resolves the name like a bare `:Session save`
        -- (branch/project-aware when configured), a string pins autosave to
        -- that one fixed name regardless of project, false disables autosave
        -- despite `autosave = true`.
        -- autosave_name = true,

        -- Write a `.{name}.json` companion file with the save context.
        -- metadata = true,

        -- Persist the per-tabpage buffer order (`vim.t.bufs`) that a tabline
        -- such as NvChad's tabufline renders from; a no-op without one.
        -- restore_buffer_order = true,

        -- Persist per-tabpage tab-pin state (ui.nvim's `vim.t.ui_pinned`);
        -- restored after the buffer order. A no-op without ui.nvim's tabline.
        -- restore_pinned_buffers = true,

        -- Attach `opts.title = "Sessions"` to `:Session`/autoload notify calls,
        -- for rich vim.notify backends; false calls vim.notify plainly.
        -- notify_title = true,

        -- Callbacks after save/load (errors are swallowed via pcall).
        -- hooks = {
        --   on_save = nil, -- fun(name: string, path: string)
        --   on_load = nil, -- fun(name: string, path: string)
        -- },

        -- Buffers matching these are wiped before `:mksession`.
        -- blacklist = {
        --   buftypes = { "quickfix", "nofile", "prompt" }, -- replaces the list
        --   filetypes = { "gitcommit", "gitrebase" }, -- replaces the list
        --   paths = {}, -- empty here; setup() fills in the platform temp dirs (/tmp/, %TEMP% on Windows) unless set explicitly
        -- },

        -- The mark list: an ordered set of files jumped to by number
        -- (`:Session marks`).
        marks = {
          -- Turn the mark list on. Default: false.
          enable = true,
          -- "global": one list wherever Neovim runs; "project": one per project
          -- root (and branch when `branch_aware`). Equals the default, set
          -- explicitly.
          scope = "global",
          -- Paths seeded into the list on first use and restored by
          -- `:Session marks defaults reset`; each entry is a list of path
          -- segments (the first may be `$REPOS_DIR`, `$HOME`, `$NVIM_HOME`) or
          -- one absolute string. Comes from this config's machine module.
          -- Default: {}.
          defaults = require("config.marks.defaults"),
          -- First run: take over a harpoon v2 list before falling back to
          -- `defaults` (also `:Session marks import-harpoon`).
          -- import_harpoon = true,
          -- Remember a marked file's cursor position when its buffer is left,
          -- debounced by this many ms (0 = write at once).
          -- context_debounce_ms = 200,
          -- Template with one `%d` for 1..9: `<leader>h1` .. `<leader>h9` jump
          -- to that entry. Default: false (no keys bound).
          select_key = "<leader>h%d",
          menu = {
            -- "auto" (kit, then snacks, telescope, fzf-lua, then the float) |
            -- "edit" | "kit" | "snacks" | "telescope" | "fzf".
            -- ui = "auto",
            -- End-of-line flag on a default/pin in the edit float.
            -- pin_marker = "📌 pin",
            -- Keys of the kit menu's preview pane: a table changes single
            -- groups, `false` turns them off. Default: nil (the kit's own keys,
            -- <C-f>/<C-p> scroll the preview, <Tab> hops into it).
            -- `<C-e>` opens the marks popup (bindings/mappings/sessions.lua), so
            -- adding it to `close` makes it a toggle, alongside q / <Esc>.
            preview_keys = { close = { "q", "<Esc>", "<C-e>" } },
          },
          -- Preview limits for the marks list.
          -- preview = {
          --   max_kb = 1536, -- larger files show only the first `max_lines`
          --   max_lines = 4000,
          -- },
          -- Template like `select_key`, e.g. "<M-%d>" to preview entry N.
          -- preview_key = false,
        },

        -- `false`, not a table: the actual keymaps are attached from
        -- bindings/mappings/sessions.lua at UIReady instead of here. This
        -- spec has `lazy = false` for the autoload/autosave reason above, so
        -- anything bound directly in `opts`/`config` runs on the synchronous
        -- startup path -- exactly what this config's keymap registration is
        -- everywhere else deliberately kept off of (see init.lua's UIReady
        -- phases). As a table it maps name -> lhs; names: save, load, save_ts,
        -- list, current, chip_toggle, picker, toggle_track, save_tab, load_tab,
        -- save_layout, load_layout, plus marks_menu, marks_edit, marks_add,
        -- marks_add_front, marks_pin, marks_remove, marks_sync, marks_debug.
        -- Default: false.
        keymaps = false,

        -- Register a which-key group label for the keymap prefix, if which-key
        -- is installed and at least one keymap is configured.
        -- which_key = { enable = true },

        -- Editor-corner indicator (ui.kit.chip); while shown it REPLACES the
        -- plain save/load/autoload notify. A soft dependency on ui.kit.
        -- Only the mode-colour wiring is set here, per ui.kit.chip's own
        -- design: it stays statusline-agnostic, so a `St_<Mode>Mode`-specific
        -- colour source is this config's job, not sessions.nvim's or ui.kit's.
        chip = {
          -- enable = true,
          -- "bottom-left" | "bottom-right" | "top-left" | "top-right".
          -- anchor = "bottom-left",
          -- "dock_left" (rounded except the left edge, meant to sit flush on
          -- the screen's left edge) | "rounded_chip" | "chip" | "classic".
          -- shape = "dock_left",
          -- Sit flush on the statusline row instead of floating above it;
          -- degrades to the ordinary placement without a real statusline row.
          -- dock = true,
          -- Refresh the chip on every ModeChanged; needed here because the
          -- `color` function below follows the mode, and without it the colour
          -- would only be re-read at the next incidental save/load/dirty event.
          -- Default: false.
          track_mode = true,
          -- Nudge on top of the computed placement: 0 is no change (the
          -- default is nil, equivalent), set explicitly.
          row_offset = 0,
          -- One column to the left of the computed placement. Default: nil.
          col_offset = -1,
          -- A highlight-group name, a `{ fg, bg }` table or a zero-arg function
          -- returning either; here a function returning the statusline's
          -- mode-pill colours, so the chip matches the current mode.
          -- Default: nil (the kit's own default colour).
          color = function()
            -- `St_<Suffix>Mode` is only defined once `ui.statusline.highlights
            -- .ensure()` has run, and this config defers that to UIReady, so
            -- the chip's first colour resolution can come earlier. `ensure()`
            -- is idempotent, which guarantees the groups exist before they
            -- are read below.
            require("ui.statusline.highlights").ensure()
            -- The same helper the statusline's own mode pill resolves its
            -- colour through, so chip and pill read one source.
            local group = require("ui.statusline.modules.highlighting").mode_band_group()
            -- The chip wants the group's own {fg,bg} pair verbatim (the mode's
            -- accent as background, like the statusline pill), not a group
            -- NAME: ui.kit.chip would tint a name's fg toward the window
            -- background, which reads as a washed-out version of the accent.
            -- Being a table, it is not re-tinted on `:colorscheme` -- it
            -- refreshes on the next mode change.
            local hl = vim.api.nvim_get_hl(0, { name = group, link = false })
            if not hl.fg or not hl.bg then
              return nil -- ui.kit.chip falls back to its own default colour
            end
            return { fg = hl.fg, bg = hl.bg }
          end,
          -- Floor under the chip's content-derived width (longest line + 2);
          -- nil/0 = none.
          -- min_width = nil, -- integer
          -- What the chip shows: "modern" (icon + folder, icon + branch, live)
          -- | "classic_text" (the plain resolved name) | a table
          -- `{ preset = "modern", icons = { folder = ..., branch = ... }, template = "..." }`.
          -- text = "modern",
          -- Auto-hide after this many ms; false (or <= 0) keeps it up.
          -- timeout_ms = 3000,
          -- Flash the chip's colour on save/load/autoload.
          -- pulse = false,
          -- pulse_color = nil, -- Sessions.Chip.Color; nil = kit.chip.pulse's "DiagnosticWarn"
          -- pulse_duration_ms = nil, -- integer; nil = kit.chip.pulse's 300
        },
      }
    end,
  },
}
