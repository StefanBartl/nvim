---@module 'config.telescope.open_background'
local notify = require("lib.nvim.notify").create("[config.telescope.open_background]")
local open_background_core = require("lib.nvim.buffer.open_background")

local action_state = require("telescope.actions.state")

local M = {}

---Open selected entry as background buffer
---@param prompt_bufnr integer
---@diagnostic disable-next-line: unused-local
function M.open_background(prompt_bufnr)
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

  local ok, bufnr_or_err = open_background_core(path)
  if not ok then
    notify.error(bufnr_or_err)
    return
  end

  notify.info("Opened in background: " .. vim.fn.fnamemodify(path, ":t"))
end

---Get static mappings table for background open (NOT attach_mappings)
---@return table mappings Table with i and n mode mappings
function M.get_mappings()
  return {
    i = {
      ["<S-CR>"] = M.open_background,
      ["<C-o>"] = M.open_background,
    },
    n = {
      ["<S-CR>"] = M.open_background,
      ["<C-o>"] = M.open_background,
    },
  }
end

---Attach mappings function (alternative approach if needed)
---@param _ integer
---@param map function
---@return boolean
function M.attach_mappings(_, map)
  map("i", "<S-CR>", M.open_background)
  map("n", "<S-CR>", M.open_background)
  map("i", "<C-o>", M.open_background)
  map("n", "<C-o>", M.open_background)
  return true
end

return M
