---@module 'config.neotree.utils.tree'
---@brief Recursive tree traversal for file/folder collection

local is_ignored_dir = require("config.neotree.helper.is_ignored_dir")
local node_utils = require("config.neotree.utils.node")

local M = {}

---Collect files or folders recursively
---@param root_path string Root path to start from
---@param collect_type "files"|"folders" What to collect
---@return string[] entries Sequential array of absolute paths
function M.collect_recursive(root_path, collect_type)
  local results = {}
  local uv = vim.uv or vim.loop
  local stack = { root_path }

  -- For folders: include root itself
  if collect_type == "folders" then
    if vim.fn.isdirectory(root_path) == 1 then
      table.insert(results, root_path)
    end
  end

  while #stack > 0 do
    local path = table.remove(stack)
    local stat = uv.fs_stat(path)

    if stat then
      if stat.type == "file" and collect_type == "files" then
        table.insert(results, path)
      elseif stat.type == "directory" then
        local req, err = uv.fs_scandir(path)
        if req then
          while true do
            local name, typ = uv.fs_scandir_next(req)
            if not name then
              break
            end

            if not is_ignored_dir(name) then
              local child = path .. (path:sub(-1) == "/" and "" or "/") .. name

              if collect_type == "folders" and typ == "directory" then
                table.insert(results, child)
              end

              table.insert(stack, child)
            end
          end
        else
          vim.notify(
            string.format("tree.collect_recursive: scandir failed for %s: %s", path, tostring(err)),
            vim.log.levels.DEBUG
          )
        end
      end
    end
  end

  return results
end

---Collect files recursively
---@param root_path string
---@return string[]
function M.collect_files(root_path)
  return M.collect_recursive(root_path, "files")
end

---Collect folders recursively
---@param root_path string
---@return string[]
function M.collect_folders(root_path)
  return M.collect_recursive(root_path, "folders")
end

--- Collect files or folders for a Neo-tree node
---@param state Cfg.NeoTree.State Neo-tree state
---@param collect_type "files"|"folders"
---@return string[] entries, string node_path
function M.collect_for_node(state, collect_type)
  -- 1) Aktuellen Node holen
  local node = state and state.current_node or nil
  if not node then
    return {}, ""
  end

  -- 2) Pfad über node_utils.get_path holen
  local path, is_dir = node_utils.get_path(node)
  if path == "" then
    return {}, ""
  end

  -- 3) Dateien/Folders sammeln
  local entries = {}
  local ok, result = pcall(function()
    if is_dir then
      return M.collect_recursive(path, collect_type)
    else
      -- Single file/folder
      return { path }
    end
  end)

  if ok and type(result) == "table" then
    entries = result
  end

  return entries, path
end

return M
