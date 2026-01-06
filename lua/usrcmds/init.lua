---@module 'usrcmds'
-- Initialize module for 'usrcmds'

-- Ziel ist diese beiden durch migrate zu ersetzen
require("usrcmds.migrate.opt").enable()
require("usrcmds.migrate.notify").enable()

require("usrcmds.gather").setup({ lua = true })
require("usrcmds.compress_dir").enable_usercmd()
require("usrcmds.diff").enable({ diff_origin = true })
require("usrcmds.fileinfo").enable()
require("usrcmds.project_tree").enable_usercmds()
require("usrcmds.newfile").enable_usercmds()
require("usrcmds.reload").enable()
require("usrcmds.system_find").enable_usercmds()
require("usrcmds.templates").setup()
require("usrcmds.update_repos").enable()
require("usrcmds.uv_doc").enable_usercmd()
