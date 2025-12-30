---@module 'lsp.servers.lua_ls.build_library'
--- Build workspace library paths for lua_ls based on project root.
--- Now includes all @types directories in project structure

local find_type_dirs = require("lsp.servers.lua_ls.find_type_dirs")

--- Build a table of library paths for a given project root.
--- Format: { [path] = true, [path2] = true, ... }
---
--- @param root string Project root directory
--- @return table<string, boolean> Map of library paths to include
return function(root)
  if not root or type(root) ~= "string" or root == "" then
    return {}
  end

  local library = {}

  -- ===================================================================
  -- THIRD-PARTY LIBRARIES (${3rd}/...)
  -- ===================================================================
  library["${3rd}/luv/library"] = true
  library["${3rd}/busted/library"] = true

  -- ===================================================================
  -- PROJECT-SPECIFIC TYPE DIRECTORIES
  -- ===================================================================
  -- CRITICAL: Include ALL @types and types directories in project
  local type_dirs = find_type_dirs(root, {
    max_results = 200,  -- Increased from 100
    max_depth = 15      -- Increased from 10
  })

  for _, dir in ipairs(type_dirs) do
    library[dir] = true
  end

  -- ===================================================================
  -- EXPLICIT @TYPES PATTERN SEARCH
  -- ===================================================================
  -- Additional explicit search for common patterns that might be missed
  local explicit_patterns = {
    root .. "/lua/@types",
    root .. "/lua/types",
    root .. "/@types",
    root .. "/types",
  }

  for _, pattern in ipairs(explicit_patterns) do
    local stat = (vim.uv or vim.loop).fs_stat(pattern)
    if stat and stat.type == "directory" then
      library[pattern] = true
    end
  end

  -- ===================================================================
  -- NEOVIM RUNTIME PATHS
  -- ===================================================================
  -- Include ALL Neovim runtime paths for vim.* API recognition
  local runtime_paths = vim.api.nvim_get_runtime_file("", true) or {}
  for _, path in ipairs(runtime_paths) do
    library[path] = true
  end

  -- ===================================================================
  -- LUAROCKS DIRECTORIES
  -- ===================================================================
  local home = vim.fn.expand("~")
  local luarocks_paths = {
    home .. "/.luarocks/share/lua/5.1",
    home .. "/.luarocks/share/lua/5.4",
    "/usr/local/share/lua/5.1",
    "/usr/local/share/lua/5.4",
  }

  for _, path in ipairs(luarocks_paths) do
    local stat = (vim.uv or vim.loop).fs_stat(path)
    if stat and stat.type == "directory" then
      library[path] = true
    end
  end

  -- ===================================================================
  -- PROJECT-LOCAL DEPENDENCIES
  -- ===================================================================
  local local_dep_dirs = {
    root .. "/lua_modules/share/lua/5.1",
    root .. "/lua_modules/share/lua/5.4",
    root .. "/deps",
    root .. "/vendor",
  }

  for _, path in ipairs(local_dep_dirs) do
    local stat = (vim.uv or vim.loop).fs_stat(path)
    if stat and stat.type == "directory" then
      library[path] = true
    end
  end

  return library
end
