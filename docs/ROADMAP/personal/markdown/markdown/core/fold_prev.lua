---@module 'custom.markdown.core.fold_prev'
--- Fold the previous Markdown heading and center the view.
--- Safe wrappers around search + fold commands; no UI notifications here.

---@class MarkdownFoldPrev
local M = {}

local api, fn, cmd = vim.api, vim.fn, vim.cmd

--- Find previous heading (H1..H6, ATX or Setext H2) and move cursor there.
--- Returns true if a heading was found and the cursor moved.
---@return boolean
local function goto_prev_heading_any()
  -- Search previous ATX heading "##+ <text>"
  local found = fn.search("^#\\+\\s\\+\\S", "bWs") -- backward, wrap, no errors
  if found > 0 then
    return true
  end
  -- If not found, try a Setext H2 (line above a "---" underline)
  local cur = fn.line(".")
  for lnum = cur - 1, 2, -1 do
    local line = fn.getline(lnum)
    local nextl = fn.getline(lnum + 1)
    if line:match("%S") and nextl and nextl:match("^%s*%-%-+%s*$") then
      api.nvim_win_set_cursor(0, { lnum, 0 })
      return true
    end
  end
  return false
end

--- Fold the previous heading and center the window on it.
--- Idempotent and safe in non-markdown buffers (early return).
---@return nil
function M.fold_prev_heading_then_center()
  if vim.bo.filetype ~= "markdown" then
    return
  end
  local buf = api.nvim_get_current_buf()
  if not (buf and api.nvim_buf_is_valid(buf)) then
    return
  end

  local view = fn.winsaveview()
  local moved = goto_prev_heading_any()
  if not moved then
    fn.winrestview(view)
    return
  end

  -- Ensure folds are computed, then close the fold at the cursor and center.
  cmd("silent! normal! zx")
  cmd("silent! normal! zc")
  cmd("silent! normal! zz")
end

return M
