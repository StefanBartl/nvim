---@module 'plugins.personal'
--- Personal and local development plugins with smart local/remote fallback.
---
--- Source control is centralized in the `MODE` table below. Each repo is set to
--- one of three states; the global `SOURCE` switch can force all of them at once.

local personal_utils = require("plugins.personal.utils")

-- ===========================================================================
-- SOURCE CONTROL
-- ===========================================================================

---@alias PersonalRepoMode "disabled"|"dir"|"remote"
---  - "disabled" → Repo gar nicht laden (enabled = false)
---  - "dir"      → lokal aus dem repos-Verzeichnis (dir), Fallback remote falls Ordner fehlt
---  - "remote"   → von GitHub (StefanBartl/...)

--- Globaler "all"-Schalter. Übersteuert die MODE-Tabelle, wenn ungleich "auto":
---   "auto"     → pro Repo entscheidet die MODE-Tabelle unten
---   "dir"      → ALLE lokal
---   "remote"   → ALLE remote
---   "disabled" → ALLE aus
---@type "auto"|PersonalRepoMode

local SOURCE = "dir"

--- Pro Repo (Key = Ordner-/Repo-Basename). Nicht gelistet → "dir".
---@type table<string, PersonalRepoMode>
local MODE = {
  -- 1. CORE / INFRASTRUCTURE, UTILITIES & SYSTEM
  ["lib.nvim"] = "dir",
  ["sessions.nvim"] = "dir",
  ["pickers.nvim"] = "dir",
  ["buffer-ctx.nvim"] = "dir",
  ["open.nvim"] = "dir",
  ["nvim-containers"] = "dir",

  -- 2. NAVIGATION, FILE SYSTEM, SEARCH & TREES
  ["fileops.nvim"] = "dir",
  ["gopath.nvim"] = "dir",
  ["replacer"] = "dir",
  ["project-insight.nvim"] = "dir",
  ["filetree.nvim"] = "dir",
  ["reposcope.nvim"] = "dir",

  -- 3. CODE QUALITY, UI, LOGGING & PRODUCTIVITY
  ["debugging.nvim"] = "dir",
  ["diff.nvim"] = "dir",
  ["languages.nvim"] = "dir",
  ["nvim-cmdlog"] = "dir",
  ["emojis.nvim"] = "dir",
  ["github_stats.nvim"] = "dir",
  -- ["learn-cli.nvim"]        = "dir",

  -- 4. FILE TYPES (MARKDOWN & DOCUMENTS)
  ["cascade.nvim"] = "dir",
  ["pdfport.nvim"] = "dir",
  ["markdown.nvim"] = "dir",
  ["color_my_ascii.nvim"] = "dir",
  ["recommender.nvim"] = "dir",
  ["mdview.nvim"] = "dir",
}

local VALID_MODE = { disabled = true, dir = true, remote = true }

--- Applies SOURCE/MODE to every spec in place:
---   resolves `dir` (lokal) bzw. `enabled = false` (disabled) anhand des Repo-Basenamens.
---@param specs LazyPluginSpec[]
---@return LazyPluginSpec[]
local function apply_source(specs)
  for _, spec in ipairs(specs) do
    local repo = spec[1]
    if type(repo) == "string" then
      local name = vim.fn.fnamemodify(repo, ":t")
      local mode = (SOURCE ~= "auto") and SOURCE or (MODE[name] or "dir")

      if not VALID_MODE[mode] then
        vim.notify(
          ("[PLUGINS PERSONAL] Ungültiger Modus '%s' für '%s' → 'remote'"):format(
            tostring(mode),
            name
          ),
          vim.log.levels.WARN
        )
        mode = "remote"
      end

      if mode == "disabled" then
        spec.enabled = false
      elseif mode == "dir" then
        spec.dir = personal_utils.local_dev(name) -- nil → remote, falls Ordner fehlt
      end
      -- "remote": dir bleibt nil → lazy nutzt repo[1]
    end
  end
  return specs
end

-- ===========================================================================
-- PLUGIN SPECS
-- ===========================================================================

---@type LazyPluginSpec[]
return apply_source({

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
        engine = "auto",
        repos_dir = repos,
        collections = {
          {
            name = "notes",
            dir = repos .. "/Notes",
            keys = { files = "<leader>mnf", grep = "<leader>mng" },
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
            keys = { files = "<leader>wkf", grep = "<leader>wkg" },
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

        history = {
          enabled = true,
          fzf_scope = "patch", -- patches telescope + fzf-lua setup() itself, no config change needed elsewhere
        },

        selected_index = {
          enabled = true,
          position = "right_align", -- "overlay" | "right_align" | "eol" | "top" | "down"
          highlight = { preset = "accent" },
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
    cmd = "Open",
    dependencies = { "StefanBartl/lib.nvim" },
    opts = {},
    config = function(_, opts)
      require("open_nvim").setup(opts)
    end,
  },

  {
    "StefanBartl/nvim-containers",
    event = "VeryLazy",
    config = function()
      require("containers").setup({})
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
    },
  },

  {
    "StefanBartl/gopath.nvim",
    event = "VeryLazy",
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
    "StefanBartl/project-insight.nvim",
    cmd = "ProjectInsight",
    config = function()
      require("project_insight").setup({})
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
          -- Mark the currently-focused file with a sign-column icon (on top of
          -- neo-tree's own fg colour for all opened files). opened_sync is on by
          -- default and keeps those opened-file colours in sync as buffers open/
          -- close, so no config needed for it.
          current_hl = { enabled = true, icon = "▸" },
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
      require("diff_nvim").setup(opts)
    end,
  },

  {
    "StefanBartl/nvim-cmdlog",
    lazy = false,
    cmd = { "CmdlogOpen", "CmdlogSearch" },
    dependencies = { "nvim-lua/plenary.nvim" },
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
          "StefanBartl/nvim-cmdlog",
          "StefanBartl/nvim-containers",
          "StefanBartl/open.nvim",
          "StefanBartl/pdfport.nvim",
          "StefanBartl/pickers.nvim",
          "StefanBartl/project-insight.nvim",
          "StefanBartl/recommender.nvim",
          "StefanBartl/replacer.nvim",
          "StefanBartl/reposcope.nvim",
        },
        token_source = "env",
        token_env_var = "GITHUB_TOKEN",
        fetch_interval_hours = 24,
        notification_level = "all",
        data_dir = vim.fn.stdpath('config') .. "/github-stats/",
      })
    end,
  },

  -- {
  --   "StefanBartl/learn-cli.nvim",
  --   lazy = false,
  --   config = function()
  --     require("learn_cli").setup({
  --       exercises_dir = vim.fs.joinpath(vim.fn.stdpath("config"), "lua", "plugins", "learn-cli.nvim", "exercises"),
  --     })
  --   end,
  -- },

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
          on = { "edit" }, -- "edit" = sofort beim Indent/Move/…, "save" = bei :w
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
      require("markdown_nvim").setup()
    end,
  },

  {
    "StefanBartl/color_my_ascii.nvim",
    ft = "markdown",
    dependencies = { "StefanBartl/lib.nvim" }, -- optional, enables graceful keymap/notify integration
    -- Typing `opts` as ColorMyAscii.Config makes lua_ls offer value completion
    -- inside the config (e.g. `preset = "…"` suggests the fence-line presets).
    -- Requires the plugin's types on the LSP path (lazydev/neodev or workspace lib).
    ---@type ColorMyAscii.Config
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
    cmd = {
      "MDViewStart",
      "MDViewStop",
      "MDViewToggle",
      "MDViewOpen",
      "MDViewTheme",
      "MDViewPreviewTab",
      "MDViewShowWebLogs",
      "MDViewLog",
      "MDViewDiagnose",
    },
    config = function()
      require("mdview").setup({
        browser = {
          -- theme = "github", -- P1-6: neues Theme (auch: catppuccin, dark-dimmed, plain, github) -> FUNKTioNNERTT
          highlighter = "hljs", -- P1-5: exakte VSCode/TextMate-Themes (oder "hljs" / "none") - shiki highligihted nichts, hljs funkltiert wunderbar! höjs als default, shiki  wenn leicht debuggen dann debuggen oder wenn performance technisch ewwas dafür spricht, weil shiki besser als hljs ist, dnn jedeflals debuggen, ansosnten lassen wenn nichts dagegen spricht und als default; wäre es auch möglich, de color_m<_ascii api zu nutzen? dann könnten wir diese sdependecmy streichen und cmein eigenes colotr_my_ascii plugin nutzen
          -- focus = "nvim", -- P2-9: Fokus bleibt in nvim (Windows best-effort) - wenn dies optin aktiv ist, dann öffnet sich nichts im browser! Bug!
        },
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
      require("recommender_nvim").setup()
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
