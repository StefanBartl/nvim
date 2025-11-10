---@module 'config.snacks.custom_dashboard.sessions'
--- Session I/O helpers and light cache.
--- Responsibilities:
--- - resolve sessions storage directory
--- - list session files with mtimes
--- - provide a safe wrapper around external `sessions` plugin load() function
--- - minimal in-memory cache to avoid re-statting on short intervals

local uv = vim.uv or vim.loop
local fn = vim.fn

---@class SessionsModule
---@field root string
---@field cache table
local M = {
  -- root will be initialized lazily
  root = "",
  cache = {
    files = nil,     -- cached file list (array of full paths)
    mtimes = nil,    -- table of mtimes keyed by path
    ts = 0,          -- timestamp (os.time) when cache was populated
    ttl = 1,         -- seconds to keep cache valid (short by default)
  },
}

--- Resolve storage root (configurable location)
--- @return string
function M.get_root()
  if M.root and type(M.root) == "string" and M.root ~= "" then
    return M.root
  end

	local path = fn.stdpath("config") .. "/lua/sessions/storage"
  M.root = path
  return M.root
end

--- Read and cache session files (fast path: glob)
--- Returns array of file paths (sorted by mtime desc)
--- @return string[] (may be empty)
function M.list_sessions()
  local root = M.get_root()
  local st = uv.fs_stat and uv.fs_stat(root)
  if not (st and st.type == "directory") then
    return {}
  end

  -- quick cache TTL check
  local now = os.time()
  if M.cache.files and (now - (M.cache.ts or 0) < (M.cache.ttl or 1)) then
    return M.cache.files
  end

  -- gather files
  local files = fn.glob(root .. "/*", false, true)
  if not files or #files == 0 then
    M.cache.files = {}
    M.cache.mtimes = {}
    M.cache.ts = now
    return {}
  end

  local n = #files
  local ix = { [n] = 0 }
  local mt = { [n] = 0 }
  for i = 1, n do
    ix[i] = i
    local s = uv.fs_stat(files[i])
    mt[i] = (s and s.mtime and s.mtime.sec) or 0
  end
  table.sort(ix, function(a, b) return mt[a] > mt[b] end)

  -- preallocate
  local out = { [n] = false }
  local mtimes_map = {}
  for k = 1, n do
    local p = files[ix[k]]
    out[k] = p
    mtimes_map[p] = mt[ix[k]] or 0
  end

  M.cache.files = out
  M.cache.mtimes = mtimes_map
  M.cache.ts = now
  return out
end

--- Safe wrapper to load a session via the external `sessions` plugin.
--- returns true, result on success; false, err on failure
--- @param name string  Name of session (without path)
--- @return boolean, any
function M.load(name)
  if type(name) ~= "string" or name == "" then
    return false, "invalid name"
  end
  -- resolve plugin
  local ok, S = pcall(require, "sessions")
  if not ok or not S then
    return false, "sessions plugin not found"
  end
  if type(S.load) ~= "function" then
    return false, "sessions.load not a function"
  end

  -- call with pcall
  local ok2, res = pcall(S.load, name)
  if not ok2 then
    return false, res
  end
  return true, res
end

--- Utility: clear cache (public)
function M.clear_cache()
  M.cache.files = nil
  M.cache.mtimes = nil
  M.cache.ts = 0
end

return M
