---@module 'bindings.mappings.buffer_jump'
--- Numeric buffer jump (`<leader>1`..`<leader>0`). Resolves a buffer order
--- (`lib.nvim.buf_win_tab.tab_buffers`: `vim.t.bufs`, then several fallbacks), then switches via
--- `ui.bindings.keymaps.tabufline.state.goto_buf` if present (respects
--- tabline winfixbuf logic), else `nvim_set_current_buf`.

local notify = require("lib.nvim.notify").create("[bindings.mappings.buffer_jump]")

local M = {}

local api = vim.api
local nvim_buf_is_valid = api.nvim_buf_is_valid

--- The buffers of the current tab in the order the user sees them: `vim.t.bufs`, then `tabpagebuflist`, the
--- tab's windows, `getbufinfo` (see `lib.nvim.buf_win_tab.tab_buffers`).
---@return number[] buflist
local function robust_tabpage_buflist()
  return (require("lib.nvim.buf_win_tab.tab_buffers").list())
end

--- Attempt to use ui.nvim's own tabufline state goto_buf if available.
--- Falls back to nvim_set_current_buf when not present.
---@param bufnr number buffer id to switch to
local function switch_to_buffer(bufnr)
  if type(bufnr) ~= "number" then
    return
  end

  local ok, tabufline_state = pcall(require, "ui.bindings.keymaps.tabufline.state")
  if ok and type(tabufline_state) == "table" and type(tabufline_state.goto_buf) == "function" then
    local succ, err = pcall(tabufline_state.goto_buf, bufnr)
    if succ then
      return
    else
      notify.warn(string.format("ui.nvim tabufline goto_buf failed: %s", tostring(err)))
    end
  end

  -- If we reach here, fallback to directly setting the buffer in the window.
  -- Ensure buffer is valid and loaded before switching.
  if nvim_buf_is_valid(bufnr) and not api.nvim_buf_is_loaded(bufnr) then
    pcall(api.nvim_buf_load, bufnr)
  end
  if nvim_buf_is_valid(bufnr) then
    api.nvim_set_current_buf(bufnr)
  else
    notify.error(string.format("Failed to switch to buffer %s (invalid)", tostring(bufnr)))
  end
end

--- Go to buffer at visual position `pos` within the resolved buffer list.
---@param pos number 1-based index
local function goto_buffer_by_pos(pos)
  if type(pos) ~= "number" then
    notify.error("Invalid buffer index (not a number)")
    return
  end

  local buflist = robust_tabpage_buflist()
  if #buflist == 0 then
    notify.warn(
      "No buffers available to jump to (buflist empty). Ensure tabufline or buffers exist."
    )
    return
  end

  if pos < 1 or pos > #buflist then
    notify.warn(string.format("Buffer position %d out of range (1..%d)", pos, #buflist))
    return
  end

  local target = buflist[pos]
  if not target then
    notify.error(string.format("No buffer id found at position %d", pos))
    return
  end

  switch_to_buffer(target)
end

---@return nil
function M.setup()
  local map = require("lib.nvim.bindings.keymap")

  for i = 1, 9 do
    local lhs = "<leader>" .. tostring(i)
    map("n", lhs, function()
      goto_buffer_by_pos(i)
    end, { desc = string.format("[Buffers] Go to buffer %d", i) })
  end

  map("n", "<leader>0", function()
    goto_buffer_by_pos(10)
  end, { desc = "[Buffers] Go to buffer 10" })
end

return M
