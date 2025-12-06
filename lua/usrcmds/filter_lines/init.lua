---@module 'usrcmds.filter_lines'
--- Provides a user command to keep or remove lines containing specified strings
--- or sets of strings (OR-groups) in the current buffer.
--- Usage examples:
---   :FilterLines foo { "bar","baz" }        -- keep lines that contain "foo" AND ( "bar" OR "baz" )
---   :FilterLines --remove foo               -- remove lines that contain "foo"
---   :FilterLines --remove { 'a','b' }       -- remove lines that contain "a" OR "b"
local M = {}

-- Helper function to determine if a line matches a condition.
-- A condition can be a string (must be present) or a table of strings (any must be present).
local function line_matches(line, condition)
    if type(condition) == "string" then
        -- Single string: line must contain this string (plain find)
        return string.find(line, condition, 1, true) ~= nil
    elseif type(condition) == "table" then
        -- Table of strings: line must contain at least one of them
        for _, str in ipairs(condition) do
            if type(str) == "string" and string.find(line, str, 1, true) then
                return true
            end
        end
        return false
    end
    return false
end

-- Parse an argument string and convert curly-braced list strings to actual Lua tables.
-- Accepts table syntaxes like: {"a","b"} or {'a','b'} (whitespace tolerated).
-- The function collects both double-quoted and single-quoted elements.
local function parse_argument(arg)
    -- Trim surrounding whitespace
    local trimmed = arg:match("^%s*(.-)%s*$") or arg

    -- Detect a curly-braced list like { ... }
    if trimmed:match("^%{.*%}$") then
        ---@type string[] list
        local list = {}

        -- Capture double-quoted strings: "..."
        for s in trimmed:gmatch([["(.-)"]]) do
            table.insert(list, s)
        end

        -- Capture single-quoted strings: '...'
        for s in trimmed:gmatch([['(.-)']]) do
            table.insert(list, s)
        end

        return list
    end

    -- Not a table-like argument, return as-is (string)
    return trimmed
end

function M.enable()
    vim.api.nvim_create_user_command("FilterLines", function(opts)
        if #opts.fargs == 0 then
            vim.notify("filter_lines: no arguments provided", vim.log.levels.WARN)
            return
        end

        local remove_flag = false
        ---@type table[] | string[] conditions
        local conditions = {}

        -- Parse flags and arguments. Flags may appear anywhere in the arg list.
        for _, arg in ipairs(opts.fargs) do
            if arg == "--remove" or arg == "-r" then
                remove_flag = true
            else
                table.insert(conditions, parse_argument(arg))
            end
        end

        if #conditions == 0 then
            vim.notify("filter_lines: no conditions provided", vim.log.levels.WARN)
            return
        end

        local buf = vim.api.nvim_get_current_buf()
        local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
        local new_lines = {}
        local matched_any = false

        for _, line in ipairs(lines) do
            -- Evaluate whether the line matches *all* conditions.
            -- Each condition is either a string (must be found) or a table (OR-group).
            local matches_all = true
            for _, cond in ipairs(conditions) do
                if not line_matches(line, cond) then
                    matches_all = false
                    break
                end
            end

            if matches_all then
                matched_any = true
            end

            -- If remove_flag is true, skip (remove) matching lines; otherwise keep only matching lines.
            if remove_flag then
                if not matches_all then
                    table.insert(new_lines, line)
                end
            else
                if matches_all then
                    table.insert(new_lines, line)
                end
            end
        end

        -- Safety: if remove_flag would remove the whole buffer, abort and warn instead of erasing everything.
        if remove_flag and #new_lines == 0 then
            -- If nothing would remain after removal, do not overwrite buffer to avoid accidental data loss.
            if matched_any then
                vim.notify("filter_lines: operation would remove all lines — aborted to prevent data loss", vim.log.levels.WARN)
            else
                vim.notify("filter_lines: no lines matched the given conditions; nothing changed", vim.log.levels.INFO)
            end
            return
        end

        -- If nothing matched and not removing (i.e., keep mode), warn and do nothing.
        if (not remove_flag) and not matched_any then
            vim.notify("filter_lines: no lines matched the given conditions; nothing changed", vim.log.levels.INFO)
            return
        end

        -- Apply the new lines to the buffer.
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, new_lines)
    end, {
        nargs = "+",
        complete = nil,
        desc = "Keep or remove lines containing all specified strings or any from OR-groups (use --remove or -r to remove instead of keep)",
    })
end

return M
