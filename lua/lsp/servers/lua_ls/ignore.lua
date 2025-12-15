---@module 'lsp.servers.lua_ls.ignore'
--- Shared ignore configuration for filesystem scanning and LSP workspace settings.
--- This module centralizes ignore entries so multiple consumers (e.g. scan/prune
--- routines and language-server configuration) reuse the same canonical list.
---
--- The module exposes:
--- 1. `names()` -> string[] : raw directory basenames for path-level checks (fast set style).
--- 2. `as_set()` -> table<string, boolean> : a set keyed by basename for O(1) membership tests.
--- 3. `as_luals_patterns()` -> string[] : converted glob patterns suitable for `Lua.workspace.ignoreDir`.
--- 4. `normalize_for_platform(str)` helper to normalize separators / case if needed.
--- Notes:
--- - Comments in code are in English as requested.
--- - This module does textual normalization only; it does not perform IO.
local M = {}

--- Raw list of directory names commonly ignored.
--- @type string[]
M._names = require("lib.filesystem.ignore.list").as_luals_patterns()

--- Platform-normalize a name for consistent comparisons (no filesystem IO).
--- On Windows this could lower-case or normalize slashes if desired.
--- @param s string
--- @return string
local function normalize_for_platform(s)
  if type(s) ~= "string" then
    return s
  end
  -- keep this minimal: trim trailing slashes and collapse repeated separators
  s = s:gsub("[/\\]+$", "") -- strip trailing separators
  -- Optionally lower-case on Windows for case-insensitive comparisons.
  if package.config:sub(1, 1) == "\\" then
    s = s:lower()
  end
  return s
end

--- Return a copy of the base names list.
--- @return string[]
function M.names()
  local out = {}
  for i = 1, #M._names do
    out[i] = M._names[i]
  end
  return out
end

--- Return a set keyed by normalized basename for fast membership checks.
--- Example: set["node_modules"] == true
--- @return table<string, boolean>
function M.as_set()
  local t = {}
  for _, n in ipairs(M._names) do
    t[normalize_for_platform(n)] = true
  end
  return t
end

--- Convert base names into glob patterns for lua_ls workspace.ignoreDir.
--- lua_ls expects patterns like "**/node_modules" to ignore any nested occurrences.
--- We produce two patterns per name to be robust: "**/name" and "name" (root-level).
--- @return string[]
function M.as_luals_patterns()
  local out = {}
  for _, n in ipairs(M._names) do
    local norm = normalize_for_platform(n)
    -- ignore at any depth
    out[#out + 1] = "**/" .. norm
    -- also explicit root-level entry (some configs use root-relative)
    out[#out + 1] = norm
  end
  return out
end

return M
