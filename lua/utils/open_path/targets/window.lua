---@module 'utils.open_path.targets.window'
--- Open under cursor in a new split window (vertical or horizontal).
--- Adds optional maximize/only behavior.

---@class TargetWindow
local T = {}

local H = require("utils.open_path.helpers")

--- Open a path in a split; optionally maximize or make it the only window.
--- This keeps backward compatibility for existing callers.
---
--- @param orientation "vertical"|"horizontal"   -- split orientation
--- @param require_existing boolean               -- if true, return when path does not exist
--- @param notify boolean                         -- show warnings if true
--- @param maximize boolean|nil                   -- if true, expand current window to full width+height (non-destructive)
--- @param close_others boolean|nil               -- if true, execute :only (destructive)
--- @return boolean
function T.open(orientation, require_existing, notify, maximize, close_others)
  local raw, line, col = H.token_under_cursor()
  if not raw then return false end

  local info = H.normalize_and_probe(raw)
  if require_existing and not info then
    return false
  end
  if not info then
    if notify then vim.notify("open_path: path does not exist", vim.log.levels.WARN) end
    return false
  end

  -- 1) create the split and open the file/dir buffer
  local cmd = (orientation == "horizontal") and "split" or "vsplit"
  vim.api.nvim_cmd({ cmd = cmd, args = { info.abs } }, {})

  -- 2) optional jump
  H.jump_if_needed(line, col)

  -- 3) post-open window shaping
  --    close_others wins over maximize (it also yields 100%/100%)
  if close_others then
    -- destructive: removes all other windows in the tab
    vim.cmd("only")
  elseif maximize then
    -- non-destructive: other windows remain at minimal sizes
    vim.cmd("wincmd |") -- make current window maximum width
    vim.cmd("wincmd _") -- make current window maximum height
    -- hint: `wincmd =` later re-equalizes window sizes if desired
  end

  return true
end

return T
