---@module 'config.telescope.actions.open_badd'
---@description Open file in background buffer without closing Telescope

local notify = require("lib.nvim.notify").create("[config.telescope.actions.open_badd]")

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

  -- Expand to absolute path
  path = fn.fnamemodify(path, ":p")

  -- Check if file exists and is readable
  if fn.filereadable(path) ~= 1 then
    notify.error("File not readable: " .. path)
    return
  end

  -- Add buffer to buffer list
  local bufnr = fn.bufadd(path)

  -- Load buffer content
  local ok = pcall(fn.bufload, bufnr)
  if not ok then
    notify.error("Failed to load buffer: " .. path)
    return
  end

  -- Ensure buffer is listed
  pcall(function()
    vim.bo[bufnr].buflisted = true
  end)

  -- Show confirmation
  local filename = fn.fnamemodify(path, ":t")
  notify.info("Buffered: " .. filename)
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
