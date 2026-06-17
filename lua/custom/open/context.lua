---@module 'custom.open.context'
---@brief Resolves the target text (path or URL) for the :Open command.
---@description
--- Two-stage resolution:
---   1. M.gather() collects raw, target-agnostic signals from the current
---      editor state: tree-buffer node, <cfile>, <cWORD>, visual selection,
---      current buffer path.
---   2. M.resolve(arg, target, signals) turns those signals (plus an optional
---      explicit user override) into the final Custom.Open.Context consumed
---      by every handler.
---
--- Explicit override tokens for `arg`:
---   "%"            → current buffer path
---   "cfile"        → <cfile> text under the cursor
---   "path=<path>"  → literal path given after "path="
---   anything else  → used verbatim as the resolved text
---
--- Default heuristic (no explicit `arg`):
---   1. Tree-buffer node (neo-tree / nvim-tree / netrw), if the current
---      buffer is a recognised tree buffer — wins regardless of `target`.
---   2. For path-oriented targets (filemanager, split, vsplit, tab):
---        <cfile> if it resolves to an existing path on disk, else the
---        current buffer path (%).
---   3. For all other targets (browser, notepad, editor, …):
---        visual selection, else <cWORD>, else the current buffer path (%).
---@see custom.open.@types

local M = {}

-- ---------------------------------------------------------------------------
-- URL heuristic
-- ---------------------------------------------------------------------------

---@param text string
---@return boolean
local function looks_like_url(text)
  return text:match("^https?://") ~= nil
    or text:match("^ftp://") ~= nil
    or text:match("^www%.") ~= nil
end

-- ---------------------------------------------------------------------------
-- Existing-path check
-- ---------------------------------------------------------------------------

---Try to resolve `candidate` to an existing file/dir on disk: first verbatim
---(resolved against the process cwd by fs_stat), then relative to the
---current buffer's directory.
---@param candidate string|nil
---@return string|nil resolved
local function resolve_existing_path(candidate)
  if type(candidate) ~= "string" or candidate == "" then
    return nil
  end

  local expanded = vim.fn.expand(candidate)
  if expanded ~= "" and vim.uv.fs_stat(expanded) then
    return expanded
  end

  local bufdir = vim.fn.expand("%:p:h")
  if bufdir ~= "" then
    local sep    = package.config:sub(1, 1)
    local joined = bufdir:gsub("[/\\]$", "") .. sep .. candidate
    if vim.uv.fs_stat(joined) then
      return joined
    end
  end

  return nil
end

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

  local buf    = vim.api.nvim_get_current_buf()
  local source = vim.b[buf] and vim.b[buf].neo_tree_source
  source = source or "filesystem"

  local ok_src, state = pcall(manager.get_state, source)
  if not ok_src or not state then
    return nil
  end

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

  local line = vim.api.nvim_get_current_line()
  if not line then
    return nil
  end

  local entry = line:match("^%s*(.-)%s*$")
  if not entry or entry == "" then
    -- Cursor is on a header line; return the directory itself.
    return curdir
  end

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
-- Target classification
-- ---------------------------------------------------------------------------

---Targets for which a validated <cfile> path is preferred over <cWORD>/visual.
---@type table<string, boolean>
local PATH_TARGETS = {
  filemanager = true,
  split       = true,
  vsplit      = true,
  tab         = true,
}

-- ---------------------------------------------------------------------------
-- Public API
-- ---------------------------------------------------------------------------

---Gather raw context signals without making any target-specific decision.
---@return Custom.Open.Signals
function M.gather()
  ---@type Custom.Open.Signals
  local signals = {}

  signals.tree_path = resolve_tree_node_path()

  local cfile = vim.fn.expand("<cfile>")
  signals.cfile      = (cfile ~= "" and cfile) or nil
  signals.cfile_path = resolve_existing_path(signals.cfile)

  local cword = vim.fn.expand("<cWORD>")
  signals.cword = (cword ~= "" and cword) or nil

  local mode = vim.fn.mode()
  if mode == "v" or mode == "V" or mode == "\22" then
    local ok, sel = pcall(function()
      local s     = vim.fn.getpos("'<")
      local e     = vim.fn.getpos("'>")
      local lines = vim.api.nvim_buf_get_text(0, s[2] - 1, s[3] - 1, e[2] - 1, e[3], {})
      return table.concat(lines, "")
    end)
    if ok and sel and sel ~= "" then
      signals.visual = sel
    end
  end

  local bufname = vim.api.nvim_buf_get_name(0)
  signals.buffer_path = (bufname ~= "" and bufname) or nil

  return signals
end

---Resolve what should be opened for `target`.
---@param arg      string|nil              Explicit scope override: "%", "cfile", "path=<path>", or literal text.
---@param target   string|nil              Handler key the context is being built for.
---@param signals  Custom.Open.Signals|nil Pre-gathered signals; gathered internally if omitted.
---@return Custom.Open.Context|nil ctx      nil when nothing useful could be resolved.
function M.resolve(arg, target, signals)
  signals = signals or M.gather()

  local text

  if arg and arg ~= "" then
    if arg == "%" then
      text = signals.buffer_path
    elseif arg == "cfile" then
      text = signals.cfile
    elseif arg:sub(1, 5) == "path=" then
      text = arg:sub(6)
    else
      text = arg
    end
  elseif signals.tree_path then
    text = signals.tree_path
  elseif PATH_TARGETS[target] then
    text = signals.cfile_path or signals.buffer_path
  else
    text = signals.visual or signals.cword or signals.buffer_path
  end

  if not text or text == "" then
    return nil
  end

  return {
    text    = text,
    is_url  = looks_like_url(text),
    is_path = resolve_existing_path(text) ~= nil,
  }
end

return M
