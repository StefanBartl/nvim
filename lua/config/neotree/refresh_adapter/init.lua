---@module 'config.neotree.refresh_adapter'
--- Small adapter to refresh Neo-tree safely with proper types and quarantine awareness.

local M = {}
local watcher_quarantine = require("config.neotree.watcher_quarantine")

--- Resolve a valid source name from a state table or fall back to a default.
--- @param state table|string|nil  -- may be a state table or a direct source name
--- @param default string?         -- fallback source name, defaults to "filesystem"
--- @return string                 -- resolved source name
local function resolve_source_name(state, default)
  -- If a plain string was provided, use it directly.
  if type(state) == "string" and state ~= "" then
    return state
  end
  -- Try the common fields on the state table.
  if type(state) == "table" then
    local s = state.name or state.source or state.source_name
    if type(s) == "string" and s ~= "" then
      return s
    end
  end
  -- Final fallback.
  return default or "filesystem"
end

--- Refresh Neo-tree for the current tab, keeping the correct API types.
--- Now quarantine-aware: uses safe_refresh if quarantined.
--- @param state table|string|nil  -- state table or explicit source name
--- @param callback fun()|nil      -- optional callback per Neo-tree API
--- @return boolean                -- true if a refresh was requested
function M.refresh(state, callback)
  local src = resolve_source_name(state, "filesystem")

  -- Check if in quarantine
  if watcher_quarantine.is_quarantined() then
    -- Use quarantine-aware safe refresh
    watcher_quarantine.safe_refresh(src, callback)
    return true
  end

  -- Normal refresh path (no quarantine)
  local ok_mgr, manager = pcall(require, "neo-tree.sources.manager")
  if not ok_mgr or type(manager) ~= "table" or type(manager.refresh) ~= "function" then
    return false
  end

  -- Ensure callback is function or nil
  if type(callback) ~= "function" then
    callback = nil
  end

  -- Standard refresh
  manager.refresh(src, callback)
  return true
end

return M
