---@module 'custom'
-- Initialize modules for 'custom'

---AUDIT:
require("custom.diff").enable({
  diff_exit = true,
  diff_origin = true,
  diff = true,
})

-- pdfport.nvim is loaded via plugins/personal.lua (cmd-lazy).
-- Setup is triggered automatically on first command use.

require("custom.open").setup()
---AUDIT
require("custom.commands_keymaps").setup({
  delete_current_file = true,
})

require("custom.insert").setup({
  enable_legacy_commands = true,
})
require("custom.format").setup({
  enable_legacy_commands = true,
})
require("custom.mynotes")
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

-- AUDIT:
local line_marker = require("custom.line_marker")
line_marker.enable_commands()
line_marker.enable_mappings()
