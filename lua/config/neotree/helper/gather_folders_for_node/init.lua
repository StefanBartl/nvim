---@module 'config.neotree.helper.gather_folders_for_node'
-- Gather folder entries for the node under cursor.
-- If the node is a directory, returns recursively-collected folder paths (absolute).
-- If the node is a file, returns the folder containing that file (single-element array).

local collect_folders_recursive = require("config.neotree.helper.collect_folders_recursively")

---@param state table Neo-tree `state` object
---@return string[] entries Sequential array of absolute folder paths (may be empty)
---@return string node_path Path string of the node (empty string if none)
return function(state)
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
      -- collect folders recursively under the directory (including the directory itself)
      return collect_folders_recursive(path)
    else
      -- node is a file: return its parent folder only
      local parent = vim.fn.fnamemodify(path, ":h")
      return { parent }
    end
  end)

  if ok and type(result) == "table" then
    entries = result
  end

  return entries, path
end
