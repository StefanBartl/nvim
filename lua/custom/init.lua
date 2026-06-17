---@module 'custom'
-- Initialize modules for 'custom'

require("custom.dir_picker").setup({
  default_engine  = "telescope",   -- or "fzf"
  fallback_engine = "fzf",
  -- optional: add or override named depth aliases
  depth_aliases = {
    work = function() return "/home/user/work" end,
  },
})

---AUDIT:
require("custom.diff").enable({
  diff_exit   = true,
  diff_origin = true,
  diff        = true,
})

---AUDIT:
--- pdfport lives entirely in lua/custom/ and has no upstream plugin URL.
--- This spec uses a local dummy plugin entry so that lazy.nvim still manages
--- the load order and we can hook into the `config` callback reliably.
--- All real work happens inside require("custom.pdfport").setup().

      require("custom.pdfport").setup({
        default_backend = "auto",

        -- Ordered fallback chain: fastest/lightest first
        fallback_chain = {
          "pdftotext",
          "pdfplumber",
          "marker",
          "docling",
          "ollama",
          "claude",
        },

        extract_opts = {
          max_pages  = nil,    -- nil = no limit; set e.g. 20 for large docs
          timeout_ms = 30000,
        },

        render_opts = {
          mode  = "buffer",
          split = "current",
          focus = true,
        },

        -- Claude API key: leave nil to read from $ANTHROPIC_API_KEY
        claude_api_key = nil,

        ollama_host  = "http://localhost:11434",
        -- Change to any model installed locally (check with: ollama list).
        -- Vision models (llava, bakllava) are needed for scanned PDFs.
        -- Text models (qwen2.5-coder:7b, mistral, llama3) work for normal PDFs.
        ollama_model = "qwen2.5-coder:7b",

        debug = false,
      })


require("custom.find_in_folder").setup({ keymaps = true, usercmds = true })
require("custom.open").setup({
  default_handler = "browser",  -- run when :Open is called with no args
})

--AUDIT
require("custom.commands_keymaps").setup({
  delete_current_file = true,
})

require("custom.insert").setup({
  enable_legacy_commands = true,
})
require("custom.format").setup({
  enable_legacy_commands = true,
})
require("custom.mynotes")
require("custom.lua_project_file_stats").setup()
require("custom.function_index").setup()
require("custom.recommender").setup()
require("custom.function_index").setup({
  enable_user_commands = true,
  -- enable_keymaps = false,
  -- keymaps = {
  --   telescope = "<leader>pf",
  --   fzf = "<leader>fF",
  -- },

  cache = {
    enabled = true, -- Enable persistent cache
    dir = vim.fn.stdpath("cache") .. "/function_index",
    ttl_seconds = 3600, -- Cache validity duration
  },

  indexing = {
    auto_rebuild_on_save = false, -- Rebuild when files change
    exclude_patterns = { -- Patterns to ignore
      "node_modules/",
      ".git/",
      "build/",
      "dist/",
    },
    max_file_size_kb = 1024, -- Skip files larger than this
  },

  languages = {
    lua = true,
    python = true,
    javascript = true,
    typescript = true,
    go = true,
    rust = true,
    c = true,
    cpp = true,
  },

  ui = {
    show_language_icons = true,
    show_function_types = true, -- local, method, exported, etc.
    group_by_file = false, -- Group entries by file
    default_picker = "telescope", -- "telescope" or "fzf"
  },
})

require("custom.filecycle").setup({
  open_target = "current", -- "current"|"split"|"vsplit"|"tab"|"background"
  keep_focus = true, -- bei Split/Vsplit Fokus im Ursprungsfenster behalten
  include_hidden = false, -- Dotfiles ignorieren
  wrap = true, -- am Ende/Anfang umbrechen
  follow_symlinks = true, -- echte Pfade für Vergleich/Öffnen nutzen
  root = "buffer_dir", -- "buffer_dir"|"cwd"
  confirm_on_modified = true, -- :confirm edit bei geänderten Buffern
  case_insensitive = true, -- alphabetische Sortierung/Matching ohne Groß/Kleinschreibung
  keymaps = true,
  usercommands = true,
})

require("custom.find_config").setup({ engine = "telescope" })
require("custom.markdown").setup()
require("custom.pathprobe").enable_keymaps()
require("custom.repo_pickers").enable({
  selector = "auto", -- "auto" | "vim_select" | "telescope" | "fzf"
  engine = "auto", -- "auto" | "telescope" | "fzf"
  expose_engine_cmds = false,
  keymaps_lhs = { repo_files = "<leader>rf", repo_grep = "<leader>rg" },
}, { usercmds = true, keymaps = true })
require("custom.pathfinder").setup({})

-- AUDIT:
local line_marker = require("custom.line_marker")
line_marker.enable_commands()
line_marker.enable_mappings()
