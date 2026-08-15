---@module 'wkdnvchad.ui.statusline.cursor_ctl'

---@class wkdnvchad.ui.statusline.cursor_ctl : WkdNvC.UI.Stl.CursorCtl.module
local cursor_ctl = { mode = "row_progress" }

--- Set mode explicitly (no-op on invalid input).
--- @param m WkdNvC.UI.Stl.CursorCtl.Progress.Mode
--- @return nil
function cursor_ctl.set_mode(m)
  if m == "classic" or m == "row_progress" or m == "col_progress" or m == "rows_cols_progress" or m == "off" then
    cursor_ctl.mode = m
  end
end

--- Cycle through modes in a stable order.
--- @return WkdNvC.UI.Stl.CursorCtl.Progress.Mode new_mode
function cursor_ctl.toggle_mode()
  local order = { "classic", "row_progress", "col_progress", "rows_cols_progress", "off" }
  local idx = 1
  for i, v in ipairs(order) do
    if v == cursor_ctl.mode then
      idx = i
      break
    end
  end
  idx = (idx % #order) + 1
  cursor_ctl.mode = order[idx]
  return cursor_ctl.mode
end

--- Get current mode.
--- @return WkdNvC.UI.Stl.CursorCtl.Progress.Mode
function cursor_ctl.get_mode()
  return cursor_ctl.mode
end

return cursor_ctl
