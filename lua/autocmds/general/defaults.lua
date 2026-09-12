---@module 'autocmds.general.defaults'

---@type AutoCmds.General.Cfg
local AUTOCMDS_GENERAL_DEFAULTS = {
  group_name = "autocmds_general",

  -- Kitty padding/margin used to be configured here too -- removed
  -- 2026-09-12, autocmds.terminals is the one owner now (see its own
  -- defaults.lua).

  cursorline = {
    enable = true,
    show_events = { "InsertLeave", "WinEnter" },
    hide_events = { "InsertEnter", "WinLeave" },
  },

  -- Jump-to-last-location used to be configured here too -- removed
  -- 2026-09-12, autocmds.text is the one owner now (see its own
  -- defaults.lua).

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
