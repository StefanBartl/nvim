---@module 'wkdnvchad.mappings.tabufline'
--- Custom buffer navigation without automatic centering

local lazy = require("lib.lazy")
local nvchad_tabufline = lazy.module("nvchad.tabufline")

local M = {}

local api = vim.api

-- Hilfsfunktion: aktuellen Buffer setzen ohne 'zz'
---@param bufnr integer
local function set_buf_no_center(bufnr)
  if api.nvim_buf_is_valid(bufnr) then
    api.nvim_set_current_buf(bufnr)
  end
end

-- Index des aktuellen Buffers
---@param bufnr integer
---@return integer|nil
local function buf_index(bufnr)
  local bufs = vim.t.bufs
  if not bufs then
    return nil
  end

  for i, b in ipairs(bufs) do
    if b == bufnr then
      return i
    end
  end
  return nil
end

---@return integer
local function cur_buf()
  return api.nvim_get_current_buf()
end

-- Nächster Buffer
function M.next()
  local bufs = vim.t.bufs
  if not bufs or #bufs == 0 then
    return
  end

  local curbufIndex = buf_index(cur_buf())

  if not curbufIndex then
    set_buf_no_center(bufs[1])
    return
  end

  local next_buf = (curbufIndex == #bufs) and bufs[1] or bufs[curbufIndex + 1]
  set_buf_no_center(next_buf)
end

-- Vorheriger Buffer
function M.prev()
  local bufs = vim.t.bufs
  if not bufs or #bufs == 0 then
    return
  end

  local curbufIndex = buf_index(cur_buf())

  if not curbufIndex then
    set_buf_no_center(bufs[1])
    return
  end

  local prev_buf = (curbufIndex == 1) and bufs[#bufs] or bufs[curbufIndex - 1]
  set_buf_no_center(prev_buf)
end

--- Move to the next buffer `n` times.
---@param n integer
function M.move_next_n(n)
  for _ = 1, n do
    pcall(M.next)
  end
end

--- Move to the previous buffer `n` times.
---@param n integer
function M.move_prev_n(n)
  for _ = 1, n do
    pcall(M.prev)
  end
end

--- Close the current buffer, and repeat `count` times.
---@param n integer
function M.close_n_buffers(n)
  local tabufline = nvchad_tabufline.get()

  if not tabufline or type(tabufline.close_buffer) ~= "function" then
    vim.notify(
      "nvchad.tabufline.close_buffer not available",
      vim.log.levels.WARN
    )
    return
  end

  for _ = 1, n do
    pcall(tabufline.close_buffer)
  end
end

return M
