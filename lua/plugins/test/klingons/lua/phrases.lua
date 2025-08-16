---@module 'klingon_notify.phrases'
--- Default Klingon phrases per level and small helper utilities.
--- This module simply returns a typed table of phrases and icons.

local M = {}

--- Default phrases taken from standard tlhIngan Hol expressions.
---@type KlingonPhrasePack
local defaults = {
  phrases = {
    success = "Qapla'!", -- “Success!”
    error   = "Qagh!",   -- “Mistake!”
    warn    = "yIqIm!",  -- “Pay attention!”
    info    = "De'!",    -- “Information!”
  },
  icons = {
    success = "", -- leave as plain text if Nerd Font unavailable
    error   = "",
    warn    = "",
    info    = "",
  },
}

--- Return a deep copy of the default phrases/icons.
--- Using a copy prevents accidental mutation of module state.
---@return KlingonPhrasePack
function M.get_defaults()
  local function copy(tbl)
    local t = {}
    for k, v in pairs(tbl) do
      t[k] = type(v) == "table" and copy(v) or v
    end
    return t
  end
  return copy(defaults)
end

return M
