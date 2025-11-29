---@module 'lua_file_stats.compute'
---Compute derived percentages from raw stats including blank-lines.
---small pure functions to compute percent tuples for rows.

local utils = require("lua_file_stats.utils")
local M = {}

--- Compute percentages for given stats table.
---returns ten values (five line-based percentages then five word-based percentages).
---@param stats table
function M.compute_percentages(stats)
    local total_lines = stats.total_lines or 0
    local total_words = stats.total_words or 0

    local p_no_comments    = utils.percent(stats.lines_without_comments or 0, total_lines)
    local p_comments       = utils.percent(stats.comment_lines or 0, total_lines)
    local p_no_annotations = utils.percent(stats.lines_without_annotations or 0, total_lines)
    local p_annotations    = utils.percent(stats.annotation_lines or 0, total_lines)
    local p_blank          = utils.percent(stats.blank_lines or 0, total_lines)

    local pw_no_comments    = utils.percent(stats.words_without_comments or 0, total_words)
    local pw_no_annotations = utils.percent(stats.words_without_annotations or 0, total_words)
    local pw_comments       = utils.percent(stats.words_in_comments or 0, total_words)
    local pw_annotations    = utils.percent(stats.words_in_annotations or 0, total_words)
    local pw_blank          = utils.percent(stats.words_in_blank or 0, total_words)

    return p_no_comments, p_comments, p_no_annotations, p_annotations, p_blank,
           pw_no_comments, pw_no_annotations, pw_comments, pw_annotations, pw_blank
end

return M
