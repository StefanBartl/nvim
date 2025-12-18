---@module 'config.neotree.helper.rel_path_to_require'
--- Converts a Neo-tree node to Lua require() string(s) and copies to clipboard
--- FIX: sollte nicht require('C:.Users.Bernhard.AppData.Local.nvim.lua.config.neotree.fzf_grep_picker') machen sondern require('config.neotree.fzf_grep_picker')


local M = {}
local fn = vim.fn
local notify = vim.notify
local path_helper = require("config.neotree.helper.node_to_path")

-- Normalize path for require(): remove leading 'lua/', replace slashes with dots, strip .lua and /init
local function path_to_module(path)
  -- normalize separators
  path = path:gsub("\\", "/")

  -- remove leading 'lua/' if present
  path = path:gsub("^lua/", "")

  -- remove .lua extension
  path = path:gsub("%.lua$", "")

  -- remove trailing /init
  path = path:gsub("/init$", "")

  -- replace slashes with dots
  path = path:gsub("/", ".")

  return path
end

-- recursively gather all lua files under a directory
---@param dir string absolute path
---@return string[] list of module paths suitable for require()
local function gather_lua_files(dir)
  local results = {}
  local entries = fn.readdir(dir)
  for _, entry in ipairs(entries) do
    local full_path = fn.fnamemodify(dir .. "/" .. entry, ":p")
    if fn.isdirectory(full_path) == 1 then
      local child_results = gather_lua_files(full_path)
      vim.list_extend(results, child_results)
    elseif full_path:match("%.lua$") then
      local rel_path, _ = path_helper({ path = full_path }, "relative")
      if rel_path then
        table.insert(results, path_to_module(rel_path))
      end
    end
  end
  return results
end

---@param node table Neo-tree node
---@param opts table {relative = boolean}
function M.copy_as_require(node, opts)
  opts = opts or {}
  if not node then
    notify("No node provided", vim.log.levels.WARN)
    return
  end

  local path, msg = path_helper(node, "relative", { base_dir = false })
  if not path then
    notify(msg or "no path", vim.log.levels.WARN)
    return
  end

  local modules = {}
  if fn.isdirectory(path) == 1 then
    -- folder: gather all lua files recursively
    modules = gather_lua_files(path)
  else
    table.insert(modules, path_to_module(path))
  end

  if #modules == 0 then
    notify("No Lua files found", vim.log.levels.WARN)
    return
  end

  local require_lines = {}
  for _, mod in ipairs(modules) do
    table.insert(require_lines, ("require('%s')"):format(mod))
  end

  vim.fn.setreg("+", table.concat(require_lines, "\n"))
  notify(("Copied %d require() string(s) to clipboard"):format(#require_lines), vim.log.levels.INFO)
end

return M
