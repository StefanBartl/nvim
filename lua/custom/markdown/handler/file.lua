---@module 'custom.markdown.handler.file'
--- Open local file under cursor (robust detection for Markdown links and simple HTML anchors/figures).
--- Provides helpers for extraction, resolution, existence check and cross-platform opening.

local M = {}

---@type table
M.config = {
  resolve_relative_to_buffer = true,
  cmd_unix = "xdg-open",
  cmd_macos = "open",
  cmd_windows = "cmd",
  notify_on_error = true,
  html_scan_radius = 12, -- number of lines to scan around cursor for html anchors/imgs
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

--- Search for an <a ... href="..."> or <img ... src="..."> pattern in a buffer near the current cursor.
--- This helper is used when the current line contains HTML wrappers like <figure> and the
--- actual href/src sits a few lines away. It scans ±radius lines around the cursor.
---@param bufnr BufNr
---@param curline number
---@param radius number
---@return string|nil
local function find_href_or_imgsrc_in_buffer_near_cursor(bufnr, curline, radius)
  radius = radius or M.config.html_scan_radius
  if not bufnr or not curline then return nil end

  local start_line = math.max(1, curline - radius)
  local end_line = curline + radius
  local ok, lines = pcall(api.nvim_buf_get_lines, bufnr, start_line - 1, end_line, false)
  if not ok or not lines then return nil end

  -- Quick single-line search first
  for _, l in ipairs(lines) do
    -- anchor href double or single quotes
    local href = l:match('<a[^>]-href%s*=%s*"(.-)"')
              or l:match("<a[^>]-href%s*=%s*'(.-)'")
    if href and href ~= "" then
      return trim(href)
    end
    -- image src double or single quotes (useful when HTML figure contains only <img>)
    local img = l:match('<img[^>]-src%s*=%s*"(.-)"')
             or l:match("<img[^>]-src%s*=%s*'(.-)'")
    if img and img ~= "" then
      return trim(img)
    end
  end

  -- Multi-line join search (covers tags split across lines)
  local joined = table.concat(lines, "\n")
  local href = joined:match('<a.-href%s*=%s*"(.-)"')
            or joined:match("<a.-href%s*=%s*'(.-)'")
  if href and href ~= "" then return trim(href) end

  local img = joined:match('<img.-src%s*=%s*"(.-)"')
           or joined:match("<img.-src%s*=%s*'(.-)'")
  if img and img ~= "" then return trim(img) end

  -- also consider <source src="..."> inside <picture>
  local source_src = joined:match('<source.-src%s*=%s*"(.-)"')
                  or joined:match("<source.-src%s*=%s*'(.-)'")
  if source_src and source_src ~= "" then return trim(source_src) end

  return nil
end

--- Extract the file target from a markdown line or nearby HTML anchor/img tags.
--- Accepts: [text](path), [text](<path with spaces>).
--- Additionally detects simple HTML snippets:
---   <a href="...">, <a href='...'>, <img src="...">, <figure> ... <img ...>
--- If a markdown link is present it is preferred. If no markdown link exists the buffer
--- is scanned near the cursor for HTML anchors or images and their href/src is returned.
---@param line string
---@return Path|Url|nil
local function extract_file_target_from_line(line)
  if not line or line == "" then return nil end

  -- Prefer markdown link syntax first: [text](path) or [text](<path with spaces>)
  local target = line:match("%[.-%]%((.-)%)")
  if target and target ~= "" then
    target = trim(target)
    -- strip enclosing angle brackets if present: [text](<path with spaces>)
    if target and target:match("^<.+>$") then target = target:sub(2, -2) end
    return target
  end

  -- If there is an inline HTML anchor or img on the same line, capture it
  local href = line:match('<a[^>]-href%s*=%s*"(.-)"')
            or line:match("<a[^>]-href%s*=%s*'(.-)'")
  if href and href ~= "" then return trim(href) end

  local img_src = line:match('<img[^>]-src%s*=%s*"(.-)"')
               or line:match("<img[^>]-src%s*=%s*'(.-)'")
  if img_src and img_src ~= "" then return trim(img_src) end

  -- No direct match on the line; attempt to locate anchor/img nearby in buffer
  local ok, bufnr = pcall(api.nvim_get_current_buf)
  if not ok or not bufnr then
    return nil
  end

  local ok2, cursor = pcall(api.nvim_win_get_cursor, 0)
  local curline = (ok2 and cursor and cursor[1]) or 1

  local found = find_href_or_imgsrc_in_buffer_near_cursor(bufnr, curline, M.config.html_scan_radius)
  if found and found ~= "" then
    return found
  end

  return nil
end

--- Return true if a target looks like a URL (http/https).
---@param target string
---@return boolean
local function is_url(target)
  return target and target:match("^https?://") ~= nil
end

--- Resolve a target to an absolute path (or return URL unmodified).
--- If configured, resolve relative paths against buffer directory.
---@param target Path|Url
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

  local ok, jid = pcall(vim.fn.jobstart, cmd, { detach = true })
  if not ok or jid == 0 or jid == -1 then
    if M.config.notify_on_error then
      vim.notify("[Custom.Markdown] File: Failed to spawn viewer for: " .. tostring(path), vim.log.levels.ERROR)
    end
    return false
  end
  return true
end

--- Detect if line contains a file link (markdown link or simple HTML anchor/img nearby).
--- This returns true only for non-HTTP(S) targets (local files).
---@param line string
---@return boolean
function M.is_file_line(line)
  local target = extract_file_target_from_line(line)
  if not target then return false end
  -- consider URL targets non-file
  return not is_url(target)
end

--- Public: extract function (exported for tests/debugging).
---@param line string
---@return string|nil
function M.extract(line)
  return extract_file_target_from_line(line)
end

--- Public: resolve function (exported for tests/debugging).
---@param target string
---@return string|nil
function M.resolve(target)
  return resolve_target_to_path(target)
end

--- Open file under cursor (markdown link, anchor href or image src).
--- Returns true on spawn success, false otherwise.
---@param line string|nil
---@return boolean
function M.open(line)
  -- if line not provided, try the current buffer line under the cursor
  line = line or api.nvim_get_current_line()
  local target = extract_file_target_from_line(line)
  if not target then
    if M.config.notify_on_error then
      vim.notify("[Custom.Markdown] File: No link/file found under cursor", vim.log.levels.INFO)
    end
    return false
  end

  local resolved = resolve_target_to_path(target)
  if not resolved or resolved == "" then
    if M.config.notify_on_error then
      vim.notify("[Custom.Markdown] File: Could not resolve path: " .. tostring(target), vim.log.levels.ERROR)
    end
    return false
  end

  -- If target is a URL, open directly (no fs check)
  if is_url(resolved) then
    return open_with_system_viewer(resolved)
  end

  -- Verify file existence before opening
  local stat = uv.fs_stat(resolved)
  if not stat then
    if M.config.notify_on_error then
      vim.notify("[Custom.Markdown] File: File does not exist: " .. resolved, vim.log.levels.WARN)
    end
    return false
  end

  local ok = open_with_system_viewer(resolved)
  if ok then
    if M.config.notify_on_error then
      vim.notify("[Custom.Markdown] File: Opening -> " .. resolved, vim.log.levels.INFO)
    end
  else
    if M.config.notify_on_error then
      vim.notify("[Custom.Markdown] File: Failed to open -> " .. resolved, vim.log.levels.ERROR)
    end
  end
  return ok
end

return M
