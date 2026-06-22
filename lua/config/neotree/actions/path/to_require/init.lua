---@module 'config.neotree.actions.path.to_require'
---@brief Converts a Neo-tree node to Lua require() string(s) and copies to clipboard

local notify = require("lib.nvim.notify").create("[config.neotree.actions.path.to_require]")

local M = {}

local fn = vim.fn

---Find the lua directory root for the given path
---@param path string absolute or relative path
---@return string|nil lua_root, string|nil relative_to_lua
local function find_lua_root(path)
  -- Normalize to absolute path
  local abs_path = fn.fnamemodify(path, ":p"):gsub("\\", "/")

  -- Try to find 'lua/' in the path
  local lua_idx = abs_path:find("/lua/")
  if lua_idx then
    local lua_root = abs_path:sub(1, lua_idx + 3) -- include '/lua'
    local rel_path = abs_path:sub(lua_idx + 5) -- after '/lua/'
    return lua_root, rel_path
  end

  -- If not found in path, check if we're in config directory
  local config_dir = fn.stdpath("config"):gsub("\\", "/")
  if abs_path:sub(1, #config_dir) == config_dir then
    local lua_root = config_dir .. "/lua"
    local rel_path = abs_path:sub(#lua_root + 2) -- +2 for the '/'
    return lua_root, rel_path
  end

  return nil, nil
end

---Normalize path for require(): replace slashes with dots, strip .lua and /init
---@param path string relative path from lua/ directory
---@return string module_path suitable for require()
local function path_to_module(path)
  -- normalize separators
  path = path:gsub("\\", "/")

  -- remove .lua extension
  path = path:gsub("%.lua$", "")

  -- remove trailing /init
  path = path:gsub("/init$", "")

  -- replace slashes with dots
  path = path:gsub("/", ".")

  return path
end

---Recursively gather all lua files under a directory
---@param dir string absolute path
---@param lua_root string the lua/ directory root
---@return string[] module_paths list of module paths suitable for require()
local function gather_lua_files(dir, lua_root)
  local results = {}
  local entries = fn.readdir(dir)

  for _, entry in ipairs(entries) do
    local full_path = fn.fnamemodify(dir .. "/" .. entry, ":p"):gsub("\\", "/")

    if fn.isdirectory(full_path) == 1 then
      local child_results = gather_lua_files(full_path, lua_root)
      vim.list_extend(results, child_results)
    elseif full_path:match("%.lua$") then
      -- Calculate path relative to lua_root
      if full_path:sub(1, #lua_root) == lua_root then
        local rel_path = full_path:sub(#lua_root + 2) -- +2 to skip '/'
        table.insert(results, path_to_module(rel_path))
      end
    end
  end

  return results
end

---Convert Neo-tree node to require() string(s)
---@param node table Neo-tree node
---@param opts? Cfg.NeoTree.Actions.PathToRequireOpts Options
---@return string[]|nil modules, string|nil error
function M.node_to_requires(node, opts)
  opts = vim.tbl_extend("force", {
    relative = false,
    show_preview = true,
  }, opts or {})

  if not node then
    return nil, "No node provided"
  end

  local path = node.path or (node.get_id and node:get_id())
  if not path or path == "" then
    return nil, "Node path is empty"
  end

  -- Find lua root directory
  local lua_root, rel_path = find_lua_root(path)
  if not lua_root then
    return nil, "Could not find lua/ directory in path"
  end

  local modules = {}

  -- Normalize path
  local abs_path = fn.fnamemodify(path, ":p"):gsub("\\", "/")

  if fn.isdirectory(abs_path) == 1 then
    -- Folder: gather all lua files recursively
    modules = gather_lua_files(abs_path, lua_root)
  else
    -- Single file
    if rel_path then
      table.insert(modules, path_to_module(rel_path))
    end
  end

  if #modules == 0 then
    return nil, "No Lua files found"
  end

  return modules, nil
end

---Copy node as require() string(s) to clipboard
---@param node table Neo-tree node
---@param opts? Cfg.NeoTree.Actions.PathToRequireOpts Options
---@return boolean success
function M.copy_as_require(node, opts)
  opts = opts or {}

  local modules, err = M.node_to_requires(node, opts)
  if not modules then
    notify.warn(err or "Failed to convert to require()")
    return false
  end

  local require_lines = {}
  for _, mod in ipairs(modules) do
    table.insert(require_lines, ("require('%s')"):format(mod))
  end

  local result = table.concat(require_lines, "\n")
  fn.setreg("+", result)

  if opts.show_preview then
    notify.info(
      ("Copied %d require() string(s) to clipboard:\n%s"):format(
        #require_lines,
        #require_lines <= 5 and result or (table.concat(require_lines, "\n", 1, 5) .. "\n...")
      )
    )
  end

  return true
end

return M
