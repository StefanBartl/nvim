---@module 'custom'
-- Initialize modules for 'custom'

require("custom.function_index").setup()
require("custom.recommender").setup()
require("custom.function_index").setup({
  cache = {
    enabled = true,                    -- Enable persistent cache
    dir = vim.fn.stdpath("cache") .. "/function_index",
    ttl_seconds = 3600,                -- Cache validity duration
  },

  indexing = {
    auto_rebuild_on_save = false,      -- Rebuild when files change
    exclude_patterns = {               -- Patterns to ignore
      "node_modules/",
      ".git/",
      "build/",
      "dist/",
    },
    max_file_size_kb = 1024,           -- Skip files larger than this
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
    show_function_types = true,         -- local, method, exported, etc.
    group_by_file = false,              -- Group entries by file
    default_picker = "telescope",       -- "telescope" or "fzf"
  },
})

require("custom.find_config").enable({ usercmds = true, keymaps = true })
require("custom.lsp_signature").setup()
require("custom.markdown").setup()
require("custom.pathprobe").enable_keymaps()
require("custom.reload").enable()
require("custom.repo_pickers").enable({
  selector = "auto", -- "auto" | "vim_select" | "telescope" | "fzf"
  engine = "auto", -- "auto" | "telescope" | "fzf"
  expose_engine_cmds = false,
  keymaps_lhs = { repo_files = "<leader>rf", repo_grep = "<leader>rg" },
}, { usercmds = true, keymaps = true })
require("custom.usr_pickers").enable({}, { usercmds = true, keymaps = true })
require("custom.pathfinder").setup{}
local line_marker = require("custom.line_marker")
line_marker.enable_commands()
line_marker.enable_mappings()

