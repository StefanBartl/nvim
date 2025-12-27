---@module 'lsp.servers.lua_ls.build_library'
--- Build workspace library paths for lua_ls based on project root.
--- This module constructs a comprehensive list of directories that lua_ls should
--- scan for type definitions, including:
--- - Third-party library definitions (luv, busted, etc.)
--- - Project-specific type directories
--- - Dependencies from common package managers (luarocks, etc.)

-- Import the type directory scanner
local find_type_dirs = require("lsp.servers.lua_ls.find_type_dirs")

--- Build a table of library paths for a given project root.
--- Returns a table suitable for lua_ls workspace.library configuration.
--- Format: { [path] = true, [path2] = true, ... }
---
--- @param root string Project root directory
--- @return table<string, boolean> Map of library paths to include
return function(root)
  -- Guard against invalid input
  if not root or type(root) ~= "string" or root == "" then
    return {}
  end

  -- Initialize the library table
  local library = {}

  -- ===================================================================
  -- THIRD-PARTY LIBRARIES (${3rd}/...)
  -- ===================================================================

  -- lua_ls supports special ${3rd} placeholders that resolve to bundled
  -- type definitions shipped with the language server itself.
  -- These provide type annotations for popular Lua libraries.

  -- luv: Lua bindings to libuv (async I/O library used by Neovim)
  -- This provides types for vim.uv / vim.loop APIs
  library["${3rd}/luv/library"] = true

  -- busted: Popular Lua testing framework
  -- Provides types for describe, it, assert, etc.
  library["${3rd}/busted/library"] = true

  -- You can add more ${3rd} libraries here as needed:
  -- library["${3rd}/luasocket/library"] = true
  -- library["${3rd}/lfs/library"] = true
  -- etc.

  -- ===================================================================
  -- PROJECT-SPECIFIC TYPE DIRECTORIES
  -- ===================================================================

  -- Scan the project for "types" and "@types" directories
  -- These typically contain custom type definitions or TypeScript declaration files
  local type_dirs = find_type_dirs(root, {
    max_results = 100,  -- Limit to prevent excessive scanning
    max_depth = 10      -- Don't descend too deep into nested directories
  })

  -- Add each discovered type directory to the library
  for _, dir in ipairs(type_dirs) do
    library[dir] = true
  end

  -- ===================================================================
  -- LUAROCKS DIRECTORIES
  -- ===================================================================

  -- If the project uses LuaRocks, include its tree directories
  -- LuaRocks typically installs to ~/.luarocks or /usr/local/share/lua

  -- Try to detect local LuaRocks tree
  local home = vim.fn.expand("~")
  local luarocks_paths = {
    home .. "/.luarocks/share/lua/5.1",
    home .. "/.luarocks/share/lua/5.4",
    "/usr/local/share/lua/5.1",
    "/usr/local/share/lua/5.4",
  }

  -- Check if each LuaRocks path exists and add it
  for _, path in ipairs(luarocks_paths) do
    -- Use vim.loop.fs_stat to check existence without errors
    local stat = (vim.uv or vim.loop).fs_stat(path)
    if stat and stat.type == "directory" then
      library[path] = true
    end
  end

  -- ===================================================================
  -- PROJECT-LOCAL DEPENDENCIES
  -- ===================================================================

  -- Some projects keep dependencies in a local directory
  -- Common patterns: lua_modules/, deps/, vendor/
  local local_dep_dirs = {
    root .. "/lua_modules/share/lua/5.1",
    root .. "/lua_modules/share/lua/5.4",
    root .. "/deps",
    root .. "/vendor",
  }

  -- Add local dependency directories if they exist
  for _, path in ipairs(local_dep_dirs) do
    local stat = (vim.uv or vim.loop).fs_stat(path)
    if stat and stat.type == "directory" then
      library[path] = true
    end
  end

  -- ===================================================================
  -- RETURN CONSTRUCTED LIBRARY
  -- ===================================================================

  return library
end
