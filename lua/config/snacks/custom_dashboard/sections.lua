---@module 'config.snacks.custom_dashboard.sections'
--- Register the `my_sessions` section with snacks.dashboard before snacks.setup runs.
--- This file keeps the section registration idempotent and lightweight.

---@type table
local notify = require("lib.nvim.notify").create("[config.snacks.custom_dashboard.sections]")

local M = {}

local ok_dash, dash = pcall(require, "snacks.dashboard")
local ok_sessions, sessions = pcall(require, "config.snacks.custom_dashboard.sessions")
local fn = vim.fn

if not ok_dash or type(dash) ~= "table" then
  -- nothing to register now; sections module is safe to require later again.
  return M
end

--- Build sessions items for the dashboard.
--- @param _ any
--- @return table[]|nil
local function my_sessions_section(_)
  -- If sessions module not available, show placeholder
  if not ok_sessions or type(sessions.list_sessions) ~= "function" then
    return {
      {
        icon = " ",
        title = "Sessions not available",
        desc = "sessions module missing",
        action = function() end,
        hidden = false,
      },
    }
  end

  local files = sessions.list_sessions()
  if not files or #files == 0 then
    return {
      {
        icon = " ",
        title = "No sessions found",
        desc = fn.fnamemodify(sessions.get_root() or "", ":~"),
        action = function() end,
        hidden = false,
      },
    }
  end

  ---@type table[]
  local items = {}
  for i = 1, #files do
    local p = files[i]
    local name = fn.fnamemodify(p, ":t:r")
    items[i] = {
      icon = " ",
      title = name,
      action = (function(n)
        return function()
          local ok, res = pcall(function()
            return sessions.load(n)
          end)
          if not ok then
            notify.error("[custom_dashboard] session load failed: " .. tostring(res))
          end
        end
      end)(name),
    }
  end

  return items
end

-- Idempotent registration
dash.sections = dash.sections or {}
if type(dash.sections.my_sessions) ~= "function" then
  dash.sections.my_sessions = my_sessions_section
end

return M
