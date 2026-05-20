---@module 'config.neotree.actions.info.node'
---@brief Toggleable hover window with file or directory information for tree nodes.
---@description
--- Displays a floating window with filesystem metadata for the currently
--- selected Neo-tree node.  Line count is accepted as an explicit parameter
--- (opts.line_count) so callers remain free to compute it however they choose.

local notify = require("lib.notify").create("[config.neotree.actions.info.node]")
local node_utils = require("config.neotree.utils.node")

local M = {}

local bitlib = require("bit")
local uv = vim.uv or vim.loop
local api = vim.api

-- ============================================================
-- Module-level hover state (intentionally module-scoped, not global)
-- ============================================================

---@type integer|nil
local active_win = nil

---@type string|nil
local active_path = nil

-- ============================================================
-- Private helpers
-- ============================================================

---Format file size in human-readable form.
---@param size integer Bytes
---@return string formatted
local function format_size(size)
  return string.format("%d bytes (%.2f MiB)", size, size / (1024 * 1024))
end

---Format Unix permission bits as rwx string.
---@param v integer Permission nibble (0–7)
---@return string
local function bits(v)
  local map = { "r", "w", "x" }
  local s = ""
  for i = 2, 0, -1 do
    local b = 2 ^ i
    s = s .. ((bitlib.band(v, b) ~= 0) and map[3 - i] or "-")
  end
  return s
end

---Format POSIX file permissions from a libuv stat object.
---@param stat table libuv stat
---@return string formatted
local function format_permissions(stat)
  local mode = stat.mode or 0
  local octal = string.format("%o", mode)

  if vim.fn.has("win32") == 1 then
    return octal .. " (Windows ACL / readonly flag)"
  end

  local perm = mode % 512
  return string.format(
    "%s (POSIX %s %s %s)",
    octal,
    bits(math.floor(perm / 64)),
    bits(math.floor((perm % 64) / 8)),
    bits(perm % 8)
  )
end

---Close the active hover window, if any.
local function close_hover()
  if active_win and api.nvim_win_is_valid(active_win) then
    api.nvim_win_close(active_win, true)
  end
  active_win = nil
  active_path = nil
end

---Open (or toggle) a floating info window.
---Toggle semantics: calling with the same path while the window is visible closes it.
---@param path  string   Filesystem path (used as identity key for toggle).
---@param lines string[] Content lines to display.
---@return nil
local function toggle_hover(path, lines)
  -- Toggle: same path already open → close
  if active_win and api.nvim_win_is_valid(active_win) and active_path == path then
    close_hover()
    return
  end

  -- Replace previous hover with new one
  close_hover()

  -- Create scratch buffer
  local buf = api.nvim_create_buf(false, true)
  api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  api.nvim_set_option_value("modifiable", false, { buf = buf })
  api.nvim_set_option_value("bufhidden", "wipe", { buf = buf })

  -- Buffer-local close keymaps
  local close_opts = { buffer = buf, noremap = true, silent = true, nowait = true }
  vim.keymap.set("n", "q", close_hover, close_opts)
  vim.keymap.set("n", "<Esc>", close_hover, close_opts)

  -- Compute window width from content
  local width = 0
  for _, l in ipairs(lines) do
    width = math.max(width, #l)
  end

  -- Open the floating window
  active_win = api.nvim_open_win(buf, true, {
    relative = "editor",
    style = "minimal",
    border = "rounded",
    width = width + 2,
    height = #lines,
    row = 2,
    col = 4,
  })

  active_path = path
end

-- ============================================================
-- Public API
-- ============================================================

---@class Cfg.NeoTree.Actions.Info.ShowOpts
---@field line_count integer|nil Pre-computed line count (nil = not applicable/not computed).

---Show a hover window with filesystem info for the currently selected node.
---
---The optional `opts.line_count` value is purely additive: when supplied it
---appends a "Lines:" row to the popup.  The caller is responsible for computing
---it (e.g. via `config.neotree.utils.line_count`) so this function stays focused
---on display only.
---
---@param state Cfg.NeoTree.State   Neo-tree state table.
---@param opts  Cfg.NeoTree.Actions.Info.ShowOpts|nil
---@return nil
function M.show_from_neotree(state, opts)
  opts = opts or {}

  local node = node_utils.get_current(state)
  if not node then
    notify.warn("No node under cursor")
    return
  end

  local path, _ = node_utils.get_path(node)
  if path == "" then
    notify.warn("Node has no path")
    return
  end

  local stat = uv.fs_stat(path)
  if not stat then
    toggle_hover(path, { "No file system information available." })
    return
  end

  -- Build info lines — label column is fixed-width for alignment
  local lines = {
    "Path:        " .. path,
    "Type:        " .. stat.type,
    "Size:        " .. format_size(stat.size),
    "Permissions: " .. format_permissions(stat),
    "Modified:    " .. os.date("%Y-%m-%d %H:%M:%S", stat.mtime.sec),
  }

  -- Append line count only when meaningful (text/source files)
  if type(opts.line_count) == "number" then
    local label = opts.line_count == 1 and "1 line" or (opts.line_count .. " lines")
    lines[#lines + 1] = "Lines:       " .. label
  end

  toggle_hover(path, lines)
end

---Show info for an nvim-tree node (compatibility shim).
---@param node table nvim-tree node (requires `absolute_path` field).
---@return nil
function M.show_from_nvim_tree(node)
  if not node or not node.absolute_path then
    return
  end

  local stat = uv.fs_stat(node.absolute_path)
  if not stat then
    toggle_hover(node.absolute_path, { "No file system information available." })
    return
  end

  toggle_hover(node.absolute_path, {
    "Path:        " .. node.absolute_path,
    "Type:        " .. stat.type,
    "Size:        " .. format_size(stat.size),
    "Permissions: " .. format_permissions(stat),
    "Modified:    " .. os.date("%Y-%m-%d %H:%M:%S", stat.mtime.sec),
  })
end

return M
