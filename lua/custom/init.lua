---@module 'custom'
-- Initialize modules for 'custom'

require("custom.find_config").enable({ usercmds = true, keymaps = true  })
require("custom.markdown").setup()
require("custom.pathprobe").enable_keymaps()
require("custom.reload").enable()
require("custom.repo_pickers").enable({
  selector = "auto",      -- "auto" | "vim_select" | "telescope" | "fzf"
  engine   = "auto",      -- "auto" | "telescope" | "fzf"
  expose_engine_cmds = false,
  keymaps_lhs = { repo_files = "<leader>rf", repo_grep = "<leader>rg" },
}, { usercmds = true, keymaps = true })
require("custom.usr_pickers").enable({}, { usercmds = true, keymaps = true })
