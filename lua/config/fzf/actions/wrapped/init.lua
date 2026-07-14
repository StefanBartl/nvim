---@module 'config.fzf.actions.wrapped'
---@description fzf-lua custom actions with proper action wrappers

local notify = require("lib.nvim.notify").create("[config.fzf.actions.wrapped]")
local strip_ansi = require("lib.lua.strings").strip_ansi
local create_entry_core = require("lib.nvim.fs.create_entry")
local open_background = require("lib.nvim.buffer.open_background")

local M = {}

local fn = vim.fn

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

  -- Remove fzf formatting (ANSI colors, leading icon/prefix)
  path = path:gsub("^%s*\27%[[%d;]*m*", "")
  path = path:gsub("^%s*[^ ]*%s+", "")
  path = strip_ansi(path)
  path = path:gsub("^%s+", ""):gsub("%s+$", "")

  -- Expand to absolute path
  path = fn.fnamemodify(path, ":p")

  return path
end

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

---Get wrapped actions for fzf-lua
---@return table actions
function M.get()
  return {
    -- Background buffer open (keeps picker open)
    ["ctrl-o"] = function(selected, _)
      local path = get_path_from_entry(selected)

      if not path then
        notify.warn("No valid path found")
        return
      end

      local ok, bufnr_or_err = open_background(path)
      if not ok then
        notify.error(bufnr_or_err)
        return
      end

      notify.info("Buffered: " .. fn.fnamemodify(path, ":t"))

      -- Resume picker
      vim.defer_fn(function()
        require("fzf-lua").resume()
      end, 50)
    end,

    ["shift-enter"] = function(selected, _)
      local path = get_path_from_entry(selected)

      if not path then
        notify.warn("No valid path found")
        return
      end

      local ok, bufnr_or_err = open_background(path)
      if not ok then
        notify.error(bufnr_or_err)
        return
      end

      notify.info("Buffered: " .. fn.fnamemodify(path, ":t"))

      -- Resume picker
      vim.defer_fn(function()
        require("fzf-lua").resume()
      end, 50)
    end,

    -- File/folder creation (closes picker)
    ["ctrl-a"] = function(selected, _)
      local path = get_path_from_entry(selected)

      if not path then
        notify.warn("No valid path found")
        return
      end

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
