---@module 'autocmds.general.defaults'

-- AUDIT: Optionen beschreiben

---@type AutoCmds.General.Cfg
local AUTOCMDS_GENERAL_DEFAULTS = {
  group_name = "autocmds_general",

  auto_mkdir = {
    enable = true,
    skip_remote = true,
    detect_remote_pattern = "^%w%w+:[\\/][\\/]", -- Matches e.g. "xx://", "ssh://", "http://", "file://", on both slash styles
  },

  kitty = {                                     -- Sets Kitty padding/margin to compact values on VimEnter and restores them on VimLeavePre.
    enable = true,                              -- Disabled by default; only meaningful inside Kitty
    enter_padding = 0,
    enter_margin = 0,
    leave_padding = 20,
    leave_margin = 10,
  },

  nvdash = {
    enable = true,
    cmd = "Nvdash",
    is_listed_only = true,                      -- Consider only listed buffers when deciding "last buffer"
  },

  cursorline = {
    enable = true,
    show_events = { "InsertLeave", "WinEnter" },
    hide_events = { "InsertEnter", "WinLeave" },
  },

  last_loc = {
    enable = true,
    exclude = { "gitcommit", "commit", "gitrebase" },
    mark = '"',
  },

  no_name_guard = {
    enable = true,
  },

}

local M = {}

---@return AutoCmds.General.Cfg
function M.get_defaults()
  return AUTOCMDS_GENERAL_DEFAULTS
end

return M
