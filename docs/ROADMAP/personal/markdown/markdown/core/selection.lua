---@module 'custom.markdown.core.selection'
--- Normalized helpers for single-line Visual selections (charwise).

---@class MarkdownSelection
local M = {}

local api, fn = vim.api, vim.fn

---@param row integer
---@param scol0 integer
---@param ecol0 integer
---@return nil
function M.reselect_charwise(row, scol0, ecol0)
  fn.setpos("'<", { 0, row + 1, scol0 + 1, 0 })
  fn.setpos("'>", { 0, row + 1, ecol0 + 1, 0 })
  local seq = api.nvim_replace_termcodes("<Esc>gv", true, false, true)
  api.nvim_feedkeys(seq, "nx", false)
end

---@return integer|nil, integer|nil, integer|nil
function M.get_visual_range_single_line()
  local p1 = fn.getpos("'<")
  local p2 = fn.getpos("'>")
  local srow = p1[2] - 1
  local erow = p2[2] - 1
  local scol0 = p1[3] - 1
  local ecol0 = p2[3] - 1
  if srow ~= erow then
    return nil, nil, nil
  end
  if (erow < srow) or (erow == srow and ecol0 < scol0) then
    srow, erow, scol0, ecol0 = erow, srow, ecol0, scol0
  end
  local row = srow
  local line = api.nvim_buf_get_lines(0, row, row + 1, false)[1] or ""
  local len = #line
  if len == 0 then
    return nil, nil, nil
  end
  local function clamp(v, lo, hi)
    if v < lo then
      return lo
    elseif v > hi then
      return hi
    else
      return v
    end
  end
  scol0 = clamp(scol0, 0, math.max(0, len - 1))
  ecol0 = clamp(ecol0, 0, math.max(0, len - 1))
  if ecol0 < scol0 then
    return nil, nil, nil
  end
  return row, scol0, ecol0
end

return M
