---@module 'config.fzf.actions.wrapped'
---@description fzf-lua custom actions with proper action wrappers

local M = {}

local fn = vim.fn
local notify = vim.notify

---Check if path ends with directory separator
---@param path string
---@return boolean
local function ends_with_separator(path)
  return path:match("[/\\]$") ~= nil
end

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

---Create file or directory
---@param parent_dir string Parent directory path
---@param name string Name of file/folder to create
---@return boolean success
local function create_entry(parent_dir, name)
  local full_path = fn.resolve(parent_dir .. "/" .. name)

  if ends_with_separator(name) then
    -- Directory creation
    local dir_path = full_path:gsub("[/\\]$", "")
    local ok, err = pcall(fn.mkdir, dir_path, "p")
    if not ok then
      notify(("Failed to create directory: %s"):format(err), vim.log.levels.ERROR)
      return false
    end
    notify(("Directory created: %s"):format(fn.fnamemodify(dir_path, ":t")), vim.log.levels.INFO)
    return true
  else
    -- File creation
    if fn.filereadable(full_path) == 1 then
      notify("File already exists", vim.log.levels.WARN)
      return false
    end

    local parent = fn.fnamemodify(full_path, ":h")
    if fn.isdirectory(parent) == 0 then
      fn.mkdir(parent, "p")
    end

    local file = io.open(full_path, "w")
    if file then
      file:close()
      notify(("File created: %s"):format(fn.fnamemodify(full_path, ":t")), vim.log.levels.INFO)

      vim.schedule(function()
        vim.cmd("edit " .. fn.fnameescape(full_path))
      end)

      return true
    else
      notify("Failed to create file", vim.log.levels.ERROR)
      return false
    end
  end
end

---Get wrapped actions for fzf-lua
---@return table actions
function M.get()
  return {
    -- Background buffer open (keeps picker open)
    ["ctrl-o"] = function(selected, opts)
      local path = get_path_from_entry(selected)

      if not path then
        notify("No valid path found", vim.log.levels.WARN)
        return
      end

      if fn.filereadable(path) ~= 1 then
        notify("File not readable: " .. fn.fnamemodify(path, ":t"), vim.log.levels.ERROR)
        return
      end

      local bufnr = fn.bufadd(path)
      pcall(fn.bufload, bufnr)
      pcall(function()
        vim.bo[bufnr].buflisted = true
      end)

      notify("Buffered: " .. fn.fnamemodify(path, ":t"), vim.log.levels.INFO)

      -- Resume picker
      vim.defer_fn(function()
        require("fzf-lua").resume()
      end, 50)
    end,

    ["shift-enter"] = function(selected, opts)
      local path = get_path_from_entry(selected)

      if not path then
        notify("No valid path found", vim.log.levels.WARN)
        return
      end

      if fn.filereadable(path) ~= 1 then
        notify("File not readable: " .. fn.fnamemodify(path, ":t"), vim.log.levels.ERROR)
        return
      end

      local bufnr = fn.bufadd(path)
      pcall(fn.bufload, bufnr)
      pcall(function()
        vim.bo[bufnr].buflisted = true
      end)

      notify("Buffered: " .. fn.fnamemodify(path, ":t"), vim.log.levels.INFO)

      -- Resume picker
      vim.defer_fn(function()
        require("fzf-lua").resume()
      end, 50)
    end,

    -- File/folder creation (closes picker)
    ["ctrl-a"] = function(selected, opts)
      local path = get_path_from_entry(selected)

      if not path then
        notify("No valid path found", vim.log.levels.WARN)
        return
      end

      local parent_dir
      if fn.isdirectory(path) == 1 then
        parent_dir = path
      else
        parent_dir = fn.fnamemodify(path, ":h")
      end

      if not parent_dir or parent_dir == "" then
        notify("Could not determine parent directory", vim.log.levels.ERROR)
        return
      end

      -- Ensure picker is closed, then show input
      vim.defer_fn(function()
        vim.ui.input({
          prompt = "Create in " .. fn.fnamemodify(parent_dir, ":~:.") .. " (/ for folder): ",
          default = "",
        }, function(input)
          if not input or input == "" then
            return
          end

          create_entry(parent_dir, input)
        end)
      end, 150)
    end,
  }
end

return M
