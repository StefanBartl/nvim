---@module 'autocmds.terminals.defaults'

--- CDX: config fields undocumented — add a one-line note per field

---@type AutoCmds.Term.Cfg
local AUTOCMDS_TERMINALS_DEFAULTS = {
  numbers = {
    enable = true,
    events = { "TermOpen" },
  },
  kitty = {
    enable = true,
    enter_padding = 0,
    enter_margin = 0,
    leave_padding = 20,
    leave_margin = 10,
  },
  auto_insert = {
    enable = false,
    events = { "TermOpen" }, -- Alternative: add "TermEnter" if one prefers aggressive insert-on-focus.
  },
}

local M = {}

---@return AutoCmds.Term.Cfg
function M.get_defaults()
  return AUTOCMDS_TERMINALS_DEFAULTS
end

return M
