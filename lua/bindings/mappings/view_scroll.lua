---@module 'bindings.mappings.view_scroll'
--- Small helper module to scroll the window (view) without moving the cursor.
--- Usage:
---   local vs = require('view.scroll')
---   vs.view_scroll_down()               -- default: half window height
---   vs.view_scroll_down(100)            -- scroll view down 100 lines, cursor stays
---   vs.map_default_keys('<C-d>','<C-u>')-- remap <C-d>/<C-u> to view-only scrolling
local M = {}

--- Default behavior: treat any non-positive/omitted count as half window height.
--- @param count number? number of lines to scroll; if nil or <=0 use half window height
local function effective_count(count)
  if type(count) ~= "number" or count <= 0 then
    -- math.floor to get an integer line count
    return math.floor(vim.api.nvim_win_get_height(0) / 2)
  end
  return math.floor(count)
end

--- Scroll view down without moving cursor by 'count' lines.
--- @param count number? lines to scroll; if nil uses half window height
function M.view_scroll_down(count)
  local cnt = effective_count(count)
  -- Use vim.cmd normal! to run literal <C-E> repeatedly.
  -- The [[\<C-E>]] form ensures the <C-E> term is interpreted by normal mode.
  vim.cmd(("normal! %d%s"):format(cnt, [[\<C-E>]]))
end

--- Scroll view up without moving cursor by 'count' lines.
--- @param count number? lines to scroll; if nil uses half window height
function M.view_scroll_up(count)
  local cnt = effective_count(count)
  vim.cmd(("normal! %d%s"):format(cnt, [[\<C-Y>]]))
end

--- Convenience function to map keys for view-only scrolling.
--- @param key_down string key for view-scroll-down (e.g. '<C-d>')
--- @param key_up string key for view-scroll-up (e.g. '<C-u>')
function M.map_default_keys(key_down, key_up)
  -- Map in normal mode. The lambda uses v:count to preserve counts (works like 3<C-d>).
  vim.keymap.set("n", key_down, function()
    local c = vim.v.count
    if c == 0 then
      M.view_scroll_down()
    else
      M.view_scroll_down(c)
    end
  end, { silent = true, desc = "View-only scroll down" })

  vim.keymap.set("n", key_up, function()
    local c = vim.v.count
    if c == 0 then
      M.view_scroll_up()
    else
      M.view_scroll_up(c)
    end
  end, { silent = true, desc = "View-only scroll up" })
end

return M
