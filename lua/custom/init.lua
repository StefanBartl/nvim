---@module 'custom'
-- Initialize modules for 'custom'

require("custom.lua_project_file_stats").setup()

require("custom.column_align").setup()
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

require("custom.find_config").enable({ usercmds = true, keymaps = true })
require("custom.markdown").setup()
require("custom.pathprobe").enable_keymaps()
require("custom.repo_pickers").enable({
  selector = "auto", -- "auto" | "vim_select" | "telescope" | "fzf"
  engine = "auto", -- "auto" | "telescope" | "fzf"
  expose_engine_cmds = false,
  keymaps_lhs = { repo_files = "<leader>rf", repo_grep = "<leader>rg" },
}, { usercmds = true, keymaps = true })
require("custom.pathfinder").setup({})
local line_marker = require("custom.line_marker")
line_marker.enable_commands()
line_marker.enable_mappings()
