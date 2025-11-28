---@module 'lua_file_stats.printer'
-- Printing functions: ASCII tables and textual summary.
-- All formatting uses helpers from utils and compute.

local utils = require("lua_file_stats.utils")
local compute = require("lua_file_stats.compute")
local M = {}

-- Defaults, can be overridden by CLI
M.col_width = 7
M.header_file_width = 60

--- Format a file/folder row (file column + cells array).
---@param left string
---@param cells string[]
---@param col_width number
---@return string
local function format_row_file_column(left, cells, col_width, left_width)
    left_width = left_width or M.header_file_width
    local parts = { "| " .. utils.fmt_cell(left, left_width) .. " |" }
    for _, c in ipairs(cells) do
        table.insert(parts, " " .. utils.fmt_cell(c, col_width) .. " |")
    end
    return table.concat(parts, "")
end

--- Build headers names L2..L5, W2..W5 (order).
-- New header ordering and numbering:
-- Lines: L1 = NoComments (old L2)
--        L2 = Comments   (old L3)
--        L3 = NoAnnotations (old L4)
--        L4 = Annotations   (old L5)
--        L5 = Whitespace/BlankLines (new)
-- Words: W1 = NoComments (old W2)
--        W2 = NoAnnotations (old W3)
--        W3 = Comments     (old W4)
--        W4 = Annotations  (old W5)
--        W5 = WhitespaceWords (new; usually 0)

-- Build headers for L1..L5 and W1..W5 (now 5+5 = 10 columns)
local function build_header_cols_names()
    -- order must match values emitted below
    return { "L1", "L2", "L3", "L4", "L5", "W1", "W2", "W3", "W4", "W5" }
end

--- Format value according to mode.
---@param format_value_fn function
---@param number any
---@param perc number
---@return string
local function cell_value(number, perc, format_value_fn)
    return format_value_fn(number, perc)
end


--- Print legend
---@param out function
local function print_legend(out)
    out = out or print
    out("Legend (percentages relative to total lines or total words):")
    out("Lines: L1=NoComments, L2=Comments, L3=NoAnnotations, L4=Annotations, L5=Whitespace")
    out("Words: W1=NoComments, W2=NoAnnotations, W3=Comments, W4=Annotations, W5=Whitespace\n")
end

-- Example row building for file rows (uses compute.compute_percentages)
local function format_file_row(rel, s, format_value_fn, col_width, left_width)
    -- compute percentages: returns p_no_comments, p_comments, p_no_annotations, p_annotations, p_blank,
    --                       pw_no_comments, pw_no_annotations, pw_comments, pw_annotations, pw_blank
    local p_no_comments, p_comments, p_no_annotations, p_annotations, p_blank,
          pw_no_comments, pw_no_annotations, pw_comments, pw_annotations, pw_blank =
          compute.compute_percentages(s)

    local cells = {
        -- Lines: L1..L5 (numbers + perc)
        format_value_fn(s.lines_without_comments or 0, p_no_comments),
        format_value_fn(s.comment_lines or 0, p_comments),
        format_value_fn(s.lines_without_annotations or 0, p_no_annotations),
        format_value_fn(s.annotation_lines or 0, p_annotations),
        format_value_fn(s.blank_lines or 0, p_blank),
        -- Words: W1..W5
        format_value_fn(s.words_without_comments or 0, pw_no_comments),
        format_value_fn(s.words_without_annotations or 0, pw_no_annotations),
        format_value_fn(s.words_in_comments or 0, pw_comments),
        format_value_fn(s.words_in_annotations or 0, pw_annotations),
        format_value_fn(s.words_in_blank or 0, pw_blank)
    }

    -- left column formatting
    local parts = { "| " .. utils.fmt_cell(rel, left_width or M.header_file_width) .. " |" }
    for _, c in ipairs(cells) do table.insert(parts, " " .. utils.fmt_cell(c, col_width) .. " |") end
    return table.concat(parts, "")
end

--- Print File Stats table (per-file rows).
---@param folder_summary table
---@param format_value_fn function
---@param col_width number
---@param left_width number
local function print_file_stats(folder_summary, format_value_fn, col_width, left_width)
    local out = print
    local line = string.rep("-", (left_width or M.header_file_width) + 8 * (col_width + 3))
    out("=== File Stats ===")
    print_legend(out)
    out(line)
    out(format_row_file_column("File", build_header_cols_names(), col_width, left_width))
    out(line)

    for _, f in pairs(folder_summary) do
        for _, file in ipairs(f.files) do
            local s = file.stats
            local lc, la, lc_nc, la_na, wc, wa, wc_nc, wa_na = compute.compute_percentages(s)
            local cells = {
                cell_value(s.lines_without_comments, lc_nc, format_value_fn),
                cell_value(s.comment_lines, lc, format_value_fn),
                cell_value(s.lines_without_annotations, la_na, format_value_fn),
                cell_value(s.annotation_lines, la, format_value_fn),
                cell_value(s.words_without_comments, wc_nc, format_value_fn),
                cell_value(s.words_without_annotations, wa_na, format_value_fn),
                cell_value(s.words_in_comments, wc, format_value_fn),
                cell_value(s.words_in_annotations, wa, format_value_fn)
            }
            out(format_row_file_column(file.rel_file:gsub("^./", ""), cells, col_width, left_width))
        end
    end

    out(line)
end

--- Print Folder Summary table.
---@param folder_summary table
---@param format_value_fn function
---@param col_width number
---@param left_width number
local function print_folder_summary(folder_summary, format_value_fn, col_width, left_width)
    local out = print
    local line = string.rep("-", (left_width or 40) + 8 * (col_width + 3))
    out("\n=== Folder Summary ===")
    print_legend(out)
    out(line)

    -- header: Folder (40) | Files (5) | then columns
    local header_parts = { "| " .. utils.fmt_cell("Folder", 40) .. " | " .. utils.fmt_cell("Files", 5) .. " |" }
    for _, h in ipairs(build_header_cols_names()) do table.insert(header_parts, " " .. utils.fmt_cell(h, col_width) .. " |") end
    out(table.concat(header_parts, ""))
    out(line)

    for folder, stats in pairs(folder_summary) do
        local lc, la, lc_nc, la_na, wc, wa, wc_nc, wa_na = compute.compute_percentages(stats)
        local cells = {
            cell_value(stats.lines_without_comments, lc_nc, format_value_fn),
            cell_value(stats.comment_lines, lc, format_value_fn),
            cell_value(stats.lines_without_annotations, la_na, format_value_fn),
            cell_value(stats.annotation_lines, la, format_value_fn),
            cell_value(stats.words_without_comments, wc_nc, format_value_fn),
            cell_value(stats.words_without_annotations, wa_na, format_value_fn),
            cell_value(stats.words_in_comments, wc, format_value_fn),
            cell_value(stats.words_in_annotations, wa, format_value_fn)
        }
        local row_parts = { "| " .. utils.fmt_cell(folder, 40) .. " | " .. utils.fmt_cell(stats.file_count, 5) .. " |" }
        for _, c in ipairs(cells) do table.insert(row_parts, " " .. utils.fmt_cell(c, col_width) .. " |") end
        out(table.concat(row_parts, ""))
    end

    out(line)
end

--- Print Total Summary (L1/W1 omitted).
---@param total_stats table
---@param format_value_fn function
---@param col_width number
local function print_total_summary_fn(total_stats, format_value_fn, col_width)
    local out = print
    local t = total_stats
    local lc, la, lc_nc, la_na, wc, wa, wc_nc, wa_na = compute.compute_percentages(t)
    local line = string.rep("-", 8 + 8 * (col_width + 3))
    out("\n=== Total Summary ===")
    print_legend(out)
    out(line)

    local header_parts = { "| " .. utils.fmt_cell("Files", 8) .. " |" }
    for _, h in ipairs(build_header_cols_names()) do table.insert(header_parts, " " .. utils.fmt_cell(h, col_width) .. " |") end
    out(table.concat(header_parts, ""))
    out(line)

    local cells = {
        cell_value(t.lines_without_comments, lc_nc, format_value_fn),
        cell_value(t.comment_lines, lc, format_value_fn),
        cell_value(t.lines_without_annotations, la_na, format_value_fn),
        cell_value(t.annotation_lines, la, format_value_fn),
        cell_value(t.words_without_comments, wc_nc, format_value_fn),
        cell_value(t.words_without_annotations, wa_na, format_value_fn),
        cell_value(t.words_in_comments, wc, format_value_fn),
        cell_value(t.words_in_annotations, wa, format_value_fn)
    }

    local row_parts = { "| " .. utils.fmt_cell(t.total_files, 8) .. " |" }
    for _, c in ipairs(cells) do table.insert(row_parts, " " .. utils.fmt_cell(c, col_width) .. " |") end
    out(table.concat(row_parts, ""))
    out(line)
end

--- Print textual summary.
---@param total_stats table
---@param out function
local function print_text_summary(total_stats, out)
    out = out or print
    local t = total_stats
    out("\n=== Text Summary ===")
    out(string.format("Analyzed files: %d", t.total_files or 0))
    out(string.format("Lines: Total=%d, WithoutComments=%d, Comments=%d, WithoutAnnotations=%d, Annotations=%d",
        t.total_lines or 0, t.lines_without_comments or 0, t.comment_lines or 0, t.lines_without_annotations or 0, t.annotation_lines or 0))
    out(string.format("Words: Total=%d, WithoutComments=%d, Comments=%d, WithoutAnnotations=%d, Annotations=%d",
        t.total_words or 0, t.words_without_comments or 0, t.words_in_comments or 0, t.words_without_annotations or 0, t.words_in_annotations or 0))
end

-- Public API
M.print_file_stats = print_file_stats
M.print_folder_summary = print_folder_summary
M.print_total_summary = print_total_summary_fn
M.print_text_summary = print_text_summary
M.col_width = M.col_width
M.build_header_cols_names = build_header_cols_names
M.print_legend = print_legend
M.format_file_row = format_file_row

return M
