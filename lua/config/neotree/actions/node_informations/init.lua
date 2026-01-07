---@module 'config.neotree.helpers.node_informations'
---Toggleable hover window with file or directory information for tree nodes.

local bitlib = require("bit")

local M = {}

local uv = vim.uv or vim.loop
local api = vim.api
local win_close = api.nvim_win_close
local str_format = string.format
local km_set = vim.keymap.set

---@type integer|nil
local active_win = nil

---@type string|nil
local active_path = nil

local function format_size(size)
  return str_format("%d bytes (%.2f MiB)", size, size / (1024 * 1024))
end

local function format_permissions(stat)
  local mode = stat.mode or 0
  local octal = str_format("%o", mode)

  if vim.fn.has("win32") == 1 then
    return octal .. " (Windows ACL / readonly flag)"
  end

  local perm = mode % 512
  local function bits(v)
    local map = { "r", "w", "x" }
    local s = ""
    for i = 2, 0, -1 do
      local b = 2 ^ i
      s = s .. ((bitlib.band(v, b) ~= 0) and map[3 - i] or "-")
    end
    return s
  end

  return str_format(
    "%s (POSIX %s %s %s)",
    octal,
    bits(math.floor(perm / 64)),
    bits(math.floor((perm % 64) / 8)),
    bits(perm % 8)
  )
end

local function toggle_hover(path, lines)
  if active_win and api.nvim_win_is_valid(active_win) and active_path == path then
    win_close(active_win, true)
    active_win, active_path = nil, nil
    return
  end

  if active_win and api.nvim_win_is_valid(active_win) then
    win_close(active_win, true)
  end

  local buf = api.nvim_create_buf(false, true)
  api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  api.nvim_set_option_value("modifiable", false, { buf = buf })
  api.nvim_set_option_value("bufhidden", "wipe", { buf = buf })

  km_set("n", "q", function()
    if active_win then
      win_close(active_win, true)
      active_win, active_path = nil, nil
    end
  end, { buffer = buf })

  km_set("n", "<Esc>", function()
    if active_win then
      win_close(active_win, true)
      active_win, active_path = nil, nil
    end
  end, { buffer = buf })

  local width = 0
  for _, l in ipairs(lines) do
    width = math.max(width, #l)
  end

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

function M.show_from_neotree(state)
  local node = state.tree:get_node()
  if not node or not node.path then
    return
  end

  local stat = uv.fs_stat(node.path)
  if not stat then
    toggle_hover(node.path, { "No file system information available." })
    return
  end

  toggle_hover(node.path, {
    "Path:        " .. node.path,
    "Type:        " .. stat.type,
    "Size:        " .. format_size(stat.size),
    "Permissions: " .. format_permissions(stat),
    "Modified:    " .. os.date("%Y-%m-%d %H:%M:%S", stat.mtime.sec),
  })
end

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
