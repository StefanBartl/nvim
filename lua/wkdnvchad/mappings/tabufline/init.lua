---@module 'wkdnvchad.mappings.tabufline'
--- Custom buffer navigation without automatic centering

local nvchad_tabufline = require("lib.lazy").require("nvchad.tabufline")

local M = {}

local api = vim.api

---@nodiscard
---@param bufnr integer
---@return boolean
local function set_buf_no_center(bufnr)
  local ok, is_valid = pcall(api.nvim_buf_is_valid, bufnr)
  if ok and is_valid then
    local ok2 = pcall(api.nvim_set_current_buf, bufnr)
    return ok2
  end
  return false
end

-- Index des aktuellen Buffers
---@param bufnr integer
---@param bufs integer[]
---@return integer|nil
local function buf_index(bufnr, bufs)
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

---@nodiscard
---@return integer
local function cur_buf()
  local ok, bufnr = pcall(api.nvim_get_current_buf)
  return ok and bufnr or 0
end

---@return boolean
function M.next()
  -- WICHTIG: vim.t.bufs wird JEDES MAL frisch gelesen
  local bufs = vim.t.bufs
  if not bufs or #bufs == 0 then
    return false
  end

  local current = cur_buf()
  if current == 0 then
    return false
  end

  local idx = buf_index(current, bufs)
  if not idx then
    return set_buf_no_center(bufs[1])
  end

  local next_buf = (idx == #bufs) and bufs[1] or bufs[idx + 1]
  return set_buf_no_center(next_buf)
end

---@return boolean
function M.prev()
  -- WICHTIG: vim.t.bufs wird JEDES MAL frisch gelesen
  local bufs = vim.t.bufs
  if not bufs or #bufs == 0 then
    return false
  end

  local current = cur_buf()
  if current == 0 then
    return false
  end

  local idx = buf_index(current, bufs)
  if not idx then
    return set_buf_no_center(bufs[1])
  end

  local prev_buf = (idx == 1) and bufs[#bufs] or bufs[idx - 1]
  return set_buf_no_center(prev_buf)
end

---@param n integer
---@return boolean
function M.move_next_n(n)
  if type(n) ~= "number" or n < 1 then
    return false
  end

  local success = true
  for _ = 1, n do
    if not M.next() then
      success = false
      break
    end

    -- KRITISCH: Kurze Pause, damit NvChad vim.t.bufs aktualisieren kann
    vim.cmd("redraw")
  end
  return success
end

---@param n integer
---@return boolean
function M.move_prev_n(n)
  if type(n) ~= "number" or n < 1 then
    return false
  end

  local success = true
  for _ = 1, n do
    if not M.prev() then
      success = false
      break
    end

    -- KRITISCH: Kurze Pause, damit NvChad vim.t.bufs aktualisieren kann
    vim.cmd("redraw")
  end
  return success
end

--- Close the current buffer, and repeat `count` times.
---@param n integer
---@return boolean
function M.close_n_buffers(n)
  if type(n) ~= "number" or n < 1 then
    return false
  end

  -- Lazy-load nvchad.tabufline only when closing buffers
  if not nvchad_tabufline then
    local ok, mod = pcall(require, "nvchad.tabufline")
    if not ok then
      vim.notify(
        "[wkdnvchad.tabufline] Failed to load nvchad.tabufline",
        vim.log.levels.ERROR
      )
      return false
    end
    nvchad_tabufline = mod
  end

  if type(nvchad_tabufline.close_buffer) ~= "function" then
    vim.notify(
      "[wkdnvchad.tabufline] close_buffer not available",
      vim.log.levels.WARN
    )
    return false
  end
  local success = true

  for _ = 1, n do
    local ok = pcall(nvchad_tabufline.close_buffer)
    if not ok then
      success = false
      break
    end

    -- Auch hier: Pause für NvChad's Buffer-Update
    vim.cmd("redraw")
  end
  return success
end

return M
