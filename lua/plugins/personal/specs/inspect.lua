---@module 'plugins.personal.specs.inspect'
--- Personal plugin specs: Debug & inspect.
---
--- Debugging, diffing, LSP, runtime analysis, code review and rule checking.
---
--- Category names follow the plugin website's registry
--- (wkd/src/data/registry.json). Source control -- local vs. remote vs.
--- disabled -- is NOT decided here but in plugins.personal.core.source; this
--- file only declares the specs. Registered from plugins/personal/init.lua.

---@type LazyPluginSpec[]
return {
  -- Debugging is a mode you enter deliberately, so nothing here belongs in
  -- startup: `keys`/`cmd` (instead of `event`) defer the plugin and its
  -- dependencies to the first keypress. lazy.nvim installs stubs for both, so
  -- the mappings and `:Dap` work as usual -- the first use just also loads the
  -- plugin.
  --
  -- The keys below MUST mirror wkddap.bindings.keymaps. `dap_prefix` is
  -- shared with opts so the two cannot drift apart; the suffixes are the ones
  -- that module maps (see its `keymap.register` actions). A binding missing
  -- here would simply never load the plugin and silently do nothing.
  (function()
    -- "<leader>d" alone collides with existing git/fzf mappings (dc, di, do),
    -- so the DAP keys live under "<leader>da".
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
        -- ui.kit backs breakpoint/validation prompts.
        "StefanBartl/ui.nvim",
        "mfussenegger/nvim-dap",
        "rcarriga/nvim-dap-ui",
        "nvim-neotest/nvim-nio",
        "theHamsta/nvim-dap-virtual-text",
        "jbyuki/one-small-step-for-vimkind",
        "igorlfs/nvim-dap-view", -- default panel UI (dap.nvim ui.provider = "dap-view")
      },
      opts = {
        -- Languages to enable; empty = all available (lua, javascript, c, go,
        -- python, rust, zig, assembly, bash, csharp, browser). Aliases such as
        -- typescript/cpp/nasm resolve automatically.
        -- languages = {},

        ui = {
          -- Wire a panel UI at all.
          -- enable = true,
          -- dap.nvim wires exactly one panel UI: "dap-view" | "dap-ui" | "auto"
          -- (first installed) | "none". An uninstalled preference falls back to
          -- the other provider. Equals the default, set explicitly so the choice
          -- is visible here; use "dap-ui" to go back to nvim-dap-ui.
          -- Default: "dap-view".
          provider = "dap-view",
          -- Options passed straight to nvim-dap-view's setup(); nil = its own defaults.
          -- dap_view = nil, -- table
          -- Options passed straight to nvim-dap-ui's setup(); nil = dap.nvim's layout.
          -- dap_ui = nil, -- table
          -- nvim-dap-virtual-text: true = dap.nvim's defaults, a table is passed to
          -- its setup() as given, false = your own plugin spec owns it.
          -- virtual_text = true,
          -- Configure the gutter signs.
          -- signs = true,
          -- Configure the default highlight groups.
          -- highlights = true,
        },

        keymaps = {
          -- Install the default keymaps.
          -- enable = true,
          -- Shared with the `keys` list above so lazy-loading and the mappings
          -- cannot drift apart: "<leader>d" alone collides with git/fzf mappings.
          -- Default: "<leader>d".
          prefix = dap_prefix,
          -- Per-action overrides (an lhs, or `false` to drop one); every default
          -- is `dap_prefix` plus the suffix shown. Keep `keys` above in step when
          -- you move one.
          -- continue = dap_prefix .. "c",
          -- step_over = dap_prefix .. "s",
          -- step_into = dap_prefix .. "i",
          -- step_out = dap_prefix .. "o",
          -- terminate = dap_prefix .. "t",
          -- restart = dap_prefix .. "r",
          -- toggle_breakpoint = dap_prefix .. "b",
          -- conditional_breakpoint = dap_prefix .. "B",
          -- log_point = dap_prefix .. "L",
          -- list_breakpoints = dap_prefix .. "l",
          -- toggle_ui = dap_prefix .. "u",
          -- eval = dap_prefix .. "e", -- normal and visual mode
          -- repl = dap_prefix .. "R",
        },

        -- Register a which-key group label for the keymap prefix.
        -- which_key = { enable = true },

        -- Default autocommands (cursorline toggle while the DAP UI is open).
        -- autocmds = { enable = true },

        -- nvzone/menu context-menu entries for a host to compose (dap.nvim ships
        -- no trigger of its own).
        -- menu = { enable = true },

        -- Which hosts may drive this plugin; `ui_menu = false` keeps ui.nvim's
        -- right-click menu from composing the DAP fly-out.
        -- integrations = { ui_menu = true },

        -- Adapter overrides keyed by nvim-dap adapter name (codelldb, pwa-node,
        -- coreclr, ...), applied after the language modules registered theirs: a
        -- table is deep-merged over the built-in definition, a function replaces
        -- it, an unknown name adds a new adapter.
        -- adapters = {},

        -- Custom launch configurations keyed by language; appended to the
        -- defaults unless the list also has `replace = true`.
        -- configurations = {},

        -- Install missing required adapters via :MasonInstall (mason.nvim must
        -- be installed separately).
        -- auto_install = false,

        -- Level of nvim-dap's own log file: a vim.log.levels value or a name
        -- ("trace" .. "error").
        -- log_level = vim.log.levels.WARN,
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
    "StefanBartl/debugging.nvim",
    -- cmd = "Debug",
    event = "VeryLazy",
    dependencies = { "StefanBartl/lib.nvim" },
    opts = {
      -- Shorthand: enable every feature category at once (overrides `features`).
      -- all = nil, -- boolean

      -- Per-category switches for the :Debug subcommands; only neotree is off by
      -- default (it is config-specific).
      -- features = {
      --   views = true, -- :Debug messages / noice / windows
      --   reports = true, -- :Debug report buf|tab|win
      --   autocmds = true, -- :Debug autocmds runtime|sources
      --   tools = true, -- :Debug inspect|cursor|dump
      --   terminals = true, -- :Debug keylogger
      --   nvim_options = true, -- :Debug indent
      --   markdown = true, -- :Debug markdown
      --   neotree = false, -- :Debug neotree ... (config-specific, opt-in)
      --   neotest = true, -- :Debug neotest adapters|state|file|root|framework|discover
      --   module_reload = true, -- :Debug module reload
      --   proc_trace = true, -- :Debug proc start|stop|status|log|watch
      --   performance = true, -- :Debug performance startup
      -- },

      -- Terminals subsystem (:Debug keylogger).
      -- terminals = {
      --   keylogger = {
      --     -- File to append recorded keys to; nil = notify only. `~` and env
      --     -- vars are expanded; `:Debug keylogger start {path}` overrides it
      --     -- per session.
      --     logfile = nil, -- string
      --   },
      -- },

      -- Neo-tree safety bridge (only used with features.neotree). Each target is a
      -- module name to `require`, or an already-loaded table injected directly.
      -- neotree = {
      --   quarantine = "config.neotree.watcher_quarantine", -- string|table
      --   safety = "config.neotree.safety", -- string|table
      -- },

      -- neotest diagnostics (:Debug neotest ...); without neotest every action
      -- degrades to one notification.
      -- neotest = {
      --   output = "float", -- "float" (scratch float per report) | "notify" (one notification)
      --   -- Files worth reporting in a project root / the cwd. Replaces the list.
      --   markers = {
      --     "package.json",
      --     "vitest.config.ts",
      --     "vitest.config.js",
      --     "vitest.config.mjs",
      --     "vitest.workspace.ts",
      --     "jest.config.ts",
      --     "jest.config.js",
      --     "jest.config.mjs",
      --     "tsconfig.json",
      --     "go.mod",
      --     "Cargo.toml",
      --     "pyproject.toml",
      --     "pytest.ini",
      --     "setup.cfg",
      --     "TESTS/run.lua",
      --   },
      --   -- Dependency names `:Debug neotest framework` looks for in package.json. Replaces the list.
      --   package_frameworks = { "vitest", "jest", "mocha", "ava", "playwright", "cypress" },
      -- },

      -- Views subsystem (keymaps, auto-refresh autocmds, capture).
      -- views = {
      --   keymaps = {
      --     enable = true,
      --     prefix = "<lt>", -- default lhs prefix: "<lt>" is the literal `<` key
      --     -- Per-action overrides (an lhs, a list of them, or false to drop
      --     -- one); defaults are "<lt>" plus the suffix shown.
      --     -- messages = "<lt>m",
      --     -- noice_all = "<lt>n",
      --     -- noice_errors = "<lt>e",
      --     -- capture = "<lt>c", -- to file + clipboard
      --     -- capture_file = "<lt>f",
      --     -- capture_clipboard = "<lt>y",
      --     -- clear = "<lt>x",
      --   },
      --   autocmds = { enable = true, group_name = "DebugViewsAuto", auto_refresh = true },
      --   -- Waits around reading :messages / Noice output; capture_timeout_ms is
      --   -- how long to wait for the window a command opens to appear (too short
      --   -- on a slow machine reports "no output" for a view still rendering).
      --   timings = {
      --     delay_messages_ms = 30,
      --     delay_noice_ms = 50,
      --     retry_delay_ms = 60,
      --     attempts = 3,
      --     capture_timeout_ms = 500,
      --   },
      --   capture = true,
      --   output_dir = nil, -- string; only used with capture = true, nil = stdpath("config")/docs/debug_views
      --   -- The <lt>m/<lt>n/<lt>e popup: lib.nvim.messages + ui.kit.message_log
      --   -- (live, paginated) when ui.nvim is installed, a static
      --   -- lib.nvim.output.viewer dump otherwise.
      --   recent = {
      --     window_s = 10, -- seconds of history shown on open; <C-j> extends by the same amount
      --     order = "newest_last", -- or "newest_first"
      --     collapsed_default = false,
      --   },
      -- },

      -- Name of the single unified user command.
      -- command = "Debug",

      -- How `:Debug` with no arguments renders the category overview: "float"
      -- (scrollable window, q/<Esc> to close) | "notify" (one notification).
      -- overview = "float",
    },
  },

  {
    "StefanBartl/diff.nvim",
    cmd = { "Diff", "DiffClear", "DiffOrig", "DiffExit" },
    -- `<leader>gd` diffs the current file against HEAD (diff.nvim resolves
    -- `git:HEAD` itself). A lazy `keys` entry rather than diff.nvim's own
    -- `keymaps.diff_head` option, because the plugin is command-lazy and an
    -- option-registered shortcut would only exist after the first `:Diff`.
    keys = {
      {
        "<leader>gd",
        "<cmd>Diff target=git:HEAD<cr>",
        desc = "[diff.nvim] Diff current file against HEAD",
      },
    },
    opts = {
      -- Which commands/features get registered; all are on by default.
      -- features = {
      --   diff = true, -- :Diff / :DiffClear
      --   diff_origin = true, -- :DiffOrig
      --   diff_exit = true, -- :DiffExit + the exit keymap
      --   diff_history = true, -- :DiffHistory
      --   diffopt_profile = true, -- :DiffProfile
      --   gitsigns_peek = true, -- bind `gh` to gitsigns.nvim's hunk preview
      -- },

      -- diff = {
      --   default_view = "vsplit", -- "vsplit" | "split" | "tab" | "inline" | "float"
      --   default_output = "buffer", -- "buffer" | "prompt" | "file" | "clipboard" | "stat"
      --   default_source = "current", -- "current" | "clipboard" | "ask" | "git:<rev>" | "http(s)://..." | path | bufnr
      --   -- Split direction of :DiffOrig; separate from default_view because
      --   -- :DiffOrig is always a native diffmode split, never "inline".
      --   default_orig_view = "vsplit", -- "vsplit" | "split"
      --   -- Named profile applied to 'diffopt' once at setup(); nil leaves
      --   -- 'diffopt' alone. :DiffProfile works regardless.
      --   diffopt_profile = nil, -- "minimal" | "context" | "review" | "strict"
      --   algorithm = "histogram", -- vim.diff algorithm
      --   ctxlen = 3, -- context lines per hunk
      --   -- Word/char-level DiffText highlighting in view=inline/float.
      --   word_diff = true,
      --   -- Timeout for http(s):// sources/targets, in ms.
      --   url_timeout_ms = 10000,
      --   -- Byte cap for http(s):// sources/targets (curl --max-filesize), so a
      --   -- huge response is never read into memory.
      --   url_max_bytes = 10 * 1024 * 1024,
      --   -- Two raster-image paths are shown side by side via images.nvim
      --   -- instead of text-diffing raw bytes.
      --   image_compare = true,
      --   -- output=stat also pushes its hunks into the quickfix ("qf") or
      --   -- location ("loc") list; "off" keeps it notification-only.
      --   stat_list = "off", -- "off" | "qf" | "loc"
      --   -- "add" accumulates entries across invocations, "replace" resets the
      --   -- list to the latest diff's hunks.
      --   stat_list_mode = "add", -- "add" | "replace"
      --   -- Cap on files walked per side of a directory diff.
      --   directory_max_files = 2000,
      --   -- Cap on commits :DiffHistory lists (git log --max-count).
      --   history_max_entries = 200,
      -- },

      -- Optional shortcuts for common invocations (none bound by default). A
      -- shortcut whose command is switched off via `features` is refused. The
      -- command-lazy `keys` entry above binds the HEAD diff.
      -- keymaps = {
      --   diff = nil, -- :Diff (pick source and target)
      --   diff_head = nil, -- :Diff target=git:HEAD
      --   diff_merge = nil, -- :Diff base=git:HEAD target=git:MERGE_HEAD
      --   diff_buffers = nil, -- :DiffBuffers
      --   diff_orig = nil, -- :DiffOrig
      --   diff_history = nil, -- :DiffHistory
      --   diff_clear = nil, -- :DiffClear
      -- },

      -- exit = {
      --   -- Exit mapping: a string, or a list to bind several, e.g.
      --   -- { "<Esc><Esc>", "<C-c>" }.
      --   key = "<Esc><Esc>",
      --   -- "buffer" binds buffer-locally, "global" is a global normal-mode
      --   -- mapping, false binds nothing (:DiffExit only).
      --   scope = "buffer",
      --   -- Also mirror the key onto buffers a native :diffthis puts into
      --   -- diffmode (scope = "buffer" only).
      --   native_diffthis = false,
      -- },

      -- User command names.
      -- commands = {
      --   diff = "Diff",
      --   diff_clear = "DiffClear",
      --   diff_buffers = "DiffBuffers",
      --   diff_orig = "DiffOrig",
      --   diff_history = "DiffHistory",
      --   diff_exit = "DiffExit",
      --   diff_profile = "DiffProfile",
      -- },

      -- Replacement for vim.ui.select in the source/target picker.
      -- select_fn = nil, -- fun(items, opts, on_choice)
      -- Use pickers.nvim's fuzzy engine for that picker when select_fn is unset;
      -- false always uses the ui.kit chooser.
      -- use_pickers_nvim = true,
    },
  },

  {
    -- The whole LSP subsystem (see docs/ROADMAP/personal/lsp.nvim.md).
    --
    -- No `opts`/`config` on purpose. init.lua calls setup() inside
    -- startup.now("lsp", ...) because capabilities have to be applied globally
    -- before the first client attaches; a lazy opts-block would hand that
    -- ordering to the plugin manager. `lazy = false` only guarantees the
    -- module is on the runtimepath by then.
    --
    -- Currently set in init.lua (everything else runs on the plugin's defaults):
    --   mason.ensure_install = false (equals the default)
    --   code_actions.gitsigns = true
    --   implement.enable = true
    --   attach.workspace_diagnostics_projects = { ["$REPOS_DIR/WKDBook-Tricentis"] = false }
    --   completion.personal_names = { enable = true, labels = <reader for the plugin-name list> }
    -- The block below lists every option lsp.nvim knows, in the order of its
    -- DEFAULTS.lua. It is a comment only: change values in init.lua. Options
    -- set there show that value and say so.
    "StefanBartl/lsp.nvim",
    lazy = false,
    priority = 900,
    dependencies = { "StefanBartl/lib.nvim" },
    -- opts = {
    --   -- Option profile the rest starts from: "default" (the values below) |
    --   -- "lean" (continuous per-keystroke/per-attach work turned down) | "full"
    --   -- (every feature on). Anything named in setup() still wins over it. Not
    --   -- `keymaps.preset`; the profiles live in lua/lsp/config/PRESETS.lua.
    --   preset = "default",
    --
    --   -- Per-project override file, looked up once at setup() by walking upward
    --   -- from the working directory. JSON, and only an allowlist of keys.
    --   project = {
    --     enable = true,
    --     file = ".nvim-lsp.json",
    --   },
    --
    --   -- Which servers are set up and enabled (resolved to lsp.servers.<name>,
    --   -- with lsp.servers.webdev.<name> as fallback). Replaces the list, so give
    --   -- it in full; the commented entries are the known-but-off ones.
    --   servers = {
    --     "bashls",
    --     "lua_ls",
    --     "gopls",
    --     "marksman",
    --     -- "emmet_ls",
    --
    --     -- Web development
    --     "html",
    --     "ts_ls",
    --     "tailwindcss",
    --     -- "astro",
    --     -- "htmx",
    --     -- "wasm_language_tools",
    --
    --     -- "clangd",
    --     "csharp",
    --     -- "zig",
    --
    --     -- Mobile development
    --     -- "jdtls", -- Java (Android)
    --     -- "kotlin_language_server", -- Kotlin (Android)
    --     -- "dartls", -- Dart/Flutter
    --   },
    --
    --   -- Merged last into the single vim.diagnostic.config() call, so it always
    --   -- wins. Besides the two keys below, any vim.diagnostic.config() key
    --   -- (virtual_text, update_in_insert, ...) is passed on as given.
    --   diagnostics = {
    --     -- Where "]d"/"[d" send you: "auto" | "native" | "trouble" ("auto" and
    --     -- "trouble" behave the same at runtime).
    --     ui = "auto",
    --     -- Leading-edge throttle for textDocument/publishDiagnostics, in ms;
    --     -- 0 turns it off.
    --     debounce_ms = 150,
    --   },
    --
    --   -- Native inlay hints (0.10+). `filetypes` overrides per filetype: an
    --   -- absent key inherits `enable`, false is an explicit off.
    --   inlay_hints = {
    --     enable = false,
    --     filetypes = {}, -- table<string, boolean>
    --   },
    --
    --   -- Code-action indicator: a mark in the line when textDocument/codeAction
    --   -- has something to offer there.
    --   lightbulb = {
    --     enable = true,
    --     filetypes = {}, -- table<string, boolean>; same rule as inlay_hints
    --     -- CodeActionKind prefixes that light it; keeps it from being lit
    --     -- permanently. Add "refactor" for the noisy version, {} = unfiltered.
    --     kinds = { "quickfix", "source" },
    --     -- "sign" (sign column on the cursor line) | "virtual_text" (window edge).
    --     render = "sign",
    --     text = "󰌵",
    --     -- Wait after the last cursor movement before the request, in ms.
    --     debounce_ms = 150,
    --     -- Extmark priority, above vim.diagnostic's signs (10).
    --     priority = 20,
    --   },
    --
    --   -- LSP breadcrumb in the window bar: `folder > file > Class > method`.
    --   winbar = {
    --     enable = true,
    --     filetypes = {}, -- table<string, boolean>; same rule as inlay_hints
    --     show_file = true, -- draw the path in front of the symbols
    --     folder_level = 1, -- directories shown before the file name
    --     separator = " › ",
    --     chips = true, -- rounded coloured chips; false = one flat string
    --     align = "left", -- "left" | "right" | "center"
    --     -- Symbols allowed after the file, per filetype; false lifts a cap.
    --     -- Markdown is capped at one so headings do not read as a table of contents.
    --     max_symbols = { markdown = 1 }, -- table<string, integer|false>
    --     debounce_ms = 60, -- last cursor movement -> repaint
    --     refresh_ms = 300, -- last edit -> next documentSymbol request
    --   },
    --
    --   -- Peek: definition / type definition in a floating, editable window.
    --   peek = {
    --     -- Fractions of the editor when <= 1, cells above that.
    --     width = 0.7,
    --     height = 0.5,
    --     border = "rounded", -- string|string[]
    --     beacon = true, -- flash the target line after a peek is taken into a real window
    --     -- Buffer-local keys of the peeked buffer; false unbinds one.
    --     keys = {
    --       close = "q",
    --       edit = "<C-o>",
    --       vsplit = "<C-v>",
    --       split = "<C-x>",
    --       tabedit = "<C-t>",
    --     },
    --   },
    --
    --   -- Marks interfaces (or other kinds) that have implementations with a
    --   -- count at the end of the line. One request per marked symbol per edit
    --   -- pause; only pays in languages that have interfaces.
    --   implement = {
    --     -- Set in init.lua: true. Default: false.
    --     enable = true,
    --     filetypes = {}, -- table<string, boolean>; same rule as inlay_hints
    --     -- SymbolKind names that get a marker (a map, not a list).
    --     kinds = { Interface = true },
    --     text = " %d impl", -- `%d` is the number of implementations
    --     debounce_ms = 600, -- last edit -> requests
    --     max_requests = 20, -- cap on requests per round
    --   },
    --
    --   -- What `lsa` (and the diagnostic quick fix) opens.
    --   code_actions = {
    --     -- "auto" (fzf-lua when installed) | "fzf-lua" (with diff preview) | "native".
    --     picker = "auto",
    --     -- Set in init.lua: true -- Stage/Reset/Preview Hunk appear in the list
    --     -- when the cursor is on a hunk. Default: false (it runs an extra
    --     -- in-process language server, visible in `:Lsp servers`).
    --     gitsigns = true,
    --   },
    --
    --   -- What `lsf` puts in one list.
    --   finder = {
    --     references = true,
    --     implementations = true,
    --     definitions = true,
    --     declarations = false,
    --     typedefs = false,
    --   },
    --
    --   formatter = {
    --     -- Format on write at startup; the runtime toggle (`:LspFormatToggle`,
    --     -- `<leader>tft`) owns it afterwards.
    --     on_save = false,
    --     timeout_ms = 1500, -- upper bound for one format request
    --   },
    --
    --   -- Which directories `:Lsp root add` / `<leader>lsw` offer as workspace
    --   -- folders. Read only when that picker opens.
    --   workspace = {
    --     -- A directory holding one of these is a candidate. Replaces the list.
    --     markers = {
    --       ".git",
    --       "go.work",
    --       "go.mod",
    --       "package.json",
    --       "tsconfig.json",
    --       "deno.json",
    --       "Cargo.toml",
    --       "pyproject.toml",
    --       "setup.py",
    --       "pom.xml",
    --       "build.gradle",
    --       "CMakeLists.txt",
    --       "compile_commands.json",
    --       ".luarc.json",
    --       "composer.json",
    --       "Gemfile",
    --       "mix.exs",
    --       ".marksman.toml",
    --     },
    --     -- Directories that hold projects rather than being one; the sibling
    --     -- scan descends exactly one level through them. Replaces the list.
    --     containers = {
    --       "packages",
    --       "apps",
    --       "services",
    --       "libs",
    --       "crates",
    --       "modules",
    --       "plugins",
    --       "projects",
    --       "src",
    --       "cmd",
    --     },
    --   },
    --
    --   -- Bring a language server back when it dies mid-session (only clients
    --   -- that were attached and working; a crash during startup is not retried).
    --   auto_restart = {
    --     enable = true,
    --     max_attempts = 4, -- consecutive attempts before giving up
    --     initial_delay_ms = 1000, -- wait before the first attempt; doubles from there
    --     max_delay_ms = 30000, -- cap on that doubling
    --     reset_after_ms = 60000, -- how long a relaunched client must survive to clear the counter
    --   },
    --
    --   attach = {
    --     -- Populate workspace diagnostics on attach (the module's own max_files
    --     -- gate still applies); `:Lsp workspace` overrides it at runtime.
    --     use_workspace_diagnostics = true,
    --     -- Per-project override of the switch above, project folder -> boolean;
    --     -- `~` and `$VAR` expand, so one entry works on every machine. Off
    --     -- also holds back the pushes marksman sends for files you have not
    --     -- opened. Set in init.lua: off for the ~900-file WKDBook-Tricentis
    --     -- vault, where the scan only produced a warning; turn it on at runtime
    --     -- with `:Lsp workspace on WKDBook-Tricentis`. Default: {}.
    --     workspace_diagnostics_projects = {
    --       ["$REPOS_DIR/WKDBook-Tricentis"] = false,
    --     },
    --     use_lazydev = true, -- wire lazydev into lua_ls attaches
    --   },
    --
    --   mason = {
    --     -- Install missing packages on setup. Equals the default (off:
    --     -- installing software is a side effect the plugin does not perform
    --     -- unasked), set explicitly in init.lua.
    --     ensure_install = false,
    --     -- Per-category force-on/off, keyed lsp / dap / linters / formatters.
    --     overrides = {
    --       lsp = {
    --         ["java-language-server"] = false,
    --         ["csharp-language-server"] = false,
    --       },
    --       dap = {
    --         ["node-debug2-adapter"] = false,
    --       },
    --       linters = {
    --         eslint_d = true,
    --       },
    --       formatters = {
    --         prettier = true,
    --       },
    --     },
    --   },
    --
    --   -- Options forwarded to lsp.lspdoctor.setup() (:LspDoctor).
    --   lspdoctor = {
    --     use_notify = false,
    --     list_limit = 8,
    --     -- Order in which the report ranks the clients that could format this
    --     -- buffer. Report only: what actually formats is conform's chain.
    --     formatter_priority = { "null-ls", "eslint", "lua_ls" },
    --     semantic_tokens_timeout = 300,
    --     -- How long `:LspDoctor probe` waits for a deliberately broken buffer to
    --     -- come back diagnosed, in ms.
    --     probe_timeout = 5000,
    --     scratch_filetype = "markdown",
    --     auto_open_scratch = true,
    --     scratch_threshold = 20,
    --   },
    --
    --   -- Extra tools, each with its own switch.
    --   tools = {
    --     eslint_prettier = {
    --       enable = true,
    --       filetypes = { "javascript", "typescript", "javascriptreact", "typescriptreact" },
    --     },
    --     lsp_signature = { enable = true },
    --     ts_type_lookup = { enable = true },
    --     deprecated_help = { enable = true },
    --   },
    --
    --   -- Filetype-specific quality-of-life setup under lsp/languages/**.
    --   languages = {
    --     enable = true,
    --     -- Resolve `$VAR/...` and `~/...` Markdown link targets (definition and
    --     -- hover) and drop marksman's false "non-existent document" diagnostic.
    --     env_links = true,
    --   },
    --
    --   -- Hand-written completion sources, read at setup time whichever
    --   -- completion engine is active.
    --   completion = {
    --     personal_names = {
    --       -- Set in init.lua (equals the default).
    --       enable = true,
    --       -- Reader for the plugin-name list; init.lua hands over this
    --       -- config's own data so it does not depend on the completion
    --       -- engine's spec. Default: nil (falls back to extra.lua alone).
    --       labels = personal_name_labels, -- fun(): (string|{ name: string })[]
    --     },
    --   },
    --
    --   rename = {
    --     -- "auto" (inc-rename when installed) | "inc_rename" | "native"
    --     -- (vim.lsp.buf.rename); both the `grn` and `<leader>rn` keys use it.
    --     provider = "auto",
    --   },
    --
    --   keymaps = {
    --     enable = true,
    --     preset = "default", -- "default" | "minimal" | "none" (catalogue: lua/lsp/config/KEYMAPS.lua)
    --     -- Per-action override: an lhs, or false to drop one. Actions and their
    --     -- default lhs (mode n unless noted):
    --     --   goto_definition lsd, goto_declaration lsD, goto_type_definition lst,
    --     --   goto_type_definition_gr grt, goto_references lsr,
    --     --   goto_implementations lsi, document_symbols lss, code_action lsa,
    --     --   code_action_range gra (x), peek_definition lsp, peek_type_definition lsT,
    --     --   signature_help <M-s> (i), rename grn, rename_leader <leader>rn,
    --     --   format_toggle <leader>tft, format_buffer <leader>ft,
    --     --   format_lsp <leader>fl, hints_toggle <leader>th,
    --     --   hints_toggle_filetype <leader>tH, lightbulb_toggle <leader>tb,
    --     --   lightbulb_toggle_filetype <leader>tB, winbar_toggle <leader>tW,
    --     --   diag_to_qflist <leader>wq, diag_to_loclist <leader>lq,
    --     --   diag_setqflist <leader>tq, diag_next ]d (n/x/o), diag_prev [d (n/x/o),
    --     --   diag_code_action <leader>xa, qf_next ]q, qf_prev [q, loc_next ]l,
    --     --   loc_prev [l, trouble_toggle <leader>xt, trouble_all <leader>xx,
    --     --   trouble_workspace <leader>xw, trouble_buffer <leader>xd,
    --     --   trouble_references <leader>xlr, trouble_definitions <leader>xld,
    --     --   trouble_type_definitions <leader>xlt, trouble_implementations <leader>xli,
    --     --   trouble_symbols <leader>xls, trouble_outline <leader>xo,
    --     --   trouble_loclist <leader>xl, trouble_qflist <leader>xq,
    --     --   trouble_diag_next ]w, trouble_diag_prev [w,
    --     --   picker_document_symbols <leader>dos, picker_workspace_symbols <leader>wos,
    --     --   picker_document_diagnostics <leader>do, picker_workspace_diagnostics <leader>wo,
    --     --   picker_incoming_calls lsc, picker_outgoing_calls lsC, picker_finder lsf,
    --     --   picker_type_super lsh, picker_type_sub lsH, root_scope_pick <leader>lsp,
    --     --   workspace_folder_add <leader>lsw, marksman_hints <leader>lb
    --     map = {}, -- table<string, string|false>, e.g. { goto_definition = "gd", rename = false }
    --   },
    --
    --   usrcmds = {
    --     enable = true, -- register the `:Lsp` verb
    --     -- Keep the ~25 flat :Lsp*/:Diag* commands as aliases onto the :Lsp routes.
    --     legacy_aliases = true,
    --   },
    --
    --   -- Label the bound key prefixes as which-key groups.
    --   which_key = { enable = true },
    --
    --   -- nvzone/menu entries (soft dependency; off automatically when missing).
    --   menu = { enable = true },
    --
    --   -- Which hosts may drive this plugin; `ui_menu = false` keeps ui.nvim's
    --   -- right-click menu from composing the LSP fly-outs.
    --   integrations = { ui_menu = true },
    -- },
  },

  {
    "StefanBartl/insights.nvim",
    -- Not `cmd = "Insights"`: the conflicts / unimported / devserver
    -- autocmds are registered by setup(), so lazy-loading on the command would
    -- mean they never fire. Set their `enable = false` to opt out instead.
    lazy = false,
    -- ui.nvim: devserver.prompt (default true) has no fallback if ui.kit is
    -- missing -- see insights.nvim's docs/installation.md.
    dependencies = { "StefanBartl/lib.nvim", "StefanBartl/ui.nvim" },
    opts = {
      -- Symbol index (ripgrep + optional Tree-sitter): the `<leader>ps` /
      -- `<leader>pS` pickers and the symbols commands.
      symbols = {
        -- enable = true,
        -- Symbol scope: "cwd" | "buffer".
        -- default_scope = "cwd",
        -- Languages to index with ripgrep; false skips one.
        -- languages = {
        --   lua = true,
        --   python = true,
        --   javascript = true,
        --   typescript = true,
        --   go = true,
        --   rust = true,
        --   c = true,
        --   cpp = true,
        --   java = true,
        --   ruby = true,
        --   php = true,
        -- },
        -- Tree-sitter for Lua (more precise names); ripgrep for every other language.
        -- use_treesitter_for_lua = false,
        -- indexing = {
        --   -- Replaces the list, so give it in full.
        --   exclude_patterns = { ".git/", "node_modules/", ".cache/", "build/", "dist/", "target/" },
        --   max_file_size_kb = 1024,
        --   follow_symlinks = false,
        --   -- Ceiling for one rg invocation, in ms; only a guard against a wedged
        --   -- process.
        --   timeout_ms = 120000,
        -- },
        -- cache = {
        --   enabled = true,
        --   dir = vim.fn.stdpath("cache") .. "/insights/symbols",
        --   ttl_seconds = 3600, -- 0 = never expire
        -- },
        -- Building the cwd symbol index runs one rg pass per language pattern.
        -- "statusline" reports it into the shared lib.nvim.progress registry
        -- (read by the statusline) instead of the default "auto" (fidget.nvim if
        -- installed, else vim.notify).
        -- Values: "auto" | "notify" | "statusline" | "fidget" | "float" | "kit".
        -- Default: "auto".
        progress_style = "statusline",
      },

      -- Lua code metrics + documentation-file analysis (:Insights metrics).
      -- metrics = {
      --   enable = true,
      --   -- Ending it in .pdf writes a PDF via pdfport.nvim instead of plain text.
      --   output_file = vim.fn.stdpath("state") .. "/insights/metrics.md",
      --   analyze_lua = true, -- analyze Lua source files
      --   analyze_misc = true, -- analyze Markdown / TXT / JSON files
      --   show_file_tables = true, -- detailed per-file table (L1-L5 / W1-W5)
      --   show_folder_tables = true, -- per-folder aggregate table
      --   show_total_summary = true, -- grand-total row
      --   show_ratios = true, -- folder ratio analysis
      --   show_deviations = true, -- deviations from the global averages
      --   show_top_lists = true, -- top-N files by lines/words
      --   show_misc_detailed = true, -- per-file listing for misc files (vs. summary only)
      --   percent_mode = "both", -- "both" | "percent" | "numbers"
      --   reverse_order = true, -- summary first (vs. files first)
      --   top_n = 50, -- items in top-N lists
      --   col_width = 7, -- data column width in tables
      --   exclude_type_files = true, -- exclude @types files from ratio analysis
      -- },

      -- File tree (:Insights tree).
      -- tree = {
      --   enable = true,
      --   exclude_patterns = { "*/.git/*", "*/node_modules/*", "*/.cache/*" },
      --   outdir = vim.fn.stdpath("state") .. "/insights/tree",
      --   outfile_fmt = "%s-tree.txt", -- %s = project name
      -- },

      -- Buffer file info float.
      -- fileinfo = {
      --   enable = true,
      --   keymap = "<leader>fi", -- false disables the key
      -- },

      keymaps = {
        -- Either a plain lhs (cwd + functions) or a table that also picks what
        -- the mapping asks for; false unbinds. The UI is fixed by which key it is.
        -- symbols_telescope = "<leader>ps",
        -- symbols_telescope = {
        --   lhs = "<leader>ps",
        --   scope = "cwd", -- "cwd" | "buffer"
        --   type = "functions", -- "functions" | "tables" | "strings"
        --   rebuild = false, -- force a cache rebuild first ("functions" only)
        -- },
        -- symbols_fzf = "<leader>pS",
        -- Annotation comments (:Insights todos): the picker on the lowercase
        -- key, the quickfix list on the uppercase one. Unbound by default
        -- (false = declared, not bound); bound here so both reports are one key away.
        -- Default: false.
        todos = "<leader>sT",
        todos_qf = "<leader>ST",
      },

      -- Buffer-local keymaps on scratch reports and the fileinfo float.
      -- ui = {
      --   close_keys = { "q", "<Esc>" }, -- {} registers no close keymap
      --   follow_key = "gf", -- follow path:line in a scratch buffer
      -- },

      -- Project compression (:Insights compress).
      -- compress = {
      --   enable = true,
      --   engine = "auto", -- "auto" (tar on Unix, powershell on Windows) | "tar" | "zip" | "powershell"
      --   outdir = "", -- "" = compressed/ next to the source directory
      -- },

      -- import/require analysis (:Insights imports).
      -- imports = {
      --   enable = true,
      --   -- Indicator for the file-reading parts (async cwd scan, `unused`'s
      --   -- re-read pass); same values as symbols.progress_style.
      --   progress_style = "auto",
      --   -- Lua backend only (other languages always regex-scan): "auto"
      --   -- (Tree-sitter when the Lua parser is available, else rg) |
      --   -- "treesitter" | "ripgrep".
      --   engine = "auto",
      --   output_file = vim.fn.stdpath("state") .. "/insights/imports.md",
      --   -- Languages scanned; false skips one. A bare language id as filter
      --   -- argument scopes one run.
      --   languages = {
      --     lua = true,
      --     python = true,
      --     javascript = true,
      --     go = true,
      --     rust = true,
      --     c = true,
      --   },
      --   -- Named groups expand to module prefixes when used as a filter.
      --   groups = {
      --     lib = { "lib", "lib.nvim", "lib.usrcmds" },
      --   },
      --   classify_external = true, -- tag modules without a local .lua file as (extern)
      --   -- "Go to definition" from the imports report.
      --   definition = {
      --     view = "edit", -- "edit" (jump in the current window) | "float" (preview)
      --     border = "rounded", -- float border
      --     keymaps = {
      --       jump = "gd", -- reveal the definition (uses `view`); false disables
      --       preview = "gp", -- always reveal in a floating preview; false disables
      --     },
      --   },
      --   -- :Insights imports graph: Graphviz graph (needs `dot` on PATH), shown
      --   -- inline via images.nvim when installed.
      --   graph = {
      --     include_external = false, -- external modules add nodes without structure
      --     outdir = vim.fn.stdpath("cache") .. "/insights/graph",
      --     layout = "dot", -- dot | neato | fdp | sfdp | twopi | circo
      --   },
      -- },

      -- Quickfix list of files holding unresolved merge conflicts.
      -- conflicts = {
      --   enable = true, -- false = no autocmd, no :Insights conflicts
      --   events = { "VimEnter" }, -- when to scan; {} = only :Insights conflicts
      --   git_cmd = "git",
      --   diff_filter = "U", -- git status code to match; U = unmerged
      --   open_qf = true, -- :copen after populating the list
      --   notify = true, -- notify with the conflicting file names
      -- },

      -- Annotation comments (TODO, FIX, AUDIT, ...): the `:Insights todos`
      -- report and the in-buffer highlight. The keyword table and colour
      -- categories ship in insights' todos/keywords.lua; both are open tables
      -- merged per entry (`FOO = { color = "info" }` adds one, `FOO = false`
      -- drops one), so a host states only the difference.
      -- todos = {
      --   enable = true,
      --   -- Shipped keyword table, merged per entry; `alt` lists the aliases of a keyword.
      --   keywords = {
      --     FIX = { icon = " ", color = "error", alt = { "FIXME", "BUG", "FIXIT", "ISSUE" } },
      --     INFO = { icon = " ", color = "info" },
      --     DEBUG = { icon = " ", color = "hint" },
      --     TODO = { icon = " ", color = "info" },
      --     ROADMAP = { icon = " ", color = "info" },
      --     AUDIT = {
      --       icon = " ",
      --       color = "audit",
      --       alt = { "VERIFY", "REVIEW", "DOUBLECHECK", "QC", "CHECK", "CHECKIT", "RECHECK", "VALIDATE" },
      --     },
      --     HACK = { icon = " ", color = "warning" },
      --     WARN = { icon = " ", color = "warning", alt = { "WARNING", "XXX" } },
      --     PERF = { icon = " ", alt = { "OPTIM", "PERFORMANCE", "OPTIMIZE" } },
      --     NOTE = { icon = " ", color = "hint" },
      --     TEST = { icon = "⏲ ", color = "test", alt = { "TESTING", "PASSED", "FAILED" } },
      --     EXP = { icon = "🔬", color = "test", alt = { "EXPERIMENT", "EXPERIMENTAL" } },
      --     REF = {
      --       icon = "󰁨 ",
      --       color = "hint",
      --       alt = { "REFACTOR", "REWRITE", "CLEANUP", "IMPROVE", "RESTRUCTURE" },
      --     },
      --     ADD = { icon = " ", color = "info", alt = { "EXT", "NEXT", "FUTURE", "ENHANCE", "HOOK" } },
      --     FEAT = { icon = " ", color = "info", alt = { "FEATURE" } },
      --     WATCH = {
      --       icon = " ",
      --       color = "warning",
      --       alt = { "MONITOR", "OBSERVE", "TRACK", "INSPECT", "SURVEILLANCE" },
      --     },
      --     REMOVE = { icon = " ", color = "warning", alt = { "DELETE", "DEL", "UNUSED" } },
      --     DEVONLY = { icon = "", color = "hint", alt = { "TEMP", "DEV", "WIP" } },
      --   },
      --   -- Colour candidates per category, best first: a highlight group (its
      --   -- foreground is used if the theme defines one) or a `#rrggbb` literal.
      --   colors = {
      --     error = { "DiagnosticError", "ErrorMsg", "#f7768e" },
      --     warning = { "DiagnosticWarn", "WarningMsg", "#ff9e64" },
      --     info = { "DiagnosticInfo", "#7aa2f7" },
      --     hint = { "DiagnosticHint", "#1abc9c" },
      --     default = { "Identifier", "#bb9af7" },
      --     test = { "Identifier", "#9ece6a" },
      --     audit = { "DiagnosticHint", "Type", "#00BFA5" },
      --   },
      --   search = {
      --     -- "auto" (snacks, then telescope, fzf-lua, quickfix list) | "snacks" |
      --     -- "telescope" | "fzf" | "qf" | "scratch".
      --     ui = "auto",
      --     -- PCRE2; KEYWORDS becomes the alternation of every known word. No
      --     -- colon: half the annotations in the wild have none.
      --     pattern = "\\b(KEYWORDS)\\b",
      --     extensions = {}, -- {} = every file rg would search; { "lua", "md" } narrows it
      --     exclude_patterns = { ".git/", "node_modules/", ".cache/", "build/", "dist/", "target/" },
      --     max_file_size_kb = 1024,
      --     follow_symlinks = false,
      --     open_qf = true, -- :copen when the report goes to the quickfix list
      --   },
      --   highlight = {
      --     enable = true,
      --     comments_only = true, -- only a keyword inside a comment is coloured
      --     signs = true, -- the keyword's icon in the sign column
      --     debounce_ms = 150, -- after a change; a scroll re-scans immediately
      --     max_file_size_kb = 512, -- larger files are left alone
      --     exclude_filetypes = { "help", "qf", "TelescopePrompt", "snacks_picker_input" },
      --   },
      -- },

      -- Warn about component tags (<Foo ...>) that are used but never imported.
      -- unimported = {
      --   enable = true,
      --   events = { "BufWritePost" },
      --   filetypes = { "astro", "javascriptreact", "typescriptreact", "vue", "svelte" },
      --   ignore = {}, -- component names to never report (e.g. globals)
      -- },

      -- Notice dev servers started in a Neovim terminal and offer to kill them on
      -- exit (only terminals this Neovim owns).
      -- devserver = {
      --   enable = true, -- false = never watch terminals
      --   prompt = true, -- ask via ui.nvim's ui.kit; false applies kill_on_exit silently
      --   kill_on_exit = true, -- the answer used when prompt = false
      --   patterns = { -- plain substrings, matched case-insensitively
      --     "astro dev",
      --     "npm run dev",
      --     "pnpm dev",
      --     "yarn dev",
      --     "bun dev",
      --     "vite",
      --     "next dev",
      --     "nuxt dev",
      --     "ng serve",
      --     "rails server",
      --   },
      -- },

      -- false registers no user commands at all.
      -- commands = true,

      -- One-time popup listing the CLI tools this plugin wants (lib.nvim.deps),
      -- shown on the first setup() after install.
      -- deps_popup = true,

      -- Tell hover.nvim who imports the module under the cursor (soft: a no-op
      -- without hover.nvim); false registers nothing.
      -- hover = true,
    },
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
      -- Where the response pane opens relative to the request buffer; any Ex
      -- split command ("split" for a horizontal one).
      -- opts.split = "vsplit"
      -- Filetype set on a new `:RARequest` buffer; "http" so VS Code's REST
      -- Client / IntelliJ's HTTP Client highlighting works unmodified.
      -- opts.request_filetype = "http"
      -- One-time popup listing the CLI tools this plugin wants (lib.nvim.deps),
      -- shown on the first setup() after install.
      -- opts.deps_popup = true
      -- How many past requests `:RA history` keeps (a ring, per project).
      -- opts.history_max_entries = 200

      -- Auto-instrumentation has no default: the absent key means "do not
      -- instrument". Here it is built from this config's policy (see
      -- lua/config/telemetry.lua) and has this shape:
      --   opts.telemetry = {
      --     -- Keyed by repo ("StefanBartl/markdown.nvim"), for plugins lazy.nvim resolves.
      --     plugins = {
      --       ["StefanBartl/<name>.nvim"] = {
      --         namespace = "<name>.nvim", -- string
      --         deep = true, -- wrap the whole loaded subtree, not just the facade
      --         profile_args = true, -- record argument fingerprints
      --         timing = true, -- record durations
      --         -- persist = true, -- forwarded to new()
      --         -- dir = nil, -- string; cache directory override
      --       },
      --     },
      --     -- lib.nvim's own aggregate, or false to skip it.
      --     lib_nvim = { profile_args = true, timing = true }, -- also persist?, dir?
      --     -- Targets no plugin manager resolves, chiefly this config's own Lua tree.
      --     extra = {
      --       {
      --         namespace = "nvim-config", -- string
      --         mains = { "config", "bindings", "plugins" }, -- root Lua prefixes
      --         profile_args = true,
      --         timing = true,
      --         -- deep = true, -- default true: a config has no facade to wrap instead
      --         -- persist = true,
      --         -- dir = nil, -- string
      --         -- wrap_at = "VimEnter", -- "VimEnter" | "setup" | "manual"
      --       },
      --     },
      --   }
      opts.telemetry = require("config.telemetry").build()
      return opts
    end,
  },

  {
    "StefanBartl/recommender.nvim",
    ft = { "lua" },
    cmd = { "Recommender" },
    -- ui.nvim: bindings/usrcmds.lua requires ui.kit at module load (the
    -- suggestion float's picker) -- setup() fails without it, no fallback.
    -- Already loaded lazy=false above, listed here for documentation.
    dependencies = { "StefanBartl/lib.nvim", "StefanBartl/ui.nvim" },
    opts = {
      -- Analyzer backend: "regex" | "treesitter" | "javascript" | "python" | "perf".
      -- analyzer = "regex",
      -- Minimum occurrences before a chain is suggested.
      -- threshold = 3,
      -- Chain -> preferred alias name; merged over the built-in map, so list
      -- only your own additions/overrides. Built-ins:
      -- custom_aliases = {
      --   ["vim.api"] = "api",
      --   ["vim.fn"] = "fn",
      --   ["vim.keymap.set"] = "km_set",
      --   ["vim.opt"] = "opt",
      --   ["vim.cmd"] = "cmd",
      --   ["vim.lsp"] = "lsp",
      --   ["vim.schedule"] = "schedule",
      --   ["vim.defer_fn"] = "defer_fn",
      --   ["vim.notify"] = "notify",
      --   ["vim.log.levels"] = "levels",
      --   ["vim.uv"] = "uv",
      --   ["vim.loop"] = "loop",
      --   ["table.insert"] = "tbl_insert",
      --   ["table.concat"] = "tbl_concat",
      --   ["table.remove"] = "tbl_remove",
      --   ["string.format"] = "str_fmt",
      --   ["string.match"] = "str_match",
      --   ["math.floor"] = "floor",
      --   ["math.ceil"] = "ceil",
      --   ["math.max"] = "max",
      --   ["math.min"] = "min",
      --   ["os.date"] = "os_date",
      --   ["os.execute"] = "os_execute",
      -- },
      -- Chains never suggested; prefix match ("vim.api" also blocks
      -- "vim.api.nvim_buf_get_lines"). Empty by default.
      -- blacklist = {},
      -- Global keymaps: true = defaults, false = none, or a table of per-action
      -- overrides (an lhs, a list of them, or false to drop one).
      -- keymaps = true,
      -- keymaps = {
      --   run = "<leader>lr",
      --   replace = "<leader>lR",
      --   regex = "<leader>lrr",
      --   treesitter = "<leader>lrt",
      --   javascript = "<leader>lrj",
      --   python = "<leader>lrp",
      --   high_threshold = "<leader>lrh",
      --   cwd = "<leader>lrc",
      -- },
      -- Directory names skipped (at any depth) by `cwd`/`path` scope scans.
      -- Replaces the list, so give it in full.
      -- cwd_ignore = { ".git", "node_modules", ".venv", "venv", "__pycache__", "dist", "build", ".next", "target", ".tox" },
      -- Cap on files a `cwd`/`path` scan reads; 0 = unbounded.
      -- cwd_max_files = 500,
      -- Indicator while a `cwd`/`path` scope scan reads files asynchronously (a
      -- single buffer/file never shows one). "statusline" reports into the
      -- shared lib.nvim.progress registry, rendered by the statusline's
      -- "plugin_progress" module, instead of the default "auto" (notify, or
      -- fidget.nvim if installed).
      -- Values: "auto" | "notify" | "statusline" | "fidget" | "float" | "kit".
      -- Default: "auto".
      progress_style = "statusline",
      -- Suggestion float layout: "detailed" (chain / alias / blank, 3 lines each)
      -- | "compact" (one line per suggestion).
      -- float_layout = "detailed",
      -- Keys inside the suggestion float: true = defaults, false = none, or a
      -- table of per-action overrides. Navigation, <CR> and q/<Esc> belong to
      -- lib.nvim's chooser.
      -- float_keymaps = true,
      -- float_keymaps = {
      --   yank = "y",
      --   insert_all = "A",
      --   ignore = "<BS>",
      --   unignore = "U",
      --   help = "?",
      -- },
    },
  },

  {
    "StefanBartl/spotlight.nvim",
    -- ui.nvim: the spotlight list itself is built on ui.kit.select with no
    -- fallback -- see spotlight.nvim's docs/installation.md.
    dependencies = { "StefanBartl/lib.nvim", "StefanBartl/ui.nvim" },
    event = "VeryLazy",
    opts = {
      -- Register a hover.nvim position preview, so resting the cursor on a
      -- spotlighted token says how often it occurs in this buffer. A no-op
      -- without hover.nvim installed.
      -- hover = true,

      -- Colors. Eight slots, each with an explicit bg AND fg so a theme switch
      -- cannot produce "yellow on yellow"; ordered so consecutive round-robin
      -- slots are maximally distinguishable. Each list replaces the default.
      -- palette = {
      --   -- Used when &background == "dark".
      --   colors = {
      --     { bg = "#ffd75f", fg = "#1c1c1c" }, -- 1 yellow
      --     { bg = "#87d7ff", fg = "#1c1c1c" }, -- 2 cyan
      --     { bg = "#ff87d7", fg = "#1c1c1c" }, -- 3 pink
      --     { bg = "#a8e22e", fg = "#1c1c1c" }, -- 4 green
      --     { bg = "#ffaf5f", fg = "#1c1c1c" }, -- 5 orange
      --     { bg = "#b48eff", fg = "#ffffff" }, -- 6 purple
      --     { bg = "#5fd7af", fg = "#1c1c1c" }, -- 7 teal
      --     { bg = "#ff5f5f", fg = "#ffffff" }, -- 8 red
      --   },
      --   -- Used when &background == "light".
      --   colors_light = {
      --     { bg = "#b58900", fg = "#ffffff" }, -- 1 yellow
      --     { bg = "#268bd2", fg = "#ffffff" }, -- 2 cyan
      --     { bg = "#d33682", fg = "#ffffff" }, -- 3 pink
      --     { bg = "#587a00", fg = "#ffffff" }, -- 4 green
      --     { bg = "#cb4b16", fg = "#ffffff" }, -- 5 orange
      --     { bg = "#6c4bb6", fg = "#ffffff" }, -- 6 purple
      --     { bg = "#2aa198", fg = "#ffffff" }, -- 7 teal
      --     { bg = "#dc322f", fg = "#ffffff" }, -- 8 red
      --   },
      --   bold = true, -- render matches bold
      --   reapply_on_colorscheme = true, -- redefine the groups after :colorscheme
      -- },

      -- Matching.
      -- match = {
      --   -- matchadd() priority; 10 renders above 'hlsearch' (priority 0) on
      --   -- purpose. Lower it below 0 to let an active search win.
      --   priority = 10,
      --   -- false pins `\C` into the pattern so the result does not change with
      --   -- 'ignorecase'/'smartcase' (logs are case-sensitive data).
      --   ignore_case = false,
      --   word_boundaries = true, -- wrap word-kind tokens in `\<` / `\>`
      --   -- Guard on how many spotlights exist at once (cost is per visible
      --   -- line); well above the palette size of eight.
      --   max = 64,
      --   -- Longest token accepted, in bytes; bounds the pattern handed to
      --   -- matchadd() (minified one-line files, restored snapshots).
      --   max_text_len = 512,
      -- },

      -- Token under the cursor.
      -- cursor = {
      --   -- Lua patterns, highest priority first; the first one whose match spans
      --   -- the cursor column wins, `<cword>` is only the fallback. Replaces the list.
      --   patterns = {
      --     "%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x", -- UUID
      --     "%d%d%d%d%-%d%d%-%d%d[T ]%d%d:%d%d:%d%d[%.%d]*[Zz%+%-:%d]*", -- ISO 8601 timestamp
      --     "%d%d:%d%d:%d%d[%.%d]*", -- bare clock time
      --     "%d+%.%d+%.%d+%.%d+:%d+", -- IPv4 + port
      --     "%d+%.%d+%.%d+%.%d+", -- IPv4
      --     "0[xX]%x+", -- hex literal / address
      --     "%x%x%x%x%x%x%x%x%x%x%x%x%x*", -- long bare hex blob (git sha, trace id)
      --     "[%w_%-%.]+@[%w_%-%.]+", -- email / user@host
      --     "[%w_]+%.[%w_%.]+", -- dotted identifier (a.b.c, package paths)
      --     "%-?%d+%.?%d*", -- number (int/float, signed)
      --     "[%w_%-]+", -- generic token incl. dashes (broader than <cword>)
      --   },
      --   fallback_cword = true, -- fall back to <cword> when no pattern matches
      --   -- Above this line length the pattern scan is skipped and <cword> is used
      --   -- (a backtracking pattern on a huge single line could hang the editor).
      --   max_line_len = 8192,
      -- },

      -- Navigation (`]k` / `[k`).
      -- nav = {
      --   scope = "auto", -- "auto" (spotlight under the cursor, else all) | "all"
      --   wrap = true, -- wrap around the end of the buffer
      --   center = true, -- `zz` after jumping
      -- },

      -- The spotlight list.
      -- list = {
      --   count = true, -- match counts, computed when the list opens
      --   -- Skip counting above this buffer line count (the list shows "?").
      --   count_max_lines = 200000,
      --   -- "buffer" counts only the buffer the list was opened from; "loaded"
      --   -- sums over every loaded buffer (more work).
      --   count_scope = "buffer",
      --   swatch = "  ", -- text painted in the spotlight's colors as the row's chip
      -- },

      -- Occurrence density in the sign column.
      -- map = {
      --   -- Painted in the spotlight's own group; at most 2 display cells.
      --   sign_text = "▪",
      --   max_entries = 10000, -- stop after this many marks
      -- },

      -- Quickfix list of matching lines.
      -- quickfix = {
      --   open = true, -- :copen after filling the list
      --   title = "Spotlight",
      --   max_entries = 10000, -- truncate (and say so) after this many matching lines
      -- },

      -- Persistence of spotlights per file.
      -- persist = {
      --   enable = true,
      --   -- Per-file default; false makes it opt-in (`:Spotlight persist on`).
      --   default = true,
      --   debounce_ms = 500, -- coalescing window for the save
      -- },

      -- Keymaps. Each is an lhs or false to unbind. Lowercase `sk` marks only the
      -- occurrence under the cursor/selection, uppercase `sK` every occurrence;
      -- none is a prefix of another, so there is no 'timeoutlen' pause.
      -- keymaps = {
      --   preset = true, -- bind the default keys
      --   toggle_here = "<leader>sk",
      --   toggle = "<leader>sK",
      --   list = "<leader>sL",
      --   clear = "<leader>sC",
      --   quickfix = "<leader>sq",
      --   line = "<leader>sW", -- whole-line rendering for the cursor token's spotlight
      --   next = "]k",
      --   prev = "[k",
      -- },

      -- nvzone/menu context-menu entries (soft dependency).
      -- menu = { enable = true },

      -- Which hosts may drive this plugin; `ui_menu = false` keeps ui.nvim's
      -- right-click menu from composing the Spotlight fly-out.
      -- integrations = { ui_menu = true },

      -- Report added/removed/cleared spotlights via lib.nvim.notify.
      -- notify = true,

      -- Structured debug logging at the decision points (why nothing lit up),
      -- via lib.nvim.logger (`:LibLogger`).
      -- debug = false,
    },
  },

  {
    -- Eager on purpose: setup() starts the CmdlineLeave tracker that records
    -- every `:` command -- that recording *is* the plugin. Loading on `:Cmdlog`
    -- would start the tracker at the moment you first ask for the history, so
    -- the history would always be empty. Opt out with `track_commands = false`.
    "StefanBartl/cmdlog.nvim",
    lazy = false,
    opts = {
      -- Picker engine: "telescope" | "fzf" | "fzf-lua".
      -- picker = "telescope",
      -- JSON file holding the favorites.
      -- favorites_path = vim.fn.stdpath("data") .. "/cmdlog/favorites.json",
      -- Shell history file to fold in: "default" (the shell's own file) or a path.
      -- shell_history_path = "default",

      -- State files of the tag / project-history / stats / error-tracking
      -- features, created on first write.
      -- favorite_tags_path = vim.fn.stdpath("data") .. "/cmdlog/favorite_tags.json",
      -- project_history_path = vim.fn.stdpath("data") .. "/cmdlog/project_history.json",
      -- stats_path = vim.fn.stdpath("data") .. "/cmdlog/stats.json",
      -- errors_path = vim.fn.stdpath("data") .. "/cmdlog/errors.json",

      -- Record every ':' command (feeds project history, usage stats and error
      -- tracking); false disables all three at the source.
      -- track_commands = true,

      -- Commands matching any of these Lua patterns (string.find) are never
      -- recorded -- not to project history, stats or the error log. The state
      -- files are plaintext, so a token in `:!curl -H "Authorization: ..."`
      -- would otherwise persist there. false (or {}) disables it. Replaces the
      -- list, so give it in full.
      -- redact_patterns = { "password", "secret", "token", "Bearer", "api[-_]?key" },

      -- Extra plain-text command files (one command per line) folded in as
      -- read-only history sources. `history` entries join the Neovim-history
      -- pickers and the combined `:Cmdlog` / `:Cmdlog full` ones; `all` entries
      -- only the latter.
      -- extra_files = {
      --   history = {}, -- e.g. { "~/my_global_history.txt" }
      --   all = {}, -- e.g. { "~/my_favs.txt" }
      -- },

      -- Keep a separate favorites.json per Git project (in a `projects/`
      -- subdirectory next to `favorites_path`, named after the Git root).
      -- project_scoped = {
      --   enabled = false,
      -- },

      -- Keys inside the cmdlog pickers; false disables one.
      -- mappings = {
      --   enabled = true,
      --   select = "<CR>", -- insert the selected command into the cmdline
      --   toggle_favorite = "<Tab>", -- mark/unmark the selected command as favorite
      --   refresh = "<C-r>", -- refresh the current picker
      --   delete = "<C-x>", -- delete the selected entry, or every marked one, from its history
      --   toggle_selection = "<C-Space>", -- mark/unmark an entry for a batch delete, then move down
      --   tag = "<C-t>", -- add a tag to the selected favorite (favorites picker only)
      --   cycle_source = "<C-s>", -- rotate to the next picker, keeping the prompt text
      --   undo_favorite = "<C-z>", -- undo the most recent favorite toggle
      --   move_favorite_up = "<C-Up>", -- move the selected favorite one slot up (favorites picker only)
      --   move_favorite_down = "<C-Down>", -- move the selected favorite one slot down (favorites picker only)
      --   lazygit = "<C-g>", -- gitsuite.nvim's lazygit for the project root (project picker only, soft dep)
      -- },

      -- Escape hatch for a shell-history format the built-in parsers do not
      -- know. Both halves belong together: without `matches` deleting is refused
      -- rather than guessed, because deleting rewrites the history file. Empty
      -- = the built-in per-shell parsers.
      -- shell_history = {
      --   parse = nil, -- fun(lines: string[], shell: string): string[]; raw file lines -> commands
      --   matches = nil, -- fun(line: string, cmd: string): boolean; does this raw line hold that command
      -- },

      -- Whether a picker's preview may *run* a history entry (`:!cmd`, `:lua`,
      -- `:term`). Off because previewing is a browse action and the entries are
      -- not necessarily your own; an entry matching `risky_patterns`, or an
      -- argument with a `|`, a quote or a shell metacharacter, is never run even
      -- when on. `:edit <file>` previews the file either way.
      -- preview_execute = false,

      -- Highlight commands prone to damage or data loss.
      -- highlight_risky = true,
      -- Plain Lua patterns matched against each command; false (or {}) disables
      -- the highlighting. Replaces the list, so give it in full.
      -- risky_patterns = {
      --   "rm%s+%-rf",
      --   "git%s+reset%s+%-%-hard",
      --   "git%s+push.-%-%-force",
      --   "git%s+clean%s+%-[fd]",
      --   "%%bd!",
      --   "qa!",
      --   "wqa!",
      --   "sudo%s+rm",
      --   "mkfs",
      --   "dd%s+if=",
      -- },

      -- Normal-mode entry-point keymaps, `:Cmdlog` subcommand -> lhs ("" = bare
      -- `:Cmdlog`). Empty so the plugin never claims a leader key on its own.
      -- keymaps = {}, -- e.g. { [""] = "<leader>hc", favorites = "<leader>hf" }
    },
  },

  {
    "StefanBartl/rules.nvim",
    cmd = { "Rules" },
    dependencies = { "StefanBartl/lib.nvim" },
    opts = {
      -- Files or directories to load fenced ```rule blocks from; rules.nvim
      -- ships no rules of its own. Points at the whole Checklists tree, not
      -- just regeln/: the loader only picks up fenced ```rule blocks, so files
      -- still in the legacy table format are silently skipped rather than
      -- needing a narrower path per migrated family.
      -- Default: {}.
      rulesets = { vim.env.REPOS_DIR .. "/WKDBooks/Development/wkdbook-Lua/Checklists" },
      -- Named groups of family prefixes for `:Rules gate`. The gate-to-family
      -- mapping is config, not a rules.nvim opinion -- see docs/BINDINGS.md in
      -- the plugin repo. `review` mirrors exactly the families REVIEW.md's own
      -- Schnell-Check cites -- run the whole family per gate, not just the
      -- specific rows REVIEW.md quotes.
      -- Default: {}.
      gates = {
        new_project = { "NEW" },
        release = { "REL" },
        review = { "ERR", "LUA", "UI", "CMT", "SEC", "PRIN", "PERF" },
      },
    },
  },
}
