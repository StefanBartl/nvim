---@module 'uv_doc.fetcher'
---@brief Fetches and aggregates genindex pages

local M = {}

local http = require("usrcmds.uv_doc.http")
local cache = require("usrcmds.uv_doc.cache")
local parser = require("usrcmds.uv_doc.parser")
local constants = require("usrcmds.uv_doc.constants")
local strings = require("lib.strings")

-- Create notify instance with proper API
local notify = require("lib.notify").create("uv_doc")

--- Fetches and caches complete genindex
---@nodiscard
---@return string|nil
function M.get_genindex()
  local cached = cache.get_genindex()
  if cached then
    return cached
  end

  -- Try single-page aggregate
  local html_all, err = http.get(constants.BASE_URL .. constants.GENINDEX_ALL)
  if html_all and not strings.is_empty_or_space(html_all) then
    cache.set_genindex(html_all)
    return html_all
  end

  if err then
    notify.warn("genindex-all.html unavailable: " .. err)
  end

  -- Fallback: fetch main page and discover splits
  local main_page, main_err = http.get(constants.BASE_URL .. constants.GENINDEX_MAIN)
  if not main_page then
    notify.error("Failed to fetch genindex.html: " .. (main_err or "unknown"))
    return nil
  end

  -- Discover split pages
  ---@type table<string, boolean>
  local discovered = {}

  for href in main_page:gmatch('href="(genindex%-[%w]+%.html)"') do
    discovered[href] = true
  end
  for href in main_page:gmatch("href='(genindex%-[%w]+%.html)'") do
    discovered[href] = true
  end

  ---@type string[]
  local parts = { [1] = main_page }

  -- Fetch discovered pages
  for href in pairs(discovered) do
    local page, page_err = http.get(constants.BASE_URL .. href)
    if page and not strings.is_empty_or_space(page) then
      parts[#parts + 1] = page
    elseif page_err then
      notify.warn("Failed to fetch " .. href .. ": " .. page_err)
    end
  end

  local aggregated = table.concat(parts, "\n<!-- GENINDEX_SPLIT -->\n")
  cache.set_genindex(aggregated)
  return aggregated
end

--- Ensures symbol cache is populated
---@return string[]|nil
function M.ensure_symbols()
  local cached = cache.get_symbols()
  if cached then
    return cached
  end

  local html = M.get_genindex()
  if not html then
    return nil
  end

  local symbols = parser.parse_symbols(html)
  if #symbols == 0 then
    notify.warn("genindex parsed but no uv_* anchors found")
    return nil
  end

  cache.set_symbols(symbols)
  return symbols
end

return M
