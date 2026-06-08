---@module 'custom.open.context'
---@brief Resolves the target path/URL for the :Open command.
---@description
--- Determines what to open based on the current editor context.
--- Resolution order (highest priority first):
---   1. Explicit argument passed to :Open
---   2. Active file-tree buffer node (neotree / nvim-tree / netrw)
---   3. Visual selection
---   4. Word under cursor
---   5. Current buffer path (fallback)

local M = {}

-- ---------------------------------------------------------------------------
-- Tree-buffer node resolution
-- ---------------------------------------------------------------------------

--- Extract the current node path from a Neo-tree buffer.
---@return string|nil path Absolute path of the node under cursor, or nil.
local function resolve_neotree_path()
  local ok_state, manager = pcall(require, "neo-tree.sources.manager")
  if not ok_state then
    return nil
  end

  -- Determine which source is active in the current window.
  local buf     = vim.api.nvim_get_current_buf()
  local source  = vim.b[buf] and vim.b[buf].neo_tree_source

  -- Fallback: try filesystem source.
  source = source or "filesystem"

  local ok_src, state = pcall(manager.get_state, source)
  if not ok_src or not state then
    return nil
  end

  -- node_utils helper used elsewhere in the config.
  local ok_nu, node_utils = pcall(require, "config.neotree.utils.node")
  if ok_nu then
    local node = node_utils.get_current(state)
    if node then
      local path = node:get_id()
      if type(path) == "string" and path ~= "" then
        return path
      end
    end
  end

  -- Direct fallback via neo-tree internal tree API.
  if state.tree then
    local ok_node, node = pcall(state.tree.get_node, state.tree)
    if ok_node and node then
      local path = node:get_id()
      if type(path) == "string" and path ~= "" then
        return path
      end
    end
  end

  return nil
end

--- Extract the current node path from an nvim-tree buffer.
---@return string|nil path Absolute path of the node under cursor, or nil.
local function resolve_nvimtree_path()
  local ok, api = pcall(require, "nvim-tree.api")
  if not ok then
    return nil
  end

  local ok_node, node = pcall(function()
    return api.tree.get_node_under_cursor()
  end)

  if ok_node and node and node.absolute_path and node.absolute_path ~= "" then
    return node.absolute_path
  end

  return nil
end

--- Extract the current path from a netrw buffer.
--- netrw stores the directory in `b:netrw_curdir` and the cursor line
--- contains the file/dir name (after the header lines).
---@return string|nil path Absolute path of the entry under cursor, or nil.
local function resolve_netrw_path()
  local buf    = vim.api.nvim_get_current_buf()
  local curdir = vim.b[buf] and vim.b[buf].netrw_curdir

  if not curdir or curdir == "" then
    return nil
  end

  -- The entry name sits on the current cursor line.
  local line = vim.api.nvim_get_current_line()
  if not line then
    return nil
  end

  -- Strip leading whitespace / netrw decorations.
  local entry = line:match("^%s*(.-)%s*$")
  if not entry or entry == "" then
    -- Cursor is on a header line; return the directory itself.
    return curdir
  end

  -- Build absolute path.
  local sep  = package.config:sub(1, 1)
  local path = curdir:gsub("[/\\]$", "") .. sep .. entry

  return path
end

--- Check whether the current buffer is a recognised file-tree buffer and
--- return the node path under the cursor.
---@return string|nil path Absolute path or nil if not in a tree buffer.
local function resolve_tree_node_path()
  local buf = vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_valid(buf) then
    return nil
  end

  local ft = vim.bo[buf].filetype

  if ft == "neo-tree" then
    return resolve_neotree_path()
  end

  if ft == "NvimTree" then
    return resolve_nvimtree_path()
  end

  if ft == "netrw" then
    return resolve_netrw_path()
  end

  return nil
end

-- ---------------------------------------------------------------------------
-- Public API
-- ---------------------------------------------------------------------------

---@class Open.Context
---@field path   string   Resolved absolute path or URL.
---@field source "arg"|"tree"|"visual"|"cword"|"buffer"  Where the path came from.

--- Resolve what should be opened.
--- When called from a file-tree buffer (neotree / nvim-tree / netrw) the node
--- under the cursor takes precedence over everything except an explicit arg.
---@param arg string|nil  Explicit argument from the user command, may be nil or "".
---@return Open.Context|nil ctx  nil when nothing useful could be resolved.
function M.resolve(arg)
  -- 1. Explicit argument from the command line.
  if arg and arg ~= "" then
    return { path = arg, source = "arg" }
  end

  -- 2. File-tree node (neotree / nvim-tree / netrw).
  local tree_path = resolve_tree_node_path()
  if tree_path then
    return { path = tree_path, source = "tree" }
  end

  -- 3. Visual selection (single line assumed; multi-line not meaningful here).
  local mode = vim.fn.mode()
  if mode == "v" or mode == "V" or mode == "\22" then
    local ok, sel = pcall(function()
      local s = vim.fn.getpos("'<")
      local e = vim.fn.getpos("'>")
      local lines = vim.api.nvim_buf_get_text(0, s[2] - 1, s[3] - 1, e[2] - 1, e[3], {})
      return table.concat(lines, "")
    end)
    if ok and sel and sel ~= "" then
      return { path = sel, source = "visual" }
    end
  end

  -- 4. Word under cursor.
  local cword = vim.fn.expand("<cWORD>")
  if cword and cword ~= "" then
    return { path = cword, source = "cword" }
  end

  -- 5. Current buffer file path.
  local bufname = vim.api.nvim_buf_get_name(0)
  if bufname and bufname ~= "" then
    return { path = bufname, source = "buffer" }
  end

  return nil
end

return M
