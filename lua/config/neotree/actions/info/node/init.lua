---@module 'config.neotree.actions.info.node'
---@brief Toggleable hover window with file or directory information for tree nodes
--- Fixed: Uses node_utils.get_current() for consistent node retrieval

local notify = require("lib.notify").create("[config.neotree.actions.info.node]")

local M = {}

local bitlib = require("bit")
local node_utils = require("config.neotree.utils.node")

local uv = vim.uv or vim.loop
local api = vim.api

---@type integer|nil
local active_win = nil

---@type string|nil
local active_path = nil

---Format file size in human-readable format
---@param size integer Size in bytes
---@return string formatted
local function format_size(size)
  return string.format("%d bytes (%.2f MiB)", size, size / (1024 * 1024))
end

---Format Unix permissions (POSIX-style)
---@param stat table libuv stat object
---@return string formatted
local function format_permissions(stat)
  local mode = stat.mode or 0
  local octal = string.format("%o", mode)

  if vim.fn.has("win32") == 1 then
    return octal .. " (Windows ACL / readonly flag)"
  end

  local perm = mode % 512

  ---Format permission bits as rwx string
  ---@param v integer Permission value (0-7)
  ---@return string formatted
  local function bits(v)
    local map = { "r", "w", "x" }
    local s = ""
    for i = 2, 0, -1 do
      local b = 2 ^ i
      s = s .. ((bitlib.band(v, b) ~= 0) and map[3 - i] or "-")
    end
    return s
  end

  return string.format(
    "%s (POSIX %s %s %s)",
    octal,
    bits(math.floor(perm / 64)),
    bits(math.floor((perm % 64) / 8)),
    bits(perm % 8)
  )
end

---Toggle hover window with node information
---@param path string Absolute path to display
---@param lines string[] Information lines
---@return nil
local function toggle_hover(path, lines)
  -- Close if same path already open
  if active_win and api.nvim_win_is_valid(active_win) and active_path == path then
    api.nvim_win_close(active_win, true)
    active_win, active_path = nil, nil
    return
  end

  -- Close previous hover
  if active_win and api.nvim_win_is_valid(active_win) then
    api.nvim_win_close(active_win, true)
  end

  -- Create new buffer
  local buf = api.nvim_create_buf(false, true)
  api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  api.nvim_set_option_value("modifiable", false, { buf = buf })
  api.nvim_set_option_value("bufhidden", "wipe", { buf = buf })

  -- Keymaps to close
  local function close_hover()
    if active_win and api.nvim_win_is_valid(active_win) then
      api.nvim_win_close(active_win, true)
      active_win, active_path = nil, nil
    end
  end

  vim.keymap.set("n", "q", close_hover, { buffer = buf })
  vim.keymap.set("n", "<Esc>", close_hover, { buffer = buf })

  -- Calculate window size
  local width = 0
  for _, l in ipairs(lines) do
    width = math.max(width, #l)
  end

  -- Open floating window
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

--- Show information for the currently selected Neo-tree node
--- FIXED: Uses node_utils.get_current() instead of direct state access
---@param state Cfg.NeoTree.State Neo-tree state table
---@return nil
function M.show_from_neotree(state)
  -- FIXED: Use node_utils for consistent node retrieval
  local node = node_utils.get_current(state)
  if not node then
    notify.warn("No node under cursor")
    return
  end

  -- Resolve the filesystem path
  local path, _ = node_utils.get_path(node)
  if path == "" then
    notify.warn("Node has no path")
    return
  end

  -- Query filesystem metadata via libuv
  local stat = uv.fs_stat(path)
  if not stat then
    toggle_hover(path, { "No file system information available." })
    return
  end

  -- Display formatted file information
  toggle_hover(path, {
    "Path:        " .. path,
    "Type:        " .. stat.type,
    "Size:        " .. format_size(stat.size),
    "Permissions: " .. format_permissions(stat),
    "Modified:    " .. os.date("%Y-%m-%d %H:%M:%S", stat.mtime.sec),
  })
end

---Show information for nvim-tree node (compatibility)
---@param node table nvim-tree node
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
  })
end

return M
