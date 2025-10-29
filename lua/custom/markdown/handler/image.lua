---@module 'custom.markdown.handler.image'
--- Open Markdown image under cursor (robust Windows-safe implementation).
--- Provides helpers for extraction, resolution, existence check and cross-platform opening.
--- English comments for code; German explanation outside code block follows.
---@license "MIT"
---@copyright "2025"
---@class custom.markdown.handler.image
---@field config table
---@field extract fun(line:string): string|nil
---@field resolve fun(target:string): string|nil
---@field is_image_line fun(line:string): boolean
---@field open fun(line?:string): boolean
local M = {}

---@type table
M.config = {
  resolve_relative_to_buffer = true,
  cmd_unix = "xdg-open",
  cmd_macos = "open",
  cmd_windows = "cmd",
  notify_on_error = true,
}

local api = vim.api
local uv = vim.loop

-- Trim helper
---@param s string
---@return string|nil
local function trim(s)
  if not s then return nil end
  return s:match("^%s*(.-)%s*$")
end

--- Extract the image target from a markdown line.
--- Accepts: ![alt](path), ![alt](<path with spaces>), fallback to [text](path).
---@param line string
---@return string|nil
local function extract_image_target_from_line(line)
  if not line or line == "" then return nil end
  -- prefer explicit image syntax first
  local t = line:match("!%b[]%(([^)]+)%)")
  if not t then
    -- fallback: plain link syntax
    t = line:match("%[.-%]%((.-)%)")
  end
  if not t then return nil end
  t = trim(t)
  if t:match("^<.+>$") then t = t:sub(2, -2) end
  return t
end

--- Return true if a target looks like a URL.
---@param target string
---@return boolean
local function is_url(target)
  return target and target:match("^https?://") ~= nil
end

--- Resolve a target to an absolute path (or return URL unmodified).
--- If configured, resolve relative paths against buffer directory.
---@param target string
---@return string|nil
local function resolve_target_to_path(target)
  if not target then return nil end
  if is_url(target) then return target end

  -- expand environment variables and ~
  local expanded = vim.fn.expand(target)

  -- If not absolute, make it relative to buffer dir if configured
  if M.config.resolve_relative_to_buffer and not expanded:match("^/") and not expanded:match("^%a:[/\\]") then
    local bufdir = vim.fn.expand("%:p:h")
    if bufdir and bufdir ~= "" then
      expanded = vim.fn.fnamemodify(bufdir .. "/" .. expanded, ":p")
    else
      expanded = vim.fn.fnamemodify(expanded, ":p")
    end
  else
    expanded = vim.fn.fnamemodify(expanded, ":p")
  end

  return expanded
end

--- Cross-platform open using shell-escaped string command.
--- Uses shell command string to allow Windows `start` to interpret quotes correctly.
---@param path string
---@return boolean
local function open_with_system_viewer(path)
  if not path or path == "" then return false end

  local esc = vim.fn.shellescape(path)
  local sysname = (uv.os_uname() and uv.os_uname().sysname) or ""
  local cmd

  if sysname:match("Windows") or sysname:match("windows") then
    -- cmd /C start "" "C:\full\path\to\file.png"
    -- Using shell string ensures the quoting semantics of start are respected.
    cmd = string.format('cmd /C start "" %s', esc)
  elseif sysname == "Darwin" then
    cmd = string.format("open %s", esc)
  else
    cmd = string.format("%s %s", M.config.cmd_unix, esc)
  end

  -- run as shell command string (jobstart with string -> run via shell)
  local ok, jid = pcall(vim.fn.jobstart, cmd, { detach = true })
  if not ok or jid == 0 or jid == -1 then
    if M.config.notify_on_error then
      vim.notify("[Custom.Markdown] Image: Failed to spawn viewer for: " .. tostring(path), vim.log.levels.ERROR)
    end
    return false
  end
  return true
end

--- Public: return true if line contains an image target.
---@param line string
---@return boolean
function M.is_image_line(line)
  return extract_image_target_from_line(line) ~= nil
end

--- Public: extract function (exported for tests/debugging).
---@param line string
---@return string|nil
function M.extract(line)
  return extract_image_target_from_line(line)
end

--- Public: resolve function (exported for tests/debugging).
---@param target string
---@return string|nil
function M.resolve(target)
  return resolve_target_to_path(target)
end

--- Open image (or image-like link) for given line or current line.
--- Returns true on spawn success, false otherwise.
---@param line string|nil
---@return boolean
function M.open(line)
  line = line or api.nvim_get_current_line()
  local target = extract_image_target_from_line(line)
  if not target then
    if M.config.notify_on_error then
      vim.notify("[Custom.Markdown] Image: No image/link found under cursor", vim.log.levels.INFO)
    end
    return false
  end

  local resolved = resolve_target_to_path(target)
  if not resolved or resolved == "" then
    if M.config.notify_on_error then
      vim.notify("[Custom.Markdown] Image: Could not resolve path: " .. tostring(target), vim.log.levels.ERROR)
    end
    return false
  end

  -- If not a URL, verify the file exists
  if not is_url(resolved) then
    local stat = uv.fs_stat(resolved)
    if not stat then
      if M.config.notify_on_error then
        vim.notify("[Custom.Markdown] Image: File does not exist: " .. resolved, vim.log.levels.WARN)
      end
      return false
    end
  end

  -- Debug notification (optional; comment out when stable)
  -- vim.notify("[Custom.Markdown] Image: Opening -> " .. resolved, vim.log.levels.DEBUG)

  return open_with_system_viewer(resolved)
end

return M
