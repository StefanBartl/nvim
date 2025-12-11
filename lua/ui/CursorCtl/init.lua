---@module 'ui.CursorCtl'

---@class CursorProgressCtl
---@field mode CursorProgressMode
local CursorCtl = { mode = "row_progress" }

--- Set mode explicitly (no-op on invalid input).
--- @param m string
--- @return nil
function CursorCtl.set_mode(m)
  if m == "classic" or m == "row_progress" or m == "col_progress" or m == "rows_cols_progress" or m == "off" then
    CursorCtl.mode = m
  end
end

--- Cycle through modes in a stable order.
--- @return string new_mode
function CursorCtl.toggle_mode()
  local order = { "classic", "row_progress", "col_progress", "rows_cols_progress", "off" }
  local idx = 1
  for i, v in ipairs(order) do
    if v == CursorCtl.mode then
      idx = i
      break
    end
  end
  idx = (idx % #order) + 1
  CursorCtl.mode = order[idx]
  return CursorCtl.mode
end

--- Get current mode.
--- @return string
function CursorCtl.get_mode()
  return CursorCtl.mode
end

return CursorCtl
