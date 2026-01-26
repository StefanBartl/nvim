---@module 'usrcmds.fileinfo'
---User command and keymap to toggle a floating file information window
---for the currently active buffer.

local bitlib = require("bit")

local M = {}

local uv = vim.uv or vim.loop
local api = vim.api
local win_close = api.nvim_win_close
local str_format = string.format
local km_set = vim.keymap.set
local os_date = os.date

---@type integer|nil
local active_win = nil

---@type string|nil
local active_path = nil

---Format permissions depending on platform
---@param stat table
---@return string
local function format_permissions(stat)
  local mode = stat.mode or 0
  local octal = str_format("%o", mode)

  if vim.fn.has("win32") == 1 then
    return octal .. " (Windows ACL / readonly flag, limited POSIX meaning)"
  end

  local perm = mode % 512
  local map = { "r", "w", "x" }
  local function bits(v)
    local s = ""
for i = 2, 0, -1 do
  local b = 2 ^ i
  s = s .. ((bitlib.band(v, b) ~= 0) and map[3 - i] or "-")
end
    return s
  end

  local u = bits(math.floor(perm / 64))
  local g = bits(math.floor((perm % 64) / 8))
  local o = bits(perm % 8)

  return str_format(
    "%s (POSIX %s %s %s)",
    octal,
    u,
    g,
    o
  )
end

---Format file size in bytes and MiB
---@param size integer
---@return string
local function format_size(size)
  local mib = size / (1024 * 1024)
  return str_format("%d bytes (%.2f MiB)", size, mib)
end

---Create or toggle hover window
---@param path string
---@param lines string[]
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
  end, { buffer = buf, nowait = true })

  km_set("n", "<Esc>", function()
    if active_win then
      win_close(active_win, true)
      active_win, active_path = nil, nil
    end
  end, { buffer = buf, nowait = true })

  local width = 0
  for _, l in ipairs(lines) do
    width = math.max(width, #l)
  end

  local win = api.nvim_open_win(buf, true, {
    relative = "editor",
    style = "minimal",
    border = "rounded",
    width = width + 2,
    height = #lines,
    row = 2,
    col = math.floor((vim.o.columns - width) / 2),
  })

  active_win = win
  active_path = path
end

---Collect and display info for current buffer
local function show_file_info()
  local path = api.nvim_buf_get_name(0)
  if path == "" then
    toggle_hover("<buffer>", { "Current buffer has no associated file." })
    return
  end

  local stat = uv.fs_stat(path)
  if not stat then
    toggle_hover(path, { "No file system information available." })
    return
  end

  toggle_hover(path, {
    "Path:        " .. path,
    "Type:        " .. stat.type,
    "Size:        " .. format_size(stat.size),
    "Permissions: " .. format_permissions(stat),
    "UID:         " .. (stat.uid or "n/a"),
    "GID:         " .. (stat.gid or "n/a"),
    "Accessed:    " .. os_date("%Y-%m-%d %H:%M:%S", stat.atime.sec),
    "Modified:    " .. os_date("%Y-%m-%d %H:%M:%S", stat.mtime.sec),
    "Changed:    " .. os_date("%Y-%m-%d %H:%M:%S", stat.ctime.sec),
  })
end

---Enable user command and keymap
function M.enable()
  api.nvim_create_user_command("FileInfo", show_file_info, {})
  km_set("n", "<leader>fi", show_file_info, { desc = "[usrcmds.fileinfo] Toggle file info hover" })
end

return M
