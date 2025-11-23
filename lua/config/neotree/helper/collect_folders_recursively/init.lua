---@module 'config.neotree.helper.collect_folders_recursively'
-- Recursively collect folder paths under the given root directory.
-- Returns an array (sequential) of absolute folder paths. The root folder
-- itself is included as the first element when called with a directory.
-- Implementation aims to be robust and synchronous (uses vim.loop).

local uv = vim.loop

---@param root string Absolute or relative path to start from
---@return string[] folders Sequential array of absolute folder paths
return function (root)
  -- Ensure absolute path and normalize separators using vim.fn
  local root_abs = vim.fn.fnamemodify(root, ":p")
  ---@type string[]
  local results = {}

  -- Defensive: bail out if not a directory
  if vim.fn.isdirectory(root_abs) ~= 1 then
    return results
  end

  -- push root first
  table.insert(results, root_abs)

  -- internal stack for iterative traversal to avoid recursion depth issues
  local stack = { root_abs }

  while #stack > 0 do
    local dir = table.remove(stack) -- pop
    local handle = uv.fs_scandir(dir)
    if handle then
      while true do
        local name, typ = uv.fs_scandir_next(handle)
        if not name then break end
        if typ == "directory" then
          local child = dir:gsub("[/\\]+$", "") .. "\\" .. name
          -- convert to absolute and normalize
          child = vim.fn.fnamemodify(child, ":p")
          table.insert(results, child)
          table.insert(stack, child)
        end
      end
    end
  end

  return results
end
