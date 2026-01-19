---@module 'wkdnvchad.ui.tabufline'
--- Custom buffer navigation without automatic centering

local M = {}

-- Hilfsfunktion: aktuellen Buffer setzen ohne 'zz'
local function set_buf_no_center(bufnr)
  if vim.api.nvim_buf_is_valid(bufnr) then
    vim.api.nvim_set_current_buf(bufnr)
    -- kein 'zz', also keine Zentrierung
  end
end

-- Index des aktuellen Buffers
local function buf_index(bufnr)
  for i, b in ipairs(vim.t.bufs or {}) do
    if b == bufnr then
      return i
    end
  end
  return nil
end

local function cur_buf()
  return vim.api.nvim_get_current_buf()
end

-- Nächster Buffer
M.next = function()
  local bufs = vim.t.bufs
  local curbufIndex = buf_index(cur_buf())

  if not curbufIndex then
    set_buf_no_center(vim.t.bufs[1])
    return
  end

  set_buf_no_center((curbufIndex == #bufs and bufs[1]) or bufs[curbufIndex + 1])
end

-- Vorheriger Buffer
M.prev = function()
  local bufs = vim.t.bufs
  local curbufIndex = buf_index(cur_buf())

  if not curbufIndex then
    set_buf_no_center(vim.t.bufs[1])
    return
  end

  set_buf_no_center((curbufIndex == 1 and bufs[#bufs]) or bufs[curbufIndex - 1])
end

return M
