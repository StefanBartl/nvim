---@module 'config.snacks.custom_dashboard.sections'
--- Snacks dashboard section registration.
--- Exposes a function that registers the `my_sessions` section with snacks.dashboard.
--- Delegates session listing/loading to sessions.lua.

local M = {}

local ok_sessions, sessions = pcall(require, "config.snacks.custom_dashboard.sessions")

-- If snacks dashboard is unavailable, do nothing quietly.
local ok_dash, dash = pcall(require, "snacks.dashboard")
if not ok_dash or type(dash) ~= "table" then
  return M
end

--- Build the sessions section used by Snacks.
--- Returns a snacks.dashboard.Section (array of items) or nil.
---@param _ any
---@return table|nil
local function my_sessions_section(_)
  -- robust dependencies
  local fn = vim.fn

  -- if sessions infrastructure missing, show placeholder
  if not ok_sessions or type(sessions.list_sessions) ~= "function" then
    return {
      { icon = " ", title = "Sessions not available", desc = "sessions module missing", action = function() end, hidden = false },
    }
  end

  local files = sessions.list_sessions()
  if not files or #files == 0 then
    return {
      { icon = " ", title = "No sessions found", desc = fn.fnamemodify(sessions.get_root(), ":~"), action = function() end, hidden = false },
    }
  end

  local n = #files
  local items = { [n] = false }
  for i = 1, n do
    local p = files[i]
    local name = fn.fnamemodify(p, ":t:r")
		---@diagnostic disable-next-line cannot assign table to boolean
    items[i] = {
      icon = " ",
      title = name,
      action = (function()
        -- closure captures name
        return function()
          local ok, res = sessions.load(name)
          if not ok then
            vim.notify("[custom_dashboard] session load failed: " .. tostring(res), vim.log.levels.ERROR)
          end
        end
      end)(),
    }
  end

  return items
end

-- Register section once (idempotent)
dash.sections = dash.sections or {}
if type(dash.sections.my_sessions) ~= "function" then
  dash.sections.my_sessions = my_sessions_section
end

return M
