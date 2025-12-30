---@module 'usrcmds'
-- Initialize module for 'usrcmds'

require("usrcmds.refactor_notify").setup()

require("usrcmds.column_align").setup()
require("usrcmds.compress_dir").enable_usercmd()
require("usrcmds.diff").enable({ diff_origin = true })
require("usrcmds.fileinfo").enable()
require("usrcmds.filter_lines").enable()
require("usrcmds.format_text_width")
require("usrcmds.insertfilepath").enable()
require("usrcmds.misc").enable_usercmds()
require("usrcmds.project_tree").enable_usercmds()
require("usrcmds.lua_module_annotation").enable()
require("usrcmds.md_tablewrap")
require("usrcmds.mymessages").enable_usercmds()
require("usrcmds.newfile").enable_usercmds()
require("usrcmds.migrate.opt").enable()
require("usrcmds.migrate.notify").enable()
require("usrcmds.reload_current_module").enable()
require("usrcmds.system_find").enable_usercmds()
require("usrcmds.templates").setup()
require("usrcmds.uv_doc").enable_usercmd()
