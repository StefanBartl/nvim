---@module 'hover-select.highlight'
--n Highlight management for hover-select cursor line

local M = {}

local api = vim.api

---Setup highlight group for current line
---@param winid integer Window ID
function M.setup(winid)
  -- Ensure cursorline is enabled
  api.nvim_set_option_value("cursorline", true, { win = winid })

  -- Define custom highlight group if it doesn't exist
  if vim.fn.hlexists("HoverSelectCursor") == 0 then
    M.define_default_highlights()
  end

  -- Link window's cursorline to custom highlight
  api.nvim_set_option_value("winhighlight", "CursorLine:HoverSelectCursor", { win = winid })
end

---Define default highlight groups
function M.define_default_highlights()
  -- Try to link to existing Neovim highlights first
  local has_pmenu = vim.fn.hlexists("PmenuSel") == 1

  if has_pmenu then
    api.nvim_set_hl(0, "HoverSelectCursor", { link = "PmenuSel" })
  else
    -- Fallback: define custom highlight
    api.nvim_set_hl(0, "HoverSelectCursor", {
      bg = "#3e4451",
      fg = "#abb2bf",
      bold = true,
    })
  end
end

---Update highlight for the given window
---@param winid integer Window ID
---@param hl_group string Highlight group name
function M.update(winid, hl_group)
  if not api.nvim_win_is_valid(winid) then
    return
  end

  api.nvim_set_option_value("winhighlight", "CursorLine:" .. hl_group, { win = winid })
end

return M
