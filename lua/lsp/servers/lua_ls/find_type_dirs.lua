---@module 'lsp.servers.lua_ls.find_type_dirs'
--- Find directories named "types" / "@types" while pruning common noise directories.
--- This module performs a breadth-first search through the project to locate
--- TypeScript/Lua type definition directories that should be included in the workspace.

-- Use vim.loop for cross-platform filesystem operations
local uv = vim.loop

-- Normalize paths for consistent comparison across platforms
local norm = vim.fs.normalize

--- Return string[] of discovered "types" dirs under root.
--- Uses breadth-first search with configurable depth and result limits.
--- @param root string Root directory to start scanning from
--- @param opts { max_results?: integer, max_depth?: integer }|nil Optional configuration
--- @return string[] Array of discovered type directory paths
return function(root, opts)
  -- Apply default options if not provided
  opts = opts or {}
  local MAX_RESULTS = opts.max_results or 200  -- Stop after finding this many type dirs
  local MAX_DEPTH = opts.max_depth or 12       -- Don't descend deeper than this

  -- Load the shared ignore set for fast O(1) membership testing
  -- This contains directories like node_modules, .git, etc.
  local ignore_set = require("lsp.servers.lua_ls.ignore").as_set()

  -- Initialize result array and search stack for breadth-first traversal
  local matches = {}
  local stack = { { path = norm(root), depth = 0 } }

  -- Continue searching while we have nodes to explore and haven't hit limits
  while #stack > 0 and #matches < MAX_RESULTS do
    -- Pop the next directory from the stack
    local node = table.remove(stack)

    -- Only process if we haven't exceeded maximum depth
    if node.depth <= MAX_DEPTH then
      -- Scan the directory for entries
      local it = uv.fs_scandir(node.path)

      if it then
        -- Iterate through all entries in this directory
        while true do
          ---@diagnostic disable-next-line: undefined-field
          local name, kind = uv.fs_scandir_next(it)

          -- Break when no more entries
          if not name then
            break
          end

          -- Skip hidden files/directories except .config
          -- .config is preserved because it might contain type definitions
          if name:sub(1, 1) == "." and name ~= ".config" then
            goto inner_continue
          end

          -- Only process directories (skip files)
          if kind == "directory" then
            -- Normalize name for case-insensitive comparison on Windows
            local key = package.config:sub(1, 1) == "\\" and name:lower() or name

            -- Skip this directory if it's in our ignore list
            if ignore_set[key] then
              goto inner_continue
            end

            -- Build the full path to this child directory
            -- Use platform-appropriate path separator
            local sep = package.config:sub(1, 1) == "\\" and "\\" or "/"
            local child = norm(node.path .. sep .. name)

            -- Check if this directory is a type directory
            if name == "types" or name == "@types" then
              -- Found a match! Add to results
              matches[#matches + 1] = child
            end

            -- Add this directory to the search stack for further exploration
            stack[#stack + 1] = { path = child, depth = node.depth + 1 }
          end

          ::inner_continue::
        end
      end
    end
  end

  -- Return all discovered type directories
  return matches
end
