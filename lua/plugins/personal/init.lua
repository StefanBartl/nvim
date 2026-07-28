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
      -- TODO: Das muss anders gemacht werden: helptags generell; usrcmds als normales userconfig nicht extra
      require("lib.nvim_usrcmds").setup({
        helptags = true,
        cwd_here = true,
        powershell_profile = true,
      })
    end,
  },

  {
    "stefanbartl/sessions.nvim",
    lazy = false,
    dependencies = { "stefanbartl/lib.nvim" },
    opts = {},
  },

  {
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
            dir = repos .. "/Notes/MyNotes/Lua",
            keys = { files = "<leader>mlf", grep = "<leader>mlg" },
          },
          {
            name = "notes_nvim",
            dir = repos .. "/Notes/MyNotes/Neovim",
            keys = { files = "<leader>mvf", grep = "<leader>mvg" },
          },
          {
            name = "checklists",
            dir = repos .. "/Notes/MyNotes/Checklists",
            keys = { files = "<leader>chf", grep = "<leader>chg" },
          },
          {
            name = "spickzettel",
            dir = repos .. "/Notes/spickzettel",
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

        experimental = {
          selected_index = {
            enabled = true,
            position = "right_align", -- "overlay" | "right_align" | "eol" | "top" | "down"
            highlight = { preset = "accent" },
          },
        },
      })
    end,
  },

  {
    "StefanBartl/buffer-ctx.nvim",
    cmd = { "Insert", "Copy", "Format", "Mark", "MarkLineToggle", "MarkLinesYank" },
    keys = { "<leader>cnl", "<leader>cnm", "<leader>cnf", "<S-m>", "<C-p>" },
    opts = {
      commands = true,
      keymaps = {
        location_copy = "<leader>cnl",
        module_copy = "<leader>cnm",
        filepath_copy = "<leader>cnf",
      },
      mark = {
        enable = true,
        keymaps = { toggle = "<S-m>", yank = "<C-p>" },
      },
    },
    config = function(_, opts)
      require("buffer_ctx").setup(opts)
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
    opts = {},
    config = function(_, opts)
      require("open").setup(opts)
    end,
  },

  {
    "StefanBartl/sandbox.nvim",
    event = "VeryLazy",
    config = function()
      require("sandbox").setup({})
    end,
  },

  -- ==========================================================================
  -- 2. NAVIGATION, FILE SYSTEM, SEARCH & TREES
  -- ==========================================================================

  {
    "StefanBartl/fileops.nvim",
    event = "VeryLazy",
    opts = {
      cycle = {
        open_target = "current",
        keep_focus = true,
        include_hidden = false,
        wrap = true,
        follow_symlinks = true,
        root = "buffer_dir",
        confirm_on_modified = true,
        case_insensitive = true,
      },
      keymaps = { cycle = true, delete = true },
      commands = true,
      auto_mkdir = { enable = true }, -- Creates missing parent dirs on BufWritePre (moved here from autocmds.general)
      on_hold = { enable = false }, -- moved here from autocmds.git.line_diff_on_hold
      conflict_marks = { enable = true }, -- moved here from autocmds.git.conflict_marks
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
        open_here = { "gF", "<2-LeftMouse>" },
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
    config = function()
      require("replacer").setup({
        engine = "telescope",
        default_scope = "%",
        progress_style = "statusline", -- "auto" | "notify" | "statusline" | "fidget" | "float" (needs lib.nvim)
      })
    end,
  },

  {
    "StefanBartl/insights.nvim",
    -- Not `cmd = "Insights"`: the conflicts / unimported / devserver
    -- autocmds are registered by setup(), so lazy-loading on the command would
    -- mean they never fire. Set their `enable = false` to opt out instead.
    lazy = false,
    config = function()
      require("insights").setup({})
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
        features = {
          cwd_sync = { enabled = true, reveal = false },
          -- The mode badge (PROJECT/LOCK/…) is shown in wkdnvchad's own
          -- statusline instead (modules/filetree_cwd_mode) via cwd_mode's
          -- external-statusline API (badge()/component()). indicator.enabled
          -- must stay false here, or the mode shows twice: once in the
          -- shared statusline, once as a float in the tree window (with
          -- laststatus=3 there is no per-window statusline for it to use,
          -- so it would fall back to exactly that float).
          cwd_mode = { indicator = { enabled = false } },
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
    config = function()
      require("reposcope.init").setup({})
    end,
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
    opts = {
      features = { neotree = false },
    },
    config = function(_, opts)
      require("debugging").setup(opts)
    end,
  },

  {
    "StefanBartl/dap.nvim",
    event = "VeryLazy",
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
      -- "<leader>d" alone collides with existing git/fzf mappings
      -- (dc = DiffviewClose, di = ToggleInlineDiff, do = FzfLua diagnostics)
      keymaps = { prefix = "<leader>da" },
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
  },

  {
    "StefanBartl/diff.nvim",
    cmd = { "Diff", "DiffClear", "DiffOrig", "DiffExit" },
    opts = {
      features = {
        diff = true,
        diff_origin = true,
        diff_exit = true,
      },
    },
    config = function(_, opts)
      require("diff").setup(opts)
    end,
  },

  {
    "StefanBartl/cmdlog.nvim",
    lazy = false,
    cmd = { "Cmdlog" },
    config = function()
      require("cmdlog").setup({
        picker = "telescope",
      })
    end,
  },

  {
    "StefanBartl/emojis.nvim",
    cmd = "Emojis",
    opts = {
      default_scope = "%",
    },
    config = function(_, opts)
      require("emojis").setup(opts)
    end,
  },

  {
    "StefanBartl/github_stats.nvim",
    event = "VimEnter",
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
          "StefanBartl/emojis.nvim",
          "StefanBartl/fileops.nvim",
          "StefanBartl/filetree.nvim",
          "StefanBartl/github_stats.nvim",
          "StefanBartl/gopath.nvim",
          "StefanBartl/language.nvim",
          "StefanBartl/lib.nvim",
          "StefanBartl/markdown.nvim",
          "StefanBartl/mdview.nvim",
          "StefanBartl/migrate.nvim",
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
        exercises_dir = vim.fs.joinpath(
          vim.fn.stdpath("config"),
          "lua",
          "plugins",
          "learn-cli.nvim",
          "exercises"
        ),
      })
    end,
  },

  -- ==========================================================================
  -- 4. FILE TYPES (MARKDOWN & DOCUMENTS)
  -- ==========================================================================

  {
    "StefanBartl/cascade.nvim",
    ft = { "markdown", "markdown.mdx", "text", "tex", "norg" },
    event = "VeryLazy",
    opts = {
      -- LIST DOMAIN (filetype-scoped) ------------------------------------------
      lists = {
        enable = true, -- master switch for the whole list domain
        -- Per-feature on/off. Disabling one stops its keymap action and the
        -- preset stops binding its keys (native keys stay native).
        features = {
          continue = true, -- <CR>/o/O continuation + empty-bullet deletion
          checkbox = true, -- toggle/cycle checkbox  (<leader>tc)
          cycle_type = true, -- cycle a single item's marker shape (<leader>tt/tT)
          rotate = true, -- block/visual form rotation (<leader>tf/tF)
          sort = true, -- block/visual A-Z sort (<leader>ts)
          reverse = true, -- block/visual reverse order (<leader>tv)
          strip = true, -- block/visual remove checkboxes (<leader>tx)
          indent = true, -- indent/outdent + level-aware renumber (<A-Right>/<A-Left>)
          move = true, -- move line/selection up/down + renumber (<A-Up>/<A-Down>)
        },
        -- WHEN ordered lists are auto-renumbered:
        renumber = {
          enable = true,
          -- "edit" = sofort bei Indent/Move/Continue, "save" = bei :w als
          -- Sicherheitsnetz fuer von Hand getippte/eingefuegte Listen (z.B.
          -- "1./1./1."), die nie ein Edit-Event ausloesen.
          on = { "edit", "save" },
        },
      },

      -- CYCLE DOMAIN (global) --------------------------------------------------
      cycle = {
        enable = true, -- master switch for word/number cycling
        features = {
          word = true, -- cycle the word/boolean under the cursor (<C-a>/<C-x>)
        },
        number_fallback = true, -- native <C-a>/<C-x> on numeric tokens
      },

      -- KEYMAPS ----------------------------------------------------------------
      keymaps = { preset = true }, -- bind the opinionated default keys
    },
  },

  {
    "StefanBartl/pdfport.nvim",
    cmd = {

      "PdfPort",
      "PdfPortText",
      "PdfPortFloat",
      "PdfPortSystem",
      "PdfPortTerminal",
      "PdfPortHealth",
    },
    opts = {
      default_backend = "auto",
      fallback_chain = { "pdftotext", "pdfplumber", "marker", "docling", "ollama", "claude" },
      extract_opts = { max_pages = nil, timeout_ms = 30000 },
      render_opts = { mode = "buffer", split = "current", focus = true },
      claude_api_key = nil,
      ollama_host = "http://localhost:11434",
      ollama_model = "qwen2.5-coder:7b",
      debug = false,
    },
  },

  {
    "StefanBartl/markdown.nvim",
    ft = { "markdown", "mdx", "md" },
    -- Soft dependency: markdown.nvim's fenced_scope feature consumes
    -- color_my_ascii's fence API when present (falls back to a built-in scanner
    -- otherwise). Listing it here just guarantees load order in this config.
    dependencies = { "StefanBartl/color_my_ascii.nvim" },
    config = function()
      require("markdown").setup()
    end,
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
    ft = { "markdown" },
    cmd = { "MDView" },
    config = function()
      require("mdview").setup({
        browser = {
          -- theme = "github", -- P1-6: neues Theme (auch: catppuccin, dark-dimmed, plain, github) -> FUNKTioNNERTT
          highlighter = "hljs", -- P1-5: shiki-Bug wird untersucht (siehe mdview.nvim-Session-Notizen); hljs bleibt bis dahin Default
          focus = "nvim", -- P2-9: Fokus bleibt in nvim. Bug (jobstart-Quoting) war in b794c27 bereits gefixt, jetzt aktiviert.

          cursor_marker = "caret",
        },
        dev = {
          binary_path = "E:/repos/mdview.nvim/native/server/mdview-server.exe",
          web_root = "E:/repos/mdview.nvim/dist/client",
        },
        standalone = { binary_path = "E:/repos/mdview.nvim/native/server/mdview-server.exe" },
        experimental = {
          line_diff = true, -- P?: nur geänderte Zeilen senden -> FUnktnioert -> postives/negatives abwägen ob default
          click_navigate = true, -- P0-3: relativer Link öffnet Datei in nvim -> FUNKTIONERT -> als Default setzen
          reverse_scroll = true, -- P1: im Browser scrollen bewegt nvim-Cursor -> funktioniert fast ideal (siehe feedback punkte)
          -- webtransport = true,  -- fällt transparent auf WebSocket zurück (kein Backend) --> FUnktinoert -> abwägen ob DEFULT positives/negatives
        },
      })
    end,
  },
  {
    "StefanBartl/recommender.nvim",
    ft = { "lua" },
    cmd = { "Recommender" },
    config = function()
      require("recommender").setup()
    end,
  },

  {
    "StefanBartl/language.nvim",
    event = "VeryLazy",
    dependencies = {
      "StefanBartl/lib.nvim",
      "folke/trouble.nvim", -- optional: nicer list; pcall-guarded in the plugin
    },
    config = function()
      require("language").setup({
        spell = {
          -- Panel is the default UI; set view = "quickfix" for the classic
          -- diagnostics + quickfix session flow instead.
          ui = { view = "picker", preview = true },
          programming_dict = true,
        },
      })
    end,
  },
})

return plugins.export()
