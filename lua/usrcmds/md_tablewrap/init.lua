---@module 'usrcmds.md_tablewrap'
--- Entry point exporting the user-facing setup from commands.

require("usrcmds.md_tablewrap.commands").setup({
  inner_pad        = 1,
  outer_left       = 3,
  outer_right      = 3,
  auto_width       = true,
	width_mode    = "minflex",
  max_col_width    = nil,
  min_col_width    = 6,
  wrap_all_default = false,
  on_save_enabled  = false,
})
