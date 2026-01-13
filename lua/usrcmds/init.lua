---@module 'usrcmds'
-- Initialize module for 'usrcmds'

require("usrcmds.copy").enable()
require("usrcmds.gather").setup({ lua = true })
require("usrcmds.compress_dir").enable_usercmd()
require("usrcmds.diff").enable({ diff_origin = true })
require("usrcmds.fileinfo").enable()
require("usrcmds.project_tree").enable_usercmds()
require("usrcmds.newfile").enable_usercmds()
require("usrcmds.migrate").setup({
    opt = true,    -- `:MigrateOpt`
    notify = true, -- `MigrateNotify`
})
require("usrcmds.reload").enable()
require("usrcmds.search_all_drives").enable()
require("usrcmds.system_find").enable_usercmds()
require("usrcmds.update_repos").enable()
require("usrcmds.uv_doc").enable_usercmd()
