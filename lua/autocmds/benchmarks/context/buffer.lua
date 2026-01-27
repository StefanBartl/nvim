---@module 'autocmds.context.buffer'
---@brief Buffer context factory with intelligent caching
---@description
--- Provides a unified interface to buffer metadata and content.
--- Caches results based on buffer changedtick to avoid redundant API calls.

local M = {}

local api, bo = vim.api, vim.bo

--- Weak-keyed cache (auto-cleanup on buffer deletion)
local cache = setmetatable({}, { __mode = "k" })

--- Statistics for debugging
M.stats = {
  hits = 0,
  misses = 0,
  invalidations = 0,
}

--- Check if buffer should be processed
---@param ctx AutoCmds.Context.BufferCtx
---@param ignore_buftypes string[]?
---@param ignore_filetypes string[]?
---@return boolean
local function is_processable(ctx, ignore_buftypes, ignore_filetypes)
  if ignore_buftypes then
    for _, bt in ipairs(ignore_buftypes) do
      if ctx.buftype == bt then return false end
    end
  end

  if ignore_filetypes then
    for _, ft in ipairs(ignore_filetypes) do
      if ctx.filetype == ft then return false end
    end
  end

  return true
end

--- Get buffer context (cached by changedtick)
---@param bufnr integer? Buffer handle (default: current)
---@return AutoCmds.Context.BufferCtx
function M.get(bufnr)
  bufnr = bufnr or api.nvim_get_current_buf()

  -- Validate buffer exists
  if not api.nvim_buf_is_valid(bufnr) then
    ---@type AutoCmds.Context.BufferCtx
    return {
      bufnr = bufnr,
      is_valid = false,
      name = "",
      filetype = "",
      buftype = "",
      modifiable = false,
      modified = false,
      tick = 0,
      line_count = 0,
      size_bytes = 0,
    }
  end

  local tick = api.nvim_buf_get_changedtick(bufnr)

  -- Check cache
  if cache[bufnr] and cache[bufnr].tick == tick then
    M.stats.hits = M.stats.hits + 1
    return cache[bufnr]
  end

  M.stats.misses = M.stats.misses + 1

  -- Build context
  local name = api.nvim_buf_get_name(bufnr)
  local line_count = api.nvim_buf_line_count(bufnr)

  local ctx = {
    bufnr = bufnr,
    is_valid = true,
    name = name,
    filetype = bo[bufnr].filetype or "",
    buftype = bo[bufnr].buftype or "",
    modifiable = bo[bufnr].modifiable,
    modified = bo[bufnr].modified,
    tick = tick,
    line_count = line_count,
    size_bytes = #name + (line_count * 80), -- Rough estimate
  }

  -- Lazy line loading via metatable
  setmetatable(ctx, {
    __index = function(t, k)
      if k == "lines" then
        local lines = api.nvim_buf_get_lines(bufnr, 0, -1, false)
        rawset(t, "lines", lines)
        -- Update size estimate
        local total_bytes = 0
        for _, line in ipairs(lines) do
          total_bytes = total_bytes + #line + 1 -- +1 for newline
        end
        rawset(t, "size_bytes", total_bytes)
        return lines
      end
    end
  })

  -- Add methods to context table directly (for LSP)
  function ctx:is_normal()
    return self.buftype == "" and self.modifiable
  end

  function ctx:is_processable(ignore_buftypes, ignore_filetypes)
    return is_processable(self, ignore_buftypes, ignore_filetypes)
  end

  function ctx:has_filetype(ft)
    if type(ft) == "string" then
      return self.filetype == ft
    elseif type(ft) == "table" then
      for _, v in ipairs(ft) do
        if self.filetype == v then return true end
      end
    end
    return false
  end

  cache[bufnr] = ctx
  return ctx
end

--- Invalidate cache for buffer
---@param bufnr integer
function M.invalidate(bufnr)
  if cache[bufnr] then
    M.stats.invalidations = M.stats.invalidations + 1
    cache[bufnr] = nil
  end
end

--- Clear all cached contexts
function M.clear_all()
  cache = setmetatable({}, { __mode = "k" })
  M.stats.invalidations = M.stats.invalidations + 1
end

--- Get cache statistics
---@return table
function M.get_stats()
  local total = M.stats.hits + M.stats.misses
  return {
    hits = M.stats.hits,
    misses = M.stats.misses,
    invalidations = M.stats.invalidations,
    total_requests = total,
    hit_rate = total > 0 and (M.stats.hits / total * 100) or 0,
  }
end

--- Print statistics
function M.print_stats()
  local stats = M.get_stats()
  print(string.format([[
Buffer Context Cache Stats:
  Hits:          %d
  Misses:        %d
  Invalidations: %d
  Total:         %d
  Hit Rate:      %.2f%%
]],
    stats.hits,
    stats.misses,
    stats.invalidations,
    stats.total_requests,
    stats.hit_rate
  ))
end

return M
