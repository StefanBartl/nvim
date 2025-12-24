-- config/telescope/open_background.lua
---@module 'config.telescope.open_background'
local action_state = require("telescope.actions.state")

local M = {}

---Open selected entry as background buffer
---@param prompt_bufnr integer
---@diagnostic disable-next-line: unused-local
function M.open_background(prompt_bufnr)
  local entry = action_state.get_selected_entry()

  if not entry then
    vim.notify("No entry selected", vim.log.levels.WARN)
    return
  end

  -- Extract path from various entry types
  local path = entry.path or entry.filename
  if not path and type(entry.value) == "string" then
    path = entry.value
  end

  if not path or path == "" then
    vim.notify("No valid path found", vim.log.levels.WARN)
    return
  end

  -- Expand to absolute path
  path = vim.fn.fnamemodify(path, ":p")

  -- Check if file exists
  if vim.fn.filereadable(path) ~= 1 then
    vim.notify(
      "File not readable: " .. path,
      vim.log.levels.ERROR
    )
    return
  end

  -- Add and load buffer
  local bufnr = vim.fn.bufadd(path)
  vim.fn.bufload(bufnr)

  -- Ensure buffer is listed
  vim.bo[bufnr].buflisted = true

  -- Show confirmation
  local filename = vim.fn.fnamemodify(path, ":t")
  vim.notify(
    "Opened in background: " .. filename,
    vim.log.levels.INFO
  )
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
