---@module 'custom.markdown.handler.url'
--- Open URL under cursor in default browser (robust detection for Markdown links,
--- inline raw URLs, and simple HTML anchors). Exports helpers for extraction and
--- cross-platform opening.

local M = {}

---@type table
M.config = {
  html_scan_radius = 12,         -- lines to scan around cursor for HTML anchors
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

--- Return true if a target looks like a URL (http/https).
---@param target string
---@return boolean
local function is_explicit_url(target)
  if not target then return false end
  return target:match("^https?://") ~= nil
end

--- Search for an <a ... href="..."> pattern in a buffer near the current cursor.
--- Scans for both double-quoted and single-quoted href attributes. Returns the first match.
---@param bufnr number
---@param curline number
---@param radius number
---@return string|nil
local function find_href_in_buffer_near_cursor(bufnr, curline, radius)
  radius = radius or M.config.html_scan_radius
  if not bufnr or not curline then return nil end

  local start_line = math.max(1, curline - radius)
  local end_line = curline + radius
  local ok, lines = pcall(api.nvim_buf_get_lines, bufnr, start_line - 1, end_line, false)
  if not ok or not lines then return nil end

  -- quick single-line matches first
  for _, l in ipairs(lines) do
    local href = l:match('<a[^>]-href%s*=%s*"(.-)"')
              or l:match("<a[^>]-href%s*=%s*'(.-)'")
    if href and href ~= "" then
      return trim(href)
    end
  end

  -- fallback: joined multi-line match (covers tags split across lines)
  local joined = table.concat(lines, "\n")
  local href = joined:match('<a.-href%s*=%s*"(.-)"')
            or joined:match("<a.-href%s*=%s*'(.-)'")
  if href and href ~= "" then
    return trim(href)
  end

  return nil
end

--- Extract URL from a single line or, if the line is HTML container, scan nearby buffer.
--- Detects:
---  * Markdown link: [text](https://example)
---  * Inline raw URL: https://example or http://example
---  * HTML anchor: <a href="https://example"> (scans surrounding lines if needed)
---@param line string
---@return Url|nil
local function extract_url_from_line(line)
  if not line or line == "" then return nil end

  -- Prefer markdown link syntax first: [text](url)
  local md = line:match("%[.-%]%((.-)%)")
  if md and md ~= "" then
    md = trim(md)
    if md:match("^<.+>$") then md = md:sub(2, -2) end
    if is_explicit_url(md) then
      return md
    end
    -- If markdown link target is not a http(s) URL, treat as non-URL (return nil)
    return nil
  end

  -- Then check for inline raw URL patterns on the same line
  -- This matches http(s)://... and common punctuation-terminated cases.
  local raw = line:match("https?://[%w%-%_%.%/%?%%=&~#@:+,;%%]+")
  if raw and raw ~= "" then
    -- trim trailing punctuation if present (common markdown/typo cases)
    raw = raw:gsub("[%.,;:%)%]%}]+$", "")
    return trim(raw)
  end

  -- Then check for simple HTML anchor on the same line
  local href = line:match('<a[^>]-href%s*=%s*"(.-)"')
            or line:match("<a[^>]-href%s*=%s*'(.-)'")
  if href and href ~= "" and is_explicit_url(href) then
    return trim(href)
  end

  -- No match on the line; attempt to locate an <a href="..."> nearby in the buffer.
  local ok, bufnr = pcall(api.nvim_get_current_buf)
  if not ok or not bufnr then return nil end

  local ok2, cursor = pcall(api.nvim_win_get_cursor, 0)
  local curline = (ok2 and cursor and cursor[1]) or 1

  local found = find_href_in_buffer_near_cursor(bufnr, curline, M.config.html_scan_radius)
  if found and found ~= "" and is_explicit_url(found) then
    return found
  end

  return nil
end

--- Cross-platform open using shell-escaped string command.
--- Uses shell command string to allow Windows `start` to interpret quotes correctly.
---@param url string
---@return boolean
local function open_with_system_viewer(url)
  if not url or url == "" then return false end

  -- For URLs, do not shellescape fully (leave as argument) to avoid breaking certain shells;
  -- however for Windows start via cmd we need quoting semantics. Use shell string approach
  -- as in other handlers to keep behaviour consistent.
  local esc = vim.fn.shellescape(url)
  local sysname = (uv.os_uname() and uv.os_uname().sysname) or ""
  local cmd

  if sysname:match("Windows") or sysname:match("windows") then
    cmd = string.format('cmd /C start "" %s', esc)
  elseif sysname == "Darwin" then
    cmd = string.format("open %s", esc)
  else
    cmd = string.format("%s %s", M.config.cmd_unix, esc)
  end

  local ok, jid = pcall(vim.fn.jobstart, cmd, { detach = true })
  if not ok or jid == 0 or jid == -1 then
    if M.config.notify_on_error then
      vim.notify("[Custom.Markdown] URL: Failed to spawn browser for: " .. tostring(url), vim.log.levels.ERROR)
    end
    return false
  end
  return true
end

--- Detect if line contains an URL (markdown link, inline URL, or HTML anchor nearby).
---@param line string
---@return boolean
function M.is_url_line(line)
  local url = extract_url_from_line(line)
  return url ~= nil
end

--- Public: extract function (exported for tests/debugging).
---@param line string
---@return string|nil
function M.extract(line)
  return extract_url_from_line(line)
end

--- Open URL under cursor.
--- Accepts markdown-style links, inline http(s) URLs, and HTML anchors (scanned nearby).
--- Returns true on spawn success, false otherwise.
---@param line string|nil
---@return boolean
function M.open(line)
  line = line or api.nvim_get_current_line()
  local target = extract_url_from_line(line)
  if not target then
    if M.config.notify_on_error then
      vim.notify("[Custom.Markdown] URL: No URL found under cursor", vim.log.levels.INFO)
    end
    return false
  end

  -- No need to verify existence for URLs.
  local ok = open_with_system_viewer(target)
  if ok then
    if M.config.notify_on_error then
      vim.notify("[Custom.Markdown] URL: Opening -> " .. target, vim.log.levels.INFO)
    end
  else
    if M.config.notify_on_error then
      vim.notify("[Custom.Markdown] URL: Failed to open -> " .. target, vim.log.levels.ERROR)
    end
  end
  return ok
end

return M
