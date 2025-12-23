---@module 'usrcmds'
-- Initialize module for 'usrcmds'


require("usrcmds.column_align").setup()
require("usrcmds.compress_dir").enable_usercmd()
require("usrcmds.diff").enable({ diff_origin = true })
require("usrcmds.filecycle").setup({
  open_target = "current",    -- "current"|"split"|"vsplit"|"tab"|"background"
  keep_focus = true,          -- bei Split/Vsplit Fokus im Ursprungsfenster behalten
  include_hidden = false,     -- Dotfiles ignorieren
  wrap = true,                -- am Ende/Anfang umbrechen
  follow_symlinks = true,     -- echte Pfade für Vergleich/Öffnen nutzen
  root = "buffer_dir",        -- "buffer_dir"|"cwd"
  confirm_on_modified = true, -- :confirm edit bei geänderten Buffern
  case_insensitive = true,    -- alphabetische Sortierung/Matching ohne Groß/Kleinschreibung
})
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
require("usrcmds.opt_migrator").enable()
require("usrcmds.recommender").enable()
require("usrcmds.reload_current_module").enable()
require("usrcmds.system_find").enable_usercmds()
require("usrcmds.templates").setup()
require("usrcmds.uv_doc").enable_usercmd()
require("usrcmds.diagnostics.quickfix").enable_usercmds_and_keymaps()

