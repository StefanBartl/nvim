---@module 'uv_doc.parser'
---@brief HTML/RST parsing and symbol extraction

local M = {}

local strings = require("lib.lua.strings")

--- Extracts uv_* symbols from genindex HTML
---@param html string
---@nodiscard
---@return string[]
function M.parse_symbols(html)
  ---@type table<string, boolean>
  local seen = {}

  -- Pattern 1: Double-quoted hrefs
  for id_part in html:gmatch('href="[^"]-%.html#c%.(uv_[%w_]+)"') do
    if id_part and not seen[id_part] then
      seen[id_part] = true
    end
  end

  -- Pattern 2: Single-quoted hrefs
  for id_part in html:gmatch("href='[^']-%.html#c%.(uv_[%w_]+)'") do
    if id_part and not seen[id_part] then
      seen[id_part] = true
    end
  end

  ---@type string[]
  local symbols = {}
  for name in pairs(seen) do
    symbols[#symbols + 1] = name
  end

  table.sort(symbols)
  return symbols
end

--- Finds HTML href for symbol
---@param html string
---@param uvname string
---@nodiscard
---@return string|nil
function M.find_href(html, uvname)
  local anchor = "c." .. uvname
  local escaped = vim.pesc(anchor)

  local pattern_dq = 'href="([^"]-%.html#' .. escaped .. ')"'
  local href = html:match(pattern_dq)
  if href then
    return href
  end

  local pattern_sq = "href='([^']-%.html#" .. escaped .. ")'"
  return html:match(pattern_sq)
end

--- Converts HTML href to RST source path
---@param href string
---@nodiscard
---@return string
function M.href_to_rst(href)
  local page = href:match("^([^#]+)%.html")
  if not page then
    return "_sources/index.rst.txt"
  end
  return "_sources/" .. page .. ".rst.txt"
end

--- Extracts c:function:: block from RST
---@param rst string
---@param uvname string
---@nodiscard
---@return string signature
---@return string[] body_lines
function M.extract_function(rst, uvname)
  local sig_pattern = "%.%.%s+c:function::%s+([^\n]-" .. vim.pesc(uvname) .. "%b())"
  local sig_start, sig_end = rst:find(sig_pattern)

  if not sig_start or not sig_end then
    return "", { "[uvdoc] function signature not found: " .. uvname }
  end

  local signature = rst:match(sig_pattern) or ""
  local tail = rst:sub(sig_end + 1)
  local next_directive = tail:find("\n%.%.[^\n]-::")
  local body_chunk = next_directive and tail:sub(1, next_directive - 1) or tail

  ---@type string[]
  local lines = {}
  for line in body_chunk:gmatch("([^\n]*)\n?") do
    lines[#lines + 1] = strings.trim(line)
  end

  while #lines > 0 and strings.is_empty_or_space(lines[#lines]) do
    table.remove(lines)
  end

  return signature, lines
end

--- Extracts c:type:: block from RST
---@param rst string
---@param uvname string
---@nodiscard
---@return string signature
---@return string[] body_lines
function M.extract_type(rst, uvname)
  local type_pattern = "%.%.%s+c:type::%s+" .. vim.pesc(uvname) .. "%s*"
  local type_start, type_end = rst:find(type_pattern)

  if not type_start or not type_end then
    return "", {}
  end

  local tail = rst:sub(type_end + 1)
  local next_directive = tail:find("\n%.%.[^\n]-::")
  local body_chunk = next_directive and tail:sub(1, next_directive - 1) or tail

  ---@type string[]
  local lines = {}
  for line in body_chunk:gmatch("([^\n]*)\n?") do
    lines[#lines + 1] = strings.trim(line)
  end

  while #lines > 0 and strings.is_empty_or_space(lines[#lines]) do
    table.remove(lines)
  end

  local signature = string.format("/* C type */ %s", uvname)
  return signature, lines
end

return M

