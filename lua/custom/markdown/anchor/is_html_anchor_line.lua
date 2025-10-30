---@module 'custom.markdown.anchor.is_html_anchor_line'
--- Detect if line or nearby lines contain an HTML anchor (#id)

local api = vim.api

---@param line string
---@return boolean
return function (line)
  if not line then return false end

  -- Check current line for HTML anchors
  if line:match('<%w+[^>]-id%s*=%s*["\']#.-["\']') or
     line:match('<a[^>]-href%s*=%s*["\']#.-["\']') or
     line:match('<img[^>]-src%s*=%s*["\']#.-["\']') then
    -- Explanation of patterns:
    -- 1. '<%w+[^>]-id%s*=%s*["\']#.-["\']'
    --    - <%w+          : matches an HTML tag (e.g., div, section, span)
    --    - [^>]-         : any characters except '>', minimal match
    --    - id%s*=%s*     : the 'id' attribute, optional spaces around '='
    --    - ["\']#.-["\'] : opening quote (' or "), '#' followed by any characters until closing quote
    --
    -- 2. '<a[^>]-href%s*=%s*["\']#.-["\']'
    --    - matches <a> tags with href="#..."
    --
    -- 3. '<img[^>]-src%s*=%s*["\']#.-["\']'
    --    - matches <img> tags with src="#...", rarely used but possible
    return true
  end

  -- Optionally, scan ±5 lines around cursor for multi-line HTML blocks like <figure>
  local bufnr = api.nvim_get_current_buf()
  local curline = api.nvim_win_get_cursor(0)[1]
  local start_line = math.max(1, curline - 5)
  local end_line = math.min(api.nvim_buf_line_count(bufnr), curline + 5)
  local ok, lines = pcall(api.nvim_buf_get_lines, bufnr, start_line-1, end_line, false)
  if ok and lines then
    local joined = table.concat(lines, "\n")
    if joined:match("<figure.-<img[^>]-src%s*=%s*['\"]#.-['\"]") then
      -- Explanation:
      -- <figure        : matches opening <figure> tag
      -- .-             : any characters (minimal), matches content between <figure> and <img>
      -- <img[^>]-      : an <img> tag inside the figure, any other attributes allowed
      -- src%s*=%s*['\"]#.-['\"] : src attribute with '#' anchor, optional spaces around '='
      return true
    end
  end

  return false
end

