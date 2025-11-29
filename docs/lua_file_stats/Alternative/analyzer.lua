---@module 'lua_file_stats.analyzer'
---File analyzer for lua_file_stats.
---this module exposes a single function analyze_file(filepath)
---that returns a table with numeric counters describing lines/words/comments/annotations.
---All helpers are intentionally small and focused so logic is easy to follow and to change.

local utils = require("lua_file_stats.utils")
local M = {}

--  Detect whitespace-only lines
--  Returns true if the trimmed line is empty (only whitespace).
---@param trimmed_line string
---@return boolean
local function is_whitespace(trimmed_line)
    -- trimmed_line is expected to be the line after removing leading/trailing whitespace
    return trimmed_line == "" or trimmed_line == nil
end

--  Detect beginning of a block comment using the Lua long bracket syntax variant
--  Recognizes patterns like --[[ or --[=[ ... for block comment start.
---@param s string raw_line_trimmed
---@return boolean
local function is_block_comment_start(s)
    -- We look for a prefix that starts a block comment: ^%-%-%[%[ (basic) or ^%-%-%[%=.*%[ (long bracket)
    -- Use plain patterns for robustness; accepting variants with equals signs is optional.
    -- We only test whether the trimmed line begins with a block comment token.
    return s:find("^%-%-%[%[") ~= nil or s:find("^%-%-%[%=+") ~= nil
end

--  Detect end of a block comment line (closing long bracket)
--  Recognizes patterns like ]] or ]=] etc. inside a line. Returns true if the line contains the close token.
---@param s string raw_line_trimmed
---@return boolean
local function is_block_comment_end(s)
    -- If a line contains ']]' or ']=]' etc., treat it as terminating block comment.
    return s:find("%]%]") ~= nil or s:find("%]%=+%]") ~= nil
end

--  Split a non-block line into code and comment parts.
--  If an inline comment is present (--) the function returns code_part and comment_part (comment_part includes the leading --).
--  If no inline comment is present, returns the full line as code_part and empty string as comment_part.
---@param s string trimmed_line
---@return string code_part, string comment_part
local function split_code_and_comment(s)
    -- We must be careful to not mis-detect a block-start '--[[' as just inline.
    -- First, check for inline block-start --[[ and treat that as comment (the block handling logic will manage state).
    -- But here, split must find the earliest '--' that is not part of an already recognized '--[['.
    local inline_pos = s:find("%-%-")
    if not inline_pos then
        return s, ""
    end

    -- If the token found is exactly the start of a long bracket (e.g. '--[[' or '--[=...['),
    -- we still consider everything from inline_pos as comment_part (the caller will manage block state).
    local possible_block = s:sub(inline_pos, inline_pos + 3) -- at least check up to 4 chars
    if possible_block:match("^%-%-%[") then
        local code_part = s:sub(1, inline_pos - 1)
        local comment_part = s:sub(inline_pos)
        return code_part, comment_part
    end

    -- Normal inline comment case: split at first --
    local code_part = s:sub(1, inline_pos - 1)
    local comment_part = s:sub(inline_pos)
    return code_part, comment_part
end

--  Check if a comment segment (starting with --) represents an annotation
--  For Emmy-style annotations the typical prefix is '---@' (three dashes + @).
--  The function is deliberately small so one can add other annotation patterns later.
---@param comment_part string (may be empty, may start with '--')
---@return boolean
local function is_annotation_comment(comment_part)
    if not comment_part or comment_part == "" then return false end
    -- Normalize leading whitespace after the comment marker, then check for '@' sign
    -- For example: '-----@param' or '-- @param' are both possible.
    -- We keep a conservative check for '---@' (three dashes then @) which is the common EmmyLua pattern.
    return comment_part:match("^%-%-%-%@") ~= nil
end

--  Small wrapper counting words; delegates to utils.count_words for shared behavior
---@param s string?
---@return number
local function count_words(s)
    return utils.count_words(s)
end

--  Analyze one file for Lua-style comments and annotations.
--  The function iterates the file line-by-line and updates counters according to:
--  - lines that are entirely whitespace -> blank_lines
--  - lines that are inside a block comment -> comment_lines (and possibly annotation_lines if marked)
--  - lines that contain inline comments: split into code and comment; code contributes to lines_without_comments if non-empty
--  - annotation detection runs only against the comment part
--  returns a table with counters; safe to call on missing/unreadable files.
---@param filepath string
---@return table stats
function M.analyze_file(filepath)
    -- initialize counters
    local total_lines = 0
    local comment_lines = 0
    local annotation_lines = 0
    local lines_without_comments = 0
    local lines_without_annotations = 0
    local blank_lines = 0

    local total_words = 0
    local words_in_comments = 0
    local words_in_annotations = 0
    local words_without_comments = 0
    local words_without_annotations = 0
    local words_in_blank = 0

    -- block comment state (true if we are currently inside a --[[ ... ]] block)
    local in_block_comment = false

    local fh, _ = io.open(filepath, "r")
    if not fh then
        -- Failed to open file: return zeroed stats (caller can still use safely)
        return {
            total_lines = 0,
            lines_without_comments = 0,
            comment_lines = 0,
            lines_without_annotations = 0,
            annotation_lines = 0,
            blank_lines = 0,
            total_words = 0,
            words_in_comments = 0,
            words_in_annotations = 0,
            words_without_comments = 0,
            words_without_annotations = 0,
            words_in_blank = 0
        }
    end

    for raw_line in fh:lines() do
        total_lines = total_lines + 1

        -- Trim leading/trailing whitespace once and reuse
        local trimmed = raw_line:match("^%s*(.-)%s*$") or ""

        -- 1) Whitespace-only line
        if is_whitespace(trimmed) then
            blank_lines = blank_lines + 1
            -- words_in_blank remains incrementally 0 in current logic; keep for symmetry
            words_in_blank = words_in_blank + 0
        else
            -- 2) If currently inside a block comment, the entire trimmed line is considered comment
            if in_block_comment then
                comment_lines = comment_lines + 1
                words_in_comments = words_in_comments + count_words(trimmed)

                -- Check if this line ends the block comment. If so, turn off in_block_comment AFTER counting.
                if is_block_comment_end(trimmed) then
                    in_block_comment = false
                end

                -- If annotation syntax can appear inside block comments, check here.
                if is_annotation_comment(trimmed) then
                    annotation_lines = annotation_lines + 1
                    words_in_annotations = words_in_annotations + count_words(trimmed)
                else
                    -- This line is a comment but not an annotation; it contributes to lines_without_annotations = false (we'll increment lines_without_annotations when not annotation)
                    -- No action needed here; we'll count lines_without_annotations for code lines below.
                end
            else
                -- 3) Not in a block comment currently. Check whether this line starts a block comment
                if is_block_comment_start(trimmed) then
                    -- This line starts a block comment. Treat entire line as comment.
                    comment_lines = comment_lines + 1
                    words_in_comments = words_in_comments + count_words(trimmed)

                    -- Set state; if the same line also ends the block (e.g. --[[ ... ]]) we should close it immediately.
                    if not is_block_comment_end(trimmed) then
                        in_block_comment = true
                    end

                    -- Annotation check on a block-start line (some people annotate the block-start line)
                    if is_annotation_comment(trimmed) then
                        annotation_lines = annotation_lines + 1
                        words_in_annotations = words_in_annotations + count_words(trimmed)
                    end
                else
                    -- 4) Not a block comment start: handle inline comment or pure code.
                    local code_part, comment_part = split_code_and_comment(trimmed)

                    -- If there is a comment_part (starts with --), handle it
                    if comment_part ~= "" then
                        -- This line contains an inline / line comment.
                        comment_lines = comment_lines + 1
                        words_in_comments = words_in_comments + count_words(comment_part)

                        -- Check for annotation within the comment part only
                        if is_annotation_comment(comment_part) then
                            annotation_lines = annotation_lines + 1
                            words_in_annotations = words_in_annotations + count_words(comment_part)
                        else
                            -- not an annotation -> contributes to lines_without_annotations if code_part exists
                            if code_part ~= "" then
                                lines_without_annotations = lines_without_annotations + 1
                                words_without_annotations = words_without_annotations + count_words(code_part)
                            else
                                -- whole line is comment (inline comment directly at start)
                                lines_without_annotations = lines_without_annotations
                            end
                        end

                        -- Code part contributes to lines_without_comments only if non-empty
                        if code_part:match("%S") then
                            lines_without_comments = lines_without_comments + 1
                            words_without_comments = words_without_comments + count_words(code_part)
                        end
                    else
                        -- No comment part: whole line is code
                        lines_without_comments = lines_without_comments + 1
                        lines_without_annotations = lines_without_annotations + 1
                        words_without_comments = words_without_comments + count_words(code_part)
                        words_without_annotations = words_without_annotations + count_words(code_part)
                    end
                end
            end
        end

        -- accumulate total words: code + comment words (blank lines add zero)
        -- Note: words_in_comments and words_without_comments have already been incremented appropriately.
        -- Compute incremental total_words for the line: safer to recompute from parts to avoid double counting edge cases.
        local line_code_words = 0
        local line_comment_words = 0
        -- We can reuse earlier logic, but recomputing via simple patterns is robust:
        -- If currently in_block_comment before line end OR line contained comment_part, count comment words accordingly.
        -- Simpler approach: sum all words in trimmed line (including code and comment) and subtract duplicates if any.
        line_code_words = 0
        line_comment_words = 0

        -- If at the end of the iteration we are in a block comment OR the line was detected as comment-only,
        -- then treat the trimmed line as comment-only; otherwise split again to count.
        if in_block_comment or is_block_comment_start(trimmed) or trimmed:match("^%-%-") then
            -- The line is comment-heavy; count total words in trimmed as comment words
            line_comment_words = count_words(trimmed)
        else
            -- The line is mostly code (maybe with inline comment). Split and sum both sides.
            local code_part, comment_part = split_code_and_comment(trimmed)
            line_code_words = count_words(code_part)
            line_comment_words = count_words(comment_part)
        end

        total_words = total_words + line_code_words + line_comment_words
    end

    fh:close()

    -- Final sanity: ensure lines_without_annotations accounts for non-annotation comment lines where code exists.
    -- (Most counters already tracked inline; this is a defensive check.)
    -- Return aggregated stats
    return {
        total_lines = total_lines,
        lines_without_comments = lines_without_comments,
        comment_lines = comment_lines,
        lines_without_annotations = lines_without_annotations,
        annotation_lines = annotation_lines,
        blank_lines = blank_lines,
        total_words = total_words,
        words_in_comments = words_in_comments,
        words_in_annotations = words_in_annotations,
        words_without_comments = words_without_comments,
        words_without_annotations = words_without_annotations,
        words_in_blank = words_in_blank
    }
end

return M
