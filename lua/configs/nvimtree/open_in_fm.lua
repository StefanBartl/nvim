---@module 'configs.nvimtree_open_in_fm'
--- Helper to open the directory of the node under the cursor (nvim-tree) or the
--- current buffer's directory (fallback) in the system file manager.
--- Handles API changes across nvim-tree versions and works on Linux/macOS.
--- Requires a helper: `utils.system_filemanager.open_dir(path) -> boolean`

---@class NvimTreeOpenFM
local M = {}

--- Try to get the nvim-tree node under cursor using the new API; fall back to the old API if present.
--- @return table|nil node  -- nvim-tree node table if available
local function get_tree_node_under_cursor()
  -- Newer API (preferred)
  local ok_api, api = pcall(require, "nvim-tree.api")
  if ok_api and api and api.tree and type(api.tree.get_node_under_cursor) == "function" then
    local node = api.tree.get_node_under_cursor()
    if node then return node end
  end

  -- Legacy API (older versions)
  local ok_lib, lib = pcall(require, "nvim-tree.lib")
  if ok_lib and lib and type(lib.get_node_at_cursor) == "function" then
    return lib.get_node_at_cursor()
  end

  return nil
end

--- Resolve an absolute filesystem path from a nvim-tree node, being robust across versions.
--- @param node table
--- @return string|nil abs_path
--- @return boolean is_file
local function resolve_node_path(node)
  if not node then return nil, false end

  -- Known fields across versions:
  -- - node.absolute_path (often present)
  -- - node.path (sometimes present)
  -- - node:get_id() (API helper returning the absolute path)
  local abs = node.absolute_path
    or node.path
    or (type(node.get_id) == "function" and node:get_id())
    or nil

  if not abs or abs == "" then return nil, false end

  -- Determine file vs directory robustly:
  -- - Prefer node.type == "file" when present
  -- - Otherwise ask the filesystem
  local is_file = false
  if node.type == "file" then
    is_file = true
  else
    -- `isdirectory()` returns 1 for directories, 0 for files/non-existing
    is_file = (vim.fn.isdirectory(abs) == 0)
  end

  return abs, is_file
end

--- Open a directory path in the system file manager using user's helper.
--- @param dir string
--- @return boolean ok
local function open_dir(dir)
  local ok, fm = pcall(require, "system.filemanager")
  if not ok or type(fm.open_dir) ~= "function" then
    vim.notify("[open_in_filemanager] missing system.filemanager.open_dir()", vim.log.levels.ERROR)
    return false
  end
  return fm.open_dir(dir)
end

--- Public entry: open the node-under-cursor directory, or current buffer's directory as fallback.
--- @param node table|nil
--- @return nil
function M.open_in_filemanager(node)
  -- Prefer explicit node if provided (kept for API parity), else resolve from cursor
  node = node or get_tree_node_under_cursor()
  if not node then
    vim.notify("[NVIMTREE] node not available.", 4)
    return
  end

  local path, is_file = resolve_node_path(node)
  if not path then
    -- Fallback: not in nvim-tree, try current buffer
    local bufpath = vim.api.nvim_buf_get_name(0)
    if bufpath ~= "" then
      path = vim.fn.fnamemodify(bufpath, ":p:h")
      is_file = false
    end
  end

  if not path or path == "" then
    vim.notify("[open_in_filemanager] Could not determine a path", vim.log.levels.ERROR)
    return
  end

  -- If the node is a file, open its parent directory
  if is_file then
    path = vim.fn.fnamemodify(path, ":h")
  end

  local ok = open_dir(path)
  if not ok then
    vim.notify(("[open_in_filemanager] Opening failed: %s"):format(path), vim.log.levels.ERROR)
  end
end

return M

