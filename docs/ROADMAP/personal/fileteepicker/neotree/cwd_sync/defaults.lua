---@module 'config.neotree.cwd_sync.defaults'

local CWD_SYNC_DEFAULTS = {
  enabled = true,
  debounce_ms = 150, -- Debounce-Zeit in Millisekunden
  keep_focus = true, -- Focus bleibt im aktiven Window
  also_set_nvim_cwd = false, -- Setzt auch :pwd
  open_if_closed = false, -- Öffnet Neo-tree wenn geschlossen
  use_project_root = true, -- Nutzt Project-Root wenn verfügbar
  project_root_fallback_to_bufdir = true, -- Fallback zu Buffer-Dir
}

return CWD_SYNC_DEFAULTS
