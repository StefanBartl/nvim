---@module 'autocmds.context.window'
---@brief Window context factory
---@description
--- Provides window-specific context (cursor position, viewport, etc.)
--- Lighter than buffer context, mostly for UI-related handlers.

local M = {}

local api = vim.api

--- Lightweight cache (no tick validation needed)
local cache = {}

--- Statistics
M.stats = {
  hits = 0,
  misses = 0,
}

--- Get window context
---@param winid integer? Window handle (default: current)
---@return AutoCmds.Context.WindowCtx
function M.get(winid)
  winid = winid or api.nvim_get_current_win()

  if not api.nvim_win_is_valid(winid) then
    ---@type AutoCmds.Context.WindowCtx
    return {
      winid = winid,
      is_valid = false,
      bufnr = -1,
      cursor = {0, 0},
      topline = 0,
      botline = 0,
      width = 0,
      height = 0,
    }
  end

  -- Window context is cheap, but we still cache within same event
  if cache[winid] then
    M.stats.hits = M.stats.hits + 1
    return cache[winid]
  end

  M.stats.misses = M.stats.misses + 1

  local bufnr = api.nvim_win_get_buf(winid)
  local cursor = api.nvim_win_get_cursor(winid)
  local width = api.nvim_win_get_width(winid)
  local height = api.nvim_win_get_height(winid)

  -- Get visible range
  local view = vim.fn.winsaveview()
  local topline = view.topline or 1
  local botline = topline + height - 1

  local ctx = {
    winid = winid,
    is_valid = true,
    bufnr = bufnr,
    cursor = cursor,
    topline = topline,
    botline = botline,
    width = width,
    height = height,
  }

  -- Add methods to context table directly (for LSP)
  function ctx:is_cursor_in_range(start_line, end_line)
    local row = self.cursor[1]
    return row >= start_line and row <= end_line
  end

  function ctx:get_visible_lines()
    return self.botline - self.topline + 1
  end

  cache[winid] = ctx

 ---@type AutoCmds.Context.WindowCtx
  return ctx
end

--- Clear cache (call this at end of event processing)
function M.clear_cache()
  cache = {}
end

--- Invalidate specific window
---@param winid integer
function M.invalidate(winid)
  cache[winid] = nil
end

--- Get statistics
---@return table
function M.get_stats()
  local total = M.stats.hits + M.stats.misses
  return {
    hits = M.stats.hits,
    misses = M.stats.misses,
    total_requests = total,
    hit_rate = total > 0 and (M.stats.hits / total * 100) or 0,
  }
end

return M
