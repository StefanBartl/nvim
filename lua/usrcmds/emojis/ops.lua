---@module 'usrcmds.emojis.ops'
---@brief Pure emoji operations on string arrays. No Neovim API calls.
---@description
--- Three separate Lua byte-patterns (Lua has no | alternation):
---
---   P_4BYTE   F0 9F [80-BF] [80-BF]   U+1F000–U+1FFFF  main emoji block
---   P_3BYTE_A E2 [98-9F] [80-BF]      U+2600–U+27FF    Misc Symbols, Dingbats
---   P_3BYTE_B E2 [AC-AF] [80-BF]      U+2B00–U+2BFF    Misc Symbols+Arrows
---   P_VS16    EF B8 8F                 U+FE0F           Variation Selector-16
---
--- string.char() is used for all byte values to avoid any escape-syntax
--- ambiguity between Lua 5.1, LuaJIT and bash heredoc processing.

local sc = string.char

-- 4-byte: main emoji block  U+1F000 – U+1FFFF
-- Bytes: F0 9F [80-BF] [80-BF]
local P_4BYTE = sc(240,159).."["..sc(128).."-"..sc(191).."]"
                            .."["..sc(128).."-"..sc(191).."]"

-- 3-byte: Misc Symbols (☀★♥⚠✅❌…)  U+2600 – U+27FF
-- Bytes: E2 [98-9F] [80-BF]
local P_3A    = sc(226).."["..sc(152).."-"..sc(159).."]"
                        .."["..sc(128).."-"..sc(191).."]"

-- 3-byte: Misc Symbols+Arrows (⭐…)  U+2B00 – U+2BFF
-- Bytes: E2 [AC-AF] [80-BF]
local P_3B    = sc(226).."["..sc(172).."-"..sc(175).."]"
                        .."["..sc(128).."-"..sc(191).."]"

-- Variation Selector-16  U+FE0F  (makes e.g. ⚠️ from ⚠)
-- Bytes: EF B8 8F
local P_VS16  = sc(239,184,143)

-- Ordered: strip VS16 last so it doesn't orphan
local PATTERNS = { P_4BYTE, P_3A, P_3B, P_VS16 }

---@class EmojiOps
local M = {}
M._patterns = PATTERNS  -- expose for debugging

-- ============================================================================
-- Helpers
-- ============================================================================

local function count_one(s)
  local n = 0
  for _, p in ipairs(PATTERNS) do
    local pos = 1
    while true do
      local ms, me = s:find(p, pos)
      if not ms then break end
      n = n + 1
      pos = me + 1
    end
  end
  return n
end

local function strip_one(s)
  local total = 0
  for _, p in ipairs(PATTERNS) do
    local out, n = s:gsub(p, "")
    total = total + n
    s = out
  end
  return s, total
end

-- ============================================================================
-- API
-- ============================================================================

---@param lines string[]
---@return string[], integer
function M.clear(lines)
  local out, total = {}, 0
  for i = 1, #lines do
    local cleaned, n = strip_one(lines[i])
    out[i] = cleaned
    total  = total + n
  end
  return out, total
end

---@param lines string[]
---@return integer
function M.count(lines)
  local total = 0
  for i = 1, #lines do
    total = total + count_one(lines[i])
  end
  return total
end

---@param lines       string[]
---@param line_offset integer   (first_1based_line - 1)
---@return {lnum:integer, col:integer, text:string}[]
function M.list(lines, line_offset)
  line_offset = line_offset or 0
  local entries = {}
  for i = 1, #lines do
    local line = lines[i]
    for _, p in ipairs(PATTERNS) do
      local pos = 1
      while true do
        local ms, me = line:find(p, pos)
        if not ms then break end
        entries[#entries + 1] = {
          lnum = i + line_offset,  -- 1-based absolute
          col  = ms - 1,           -- 0-based byte col
          text = line:sub(ms, me),
        }
        pos = me + 1
      end
    end
  end
  table.sort(entries, function(a, b)
    if a.lnum ~= b.lnum then return a.lnum < b.lnum end
    return a.col < b.col
  end)
  return entries
end

---@param lines string[]
---@return string[], integer
function M.replace(lines)
  local NAMES = {
    [0x2705]=":white_check_mark:", [0x274C]=":x:",
    [0x2B50]=":star:",             [0x26A0]=":warning:",
    [0x1F600]=":grinning:",        [0x1F602]=":joy:",
    [0x1F525]=":fire:",            [0x1F680]=":rocket:",
    [0x1F4A1]=":bulb:",            [0x1F4DD]=":memo:",
    [0x1F41B]=":bug:",             [0x1F527]=":wrench:",
    [0x1F512]=":lock:",            [0x1F3AF]=":dart:",
    [0x1F3C1]=":checkered_flag:",  [0x1F534]=":red_circle:",
    [0x1F7E2]=":green_circle:",    [0x1F7E1]=":yellow_circle:",
    [0x1F44D]=":thumbsup:",        [0x1F44E]=":thumbsdown:",
  }
  local function codepoint(s)
    local b1 = s:byte(1) or 0
    if b1 >= 0xF0 and #s >= 4 then
      local b2,b3,b4 = s:byte(2),s:byte(3),s:byte(4)
      return ((b1-0xF0)*0x40000)+((b2-0x80)*0x1000)+((b3-0x80)*0x40)+(b4-0x80)
    elseif b1 >= 0xE0 and #s >= 3 then
      local b2,b3 = s:byte(2),s:byte(3)
      return ((b1-0xE0)*0x1000)+((b2-0x80)*0x40)+(b3-0x80)
    end
    return b1
  end
  local out, total = {}, 0
  for i = 1, #lines do
    local line = lines[i]
    for _, p in ipairs(PATTERNS) do
      line = line:gsub(p, function(m)
        total = total + 1
        local cp = codepoint(m)
        return NAMES[cp] or string.format(":U+%04X:", cp)
      end)
    end
    out[i] = line
  end
  return out, total
end

return M
