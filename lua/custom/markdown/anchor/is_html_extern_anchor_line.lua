---@module 'custom.markdown.anchor.is_html_extern_anchor_line'
--- Detect and parse external file-like links (with optional fragment/anchor)
--- Examples detected:
---   [text](path/to/file.md#anchor)
---   ![alt](../figs/img.png#anchor)
---   <a href="docs/other.md#id">, <img src="file.svg#id">
--- Returns table { target = "<path-or-uri>", fragment = "<anchor-or-nil>" } or nil.
local api = vim.api

local function trim(s)
  if not s then return nil end
  return s:match("^%s*(.-)%s*$")
end

-- Heuristic: treat as file-like if contains slash or has a file-extension.
local function looks_like_file_uri(uri)
  if not uri or uri == "" then return false end
  uri = trim(uri)
	if not uri then return nil end
  if uri:match("^#") then return false end
  -- protocol check
  if uri:match("^%w[%w+.-]*:") then return false end
  if uri:match("[/\\]") then return true end
  if uri:match("%.[%w%d]+%s*$") then return true end
  if uri:match("%.%w+[#]") or uri:match("%.%w+$") then return true end
  return false
end

-- Extract first parentheses content for markdown link/image
local function extract_md_paren_target(line)
  if not line then return nil end
  -- capture inner of first parentheses: [text](HERE)
  local inner = line:match("%b()")
  if not inner then return nil end
  inner = inner:sub(2, -2) -- remove surrounding ()
  inner = trim(inner)
  if inner == "" then return nil end
  return inner
end

-- Extract href/src from HTML tag on a line (basic)
local function extract_html_attr(line)
  if not line then return nil end
  local href = line:match('<a[^>]-href%s*=%s*"(.-)"') or line:match("<a[^>]-href%s*=%s*'(.-)'")
  if href and href ~= "" then return href end
  href = line:match('<img[^>]-src%s*=%s*"(.-)"') or line:match("<img[^>]-src%s*=%s*'(.-)'")
  if href and href ~= "" then return href end
  -- also generic attr without quotes (rare)
  href = line:match('<a[^>]-href%s*=%s*([^%s>]+)') or line:match('<img[^>]-src%s*=%s*([^%s>]+)')
  if href and href ~= "" then return href end
  return nil
end

-- If the buffer contains a multi-line tag, scan ±radius lines for a matching attr.
local function find_attr_near_cursor(radius)
  radius = radius or 8
  local ok, bufnr = pcall(api.nvim_get_current_buf)
  if not ok or not bufnr then return nil end
  local ok2, cur = pcall(api.nvim_win_get_cursor, 0)
  local curline = (ok2 and cur and cur[1]) or 1
  local start_line = math.max(1, curline - radius)
  local end_line = math.min(api.nvim_buf_line_count(bufnr), curline + radius)
  local ok3, lines = pcall(api.nvim_buf_get_lines, bufnr, start_line-1, end_line, false)
  if not ok3 or not lines then return nil end
  local joined = table.concat(lines, " ")
  -- try to pick first href/src in the joined chunk
  local v = joined:match('href%s*=%s*"(.-)"') or joined:match("href%s*=%s*'(.-)'")
         or joined:match('src%s*=%s*"(.-)"') or joined:match("src%s*=%s*'(.-)'")
  if v and v ~= "" then return trim(v) end
  return nil
end

-- parse a target like "path/to/file.md#anchor" into target and fragment
local function split_target_and_fragment(s)
  if not s or s == "" then return nil end
  -- strip surrounding <> used in markdown for spaces: <path with spaces>
  if s:match("^<.+>$") then s = s:sub(2, -2) end
  s = trim(s)
  -- sometimes title-like syntax "file.md 'title'" may appear; keep only token before space
  if not s then return nil end
  local token = s:match("^(%S+)")
  if not token then token = s end
  local before, frag = token:match("^(.-)#(.-)$")
  if before then
    return trim(before), trim(frag)
  else
    return token, nil
  end
end

-- Public: scan the line (and nearby lines) and return { target, fragment } if looks like external file link
return function(line)
  if not line or line == "" then
    -- try to find an html attr near cursor (if line empty)
    local near = find_attr_near_cursor(8)
    if near and looks_like_file_uri(near) then
      local t, f = split_target_and_fragment(near)
      if t then return { target = t, fragment = f } end
    end
    return nil
  end

  -- 1) markdown parenthesis-based link/image
  local md_target = extract_md_paren_target(line)
  if md_target and looks_like_file_uri(md_target) then
    local t, f = split_target_and_fragment(md_target)
    if t then return { target = t, fragment = f } end
  end

  -- 2) inline HTML attributes
  local html_target = extract_html_attr(line)
  if html_target and looks_like_file_uri(html_target) then
    local t, f = split_target_and_fragment(html_target)
    if t then return { target = t, fragment = f } end
  end

  -- 3) multi-line HTML blocks near cursor
  local near = find_attr_near_cursor(12)
  if near and looks_like_file_uri(near) then
    local t, f = split_target_and_fragment(near)
    if t then return { target = t, fragment = f } end
  end

  return nil
end
