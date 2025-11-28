---@module 'lua_file_stats.utils'
-- Utility helpers used by other modules.
-- English comments inside code.

local M = {}

--- Known ignore directories.
---@type string[]
M.IGNORE_DIRS = { ".git", "debuglog", "docs" }

--- Safe number helper.
---@param n number?
---@return number
function M.safe_number(n) return n or 0 end

--- Compute percentage (returns 0 if total nil/0).
---@param part number
---@param total number
---@return number
function M.percent(part, total)
    if not total or total == 0 then return 0 end
    return (part / total) * 100
end

--- Count words in a string.
---@param s string
---@return number
function M.count_words(s)
    local c = 0
    if not s then return 0 end
    for _ in s:gmatch("%S+") do c = c + 1 end
    return c
end

--- Pad format helper for string.format.
---@param n number
---@return string
function M.pad_fmt(n) return "%-" .. tostring(n) .. "s" end

--- Format a cell with fixed width (left aligned).
---@param value any
---@param width number
---@return string
function M.fmt_cell(value, width) return string.format("%-" .. tostring(width) .. "s", tostring(value)) end

--- Join table of strings with separator.
---@param tbl string[]
---@param sep string
---@return string
function M.join(tbl, sep)
    sep = sep or ""
    local out = {}
    for i = 1, #tbl do out[#out+1] = tbl[i] end
    return table.concat(out, sep)
end

return M
