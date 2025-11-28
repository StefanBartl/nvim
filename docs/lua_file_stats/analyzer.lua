---@module 'lua_file_stats.analyzer'
-- File content analyzer: counts lines, comments, annotations, words and blank lines for a single file.

local utils = require("lua_file_stats.utils")
local M = {}

--- Analyze one file for Lua-style comments and annotations (---@).
--- Returns stats including blank_lines and words_in_blank (always 0 but kept for symmetry).
---@param filepath string
---@return table stats
function M.analyze_file(filepath)
    local total_lines, comment_lines, annotation_lines, lines_without_comments, lines_without_annotations, blank_lines = 0,0,0,0,0,0
    local total_words, words_in_comments, words_in_annotations, words_without_comments, words_without_annotations, words_in_blank = 0,0,0,0,0,0
    local in_block_comment = false

    local f, err = io.open(filepath, "r")
    if not f then return {
        total_lines=0, lines_without_comments=0, comment_lines=0,
        lines_without_annotations=0, annotation_lines=0, blank_lines=0,
        total_words=0, words_in_comments=0, words_in_annotations=0,
        words_without_comments=0, words_without_annotations=0, words_in_blank=0
    } end

    for line in f:lines() do
        total_lines = total_lines + 1
        local trimmed = line:match("^%s*(.-)%s*$") or ""
        -- blank line detection
        if trimmed == "" then
            blank_lines = blank_lines + 1
            -- blank line contributes 0 words
            words_in_blank = words_in_blank + 0
            -- continue to next line; do not treat as code nor comment
            total_words = total_words + 0
        else
            local code_part, comment_part = trimmed, ""

            if in_block_comment then
                comment_part = code_part
                code_part = ""
                if trimmed:find("%]%]") then in_block_comment = false end
            elseif trimmed:match("^%-%-%[%[") then
                in_block_comment = true
                comment_part = code_part
                code_part = ""
            else
                local inline_pos = code_part:find("%-%-")
                if inline_pos then
                    comment_part = code_part:sub(inline_pos)
                    code_part = code_part:sub(1, inline_pos - 1)
                elseif trimmed:match("^%-%-") then
                    comment_part = code_part
                    code_part = ""
                end
            end

            local is_annotation = false
            if comment_part:match("^%-%-%-%@") then
                is_annotation = true
                annotation_lines = annotation_lines + 1
            end

            if #comment_part > 0 then
                comment_lines = comment_lines + 1
                words_in_comments = words_in_comments + utils.count_words(comment_part)
            end

            if #code_part > 0 then
                lines_without_comments = lines_without_comments + 1
                words_without_comments = words_without_comments + utils.count_words(code_part)
            end

            if not is_annotation then
                lines_without_annotations = lines_without_annotations + 1
                words_without_annotations = words_without_annotations + utils.count_words(code_part)
            else
                words_in_annotations = words_in_annotations + utils.count_words(comment_part)
            end

            total_words = total_words + utils.count_words(code_part) + utils.count_words(comment_part)
        end
    end

    f:close()

    return {
        total_lines = total_lines,
        lines_without_comments = lines_without_comments,   -- code lines (excluding blanks)
        comment_lines = comment_lines,
        lines_without_annotations = lines_without_annotations,
        annotation_lines = annotation_lines,
        blank_lines = blank_lines,                         -- NEW: blank/whitespace-only lines
        total_words = total_words,
        words_in_comments = words_in_comments,
        words_in_annotations = words_in_annotations,
        words_without_comments = words_without_comments,
        words_without_annotations = words_without_annotations,
        words_in_blank = words_in_blank                    -- NEW: always 0 (kept for completeness)
    }
end

return M
