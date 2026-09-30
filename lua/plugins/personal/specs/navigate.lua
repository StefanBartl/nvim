---@module 'plugins.personal.specs.navigate'
--- Files & navigation -- personal plugin specs (Paths, hover previews, pickers, trees, file operations and sessions.)
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
      mode = "hybrid",
      alternate = {
        enable = true,
        similarity_threshold = 75,
      },
      external = {
        enable = true,
      },
      mappings = {
        -- `gF` only. `<2-LeftMouse>` used to be listed here as well, but
        -- gopath maps its lhs globally in normal mode: every double-click in
        -- any buffer then ran a path resolve instead of selecting the word
        -- under the cursor, and each miss logged `[gopath] no match: no-match`
        -- -- including the one right after startup on the dashboard.
        open_here = "gF",
        open_split = "g|",
        open_vsplit = "g\\",
        open_tab = "g}",
        copy_location = "gY",
        debug = "g?",
      },
    },
  },

  {
    -- Path/link hover for every filetype. Formerly lib.nvim.hover; split out
    -- 2026-09-01 as the only lib.nvim module that opens windows, installs
    -- autocmds in every buffer, borrows keymaps, ships usercommands and
    -- knows four sibling plugins by name -- see documentation.nvim/
    -- docs/ECOSYSTEM.md for the rule behind that split.
    --
    -- `lazy = false` because `enable()` must run from something that isn't
    -- itself lazy: markdown.nvim is ft-lazy on Markdown, so a session that
    -- never opens a .md would otherwise get no hover at all -- exactly the
    -- case this feature is meant to cover (paths in .txt, code comments,
    -- :messages). `priority` sits below lib.nvim, a hard dependency.
    --
    -- No options set below -- every feature switch (web links + fetch/shot,
    -- office documents via pdfport, zen, persist, zoom keys, `auto_hover`)
    -- runs on hover.nvim's own defaults. Full behaviour, the two-axis
    -- on/auto distinction, and measured costs (browser start, page render,
    -- LibreOffice conversion) are documented in hover.nvim/docs/
    -- configuration.md and docs/FEATURES/*.md; `:Hover why`/`:Hover status`
    -- explain a given switch at runtime.
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
        -- trigger only, `:Hover show` always answers for every type. Default
        -- shown in full because a partial table merges additively.
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
          -- Confirmed working 2026-09-09.
          use_mpv = false,

          -- ---------------------------------------------------------------
          -- EXPERIMENTAL (system-player window positioning) -- nested under
          -- its own key so it reads as clearly separate from ordinary
          -- playback settings above. None of these three only do anything
          -- when there is no mpv window (no mpv, or use_mpv = false above),
          -- and the second and third only matter at all when the first is
          -- true. Nothing here is load-bearing for ordinary playback; all
          -- three are "best effort, may silently do nothing" by design --
          -- see docs/FEATURES/VIDEO.md.
          -- ---------------------------------------------------------------
          experimental = {
            -- Best-effort centre whatever window the system-player fallback
            -- opens, on the monitor the terminal is on right now. Off by
            -- default -- whether it does anything depends on what is
            -- registered on this machine (a UWP handler on Windows
            -- historically ignores it; macOS needs Accessibility permission;
            -- Linux needs xdotool/wmctrl and no Wayland in the way). Never
            -- reports failure either way.
            system_player_align = true,

            -- Only consulted when system_player_align (above) is true. A
            -- fullscreen window defeats alignment before it starts --
            -- reported 2026-09-09: VLC (this machine's system handler) opens
            -- in its remembered fullscreen state, same visible result as
            -- system_player_align = false. With this true (the default), the
            -- fallback tries a known, scriptable player by name first (`vlc
            -- --no-fullscreen`, today) before the system's own handler, so
            -- there is a non-fullscreen window for alignment to actually act
            -- on. Set false to always go through the system handler even
            -- with alignment on.
            system_player_prefer_classic = true,

            -- Only consulted when system_player_align (above) is true, same
            -- as system_player_prefer_classic. `vlc` alone missed on PATH on
            -- this machine -- reported 2026-09-12: the Windows VLC installer
            -- does not extend PATH, so the known-player search above found
            -- nothing and fell all the way through to the system handler's
            -- remembered fullscreen state, same as if alignment were off
            -- entirely. With this true (the default), a name that misses on
            -- PATH is tried again against the install locations Windows
            -- actually puts it in (Program Files / Program Files (x86)).
            -- Set false to search PATH only.
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
        -- nav_keys = { left = { "h" }, right = { "l" }, up = { "k" }, down = { "j" } }, -- pan while zoomed
        -- position_keys = { next = { "<M-n>" } }, -- step to the next position-preview contributor
        -- zoom_keys = { into = { ">" }, out = { "|" }, reset = { "=" } },
        -- zen_keys = { toggle = { "F" } },
        -- transport_keys = { toggle = { "<CR>" }, forward = { "." }, back = { "," } }, -- video play/pause, frame step

        -- Keymaps this plugin sets in the user's own namespace.
        -- keymaps = { show = false },
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
        engine = "snacks",
        repos_dir = repos,
        -- One exclude list for every engine (lib.nvim.fs.ignore.list), also
        -- patched onto the native :FzfLua / :Telescope / Snacks pickers.
        find = { ignore_list = true },
        -- Prompt on top, wrap-around navigation, no preview line wrapping --
        -- on every engine, native pickers included.
        display = { cycle = true, prompt_top = true, preview_wrap = false, path_adaptive = true },
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

        keymaps = {
          -- Smart action: one picker running grep (content) + find (filenames)
          -- for the same query, merged and ranked by relevance. See
          -- pickers.nvim docs/COMMANDS.md#the-smart-action.
          cwd_smart = "<leader>CW", -- smart grep+find in CWD
          config_smart = "<leader>CF", -- smart grep+find in nvim config
        },

        -- Declarative mappings surface: any pickers.builtins name, or any
        -- <scope>_<files|grep|smart|find_all>, each with its own lhs -- the
        -- flexible alternative to the fixed `keymaps` fields above.
        mappings = {
          -- Formerly config/snacks/mappings/standard.lua (lazy `keys` of the snacks
          -- spec), now declared here: they dispatch through pickers.builtins /
          -- :Pickers anyway, whichever engine is active. `recent` is also on
          -- <leader>fo (snacks "recent" / telescope+fzf "oldfiles").
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
          -- the list) -- pickers.nvim's own in-house `git_status_filtered`
          -- builtin (renamed from `git_status_marks`: it has no bookmark/mark
          -- semantics, just a filtered git status list -- ecosystem-wide
          -- mark/link naming-consistency pass), NOT the native `git_status`
          -- picker already on <leader>gs (the `git_status` entry above).
          -- <leader>g{s,S,l,L,B,D,f,i,I,p,P} and bare gb/gd/gg are all taken
          -- across this ecosystem's git keymaps (pickers.nvim's own +
          -- gitsuite.nvim + neogit + diff.nvim); <leader>gm was free -- kept
          -- as the mnemonic key even though the builtin name moved on.
          git_status_filtered = { "<leader>gm" },
        },

        history = {
          enabled = true,
          fzf_scope = "patch", -- patches telescope + fzf-lua setup() itself, no config change needed elsewhere
        },

        keys = {
          -- Keep the old config.telescope.keymaps horizontal-scroll bindings
          -- (that module is now redundant/removed) instead of the plugin's
          -- own <C-Left>/<C-Right> default.
          preview_scroll_left = "<M-Left>",
          preview_scroll_right = "<M-Right>",
        },
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
      -- ui.kit/ui.contextmenu (right-click menu, on by default) -- moved out
      -- of lib.nvim.ui.kit/lib.nvim.contextmenu in the 2026-09 migration.
      "StefanBartl/ui.nvim",
      -- only ONE tree plugin is needed:
      "nvim-neo-tree/neo-tree.nvim",
      -- or: "nvim-tree/nvim-tree.lua",
    },
    config = function()
      -- Every feature is on by default; cwd_sync is opt-in (auto-chdir), so
      -- enable it explicitly. It anchors the cwd to the nearest .git ancestor on
      -- buffer switch. reveal = false because neo-tree already follows the cwd
      -- (bind_to_cwd + follow_current_file) — so cwd_sync only sets the cwd and
      -- lets neo-tree root/reveal, instead of the two fighting each other.
      require("filetree").setup({
        adapter = "neotree",
        -- Reference engine: also rewrite bare filesystem paths written as
        -- running text (`see ../Test/Tester.md` in a note) or in code
        -- comments, not just paths inside link/require/import syntax. Opt-in
        -- and namespaced under `experimental` on purpose — it is a new
        -- provider whose config shape may still move, and future
        -- in-development refs features land under the same key. `comments`
        -- defaults to true (scan comment lines in .lua/.py/.ts/… too); set
        -- it false to restrict to prose/text files. A token is only ever
        -- rewritten when it resolves to exactly the file that moved.
        refs = {
          experimental = {
            plaintext = { enabled = true },
          },
          -- Cascade-delete-assets: when a file is deleted, also detect
          -- outgoing links it holds to asset files (screenshots etc.) under
          -- assets/ and offer to delete those too, once nothing else still
          -- references them. Opt-in upstream (default off); enabled here
          -- since this is the feature under active development/testing —
          -- see wkdbook-myplugins/filetree.nvim/ROADMAP/IDEAS/Cascade_Delete_Assets.md.
          outgoing_assets = { enabled = true },
        },
        features = {
          cwd_sync = { enabled = true, reveal = false },
          -- The mode badge (PROJECT/LOCK/…) is shown in this host's own
          -- ui.nvim statusline instead (config/ui_statusline/variant.lua,
          -- filetree_cwd_mode module) via cwd_mode's
          -- external-statusline API (badge()/component()). indicator.enabled
          -- must stay false here, or the mode shows twice: once in the
          -- shared statusline, once as a float in the tree window (with
          -- laststatus=3 there is no per-window statusline for it to use,
          -- so it would fall back to exactly that float).
          -- labels.follow is "" upstream by design: filetree's own in-tree
          -- badge is meant to be invisible while no policy is active. In a
          -- shared statusline that reads as "the component is broken" rather
          -- than "no mode" — so give follow a visible label. Everything else
          -- keeps filetree's defaults (PROJECT/PKG/LOCK/MANUAL/TREE).
          cwd_mode = {
            indicator = {
              enabled = false,
              labels = { follow = "FOLLOW" },
            },
          },
          -- Mark the currently-focused file with a sign-column icon (on top of
          -- neo-tree's own fg colour for all opened files). opened_sync is on by
          -- default and keeps those opened-file colours in sync as buffers open/
          -- close, so no config needed for it.
          current_hl = { enabled = true, icon = "▸" },
          -- Trash and watcher_quarantine are on by default in filetree.nvim
          -- (not in its DEFAULT_DISABLED list) - listed here only to make
          -- that explicit, no functional effect.
          trash = { enabled = true },
          watcher_quarantine = { enabled = true },
          -- handle_guard: actually closes neo-tree's leaked directory-watcher
          -- handles before a rename/move so the Windows EPERM file-lock can't
          -- happen (watcher_quarantine only hides the error). Opt-in / default
          -- off; enabled here to test whether the sporadic lock stops recurring.
          handle_guard = { enabled = true },
          -- context_menu: left on its default (<RightMouse>, opt-out) -
          -- filetree.nvim is now the sole right-click implementation for the
          -- tree. config/menu/neotree/ (the old hand-maintained entries) is
          -- gone, and ui.nvim's ui.menu global RightMouse handler no
          -- longer special-cases neo-tree - filetree's own buffer-local
          -- binding shadows it inside the tree, same items() source either
          -- way. Non-tree right-click (markdown, everything else) still goes
          -- through the global handler, unaffected.
          -- statusline defaults to true, but that blanks the tree window's
          -- local 'statusline' — harmless under laststatus=2 (per-window),
          -- but with laststatus=3 (global statusline, see options.lua) that
          -- blank local override becomes the content of the ONE shared
          -- statusline whenever the tree is focused. Disabled here so
          -- filetree leaves the global statusline alone.
          -- highlights_isolate confirmed working in real interactive use -
          -- replaces config.neotree's window/{disable_statusline,highlight}.lua
          -- + autocmds/init.lua, all removed.
          window_style = { statusline = false, highlights_isolate = true },

          -- The last three pieces of this config's own neo-tree layer,
          -- moved into filetree.nvim 2026-09-19 (external-plugins report,
          -- "neo-tree config -> filetree.nvim"):
          --   * the source switcher -- `"`/`!` cycle in place (default),
          --     `<leader>ns` picks from a list (was config.neotree's global
          --     key), and plugins/neotree.lua takes the source_selector
          --     names from the same module;
          --   * the four Alt toggle keys, with the E95 self-heal now in the
          --     adapter (was config/neotree/window/open/keymaps/only_lhs.lua);
          --   * `y` in the tree as a second key for path_copy's absolute-path
          --     copy (was a hand-rolled delegate in config.neotree.keymaps).
          source_switcher = { keymap_pick = "<leader>ns" },
          tree_toggle = { enabled = true },
          path_copy = { keymap_abs = { "[a", "y" } },
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
        -- Bare `nvim` (no file args) resumes the last-loaded session — see
        -- docs/ROADMAP/casedesk/SESSIONS.md §4.3.
        -- autoload = true,

        -- The mark list.
        marks = {
          enable = true,
          scope = "global",
          defaults = require("config.marks.defaults"),
          select_key = "<leader>h%d",
          -- `<C-e>` opens the marks popup (bindings/mappings/sessions.lua), so
          -- pressing it again closes it: a toggle, alongside q / <Esc>.
          menu = { preview_keys = { close = { "q", "<Esc>", "<C-e>" } } },
        },
        -- `false`, not a table: the actual keymaps are attached from
        -- bindings/mappings/sessions.lua at UIReady instead of here. This
        -- spec has `lazy = false` for the autoload/autosave reason above, so
        -- anything bound directly in `opts`/`config` runs on the synchronous
        -- startup path -- exactly what this config's keymap registration is
        -- everywhere else deliberately kept off of (see init.lua's UIReady
        -- phases).
        keymaps = false,

        -- shape/dock already default to sessions.nvim's own "dock_left"/true
        -- (statusline-docked look) -- only the mode-colour wiring belongs
        -- here, per ui.kit.chip's own design: it stays statusline-agnostic,
        -- so a `St_<Mode>Mode`-specific colour source is this config's job,
        -- not sessions.nvim's or ui.kit's.
        chip = {
          -- Without this, the colour function below would only ever be
          -- re-read at the next incidental save/load/dirty-tracking event,
          -- not when the mode itself actually changes.
          track_mode = true,
          row_offset = 0,
          col_offset = -1,
          color = function()
            -- `St_<Suffix>Mode` is only DEFINED once `ui.statusline.highlights
            -- .ensure()` has run -- and this config wires that in at UIReady
            -- (VimEnter + vim.schedule(), see config/ui_statusline/init.lua),
            -- the same deferred pattern ui.kit.chip's own startup settle pass
            -- uses for its VimEnter re-resolve. Whichever of the two
            -- `vim.schedule()` callbacks happens to queue first wins the
            -- race; when the chip's settle pass wins, this function read an
            -- undefined group on its first (and, until some later unrelated
            -- refresh/mode-change, only) resolution -- `hl.fg`/`hl.bg` were
            -- nil, this returned nil, and the chip fell back to
            -- `ui.kit.chip`'s own default (`"Special"`, an amber/orange in
            -- this colorscheme) until whatever incidental event happened to
            -- refresh it next. Live-reproduced via real startup screenshots:
            -- orange on first paint, the real mode colour only after ~1-2s.
            -- `ensure()` is idempotent (a boolean guard) and reads the LIVE
            -- colorscheme fresh, so calling it here closes the race outright
            -- regardless of which `vim.schedule() ` wins -- by the time this
            -- function is ever invoked, the groups it is about to read are
            -- guaranteed to already exist.
            require("ui.statusline.highlights").ensure()
            -- The same helper the real statusline's own mode pill resolves
            -- its colour through (`St_<Suffix>Mode`, cached/invalidated on
            -- ModeChanged already) -- reusing it here means this chip
            -- reads the exact same source the statusline does, every time
            -- it repaints. That is NOT an unconditional "never drifts"
            -- guarantee, though: `ui.kit.chip`'s own `ColorScheme` re-tint
            -- handler only re-paints a chip whose `color` resolves through
            -- a highlight-group *name* (`resolve_colors()`'s `themed =
            -- true` branch) -- this chip's `color` always returns a
            -- `{fg,bg}` table instead, so that handler skips it. A real
            -- `:colorscheme` switch during an otherwise idle session (no
            -- mode change, no buffer/window/tab churn) can therefore leave
            -- this chip showing pre-switch colours until the next
            -- incidental refresh -- found and confirmed live (adversarial
            -- review, 2026-09-28); pre-existing since `track_mode`/
            -- function-valued `color` shipped, not something this
            -- `ensure()` call introduces or fixes. Low-impact in practice
            -- (`track_mode` alone re-paints on every real mode change,
            -- which is frequent), left as a known gap rather than a
            -- rushed fix here.
            local group = require("ui.statusline.modules.highlighting").mode_band_group()
            -- The chip wants the group's own {fg,bg} pair verbatim (the
            -- mode's accent colour as the chip's background, same as the
            -- statusline's pill), not a highlight-group NAME -- ui.kit.chip
            -- would tint a name's fg toward the window background instead
            -- of using the referenced group's own bg, which reads as a
            -- washed-out version of the mode colour rather than the actual
            -- accent pill this is supposed to match.
            local hl = vim.api.nvim_get_hl(0, { name = group, link = false })
            if not hl.fg or not hl.bg then
              return nil -- ui.kit.chip falls back to its own default colour
            end
            return { fg = hl.fg, bg = hl.bg }
          end,
        },
      }
    end,
  },
}
