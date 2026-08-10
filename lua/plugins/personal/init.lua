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
    opts = {
      -- Bare `nvim` (no file args) resumes the last-loaded session — see
      -- docs/ROADMAP/casedesk/SESSIONS.md §4.3.
      autoload = true,
    },
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
    "StefanBartl/images.nvim",
    -- Ersetzt snacks.image, das hier prinzipiell nicht funktionieren kann:
    -- es sendet nur Kitty-APC, und das wird aus Neovim heraus in WezTerm nie
    -- gezeichnet. images.nvim nutzt stattdessen OSC 1337.
    --
    -- Beide Namen nötig: `:Image` deckt den Command ab, die Filetypes sorgen
    -- dafür, dass <leader>im und der Doppelklick auch ohne vorherigen
    -- Command-Aufruf in Markdown-Buffern gesetzt sind.
    cmd = { "Image" },
    ft = { "markdown", "vimwiki", "norg", "text" },
    dependencies = { "StefanBartl/lib.nvim" },
    opts = {},
    config = function(_, opts)
      require("images").setup(opts)
    end,
  },

  {
    "StefanBartl/sandbox.nvim",
    event = "VeryLazy",
    dependencies = { "StefanBartl/lib.nvim" },
    config = function()
      require("sandbox").setup({
        -- `image pull`/`push` and the devcontainer build report into the shared
        -- lib.nvim.progress registry, rendered by the statusline's
        -- "plugin_progress" module.
        progress_style = "statusline",
      })
    end,
  },

  {
    "StefanBartl/documentation.nvim",
    cmd = { "DocMap", "DocBrowse" },
    dependencies = { "StefanBartl/lib.nvim" },
    -- Kein `root`: die Commands mappen bewusst das aktuelle Arbeitsverzeichnis,
    -- weil hier reihenweise Repos nebeneinander liegen und ein fixes Ziel genau
    -- das Falsche waere. `source` leitet documentation.config aus dem Root ab
    -- (lua/<name>, wenn lua/ genau einen Kandidaten enthaelt).
    opts = {
      -- `:DocMap full` (LuaLS over the whole tree) and `:DocMap churn` (walks
      -- the repo history) both report into the shared progress registry.
      progress_style = "statusline",
      -- Experimental (2026-08-10): a "Compiler Explorer" link next to every
      -- module/function in the generated page, real luac -l -l -p bytecode
      -- disassembly, not a workaround for Lua. Off by default upstream;
      -- turned on here explicitly per request.
      godbolt = true,
    },
    config = function(_, opts)
      require("documentation").setup(opts)
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
    config = function(_, opts)
      require("runtime-analysis").setup(opts)
    end,
  },

  {
    "StefanBartl/spotlight.nvim",
    dependencies = { "StefanBartl/lib.nvim" },
    event = "VeryLazy",
    config = function()
      require("spotlight").setup()
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
    dependencies = { "StefanBartl/lib.nvim" },
    config = function()
      require("insights").setup({
        -- Building the cwd symbol index runs one rg pass per language pattern;
        -- reports into the shared lib.nvim.progress registry.
        symbols = { progress_style = "statusline" },
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
    config = function()
      require("reposcope.init").setup({
        -- `:Reposcope update`/`status` walk a whole directory of clones; both
        -- report into the shared lib.nvim.progress registry.
        progress_style = "statusline",
      })
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
      -- OCR/AI backends run for minutes on a large PDF. Not cancellable from
      -- the indicator (see pdfport's docs), so a non-interactive style only.
      progress_style = "statusline",
      ollama_host = "http://localhost:11434",
      ollama_model = "qwen2.5-coder:7b",
      debug = false,
    },
  },

  {
    -- Finds/rewrites deprecated Neovim API calls (vim.highlight.* ->
    -- vim.hl.*, vim.lsp.buf_get_clients() -> vim.lsp.get_clients(), ...) in
    -- the current line, a range, the whole buffer, or cwd, with a Telescope
    -- picker+preview past single-line scope. Useful directly on this
    -- config's own Lua as it moves across Neovim versions.
    "StefanBartl/migrate.nvim",
    dependencies = { "StefanBartl/lib.nvim" },
    cmd = { "MigrateOpt", "MigrateNotify", "MigrateHl", "MigrateLsp" },
    opts = {}, -- opt + notify + hl + lsp all enabled by default
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
        -- Release-Variante (v0.3.0 von GitHub Releases, kein Toolchain nötig).
        -- Die dev/standalone-Overrides zeigten auf E:/repos (Checkout liegt jetzt
        -- unter C:/repos) und auf mdview-server.exe - `npm run build:go` erzeugt
        -- unter Windows aber mdview-server OHNE .exe. Zum Testen eines lokal
        -- gebauten Relays (siehe docs/development.md) wieder einkommentieren:
        --   dev = {
        --     binary_path = "C:/repos/mdview.nvim/native/server/mdview-server",
        --     web_root = "C:/repos/mdview.nvim/dist/client", -- braucht wasm-pack
        --   },
        --   standalone = { binary_path = "C:/repos/mdview.nvim/native/server/mdview-server" },
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
        },
      })
    end,
  },
})

return plugins.export()
