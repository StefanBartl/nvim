---@module 'plugins.personal'
--- Personal and local development plugins - the SPEC IMPLEMENTATION only.
---
--- All source control (which repo loads locally / remotely / not at all, the
--- global OVERRIDE switch, machine-role handling and the per-repo mode table)
--- lives in plugins.personal.source. This file just registers the specs and
--- exports them for lazy:
---   local plugins = require("plugins.personal.source")
---   plugins.add({ ...specs... })
---   return plugins.export()
--- To turn a repo off or switch it local/remote, edit plugins/personal/source.lua,
--- not this file.

local personal_utils = require("plugins.personal.utils")
local machine = require("machine")
local plugins = require("plugins.personal.source")

-- ===========================================================================
-- PLUGIN SPECS
-- ===========================================================================

plugins.add({

  -- ==========================================================================
  -- 1. CORE / INFRASTRUCTURE, UTILITIES & SYSTEM
  -- ==========================================================================

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
    end,
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
          -- EXPERIMENTAL (system-player window positioning) -- both of the
          -- two settings below only do anything when there is no mpv window
          -- (no mpv, or use_mpv = false above), and the second only matters
          -- at all when the first is true. Neither is load-bearing for
          -- ordinary playback; both are "best effort, may silently do
          -- nothing" by design -- see docs/FEATURES/VIDEO.md.
          -- ---------------------------------------------------------------

          -- Best-effort centre whatever window the system-player fallback
          -- opens, on the monitor the terminal is on right now. Off by
          -- default -- whether it does anything depends on what is
          -- registered on this machine (a UWP handler on Windows
          -- historically ignores it; macOS needs Accessibility permission;
          -- Linux needs xdotool/wmctrl and no Wayland in the way). Never
          -- reports failure either way.
          system_player_align = true,

          -- Only consulted when system_player_align (above) is true. A
          -- fullscreen window defeats alignment before it starts -- reported
          -- 2026-09-09: VLC (this machine's system handler) opens in its
          -- remembered fullscreen state, same visible result as
          -- system_player_align = false. With this true (the default), the
          -- fallback tries a known, scriptable player by name first (`vlc
          -- --no-fullscreen`, today) before the system's own handler, so
          -- there is a non-fullscreen window for alignment to actually act
          -- on. Set false to always go through the system handler even with
          -- alignment on.
          system_player_prefer_classic = true,

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
    -- The whole LSP subsystem, extracted from this config's former lua/lsp/**
    -- (see docs/ROADMAP/personal/lsp.nvim.md). Module root is still `lsp`, so
    -- every existing require("lsp.…") keeps resolving -- which also means this
    -- plugin and a local lua/lsp/** cannot coexist: the config would shadow it.
    --
    -- No `opts`/`config` on purpose. init.lua calls setup() inside
    -- startup.now("lsp", ...) because capabilities have to be applied globally
    -- before the first client attaches; a lazy opts-block would hand that
    -- ordering to the plugin manager. `lazy = false` only guarantees the
    -- module is on the runtimepath by then.
    "StefanBartl/lsp.nvim",
    lazy = false,
    priority = 900,
    dependencies = { "StefanBartl/lib.nvim" },
  },

  {
    -- This config's former lua/wkdoptions/** plus lua/options.lua: the
    -- declarative option set, the highlight features, the editor-option
    -- toggles, italic keywords and per-filetype indentation. Module root is
    -- `my`, so a local lua/wkdoptions/ would not shadow it -- but the old
    -- callers were repointed in the same commit that deleted it, so there is
    -- nothing left to shadow either.
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

  {
    -- Eager: setup() registers the VimEnter autoload and the VimLeavePre
    -- autosave. Both are startup/shutdown events, so a lazy trigger would have
    -- to fire before VimEnter to be of any use -- which is what `lazy = false`
    -- means.
    "stefanbartl/sessions.nvim",
    lazy = false,
    dependencies = { "stefanbartl/lib.nvim" },
    opts = {
      -- Bare `nvim` (no file args) resumes the last-loaded session — see
      -- docs/ROADMAP/casedesk/SESSIONS.md §4.3.
      -- autoload = true,
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
        },

        keymaps = {
          -- Smart action: one picker running grep (content) + find (filenames)
          -- for the same query, merged and ranked by relevance. See
          -- pickers.nvim docs/COMMANDS.md#the-smart-action.
          cwd_smart = "<leader>cw", -- smart grep+find in CWD
          config_smart = "<leader>cf", -- smart grep+find in nvim config
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

  {
    "StefanBartl/buffer-ctx.nvim",
    cmd = {
      "Insert",
      "Copy",
      "Format",
      "Mark",
      "MarkLineToggle",
      "MarkLinesYank",
      "CopyFilepathAbsolute",
      "CopyFilepathRelative",
    },
    keys = { "<leader>cnl", "<leader>cnm", "<leader>cnf", "<S-m>", "<C-p>" },
    opts = {},
  },

  {
    "StefanBartl/open.nvim",
    -- All three names are needed: the viewer commands are registered by
    -- open.nvim's setup(), so lazy-loading on "Open" alone would leave
    -- :UrlView / :MDLinksView undefined until something else pulled the
    -- plugin in.
    cmd = { "Open", "UrlView", "MDLinksView" },
    dependencies = { "StefanBartl/lib.nvim" },
    opts = {},
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
    -- cell_aspect: measured width/height ratio of this WezTerm setup (the 0.5
    -- default in images.scale leaves an empty strip below images).
    --
    -- terminal_padding is deliberately NOT set here: it lives in the stored
    -- calibration written by `:Image calibrate` (stdpath("data")/images.nvim),
    -- and an explicit option here would silently override it. draw_inset
    -- catches whatever sub-cell remainder is left after that.
    --
    -- ocr.lang: `:Image ocr` and `:Case ocr` read customer screenshots, and
    -- those are German or English depending on which system produced them --
    -- tesseract takes both at once in this form. Both language files are
    -- installed here; `:checkhealth images` checks each half separately and
    -- says so if one goes missing.
    opts = {
      display = { cell_aspect = 0.46 },
      ocr = { lang = "deu+eng" },
    },
  },

  {
    "StefanBartl/sandbox.nvim",
    event = "VeryLazy",
    dependencies = { "StefanBartl/lib.nvim" },
    opts = {
      -- `image pull`/`push` and the devcontainer build report into the shared
      -- lib.nvim.progress registry, rendered by the statusline's
      -- "plugin_progress" module.
      progress_style = "statusline",
    },
  },

  {
    "StefanBartl/documentation.nvim",
    cmd = { "DocMap", "DocBrowse", "DocMapAll", "DocMapAllFull" },
    dependencies = { "StefanBartl/lib.nvim" },
    -- No `root`: the commands deliberately map the current working directory,
    -- because rows of repos sit side by side here and a fixed target would be
    -- exactly wrong. `source` derives documentation.config from the root
    -- (lua/<name>, when lua/ contains exactly one candidate).
    opts = function(_, opts)
      opts.progress_style = "statusline"
      -- `require-not-declared` false positives, confirmed 2026-08-16 by
      -- tracing every hit back to the actual require site (not fixed here,
      -- not fixable in the checker without a real capability it doesn't
      -- have): the checker treats "own[first segment]" as sufficient proof a
      -- require belongs to this tree, which is right except for two cases.
      -- (1) `nvchad.*` (stl.utils, tabufline, themes, term, utils, nvdash,
      -- mason, colorify, lsp.signature, winmes, configs.lspconfig, ...)
      -- resolves to the real NvChad plugins' (`NvChad`/`ui`) own
      -- `lua/nvchad/*` tree, which happens to share this repo's own
      -- `lua/nvchad/` top segment -- 24 of the 31 remaining
      -- `require-not-declared` hits. (2) `config.harpoon.api.lua`'s
      -- `require("config.harpoon.ui.menu_" .. kind)` is a dynamic require;
      -- the checker only ever sees the pre-concatenation literal
      -- `"config.harpoon.ui.menu_"`, never the resolved `menu_telescope`/
      -- `menu_fzf` it actually loads. `:DocMap check` will keep listing
      -- these 25 as warnings -- known, not drift.
      -- Experimental (2026-08-10): a "Compiler Explorer" link next to every
      -- module/function in the generated page, real luac -l -l -p bytecode
      -- disassembly, not a workaround for Lua. Off by default upstream;
      -- turned on here explicitly per request.
      opts.godbolt = true

      -- `:DocMap bindings` (2026-08-15): declare THIS config's own keymap/
      -- usercmd/autocmd helpers so they are extracted too. The `vim.*` APIs
      -- need no declaration; these five do, and without them `:DocMap
      -- bindings` finds ~10 registrations here instead of ~300.
      --
      -- Why the plugin cannot just guess these: a bare `map(...)` is also
      -- the most natural name for a list-mapping helper, so guessing would
      -- silently report `vim.tbl_map` calls as keymaps. The caller knows its
      -- own helper names and the scanner cannot — see core/bindings.lua.
      --
      -- All five are real shapes in this tree: `map` is
      -- `lib.nvim.bindings.keymap` (same argument order as vim.keymap.set,
      -- which is why it can reuse that layout), `usercmd.create` and
      -- `autocmd.create` are lib.nvim's, and
      -- the two bare names are `local nvim_create_autocmd =
      -- api.nvim_create_autocmd`-style aliases (autocmds/terminals/init.lua).
      -- `composer.verb` is deliberately absent: it registers a whole verb
      -- tree rather than one command, so its first argument is not a command
      -- name and no built-in layout describes it.
      opts.bindings = {
        wrappers = {
          ["map"] = "keymap",
          ["usercmd.create"] = "usercmd",
          ["autocmd.create"] = "autocmd",
          ["nvim_create_autocmd"] = "autocmd",
          ["nvim_create_user_command"] = "usercmd",
        },
      }

      -- `:DocMap all` / `:DocMapAll` (2026-08-14): documentation.nvim owns
      -- the command, this config supplies only the data -- the same split
      -- runtime-analysis.nvim's own `opts.telemetry` already draws one
      -- entry below. `plugins.personal.export.projects()` is the same
      -- resolved entry list `config.telemetry.build()` reads, so nothing
      -- here has to be kept in sync with `plugins/personal/init.lua` by
      -- hand -- add a plugin to the spec below and both wirings pick it up.
      local export = require("plugins.personal.export")
      local projects = export.projects()
      local gen_projects = {}
      for _, p in ipairs(projects) do
        gen_projects[#gen_projects + 1] = { root = p.dir, title = p.name }
      end
      -- This config itself (2026-08-15) -- not a `plugins.personal` entry
      -- (it is the config, not an installed plugin `export.projects()` could
      -- ever resolve), so it is appended here by hand rather than made
      -- `export.projects()`'s problem: `:MyPlugins`/the statusline badge
      -- read that same list for "which plugins are installed", a question
      -- this config is not an answer to. `vim.fn.stdpath("config")` is the
      -- one thing here that is always right regardless of machine --
      -- already has `docs/map/` from a prior manual `:DocMap`, so this is
      -- "join the All sweep", not a first-time map.
      gen_projects[#gen_projects + 1] = { root = vim.fn.stdpath("config"), title = "nvim-config" }
      if #gen_projects > 0 then
        opts.generate_all = {
          projects = gen_projects,
          -- Listing a plugin in the spec below is already the active signal
          -- that its data is wanted -- see bindings.usrcmds.docmap_all's old
          -- header (now removed) for the "never infer" reasoning this
          -- overrides deliberately, once, here.
          autoload = true,
        }
      end

      return opts
    end,
  },

  {
    "StefanBartl/runtime-analysis.nvim",
    lazy = false,
    dependencies = { "StefanBartl/lib.nvim" },
    -- Telemetry auto-instrumentation (which of Stefan's plugins, with what
    -- settings) lives here, on this plugin's own spec, not a separate
    -- config file or a call before lazy.setup() -- see lua/config/
    -- telemetry.lua for the policy, runtime-analysis.telemetry.lazy for
    -- the mechanism this opts table drives.
    opts = function(_, opts)
      opts.telemetry = require("config.telemetry").build()
      return opts
    end,
  },

  {
    "StefanBartl/spotlight.nvim",
    dependencies = { "StefanBartl/lib.nvim" },
    event = "VeryLazy",
    opts = {},
  },

  -- ==========================================================================
  -- 2. NAVIGATION, FILE SYSTEM, SEARCH & TREES
  -- ==========================================================================

  {
    "StefanBartl/fileops.nvim",
    event = "VeryLazy",
    -- auto_mkdir, conflict_marks and the cycle keymaps used to live in this
    -- config's own autocmds/ and were moved into the plugin; they are on by
    -- default there, so nothing has to be repeated here.
    opts = {
      cycle = { open_target = "current" }, -- default is a split
    },
  },

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
    "StefanBartl/replacer.nvim",
    cmd = { "Replace", "Replacer", "Surround", "Wrap" },
    dependencies = {
      "ibhagwan/fzf-lua",
      "StefanBartl/lib.nvim",
      -- "j-hui/fidget.nvim"
    },
    opts = {
      engine = "telescope", -- plugin default is "auto" (fzf-lua first)
      progress_style = "statusline", -- "auto" | "notify" | "statusline" | "fidget" | "float" (needs lib.nvim)
    },
  },

  {
    "StefanBartl/insights.nvim",
    -- Not `cmd = "Insights"`: the conflicts / unimported / devserver
    -- autocmds are registered by setup(), so lazy-loading on the command would
    -- mean they never fire. Set their `enable = false` to opt out instead.
    lazy = false,
    dependencies = { "StefanBartl/lib.nvim" },
    opts = {
      -- Building the cwd symbol index runs one rg pass per language pattern;
      -- reports into the shared lib.nvim.progress registry.
      symbols = { progress_style = "statusline" },
    },
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
        },
        features = {
          cwd_sync = { enabled = true, reveal = false },
          -- The mode badge (PROJECT/LOCK/…) is shown in wkdnvchad's own
          -- statusline instead (modules/filetree_cwd_mode) via cwd_mode's
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
          -- gone, and config/menu/mappings.lua's global RightMouse handler no
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

  {
    "StefanBartl/reposcope.nvim",
    name = "reposcope",
    event = "VeryLazy",
    dependencies = { "StefanBartl/lib.nvim" },
    opts = {
      -- `:Reposcope update`/`status` walk a whole directory of clones; both
      -- report into the shared lib.nvim.progress registry.
      progress_style = "statusline",
    },
  },

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

  -- ==========================================================================
  -- 3. CODE QUALITY, UI, LOGGING & PRODUCTIVITY
  -- ==========================================================================

  {
    "StefanBartl/debugging.nvim",
    -- cmd = "Debug",
    event = "VeryLazy",
    dependencies = { "StefanBartl/lib.nvim" },
    opts = {}, -- features.neotree is off in the plugin's own defaults
  },

  -- Debugging is a mode you enter deliberately, so nothing here belongs in
  -- startup. On `event = "VeryLazy"` this cost 142-180ms (and once 328ms) on
  -- every launch, dependencies included, in sessions that never debugged
  -- anything. `keys`/`cmd` moves all of it to the first keypress: lazy.nvim
  -- installs stubs for both, so the mappings and `:Dap` behave exactly as
  -- before -- the first use just also loads the plugin.
  --
  -- The keys below MUST mirror wkddap.bindings.keymaps. `dap_prefix` is
  -- shared with opts so the two cannot drift apart; the suffixes are the ones
  -- that module maps (see its `map("n", prefix .. …)` calls). A binding
  -- missing here would simply never load the plugin and silently do nothing.
  (function()
    -- "<leader>d" alone collides with existing git/fzf mappings
    -- (dc = DiffviewClose, di = ToggleInlineDiff, do = FzfLua diagnostics)
    local dap_prefix = "<leader>da"

    ---@type table[]
    local dap_keys = {}
    for _, m in ipairs({
      { "c", "Continue" },
      { "s", "Step Over" },
      { "i", "Step Into" },
      { "o", "Step Out" },
      { "t", "Terminate" },
      { "r", "Restart" },
      { "b", "Toggle Breakpoint" },
      { "B", "Conditional Breakpoint" },
      { "L", "Log Point" },
      { "l", "List Breakpoints" },
      { "u", "Toggle UI" },
      { "e", "Evaluate" },
      { "R", "Open REPL" },
    }) do
      dap_keys[#dap_keys + 1] = { dap_prefix .. m[1], desc = "[DAP] " .. m[2] }
    end
    -- `e` is mapped in visual mode too (evaluate the selection).
    dap_keys[#dap_keys + 1] = { dap_prefix .. "e", mode = "v", desc = "[DAP] Evaluate selection" }

    return {
      "StefanBartl/dap.nvim",
      cmd = "Dap",
      keys = dap_keys,
      dependencies = {
        "StefanBartl/lib.nvim",
        "mfussenegger/nvim-dap",
        "rcarriga/nvim-dap-ui",
        "nvim-neotest/nvim-nio",
        "theHamsta/nvim-dap-virtual-text",
        "jbyuki/one-small-step-for-vimkind",
        "igorlfs/nvim-dap-view", -- default panel UI (dap.nvim ui.provider = "dap-view")
      },
      opts = {
        keymaps = { prefix = dap_prefix },
        -- dap.nvim wires exactly one panel UI. nvim-dap-view is the default;
        -- switch to ui = { provider = "dap-ui" } to go back to nvim-dap-ui.
        ui = { provider = "dap-view" },
      },
      -- dap.nvim's own Lua module is "wkddap", not "dap" -- it depends on
      -- nvim-dap, which itself owns the top-level `dap` module (lua/dap.lua)
      -- and several submodule names (dap.ui, dap.utils) that would otherwise
      -- collide with this plugin's files if both used "dap" as their root.
      config = function(_, opts)
        require("wkddap").setup(opts)
      end,
    }
  end)(),

  {
    "StefanBartl/diff.nvim",
    cmd = { "Diff", "DiffClear", "DiffOrig", "DiffExit" },
    opts = {}, -- all three features are on by default
  },

  {
    -- Eager on purpose, and `cmd = { "Cmdlog" }` is gone rather than kept
    -- alongside `lazy = false` (where lazy.nvim ignores it anyway, so it only
    -- read as if this were command-lazy). setup() starts the CmdlineLeave
    -- tracker that records every `:` command -- that recording *is* the
    -- plugin. Loading on `:Cmdlog` would start the tracker at the moment you
    -- first ask for the history, so the history would always be empty.
    -- Opt out with `track_commands = false`.
    "StefanBartl/cmdlog.nvim",
    lazy = false,
    opts = {}, -- picker already defaults to telescope
  },

  {
    "StefanBartl/emojis.nvim",
    cmd = "Emojis",
    opts = {}, -- default_scope is already "%"
  },

  {
    "StefanBartl/github_stats.nvim",
    event = "VimEnter",
    dependencies = { "StefanBartl/lib.nvim" },
    config = function()
      require("github_stats").setup({
        -- Explicit allowlist instead of watch_users auto-discovery: discovery
        -- pulled in every public repo (~40), and fetch_all spawns one curl
        -- process per repo per metric (4 metrics) in a tight synchronous
        -- loop. On machines where process creation is slow (AV/EDR scanning
        -- each spawn), that many near-simultaneous spawns froze the UI for
        -- 45-90s. Capping the repo list keeps the spawn count small.
        repos = {
          "StefanBartl/buffer-ctx.nvim",
          "StefanBartl/cascade.nvim",
          "StefanBartl/color_my_ascii.nvim",
          "StefanBartl/debugging.nvim",
          "StefanBartl/diff.nvim",
          "StefanBartl/documentation.nvim",
          "StefanBartl/emojis.nvim",
          "StefanBartl/fileops.nvim",
          "StefanBartl/filetree.nvim",
          "StefanBartl/github_stats.nvim",
          "StefanBartl/gopath.nvim",
          "StefanBartl/hover.nvim",
          "StefanBartl/language.nvim",
          "StefanBartl/lib.nvim",
          "StefanBartl/lsp.nvim",
          "StefanBartl/markdown.nvim",
          "StefanBartl/mdview.nvim",
          "StefanBartl/cmdlog.nvim",
          "StefanBartl/sandbox.nvim",
          "StefanBartl/open.nvim",
          "StefanBartl/pdfport.nvim",
          "StefanBartl/pickers.nvim",
          "StefanBartl/insights.nvim",
          "StefanBartl/recommender.nvim",
          "StefanBartl/replacer.nvim",
          "StefanBartl/reposcope.nvim",
        },
        token_source = "env",
        token_env_var = "GITHUB_TOKEN",
        fetch_interval_hours = 24,
        notification_level = "all",
        -- Manual fetches only (`:GithubStatsFetch`, dashboard refresh keys) —
        -- the background cycle deliberately never shows an indicator.
        progress_style = "statusline",
        -- "workstation" only reads the already-committed data/ snapshots
        -- (dashboard, :GithubStatsShow, ... all read from disk regardless);
        -- it just never runs the fetch cycle itself.
        background = { enabled = not machine.is("workstation") },
      })
    end,
  },

  {
    "StefanBartl/learn-cli.nvim",
    lazy = false,
    config = function()
      require("learn_cli").setup({
        -- The plugin's own config key is exercises_path (see
        -- lua/learn_cli/config/init.lua); exercises_dir was silently
        -- ignored and the plugin fell back to its stdpath("config")/exercises
        -- default.
        exercises_path = vim.fs.joinpath(
          vim.fn.stdpath("config"),
          "lua",
          "plugins",
          "learn-cli.nvim",
          "exercises"
        ),
      })
    end,
  },

  {
    -- casedesk: the `:Case` / `:Cases` / `:Tricentis` command tree for
    -- SAP-Support case work, extracted from this config's former
    -- lua/bindings/usrcmds/case/** (docs/ROADMAP/casedesk/PLUGIN.md). That
    -- copy is still on disk but FROZEN -- bindings/usrcmds/init.lua no longer
    -- calls its enable(). Exactly one of the two may be active; both would
    -- register :Case twice.
    --
    -- Eager on purpose. setup() registers the command tree AND starts the SLA
    -- watcher (sla/notify.lua: a background timer plus a FocusGained hook that
    -- re-checks P1/P2 deadlines). A `cmd = "Case"` trigger would hand back the
    -- commands but stay silent about deadlines until the first :Case of the
    -- session -- the wrong way round for a feature whose entire point is
    -- telling you about a clock you forgot. The statusline segment
    -- (wkdnvchad/ui/statusline/modules/casedesk) reads casedesk.resolve on
    -- redraw and wants it loaded too.
    --
    -- `opts = {}` and not a single override: every path already derives from
    -- $REPOS_DIR inside config/DEFAULTS.lua, so this machine has nothing to
    -- correct. Overrides belong here the day a machine disagrees about where
    -- WKDBook-Tricentis lives -- see the plugin's docs/configuration.md.
    "StefanBartl/casedesk.nvim",
    lazy = false,
    dependencies = { "StefanBartl/lib.nvim" },
    opts = {},
  },

  -- ==========================================================================
  -- 4. FILE TYPES (MARKDOWN & DOCUMENTS)
  -- ==========================================================================

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
    "StefanBartl/pdfport.nvim",
    -- Only ":PdfPort <sub>" is ever registered (composer.verb, see
    -- lua/pdfport/bindings/usrcmds.lua); the plugin has no separate
    -- PdfPortText/Float/System/Terminal/Health commands.
    cmd = "PdfPort",
    opts = {
      default_backend = "auto",
      fallback_chain = { "pdftotext", "pdfplumber", "marker", "docling", "ollama", "claude" },
      extract_opts = { max_pages = nil, timeout_ms = 30000 },
      render_opts = { mode = "buffer", split = "current", focus = true },
      claude_api_key = nil,
      -- OCR/AI backends run for minutes on a large PDF. Not cancellable from
      -- the indicator (see pdfport's docs), so a non-interactive style only.
      progress_style = "statusline",
      ollama_host = "http://localhost:11434",
      ollama_model = "qwen2.5-coder:7b",
      debug = false,
    },
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
      -- Every option media.nvim has, current value active and everything
      -- else commented out with its own default -- see docs/configuration.md
      -- for the full reasoning behind each one.

      -- Explicit binary paths, for when one is installed but not on PATH
      -- (the Windows winget/scoop shim-dir case). `core.bin` probes the
      -- usual locations itself; this is the escape hatch for what it misses.
      -- `:checkhealth media` says whether ffmpeg was found -- on this
      -- machine it is NOT installed yet:
      --   winget install Gyan.FFmpeg   (then restart the terminal for PATH)
      -- bin = { ffmpeg = nil, ffprobe = nil, mpv = nil },

      -- Hard ceiling on one ffmpeg/ffprobe run, in ms -- the backstop for a
      -- stalled network mount or a truncated download that would otherwise
      -- hang forever.
      -- timeout_ms = 15000,

      -- The poster frame (`media.frame` / `:Media frame`).
      frame = { at = "10%", width = 800 },
      -- frame = {
      --   at = "10%",   -- seconds, "10%" of duration, or an ffmpeg timestamp
      --   width = 800,  -- pixel width the still is scaled to
      -- },

      -- A run of stills at a fixed rate (`media.frames`) -- what hover.nvim's
      -- *inline* transport draws as moving picture.
      -- frames = {
      --   from = nil,     -- nil starts at the beginning
      --   fps = 12,       -- stills per second of source sampled
      --   count = 24,     -- stills per run -- two seconds at fps=12
      --   width = 320,    -- pixel width before sampling down to cells
      -- },

      -- The contact sheet (`media.sheet` / `:Media sheet`): one picture of
      -- the whole file.
      sheet = { rows = 3, cols = 4, width = 1200 },
      -- sheet = {
      --   rows = 3, cols = 4,
      --   width = 1200,     -- of the finished sheet, not one tile
      --   margin = 4,       -- gap between tiles, in pixels
      --   timeout_ms = 120000, -- a sheet is a full pass over the file, not a seek
      -- },

      -- Where rendered stills live, on disk, outliving the session (keyed by
      -- the source file's mtime, so a kept file is safe to serve forever).
      -- cache = {
      --   enabled = true,
      --   dir = nil, -- nil means stdpath("cache") .. "/media.nvim"
      -- },

      -- What `media.play` / `:Media play` launches -- also what hover.nvim's
      -- system-player fallback tier uses when there is no mpv (or
      -- `video.use_mpv = false`). nil hands the file to the system's default
      -- handler, which on Windows opens *behind* the terminal either way --
      -- Windows only grants foreground to the process owning it, which
      -- inside a terminal is the terminal host, not nvim.exe. Set to "mpv"
      -- (or { "mpv", "--loop-file=no" }) to override.
      player = nil,

      -- The windowed mpv player (`media.play_window` / `:Media window` /
      -- hover.nvim's `<CR>`). Always mpv, unlike `player` above -- a
      -- controllable window needs the same binary every time.
      -- window = {
      --   autofit = "80%x80%", -- mpv's --autofit-larger; "" leaves size to mpv
      --   ontop = true,        -- stay above the terminal regardless of focus
      --   args = {},           -- extra mpv flags, appended before the file
      -- },
      --
      -- NOTE: no static `window.args = { "--screen=1" }` here on purpose.
      -- hover.nvim's `<CR>` now detects which monitor the terminal is on and
      -- passes a per-call `screen` to `play_window` itself (2026-09-09) --
      -- a static `--screen=1` in `args` would be appended *after* that and
      -- win, silently overriding the dynamic detection and pinning the
      -- window back to one monitor regardless of where nvim actually is.
      -- Only add this back if the dynamic detection is ever turned off.

      keymaps = { preset = true },
      -- keymaps = {
      --   preset = true,       -- false binds nothing at all
      --   probe = "<leader>Mp",
      --   frame = "<leader>Mf",
      --   sheet = "<leader>Ms",
      --   play = "<leader>Mo",
      --   which_key = true,
      -- },
    },
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
    "StefanBartl/color_my_ascii.nvim",
    ft = "markdown",
    dependencies = { "StefanBartl/lib.nvim" }, -- optional, enables graceful keymap/notify integration
    -- Typing `opts` as ColorMyAscii.Config makes lua_ls offer value completion
    -- inside the config (e.g. `preset = "…"` suggests the fence-line presets).
    -- Requires the plugin's types on the LSP path (lazydev/neodev or workspace lib).
    opts = {
      -- Force the CommonMark-correct heuristic scanner for fence-block
      -- detection instead of treesitter: the installed markdown grammar
      -- version can differ machine-to-machine (no lockfile pinning), and
      -- some versions mis-parse a shorter fence nested inside a longer one
      -- as its own block, causing spurious fence-line highlights.
      treesitter = { block_detection = false },
    },
  },

  {
    "StefanBartl/mdview.nvim",
    dependencies = { "StefanBartl/lib.nvim" },
    build = "npm ci && npm run build:go && npm run build",
    ft = { "markdown" },
    cmd = { "MDView" },
    config = function()
      -- Non-default choices only; the feedback log behind each (which
      -- experimental flags earned "make this the default") lives in
      -- mdview.nvim's own ROADMAP, not here.
      require("mdview").setup({
        browser = {
          -- shiki mis-highlights some fences; hljs until that is fixed upstream.
          highlighter = "hljs",
          focus = "nvim",
          cursor_marker = "caret",
        },
        -- Release build (from GitHub Releases, no toolchain needed). To test a
        -- locally built relay, uncomment and see mdview.nvim/docs/development.md
        -- (`npm run build:go` produces `mdview-server` without .exe on Windows):
        -- dev = {
        -- binary_path = vim.env.REPOS_DIR .. "/mdview.nvim/native/server/mdview-server",
        -- web_root = vim.env.REPOS_DIR .. "/mdview.nvim/dist/client",
        -- },
        -- standalone = {
        -- binary_path = vim.env.REPOS_DIR .. "/mdview.nvim/native/server/mdview-server",
        -- },
        experimental = {
          line_diff = true, -- send only changed lines to the browser
          click_navigate = true, -- relative link opens the file in nvim
          reverse_scroll = true, -- browser scroll moves the nvim cursor
        },
      })
    end,
  },
  {
    "StefanBartl/recommender.nvim",
    ft = { "lua" },
    cmd = { "Recommender" },
    dependencies = { "StefanBartl/lib.nvim" },
    opts = {
      -- `cwd`/`path` scope (the one `:Recommender perf cwd` over this whole
      -- config actually uses) runs the directory walk + file reads
      -- asynchronously since 2026-09-03; reports into the shared
      -- lib.nvim.progress registry, rendered by the statusline's
      -- "plugin_progress" module -- same convention as sandbox.nvim,
      -- documentation.nvim, replacer.nvim, insights.nvim, reposcope.nvim,
      -- github_stats.nvim, pdfport.nvim above.
      progress_style = "statusline",
    },
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
          -- lua/spell_wordlists.lua. Load unconditionally: a few hundred
          -- `:spellgood!` calls, scheduled off the hot path, is not worth
          -- gating behind machine.is("workstation").
          extra_wordlists = require("spell_wordlists"),
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
})

return plugins.export()
