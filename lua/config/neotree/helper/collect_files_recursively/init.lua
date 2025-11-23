---@module 'config.neotree.helper.collect_files_recursively'
-- Collect file tree for a given path (recursive, platform-agnostic)

local is_ignored_dir = require("config.neotree.helper.is_ignored_dir")

--- Recursively collect all files (regular files) under `root_path`.
--- Returns an array (sequential table) of absolute file paths.
--- Uses luv (vim.loop) for fast, dependency-free traversal.
---@param root_path string Root absolute path (file or directory)
---@return string[] list Sequential array of absolute file paths
return function (root_path)
  local results = {}
  local uv = vim.loop
  local stack = { root_path }

  while #stack > 0 do
    local path = table.remove(stack)
    local stat = uv.fs_stat(path)

    if stat then
      if stat.type == "file" then
        table.insert(results, path)
      elseif stat.type == "directory" then
        local req, err = uv.fs_scandir(path)
        if req then
          while true do
            local name, _ = uv.fs_scandir_next(req)
            if not name then
              break
            end
            if not is_ignored_dir(name) then
              local child = path .. (path:sub(-1) == "/" and "" or "/") .. name
              table.insert(stack, child)
            end
          end
        else
          vim.notify(
            ("collect_files_recursive: scandir failed for %s: %s"):format(path, tostring(err)),
            vim.log.levels.DEBUG
          )
        end
      end
    else
      vim.notify(("collect_files_recursive: fs_stat failed for %s"):format(path), vim.log.levels.DEBUG)
    end
  end

  return results
end
