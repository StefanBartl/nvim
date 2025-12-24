---@module 'custom'
-- Initialize modules for 'custom'

require("custom.recommender").setup()

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

