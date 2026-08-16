---@module 'bindings.mappings.buffer_jump'
--- Numeric buffer jump that leverages nvchad.tabufline's goto_buf when available.
--- The module resolves a sensible buffer order (prefer vim.t.bufs), then jumps
--- to the selected buffer. If nvchad.tabufline.goto_buf is present it will be
--- used to perform the switch (this respects tabline-specific winfixbuf logic).
--- Otherwise a safe fallback to `nvim_set_current_buf` is used.

local notify = require("lib.nvim.notify").create("[bindings.mappings.buffer_jump]")

local M = {}

local api = vim.api
local nvim_buf_is_valid = api.nvim_buf_is_valid

--- Deduplicate numbers while preserving order.
---@param arr number[] array of buffer-ids
---@return number[] unique ordered array
local function unique_ordered(arr)
  local seen = {}
  local out = {}
  for _, v in ipairs(arr) do
    if type(v) == "number" and not seen[v] then
      seen[v] = true
      out[#out + 1] = v
    end
  end
  return out
end

--- Try to read buffer list from vim.t.bufs (nvchad tabufline storage).
---@return number[] buflist
local function buflist_from_vim_t_bufs()
  local t = vim.t.bufs
  if type(t) == "table" and #t > 0 then
    return unique_ordered(t)
  end
  return {}
end

--- Parse various possible return types from tabpagebuflist into a Lua array.
---@return number[] buflist
local function parse_tabpagebuflist_raw()
  local ok, raw = pcall(vim.fn.tabpagebuflist, 0)
  if not ok then
    return {}
  end
  if type(raw) == "table" then
    return raw
  end
  if type(raw) == "string" then
    local t = {}
    for num in raw:gmatch("%d+") do
      t[#t + 1] = tonumber(num)
    end
    return t
  end
  return {}
end

--- Build buffer list by iterating visible windows in current tabpage (window order).
---@return number[] buflist
local function build_from_windows()
  local ok, wins = pcall(api.nvim_tabpage_list_wins, 0)
  if not ok or type(wins) ~= "table" then
    return {}
  end
  local t = {}
  for _, w in ipairs(wins) do
    local buf = api.nvim_win_get_buf(w)
    if buf and nvim_buf_is_valid(buf) then
      t[#t + 1] = buf
    end
  end
  return unique_ordered(t)
end

--- Fallback: get all listed buffers.
---@return number[] buflist
local function fallback_listed_buffers()
  local ok, infos = pcall(vim.fn.getbufinfo, { buflisted = 1 })
  if not ok or type(infos) ~= "table" then
    return {}
  end
  local t = {}
  for _, info in ipairs(infos) do
    if type(info.bufnr) == "number" then
      t[#t + 1] = info.bufnr
    end
  end
  return unique_ordered(t)
end

--- Compose a robust tabpage buffer list using multiple strategies.
---@return number[] buflist
local function robust_tabpage_buflist()
  local t = buflist_from_vim_t_bufs()
  if #t > 0 then
    return t
  end

  local t2 = parse_tabpagebuflist_raw()
  if #t2 > 0 then
    return unique_ordered(t2)
  end

  local winlist = build_from_windows()
  if #winlist > 0 then
    return winlist
  end

  local fallback = fallback_listed_buffers()
  if #fallback > 0 then
    return fallback
  end

  return {}
end

--- Attempt to use nvchad.tabufline's goto_buf function if available.
--- Falls back to nvim_set_current_buf when not present.
---@param bufnr number buffer id to switch to
local function switch_to_buffer(bufnr)
  if type(bufnr) ~= "number" then
    return
  end

  -- Try to require nvchad.tabufline and call its goto_buf (name used in tabufline source)
  local ok, tabufline = pcall(require, "nvchad.tabufline")
  if ok and type(tabufline) == "table" then
    -- prefer `goto_buf` if present (matches the tabufline implementation you quoted)
    if type(tabufline.goto_buf) == "function" then
      local succ, err = pcall(tabufline.goto_buf, bufnr)
      if succ then
        return
      else
        notify.warn(string.format("nvchad.tabufline.goto_buf failed: %s", tostring(err)))
      end
    end

    -- Some builds may expose a differently named function; try common variants defensively
    if type(tabufline.go_to) == "function" then
      local succ, err = pcall(tabufline.go_to, bufnr)
      if succ then
        return
      else
        notify.warn(string.format("nvchad.tabufline.go_to failed: %s", tostring(err)))
      end
    end
  end

  -- If we reach here, fallback to directly setting the buffer in the window.
  -- Ensure buffer is valid and loaded before switching.
  if nvim_buf_is_valid(bufnr) and not api.nvim_buf_is_loaded(bufnr) then
    pcall(api.nvim_buf_load, bufnr)
  end
  if nvim_buf_is_valid(bufnr) then
    api.nvim_set_current_buf(bufnr)
  else
    notify.error(string.format("Failed to switch to buffer %s (invalid)", tostring(bufnr)))
  end
end

--- Go to buffer at visual position `pos` within the resolved buffer list.
---@param pos number 1-based index
local function goto_buffer_by_pos(pos)
  if type(pos) ~= "number" then
    notify.error("Invalid buffer index (not a number)")
    return
  end

  local buflist = robust_tabpage_buflist()
  if #buflist == 0 then
    notify.warn("No buffers available to jump to (buflist empty). Ensure tabufline or buffers exist.")
    return
  end

  if pos < 1 or pos > #buflist then
    notify.warn(string.format("Buffer position %d out of range (1..%d)", pos, #buflist))
    return
  end

  local target = buflist[pos]
  if not target then
    notify.error(string.format("No buffer id found at position %d", pos))
    return
  end

  switch_to_buffer(target)
end

function M.setup()
  local map = vim.g.__map_helper
  if type(map) ~= "function" then
    map = require("lib.nvim.map")
  end

  for i = 1, 9 do
    local lhs = "<leader>" .. tostring(i)
    map("n", lhs, function()
      goto_buffer_by_pos(i)
    end, { desc = string.format("[Buffers] Go to buffer %d", i) })
  end

  map("n", "<leader>0", function()
    goto_buffer_by_pos(10)
  end, { desc = "[Buffers] Go to buffer 10" })
end

return M
