---@module 'lua_file_stats.analyzer'
---File analyzer for lua_file_stats.
---This module exposes a single function analyze_file(filepath)
---that returns a table with numeric counters describing lines/words/comments/annotations.
---All helpers are intentionally small and focused so logic is easy to follow and to change.

local utils = require("lua_file_stats.utils")
local M = {}

-- Detect whitespace-only lines
-- Returns true if the trimmed line is empty (only whitespace).
---@param trimmed_line string
---@return boolean
local function is_whitespace(trimmed_line)
    return trimmed_line == "" or trimmed_line == nil
end

-- Detect beginning of a block comment using the Lua long bracket syntax variant
-- Recognizes patterns like --[[ or --[=[ ... for block comment start.
---@param s string raw_line_trimmed
---@return boolean
local function is_block_comment_start(s)
    return s:find("^%-%-%[%[") ~= nil or s:find("^%-%-%[%=+%[") ~= nil
end

-- Detect end of a block comment line (closing long bracket)
-- Recognizes patterns like ]] or ]=] etc. inside a line.
---@param s string raw_line_trimmed
---@return boolean
local function is_block_comment_end(s)
    return s:find("%]%]") ~= nil or s:find("%]%=+%]") ~= nil
end

-- Split a non-block line into code and comment parts.
-- If an inline comment is present (--) returns code_part and comment_part.
-- If no inline comment is present, returns the full line as code_part and empty string as comment_part.
---@param s string trimmed_line
---@return string code_part, string comment_part
local function split_code_and_comment(s)
    local inline_pos = s:find("%-%-")
    if not inline_pos then
        return s, ""
    end

    -- Check if this is a block comment start
    local possible_block = s:sub(inline_pos, inline_pos + 3)
    if possible_block:match("^%-%-%[") then
        local code_part = s:sub(1, inline_pos - 1)
        local comment_part = s:sub(inline_pos)
        return code_part, comment_part
    end

    -- Normal inline comment case
    local code_part = s:sub(1, inline_pos - 1)
    local comment_part = s:sub(inline_pos)
    return code_part, comment_part
end

-- Check if a comment segment represents an annotation
-- For Emmy-style annotations the typical prefix is '---@' (three dashes + @).
---@param comment_part string (may be empty, may start with '--')
---@return boolean
local function is_annotation_comment(comment_part)
    if not comment_part or comment_part == "" then return false end
    return comment_part:match("^%-%-%-%@") ~= nil
end

-- Small wrapper counting words; delegates to utils.count_words
---@param s string?
---@return number
local function count_words(s)
    return utils.count_words(s)
end

-- Analyze one file for Lua-style comments and annotations.
-- Returns disjoint categories: code, comments (non-annotation), annotations, whitespace.
-- Sum of these four categories always equals total_lines (100%).
---@param filepath string
---@return table stats
function M.analyze_file(filepath)
    -- Initialize counters
    local total_lines = 0
    local code_lines = 0           -- pure code lines (no comments)
    local comment_lines = 0        -- comment lines that are NOT annotations
    local annotation_lines = 0     -- annotation lines
    local blank_lines = 0          -- whitespace-only lines

    local total_words = 0
    local words_in_code = 0
    local words_in_comments = 0
    local words_in_annotations = 0
    local words_in_blank = 0

    -- Block comment state
    local in_block_comment = false
    local block_is_annotation = false  -- track if current block is annotation

    local fh, _ = io.open(filepath, "r")
    if not fh then
        return {
            total_lines = 0,
            code_lines = 0,
            comment_lines = 0,
            annotation_lines = 0,
            blank_lines = 0,
            total_words = 0,
            words_in_code = 0,
            words_in_comments = 0,
            words_in_annotations = 0,
            words_in_blank = 0
        }
    end

    for raw_line in fh:lines() do
        total_lines = total_lines + 1
        local trimmed = raw_line:match("^%s*(.-)%s*$") or ""

        -- 1) Whitespace-only line
        if is_whitespace(trimmed) then
            blank_lines = blank_lines + 1
            -- no words in blank lines

        -- 2) Inside block comment
        elseif in_block_comment then
            -- Entire line is part of block comment
            if block_is_annotation then
                annotation_lines = annotation_lines + 1
                words_in_annotations = words_in_annotations + count_words(trimmed)
            else
                comment_lines = comment_lines + 1
                words_in_comments = words_in_comments + count_words(trimmed)
            end

            -- Check if block ends
            if is_block_comment_end(trimmed) then
                in_block_comment = false
                block_is_annotation = false
            end

        -- 3) Block comment start
        elseif is_block_comment_start(trimmed) then
            -- Determine if this block is annotation
            block_is_annotation = is_annotation_comment(trimmed)

            if block_is_annotation then
                annotation_lines = annotation_lines + 1
                words_in_annotations = words_in_annotations + count_words(trimmed)
            else
                comment_lines = comment_lines + 1
                words_in_comments = words_in_comments + count_words(trimmed)
            end

            -- Set block state (if not closed on same line)
            if not is_block_comment_end(trimmed) then
                in_block_comment = true
            else
                block_is_annotation = false
            end

        -- 4) Inline comment or pure code
        else
            local code_part, comment_part = split_code_and_comment(trimmed)

            -- Classify line based on dominant content
            local has_code = code_part:match("%S") ~= nil
            local has_comment = comment_part ~= ""

            if has_comment then
                -- Line contains comment - classify by comment type
                if is_annotation_comment(comment_part) then
                    -- This is an annotation line
                    annotation_lines = annotation_lines + 1
                    words_in_annotations = words_in_annotations + count_words(comment_part)

                    -- Code part contributes to code words
                    if has_code then
                        words_in_code = words_in_code + count_words(code_part)
                    end
                else
                    -- This is a regular comment line (not annotation)
                    comment_lines = comment_lines + 1
                    words_in_comments = words_in_comments + count_words(comment_part)

                    -- Code part contributes to code words
                    if has_code then
                        words_in_code = words_in_code + count_words(code_part)
                    end
                end
            else
                -- Pure code line (no comment at all)
                code_lines = code_lines + 1
                words_in_code = words_in_code + count_words(code_part)
            end
        end

        -- Accumulate total words
        total_words = total_words + count_words(trimmed)
    end

    fh:close()

    return {
        total_lines = total_lines,
        code_lines = code_lines,
        comment_lines = comment_lines,
        annotation_lines = annotation_lines,
        blank_lines = blank_lines,
        total_words = total_words,
        words_in_code = words_in_code,
        words_in_comments = words_in_comments,
        words_in_annotations = words_in_annotations,
        words_in_blank = words_in_blank
    }
end

return M
