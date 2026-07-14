---@module 'config.telescope.actions.open_badd'
---@description Open file in background buffer without closing Telescope

local notify = require("lib.nvim.notify").create("[config.telescope.actions.open_badd]")
local open_background = require("lib.nvim.buffer.open_background")

local M = {}

local action_state = require("telescope.actions.state")
local fn = vim.fn

---Open selected entry as background buffer
---@param prompt_bufnr integer Telescope prompt buffer number
---@diagnostic disable-next-line: unused-local
function M.open_badd(prompt_bufnr)
  local entry = action_state.get_selected_entry()

  if not entry then
    notify.warn("No entry selected")
    return
  end

  -- Extract path from various entry types
  local path = entry.path or entry.filename
  if not path and type(entry.value) == "string" then
    path = entry.value
  end

  if not path or path == "" then
    notify.warn("No valid path found")
    return
  end

  local ok, bufnr_or_err = open_background(path)
  if not ok then
    notify.error(bufnr_or_err)
    return
  end

  notify.info("Buffered: " .. fn.fnamemodify(path, ":t"))
end

---Get mappings for Telescope
---@return table mappings
function M.get_mappings()
  return {
    i = {
      ["<S-CR>"] = M.open_badd,
      ["<C-o>"] = M.open_badd, -- Alternative mapping
    },
    n = {
      ["<S-CR>"] = M.open_badd,
      ["<C-o>"] = M.open_badd,
    },
  }
end

return M
