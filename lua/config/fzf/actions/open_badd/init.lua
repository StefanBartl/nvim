---@module 'config.fzf.actions.open_badd'
---@description Open file in background buffer without closing fzf-lua

local M = {}

local fn = vim.fn
local notify = vim.notify

---Extract file path from fzf-lua entry
---@param selected table|string fzf-lua selected entry
---@return string|nil path Absolute file path
local function get_path_from_entry(selected)
  local path

  if type(selected) == "string" then
    path = selected
  elseif type(selected) == "table" then
    path = selected.path or selected.filename or selected[1]
  end

  if not path or path == "" then
    return nil
  end

  -- Remove fzf formatting
  path = path:gsub("^%s*\27%[[%d;]*m*", "")
  path = path:gsub("^%s*[^ ]*%s+", "")
  path = path:gsub("\27%[[%d;]*m", "")
  path = path:gsub("^%s+", ""):gsub("%s+$", "")

  -- Expand to absolute path
  path = fn.fnamemodify(path, ":p")

  return path
end

---Open selected entry as background buffer
---@param selected table|string fzf-lua selected entry
---@param opts table fzf-lua options
---@return boolean continue Continue fzf-lua picker
---@diagnostic disable-next-line: unused-local
function M.open_badd(selected, opts)
  -- Debug output
  notify("[DEBUG] open_badd triggered", vim.log.levels.INFO)
  notify("[DEBUG] selected type: " .. type(selected), vim.log.levels.INFO)

  local path = get_path_from_entry(selected)

  if not path then
    notify("No valid path found", vim.log.levels.WARN)
    return true  -- Keep picker open
  end

  notify("[DEBUG] path: " .. path, vim.log.levels.INFO)

  -- Check if file exists and is readable
  if fn.filereadable(path) ~= 1 then
    notify("File not readable: " .. fn.fnamemodify(path, ":t"), vim.log.levels.ERROR)
    return true  -- Keep picker open
  end

  -- Add buffer to buffer list
  local bufnr = fn.bufadd(path)

  -- Load buffer content
  local ok = pcall(fn.bufload, bufnr)
  if not ok then
    notify("Failed to load buffer: " .. fn.fnamemodify(path, ":t"), vim.log.levels.ERROR)
    return true  -- Keep picker open
  end

  -- Ensure buffer is listed
  pcall(function()
    vim.bo[bufnr].buflisted = true
  end)

  -- Show confirmation
  local filename = fn.fnamemodify(path, ":t")
  notify("Buffered: " .. filename, vim.log.levels.INFO)

  return true  -- Keep picker open
end

return M
