---@module 'config.telescope.actions.create_file'
---@description Create file/folder in current entry's directory using hover_select

local notify = require("lib.nvim.notify").create("[config.telescope.actions.create_file]")
local create_entry_core = require("lib.nvim.fs.create_entry")

local M = {}

local action_state = require("telescope.actions.state")
local fn = vim.fn

---Create file or directory, notify, and open newly created files
---@param parent_dir string Parent directory path
---@param name string Name of file/folder to create
---@return boolean success
local function create_entry(parent_dir, name)
  local ok, kind, path_or_err = create_entry_core(parent_dir, name)
  if not ok then
    notify.error(path_or_err)
    return false
  end

  if kind == "directory" then
    notify.info(("Directory created: %s"):format(fn.fnamemodify(path_or_err, ":t")))
  else
    notify.info(("File created: %s"):format(fn.fnamemodify(path_or_err, ":t")))
    vim.schedule(function()
      vim.cmd("edit " .. fn.fnameescape(path_or_err))
    end)
  end

  return true
end

---Create file/folder action for Telescope
---@param prompt_bufnr integer Telescope prompt buffer number
function M.create_file(prompt_bufnr)
  local entry = action_state.get_selected_entry()

  if not entry then
    notify.warn("No entry selected")
    return
  end

  -- Extract path from entry
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

  -- Get parent directory
  local parent_dir
  if fn.isdirectory(path) == 1 then
    parent_dir = path
  else
    parent_dir = fn.fnamemodify(path, ":h")
  end

  if not parent_dir or parent_dir == "" then
    notify.error("Could not determine parent directory")
    return
  end

  -- Close Telescope picker
  require("telescope.actions").close(prompt_bufnr)

  -- Directly show input prompt (skip hover_select intermediary)
  vim.schedule(function()
    vim.ui.input({
      prompt = "Create in " .. fn.fnamemodify(parent_dir, ":~:.") .. " (/ for folder): ",
      default = "",
    }, function(input)
      if not input or input == "" then
        return
      end

      create_entry(parent_dir, input)
    end)
  end)
end

---Get mappings for Telescope
---@return table mappings
function M.get_mappings()
  return {
    i = {
      ["<C-a>"] = M.create_file,
    },
    n = {
      ["<C-a>"] = M.create_file,
    },
  }
end

return M
