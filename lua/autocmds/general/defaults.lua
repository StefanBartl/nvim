---@module 'autocmds.general.defaults'

--- CDX: config fields undocumented — add a one-line note per field

---@type AutoCmds.General.Cfg
local AUTOCMDS_GENERAL_DEFAULTS = {
  group_name = "autocmds_general",

  kitty = { -- Sets Kitty padding/margin to compact values on VimEnter and restores them on VimLeavePre.
    enable = true, -- only has an effect inside Kitty
    enter_padding = 0,
    enter_margin = 0,
    leave_padding = 20,
    leave_margin = 10,
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
