---@module 'usrcmds'
-- Initialize module for 'usrcmds'

require("usrcmds.format_table").setup({
  header_align = "center",
  entry_align = "center",
})
require("usrcmds.gather").setup({ lua = true })
-- Ziel ist diese beiden durch migrate zu ersetzen
require("usrcmds.migrate.opt").enable()
require("usrcmds.migrate.notify").enable()

require("usrcmds.compress_dir").enable_usercmd()
require("usrcmds.diff").enable({ diff_origin = true })
require("usrcmds.fileinfo").enable()
require("usrcmds.filter_lines").enable()
require("usrcmds.format_text_width")
require("usrcmds.insertfilepath").enable()
require("usrcmds.misc").enable_usercmds()
require("usrcmds.project_tree").enable_usercmds()
require("usrcmds.lua_module_annotation").enable()
require("usrcmds.newfile").enable_usercmds()
require("usrcmds.reload").enable()
require("usrcmds.system_find").enable_usercmds()
require("usrcmds.templates").setup()
require("usrcmds.update_repos").enable()
require("usrcmds.uv_doc").enable_usercmd()
