---@module 'config.neotree.helper.gather_entries_for_node'
-- Gather file entries for the node under cursor.
--
-- If node is a directory, returns recursively-collected files (absolute).
-- If node is a file, returns a one-element array with that file path.

local collect_files_recursive = require("config.neotree.helper.collect_files_recursively")

---@param state table Neo-tree `state` object
---@return string[] entries Sequential array of absolute paths (may be empty)
---@return string node_path Path string of the node (empty string if none)
return function (state)
  local node = state and state.tree and state.tree:get_node()
  if not node then
    return {}, ""
  end

  local path = node.path or node:get_id() or ""
  if path == "" then
    return {}, ""
  end

  local entries = {} ---@type string[]
  local ok, result = pcall(function()
    if vim.fn.isdirectory(path) == 1 then
      return collect_files_recursive(path)
    else
      return { path }
    end
  end)

  if ok and type(result) == "table" then
    entries = result
  end

  return entries, path
end
