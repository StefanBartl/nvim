---@module 'lua_file_stats.utils'
---Utility helpers for lua_file_stats.
---small, self-contained helpers used by analyzer, scanner, compute and printer.

local M = {}

--- Known ignore directories.
---@type string[]
M.IGNORE_DIRS = { ".git", "debuglog", "docs" }

--- Return safe numeric (nil -> 0).
---avoid nil arithmetic.
---@param n number?
---@return number
function M.safe_number(n) return n or 0 end

--- Compute percentage guard against division by zero.
---returns 0 when total is zero or nil.
---@param part number
---@param total number
---@return number
function M.percent(part, total) if not total or total == 0 then return 0 end; return (part/total)*100 end

--- Rough word count by splitting on whitespace.
---counts non-space runs as words.
---@param s string?
---@return number
function M.count_words(s)
    if not s then return 0 end
    local c = 0
    for _ in s:gmatch("%S+") do c = c + 1 end
    return c
end

--- Whether path contains any ignore-dir substring.
---case-insensitive contains check.
---@param path string
---@return boolean
function M.should_ignore(path)
    if not path then return false end
    local p = path:lower()
    for _, d in ipairs(M.IGNORE_DIRS) do
        if p:find(d:lower(), 1, true) then return true end
    end
    return false
end

--- Table contains for array-like tables.
---linear search.
---@generic T
---@param tbl T[]
---@param val T
---@return boolean
function M.tbl_contains(tbl, val)
    for _, v in ipairs(tbl) do if v == val then return true end end
    return false
end

--- Format helper for fixed-width cell (left aligned).
---wrapper around string.format.
---@param value any
---@param width number
---@return string
function M.fmt_cell(value, width) return string.format("%-" .. tostring(width) .. "s", tostring(value)) end

--- Normalize full path to relative path against current working directory.
---uses 'cd' for cwd; converts backslashes to forward slashes.
---@param full_path string
---@return string
function M.relative_path(full_path)
    if not full_path then return "" end
    local p = full_path:gsub("\\", "/")
    local ok, handle = pcall(io.popen, "cd")
    local cwd = ""
    if ok and handle then
        cwd = (handle:read("*l") or ""):gsub("\\", "/")
        handle:close()
    end
    if cwd ~= "" then
        local prefix = cwd
        if prefix:sub(-1) ~= "/" then prefix = prefix .. "/" end
        if p:sub(1, #prefix) == prefix then
            return p:sub(#prefix + 1)
        end
    end
    return p
end

--- Join array of strings with a separator.
---simple join optimized for integer keys 1..n.
---@param tbl string[]
---@param sep string?
---@return string
function M.join(tbl, sep)
    sep = sep or ""
    local out = {}
    for i = 1, #tbl do out[#out + 1] = tbl[i] end
    return table.concat(out, sep)
end

return M
