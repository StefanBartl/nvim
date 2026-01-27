---@module 'autocmds.benchmarks.context.cache'
---@brief Generic cache infrastructure for event handlers
---@description
--- Provides TTL-based and tick-based caching for expensive computations.
--- Auto-invalidation on TextChanged/BufWritePost.

local M = {}

local api = vim.api

---@class CacheEntry
---@field value any
---@field tick integer Buffer changedtick when cached
---@field timestamp number os.clock() when cached
---@field ttl number? Time-to-live in seconds

--- Global cache storage (weak keys for auto-cleanup)
local caches = setmetatable({}, { __mode = "k" })

--- Statistics per cache namespace
local stats = {}

--- Create or get a cache namespace
---@param name string Unique cache identifier
---@param opts table? { ttl: number, max_size: number }
---@return table cache
function M.namespace(name, opts)
  opts = opts or {}

  if not caches[name] then
    caches[name] = setmetatable({}, { __mode = "k" })
    stats[name] = {
      hits = 0,
      misses = 0,
      invalidations = 0,
      evictions = 0,
    }
  end

  local cache = caches[name]
  local namespace_stats = stats[name]

  return {
    --- Get value from cache
    ---@param key any
    ---@param bufnr integer? For tick-based validation
    ---@return any|nil
    get = function(key, bufnr)
      local entry = cache[key]

      if not entry then
        namespace_stats.misses = namespace_stats.misses + 1
        return nil
      end

      -- TTL check
      if opts.ttl and entry.ttl then
        local age = os.clock() - entry.timestamp
        if age > entry.ttl then
          cache[key] = nil
          namespace_stats.evictions = namespace_stats.evictions + 1
          namespace_stats.misses = namespace_stats.misses + 1
          return nil
        end
      end

      -- Tick-based validation
      if bufnr and entry.tick then
        local current_tick = api.nvim_buf_get_changedtick(bufnr)
        if current_tick ~= entry.tick then
          cache[key] = nil
          namespace_stats.evictions = namespace_stats.evictions + 1
          namespace_stats.misses = namespace_stats.misses + 1
          return nil
        end
      end

      namespace_stats.hits = namespace_stats.hits + 1
      return entry.value
    end,

    --- Set value in cache
    ---@param key any
    ---@param value any
    ---@param bufnr integer? For tick-based caching
    set = function(key, value, bufnr)
      local entry = {
        value = value,
        timestamp = os.clock(),
        ttl = opts.ttl,
      }

      if bufnr then
        entry.tick = api.nvim_buf_get_changedtick(bufnr)
      end

      cache[key] = entry
    end,

    --- Invalidate specific key
    ---@param key any
    invalidate = function(key)
      if cache[key] then
        cache[key] = nil
        namespace_stats.invalidations = namespace_stats.invalidations + 1
      end
    end,

    --- Clear entire cache
    clear = function()
      local count = 0
      for _ in pairs(cache) do
        count = count + 1
      end
      caches[name] = setmetatable({}, { __mode = "k" })
      cache = caches[name]
      namespace_stats.invalidations = namespace_stats.invalidations + count
    end,

    --- Get statistics
    stats = function()
      local total = namespace_stats.hits + namespace_stats.misses
      return {
        name = name,
        hits = namespace_stats.hits,
        misses = namespace_stats.misses,
        invalidations = namespace_stats.invalidations,
        evictions = namespace_stats.evictions,
        total_requests = total,
        hit_rate = total > 0 and (namespace_stats.hits / total * 100) or 0,
      }
    end,
  }
end

--- Auto-invalidation setup (call once in init.lua)
function M.setup_auto_invalidation()
  local aug = api.nvim_create_augroup("AutocmdCacheInvalidation", { clear = true })

  -- Invalidate on text changes
  api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
    group = aug,
    callback = function(ev)
      for name, cache_obj in pairs(caches) do
        -- Invalidate all entries for this buffer
        local invalidated = 0
        for key, entry in pairs(cache_obj) do
          if entry.tick and api.nvim_buf_is_valid(ev.buf) then
            local current_tick = api.nvim_buf_get_changedtick(ev.buf)
            if entry.tick ~= current_tick then
              cache_obj[key] = nil
              invalidated = invalidated + 1
            end
          end
        end

        if invalidated > 0 and stats[name] then
          stats[name].invalidations = stats[name].invalidations + invalidated
        end
      end
    end,
    desc = "Auto-invalidate caches on buffer changes",
  })

  -- Full invalidation on write
  api.nvim_create_autocmd("BufWritePost", {
    group = aug,
    callback = function()
      for name in pairs(caches) do
        caches[name] = setmetatable({}, { __mode = "k" })
      end
    end,
    desc = "Clear all caches on buffer write",
  })
end

--- Get all cache statistics
---@return table[]
function M.get_all_stats()
  local all_stats = {}
  for name in pairs(caches) do
    local total = stats[name].hits + stats[name].misses
    table.insert(all_stats, {
      name = name,
      hits = stats[name].hits,
      misses = stats[name].misses,
      invalidations = stats[name].invalidations,
      evictions = stats[name].evictions,
      total_requests = total,
      hit_rate = total > 0 and (stats[name].hits / total * 100) or 0,
    })
  end
  return all_stats
end

--- Print all statistics
function M.print_all_stats()
  local all_stats = M.get_all_stats()

  print("Cache Statistics:")
  print(string.format("%-30s %8s %8s %8s %8s %10s",
    "Namespace", "Hits", "Misses", "Invalid", "Evict", "Hit Rate"))
  print(string.rep("-", 80))

  for _, stat in ipairs(all_stats) do
    print(string.format("%-30s %8d %8d %8d %8d %9.2f%%",
      stat.name,
      stat.hits,
      stat.misses,
      stat.invalidations,
      stat.evictions,
      stat.hit_rate
    ))
  end
end

return M
