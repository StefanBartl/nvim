---@module 'lsp.servers.lua_ls.find_type_dirs'
--- Find directories named "types" / "@types" with ENHANCED detection
--- This module performs a breadth-first search through the project

local uv = vim.loop or vim.uv
local norm = vim.fs.normalize

--- Return string[] of discovered "types" dirs under root.
--- @param root string Root directory to start scanning from
--- @param opts { max_results?: integer, max_depth?: integer }|nil Optional configuration
--- @return string[] Array of discovered type directory paths
return function(root, opts)
  opts = opts or {}
  local MAX_RESULTS = opts.max_results or 200
  local MAX_DEPTH = opts.max_depth or 15

  local ignore_set = require("lsp.servers.lua_ls.ignore").as_set()

  local matches = {}
  local stack = { { path = norm(root), depth = 0 } }
  local seen = {}  -- Prevent duplicates

  while #stack > 0 and #matches < MAX_RESULTS do
    local node = table.remove(stack)

    -- Skip if already processed
    if seen[node.path] then
      goto continue
    end
    seen[node.path] = true

    if node.depth <= MAX_DEPTH then
      local it = uv.fs_scandir(node.path)

      if it then
        while true do
          local name, kind = uv.fs_scandir_next(it)

          if not name then
            break
          end

          -- Skip hidden files/directories except .config
          if name:sub(1, 1) == "." and name ~= ".config" then
            goto inner_continue
          end

          if kind == "directory" then
            local key = package.config:sub(1, 1) == "\\" and name:lower() or name

            -- Skip ignored directories
            if ignore_set[key] then
              goto inner_continue
            end

            local sep = package.config:sub(1, 1) == "\\" and "\\" or "/"
            local child = norm(node.path .. sep .. name)

            -- CRITICAL: Check multiple patterns for @types
            local is_types = false
            if name == "types" or name == "@types" then
              is_types = true
            elseif name:match("^@types") or name:match("types$") then
              is_types = true
            end

            if is_types then
              -- Verify it actually contains .lua files (avoid empty directories)
              local has_lua = false
              local check_it = uv.fs_scandir(child)
              if check_it then
                while true do
                  local file_name, file_kind = uv.fs_scandir_next(check_it)
                  if not file_name then break end

                  if file_kind == "file" and file_name:match("%.lua$") then
                    has_lua = true
                    break
                  elseif file_kind == "directory" then
                    -- Check one level deeper for lua files
                    local deep_check = uv.fs_scandir(child .. sep .. file_name)
                    if deep_check then
                      while true do
                        local deep_name, deep_kind = uv.fs_scandir_next(deep_check)
                        if not deep_name then break end
                        if deep_kind == "file" and deep_name:match("%.lua$") then
                          has_lua = true
                          break
                        end
                      end
                    end
                    if has_lua then break end
                  end
                end
              end

              -- Only add if contains actual type definitions
              if has_lua then
                matches[#matches + 1] = child
              end
            end

            -- Add to stack for further exploration
            stack[#stack + 1] = { path = child, depth = node.depth + 1 }
          end

          ::inner_continue::
        end
      end
    end

    ::continue::
  end

  -- DEBUG: Log found directories
  if vim.env.DEBUG_LUA_LS and #matches > 0 then
    vim.notify(
      string.format("find_type_dirs: Found %d type directories", #matches),
      vim.log.levels.INFO
    )
  end

  return matches
end
