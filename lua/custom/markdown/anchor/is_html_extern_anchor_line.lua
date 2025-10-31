--- BUG: Funktioniert nicht!

---@module 'custom.markdown.anchor.is_html_extern_anchor_line'
--- Detect if the current line (or nearby lines) contains a Markdown/HTML link
--- that references an external file (optionally with a fragment/anchor).
--- This helper intentionally focuses on *external* file links like:
---   - Markdown inline links: [text](path/to/file.md#anchor)
---   - Markdown image links:     ![alt](../figs/img.png#anchor)
---   - HTML tags:                <a href="docs/other.md#id">, <img src="file.svg#id">
--- It excludes pure intra-file anchors that start with `#` and excludes
--- full URLs with protocols (http://, https://, mailto:, etc.).
--- The function is conservative: it returns true when it is likely the line
--- links to a file (with optional #fragment) so the caller can attempt a file-open + anchor jump.
---
--- Comments and function docs are written in English per project convention.

local api = vim.api

--- Determine whether a URI looks like an external file reference.
--- We consider it a file if:
---  * it contains a path separator (`/` or `\`) or a filename with an extension (e.g. `.md`, `.html`, `.png`, `.svg`),
---  * and it does NOT begin with a lone `#` (intra-file anchor),
---  * and it does NOT start with a known protocol (e.g. http:, https:, mailto:, ftp:).
---@param uri string
---@return boolean
local function looks_like_file_uri(uri)
  if not uri or uri == "" then return false end
  -- trim surrounding whitespace
  uri = uri:match("^%s*(.-)%s*$")

  -- ignore fragment-only anchors
  if uri:match("^#") then return false end

  -- ignore protocol-based URIs
  if uri:match("^%w[%w+.-]*:") then return false end

  -- if it contains a path separator or a common file-extension -> likely a file
  if uri:match("[/\\]") then return true end
  if uri:match("%.[%w%d]+%s*$") then return true end

  -- also treat things like "file.md#anchor" (no slash) as file-like
  if uri:match("%.%w+[#]") or uri:match("%.%w+$") then return true end

  return false
end

--- Check markdown inline/link pattern for external-file + optional anchor.
--- Matches `( ... )` content and decides via looks_like_file_uri().
---@param line string
---@return boolean
local function markdown_link_is_file(line)
  -- find first parentheses content for markdown link or image
  -- examples: (file.md#id), (./path/to/file.md#id), (![alt](file.png#id))
  local inner = line:match("%(([^%)]+)%)")
  if not inner or inner == "" then return false end
  -- If inner contains multiple comma-separated items (rare), still examine first token
  inner = inner:match("^%s*(.-)%s*$")
  -- Exclude protocol URLs and pure fragments
  if looks_like_file_uri(inner) then
    return true
  end
  return false
end

--- Check HTML tag attributes for file-like href/src values.
--- Handles <a href="...">, <img src="..."> and generic tags with href/src attributes.
---@param line string
---@return boolean
local function html_attr_is_file(line)
  -- try to capture href / src attribute values on the same line
  for _ in line:gmatch("[%s%w]-([hH][rR][eE][fF])%s*=%s*['\"]?([^'\">%s]+)") do
    -- (unlikely this loop runs because pattern returns attr then value, keep for safety)
		vim.notify("[Custom.Markdown] Anchor: ref / src attribute values captured on the same line", vim.log.levels.INFO)
  end

  -- capture href
  local href = line:match('<a[^>]-href%s*=%s*["\']([^"\']+)["\']')
  if href and looks_like_file_uri(href) then return true end

  -- capture generic href without quotes (less common)
  href = line:match('<a[^>]-href%s*=%s*([^%s>]+)')
  if href and looks_like_file_uri(href) then return true end

  -- capture img src
  local src = line:match('<img[^>]-src%s*=%s*["\']([^"\']+)["\']')
  if src and looks_like_file_uri(src) then return true end

  src = line:match('<img[^>]-src%s*=%s*([^%s>]+)')
  if src and looks_like_file_uri(src) then return true end

  -- capture other tags with src/href-like attributes (e.g., <a data-src="..."> is ignored)
  return false
end

--- Scan ±N lines around cursor for inline markdown-style or HTML file links.
--- This helps detect multi-line constructs or when the cursor is on surrounding text.
---@param line string
---@return boolean
local function scan_neighboring_lines_for_file_link(line)
  -- Quick check current line first
  if markdown_link_is_file(line) or html_attr_is_file(line) then return true end

  local bufnr = api.nvim_get_current_buf()
  local cur = api.nvim_win_get_cursor(0)[1]
  local start_line = math.max(1, cur - 5)
  local end_line = math.min(api.nvim_buf_line_count(bufnr), cur + 5)
  local ok, lines = pcall(api.nvim_buf_get_lines, bufnr, start_line-1, end_line, false)
  if not ok or not lines then return false end

  local joined = table.concat(lines, " ")
  if markdown_link_is_file(joined) or html_attr_is_file(joined) then return true end

  -- also detect <figure ...> ... <img src="file.md#id"> across lines
  if joined:match("<figure.-<img[^>]-src%s*=%s*['\"][^'\"]*#.-['\"]") then
    return true
  end

  return false
end

--- Public entry: return true when the current line (or the nearby block)
--- likely contains a reference to an external file (optionally with fragment).
--- This function is intentionally permissive: it returns true when a file-like
--- uri is present so the central handler may attempt to open the file and jump.
---@param line string
---@return boolean
return function(line)
  if not line then return false end

  -- 1) Inline markdown link pointing to a file: (file.md#anchor) or (path/to/file#anchor)
  if markdown_link_is_file(line) then return true end

  -- 2) HTML attributes pointing to a file: <a href="file.md#id"> or <img src="...#id">
  if html_attr_is_file(line) then return true end

  -- 3) Scan surrounding lines for multi-line HTML/figure blocks that contain file links
  if scan_neighboring_lines_for_file_link(line) then return true end

  return false
end
