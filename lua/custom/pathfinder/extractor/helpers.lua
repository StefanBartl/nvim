---@module 'custom.pathfinder.extractor.helpers'

local M = {}

-- Characters that terminate a path when expanding left/right
---@type table<string,boolean>
local TERMINATORS = require("custom.pathfinder.extractor.terminators")

-- unify and deduplicate candidates by raw string
---@param list candidates
---@return candidates
function M.uniq(list)
  local seen = {}
  local out = {}
  if not list then return out end
  for _, c in ipairs(list) do
    if c and c.raw and c.raw ~= "" and not seen[c.raw] then
      seen[c.raw] = true
      table.insert(out, c)
    end
  end
  return out
end

-- Check if char is a path separator
---@param ch string
---@return boolean
function M.is_sep(ch)
  return ch == "/" or ch == "\\"
end

-- Move left from index until terminator or start
---@param s string
---@param i number starting index (1-based)
---@return number left_index
function M.expand_left(s, i)
  local j = i
  while j > 1 do
    local c = s:sub(j, j)
    if TERMINATORS[c] then break end
    j = j - 1
  end
  if j > 1 and TERMINATORS[s:sub(j, j)] then
    return j + 1
  end
  return 1
end

-- Move right from index until terminator or end
---@param s string
---@param i number starting index (1-based)
---@return number right_index
function M.expand_right(s, i)
  local n = #s
  local j = i
  while j < n do
    local c = s:sub(j, j)
    if TERMINATORS[c] then break end
    j = j + 1
  end
  return j
end


return M
