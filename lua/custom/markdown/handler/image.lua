---@module 'custom.markdown.handler.image'
--- Open Markdown image under cursor (robust Windows-safe implementation).
--- Provides helpers for extraction, resolution, existence check and cross-platform opening.

---@class custom.markdown.handler.image
---@field config table
---@field extract fun(line:string): string|nil
---@field resolve fun(target:string): string|nil
---@field is_image_line fun(line:string): boolean
---@field open fun(line?:string): boolean

local notify = require("lib.notify").create("[custom.markdown.handler.image]")

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
  if not s then
    return nil
  end
  return s:match("^%s*(.-)%s*$")
end

--- Search for an <img ... src="..."> (or src='...') pattern in a buffer near the current cursor.
--- This helper is used when the current line is part of an HTML <figure> block or when the
--- user cursor is on a nearby line. It scans a configurable number of lines before and after
--- the cursor to find an <img> tag and returns the value of its src attribute.
---@param bufnr number
---@param curline number
---@param radius number
---@return string|nil
local function find_img_src_in_buffer_near_cursor(bufnr, curline, radius)
  -- defensive defaults
  radius = radius or 8
  if not bufnr or not curline then
    return nil
  end

  local start_line = math.max(1, curline - radius)
  local end_line = curline + radius
  local ok, lines = pcall(api.nvim_buf_get_lines, bufnr, start_line - 1, end_line, false)
  if not ok or not lines then
    return nil
  end

  -- join lines into a single string with newlines to allow matching across line breaks,
  -- but also attempt single-line matches first for speed.
  for _, l in ipairs(lines) do
    -- quick single-line match for <img ... src="..."> or src='...'
    local single = l:match('<img[^>]-src%s*=%s*"(.-)"') or l:match("<img[^>]-src%s*=%s*'(.-)'")
    if single and single ~= "" then
      return trim(single)
    end
  end

  -- fallback: multi-line search by concatenating the window and searching for the first <img ...> tag
  local joined = table.concat(lines, "\n")
  -- try to find src attr with double or single quotes, allowing any attributes/newlines before src
  local src = joined:match('<img.-src%s*=%s*"(.-)"') or joined:match("<img.-src%s*=%s*'(.-)'")
  if src and src ~= "" then
    return trim(src)
  end

  -- also consider <source src="..."> inside <picture> or <figure> patterns
  local source_src = joined:match('<source.-src%s*=%s*"(.-)"') or joined:match("<source.-src%s*=%s*'(.-)'")
  if source_src and source_src ~= "" then
    return trim(source_src)
  end

  return nil
end

--- Extract the image target from a markdown line or nearby HTML figure/img tags.
--- Accepts: ![alt](path), ![alt](<path with spaces>), fallback to [text](path)
--- Additionally detects simple HTML snippets:
---   <img src="...">, <img src='...'>, and <figure> ... <img ...> ... </figure>
--- When the provided `line` is part of a multi-line HTML figure block, this function will
--- scan surrounding buffer lines (±8 by default) to locate the image `src`.
---@param line string
---@return string|nil
local function extract_image_target_from_line(line)
  if not line or line == "" then
    return nil
  end

  -- prefer explicit markdown image syntax first: ![alt](path) or ![alt](<path with spaces>)
  -- capture everything inside the parentheses
  local t = line:match("!%b[]%(([^)]+)%)")
  if not t then
    -- fallback: plain markdown link syntax [text](path)
    t = line:match("%[.-%]%((.-)%)")
  end

  -- If markdown-style target found, normalize and return
  if t ~= nil and t ~= "" then
    t = trim(t)
    if t and t:match("^<.+>$") then
      t = t:sub(2, -2)
    end
    return t
  end

  -- No markdown image/link found on the line. Check for inline HTML <img ... src="...">
  -- Attempt single-line <img> capture (double or single quoted src)
  local img_src = line:match('<img[^>]-src%s*=%s*"(.-)"') or line:match("<img[^>]-src%s*=%s*'(.-)'")
  if img_src and img_src ~= "" then
    return trim(img_src)
  end

  -- The current line might be a <figure> start or other HTML wrapper. In that case,
  -- attempt to search the surrounding buffer for an <img> tag and extract its src.
  -- Use protected calls since this helper might be used in contexts without a visible window.
  local ok, bufnr = pcall(api.nvim_get_current_buf)
  if not ok or not bufnr then
    return nil
  end

  -- try to obtain current cursor line number; fallback to 1 if unavailable
  local ok2, cursor = pcall(api.nvim_win_get_cursor, 0)
  local curline = (ok2 and cursor and cursor[1]) or 1

  -- If the provided `line` looks like HTML container or has an <figure> tag, scan nearby lines.
  if line:match("<figure") or line:match("<img") or line:match("<picture") then
    local found = find_img_src_in_buffer_near_cursor(bufnr, curline, 12)
    if found and found ~= "" then
      return found
    end
  end

  -- If nothing found yet, as a last-ditch effort, run a small windowed search around cursor
  -- to capture cases where the line itself is e.g. the <figure> opening and the <img> sits a few lines below.
  local found = find_img_src_in_buffer_near_cursor(bufnr, curline, 12)
  if found and found ~= "" then
    return found
  end

  return nil
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
  if not target then
    return nil
  end
  if is_url(target) then
    return target
  end

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
  if not path or path == "" then
    return false
  end

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
      notify.error("[Custom.Markdown] Image: Failed to spawn viewer for: " .. tostring(path))
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
      notify.info("[Custom.Markdown] Image: No image/link found under cursor")
    end
    return false
  end

  local resolved = resolve_target_to_path(target)
  if not resolved or resolved == "" then
    if M.config.notify_on_error then
      notify.error("[Custom.Markdown] Image: Could not resolve path: " .. tostring(target))
    end
    return false
  end

  -- If not a URL, verify the file exists
  if not is_url(resolved) then
    local stat = uv.fs_stat(resolved)
    if not stat then
      if M.config.notify_on_error then
        notify.warn("[Custom.Markdown] Image: File does not exist: " .. resolved)
      end
      return false
    end
  end

  return open_with_system_viewer(resolved)
end

return M
