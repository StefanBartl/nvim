---@module 'lua_file_stats.printer_alternate'
---Alternative printer for lua_file_stats.
---English comments: exposes the same API as the original printer module so it can be
---required as `lua_file_stats.printer_alternate` and used interchangeably from cli.lua.
---This printer emits four-line/word columns (Total/Comments/Annotations/Whitespace for Numbers mode;
---Code/Comments/Annotations/Whitespace for Percent mode). Supports percent_mode = "both" | "percent" | "numbers".

local utils = require("lua_file_stats.utils")
local M = {}

-- Column definitions:
-- Numbers mode:
--   Lines: L1 = Total, L2 = Comments, L3 = Annotations, L4 = Whitespace
--   Words: W1 = Total, W2 = Comments, W3 = Annotations, W4 = Whitespace
-- Percent mode:
--   Lines: L1 = Code, L2 = Comments, L3 = Annotations, L4 = Whitespace  (percent of total lines)
--   Words: W1 = Code, W2 = Comments, W3 = Annotations, W4 = Whitespace  (percent of total words)

-- Build header column names (L1..L4, W1..W4)
local function build_header_cols_names()
    return { "L1", "L2", "L3", "L4", "W1", "W2", "W3", "W4" }
end

-- Formatting factory for value presentation according to percent_mode.
-- "both" -> "N (xx.x%)"
-- "percent" -> "xx.x%"
-- "numbers" -> "N"
---@param percent_mode string
---@return fun(number, number): string
local function format_value_factory(percent_mode)
    return function(number, perc)
        if percent_mode == "both" then
            return string.format("%d (%.1f%%)", utils.safe_number(number), utils.safe_number(perc))
        elseif percent_mode == "percent" then
            return string.format("%.1f%%", utils.safe_number(perc))
        else
            return string.format("%d", utils.safe_number(number))
        end
    end
end

local function print_legend_numbers()
    print("Legend (Numbers mode):")
    print("Lines: L1=Total, L2=Comments, L3=Annotations, L4=Whitespace")
    print("Words: W1=Total, W2=Comments, W3=Annotations, W4=Whitespace\n")
end

local function print_legend_percent()
    print("Legend (Percent mode, percent of file/folder/total):")
    print("Lines: L1=Code, L2=Comments, L3=Annotations, L4=Whitespace")
    print("Words: W1=Code, W2=Comments, W3=Annotations, W4=Whitespace\n")
end

-- Helper: safe percentages computed directly (used for percent-mode columns)
local function percent_or_zero(part, total)
    if not total or total == 0 then return 0 end
    return utils.percent(part, total)
end

-- Print file stats (per-file rows).
-- folder_summary: table of folders -> { file_count, files = { { rel_file, stats } } }
-- total_stats: not used for per-file rows, but kept in signature for compatibility.
-- cfg: { col_width=7, percent_mode="both", fields_to_print = {...} }
---@param folder_summary table
---@param _total_stats table
---@param cfg table
function M.print_file_stats(folder_summary, _total_stats, cfg)
    cfg = cfg or {}
    local col_width = cfg.col_width or 7
    local percent_mode = cfg.percent_mode or "both"
    if cfg.fields_to_print and not utils.tbl_contains(cfg.fields_to_print, "files") then return end

    local line = string.rep("-", 60 + 8 * (col_width + 3))
    print("=== File Stats (alternate) ===")
    if percent_mode == "numbers" then print_legend_numbers() else print_legend_percent() end
    print(line)

    -- Header: File (60) | L1..L4 | W1..W4
    local headers = build_header_cols_names()
    local header_row = "| " .. utils.fmt_cell("File", 60) .. " |"
    for _, h in ipairs(headers) do header_row = header_row .. " " .. utils.fmt_cell(h, col_width) .. " |" end
    print(header_row)
    print(line)

    local fv = format_value_factory(percent_mode)
    for _, folder in pairs(folder_summary) do
        for _, file in ipairs(folder.files) do
            local s = file.stats or {}
            -- Numbers baseline
            local lines_total = s.total_lines or 0
            local lines_comments = s.comment_lines or 0
            local lines_annotations = s.annotation_lines or 0
            local lines_whitespace = s.blank_lines or 0

            local words_total = s.total_words or 0
            local words_comments = s.words_in_comments or 0
            local words_annotations = s.words_in_annotations or 0
            local words_whitespace = s.words_in_blank or 0

            -- Percent baseline (relative to file totals)
            local pct_lines_code = percent_or_zero((s.lines_without_comments or 0), lines_total) -- code share
            local pct_lines_comments = percent_or_zero(lines_comments, lines_total)
            local pct_lines_annotations = percent_or_zero(lines_annotations, lines_total)
            local pct_lines_whitespace = percent_or_zero(lines_whitespace, lines_total)

            local pct_words_code = percent_or_zero((s.words_without_comments or 0), words_total)
            local pct_words_comments = percent_or_zero(words_comments, words_total)
            local pct_words_annotations = percent_or_zero(words_annotations, words_total)
            local pct_words_whitespace = percent_or_zero(words_whitespace, words_total)

            local cell_values = {}
            if percent_mode == "numbers" then
                -- Numbers mode: show totals / comments / annotations / whitespace (absolute)
                table.insert(cell_values, fv(lines_total, percent_or_zero(lines_total, lines_total))) -- prints "N (100.0%)" in both or "N" in numbers
                table.insert(cell_values, fv(lines_comments, percent_or_zero(lines_comments, lines_total)))
                table.insert(cell_values, fv(lines_annotations, percent_or_zero(lines_annotations, lines_total)))
                table.insert(cell_values, fv(lines_whitespace, percent_or_zero(lines_whitespace, lines_total)))

                table.insert(cell_values, fv(words_total, percent_or_zero(words_total, words_total)))
                table.insert(cell_values, fv(words_comments, percent_or_zero(words_comments, words_total)))
                table.insert(cell_values, fv(words_annotations, percent_or_zero(words_annotations, words_total)))
                table.insert(cell_values, fv(words_whitespace, percent_or_zero(words_whitespace, words_total)))
            else
                -- Percent or both mode: show Code/Comments/Annotations/Whitespace as percent and/or numbers
                table.insert(cell_values, fv(s.lines_without_comments or 0, pct_lines_code))
                table.insert(cell_values, fv(lines_comments, pct_lines_comments))
                table.insert(cell_values, fv(lines_annotations, pct_lines_annotations))
                table.insert(cell_values, fv(lines_whitespace, pct_lines_whitespace))

                table.insert(cell_values, fv(s.words_without_comments or 0, pct_words_code))
                table.insert(cell_values, fv(words_comments, pct_words_comments))
                table.insert(cell_values, fv(words_annotations, pct_words_annotations))
                table.insert(cell_values, fv(words_whitespace, pct_words_whitespace))
            end

            local row = "| " .. utils.fmt_cell(file.rel_file, 60) .. " |"
            for _, c in ipairs(cell_values) do row = row .. " " .. utils.fmt_cell(c, col_width) .. " |" end
            print(row)
        end
    end

    print(line)
end

--- Print folder summary (per-folder aggregated rows).
---@param folder_summary table
---@param total_stats table
---@param cfg table
function M.print_folder_summary(folder_summary, total_stats, cfg)
    cfg = cfg or {}
    local col_width = cfg.col_width or 7
    local percent_mode = cfg.percent_mode or "both"
    if cfg.fields_to_print and not utils.tbl_contains(cfg.fields_to_print, "folders") then return end

    local line = string.rep("-", 52 + 8 * (col_width + 3))
    print("\n=== Folder Summary (alternate) ===")
    if percent_mode == "numbers" then print_legend_numbers() else print_legend_percent() end
    print(line)

    -- Header: Folder (40) | Files (6) | L1..L4 | W1..W4
    local header = "| " .. utils.fmt_cell("Folder", 40) .. " | " .. utils.fmt_cell("Files", 6) .. " |"
    for _, h in ipairs(build_header_cols_names()) do header = header .. " " .. utils.fmt_cell(h, col_width) .. " |" end
    print(header)
    print(line)

    local fv = format_value_factory(percent_mode)
    for folder, stats in pairs(folder_summary) do
        local lines_total = stats.total_lines or 0
        local lines_comments = stats.comment_lines or 0
        local lines_annotations = stats.annotation_lines or 0
        local lines_whitespace = stats.blank_lines or 0

        local words_total = stats.total_words or 0
        local words_comments = stats.words_in_comments or 0
        local words_annotations = stats.words_in_annotations or 0
        local words_whitespace = stats.words_in_blank or 0

        -- percents relative to folder totals
        local pct_lines_code = percent_or_zero((stats.lines_without_comments or 0), lines_total)
        local pct_lines_comments = percent_or_zero(lines_comments, lines_total)
        local pct_lines_annotations = percent_or_zero(lines_annotations, lines_total)
        local pct_lines_whitespace = percent_or_zero(lines_whitespace, lines_total)

        local pct_words_code = percent_or_zero((stats.words_without_comments or 0), words_total)
        local pct_words_comments = percent_or_zero(words_comments, words_total)
        local pct_words_annotations = percent_or_zero(words_annotations, words_total)
        local pct_words_whitespace = percent_or_zero(words_whitespace, words_total)

        local cell_values = {}
        if percent_mode == "numbers" then
            table.insert(cell_values, fv(lines_total, percent_or_zero(lines_total, lines_total)))
            table.insert(cell_values, fv(lines_comments, percent_or_zero(lines_comments, lines_total)))
            table.insert(cell_values, fv(lines_annotations, percent_or_zero(lines_annotations, lines_total)))
            table.insert(cell_values, fv(lines_whitespace, percent_or_zero(lines_whitespace, lines_total)))

            table.insert(cell_values, fv(words_total, percent_or_zero(words_total, words_total)))
            table.insert(cell_values, fv(words_comments, percent_or_zero(words_comments, words_total)))
            table.insert(cell_values, fv(words_annotations, percent_or_zero(words_annotations, words_total)))
            table.insert(cell_values, fv(words_whitespace, percent_or_zero(words_whitespace, words_total)))
        else
            table.insert(cell_values, fv(stats.lines_without_comments or 0, pct_lines_code))
            table.insert(cell_values, fv(lines_comments, pct_lines_comments))
            table.insert(cell_values, fv(lines_annotations, pct_lines_annotations))
            table.insert(cell_values, fv(lines_whitespace, pct_lines_whitespace))

            table.insert(cell_values, fv(stats.words_without_comments or 0, pct_words_code))
            table.insert(cell_values, fv(words_comments, pct_words_comments))
            table.insert(cell_values, fv(words_annotations, pct_words_annotations))
            table.insert(cell_values, fv(words_whitespace, pct_words_whitespace))
        end

        local row = "| " .. utils.fmt_cell(folder, 40) .. " | " .. utils.fmt_cell(stats.file_count or 0, 6) .. " |"
        for _, c in ipairs(cell_values) do row = row .. " " .. utils.fmt_cell(c, col_width) .. " |" end
        print(row)
    end

    print(line)
end

--- Print total summary (aggregated across root).
---@param total_stats table
---@param cfg table
function M.print_total_summary(total_stats, cfg)
    cfg = cfg or {}
    local col_width = cfg.col_width or 7
    local percent_mode = cfg.percent_mode or "both"
    if cfg.fields_to_print and not utils.tbl_contains(cfg.fields_to_print, "summary") then return end

    local t = total_stats or {}
    local lines_total = t.total_lines or 0
    local lines_comments = t.comment_lines or 0
    local lines_annotations = t.annotation_lines or 0
    local lines_whitespace = t.blank_lines or 0

    local words_total = t.total_words or 0
    local words_comments = t.words_in_comments or 0
    local words_annotations = t.words_in_annotations or 0
    local words_whitespace = t.words_in_blank or 0

    local pct_lines_code = percent_or_zero((t.lines_without_comments or 0), lines_total)
    local pct_lines_comments = percent_or_zero(lines_comments, lines_total)
    local pct_lines_annotations = percent_or_zero(lines_annotations, lines_total)
    local pct_lines_whitespace = percent_or_zero(lines_whitespace, lines_total)

    local pct_words_code = percent_or_zero((t.words_without_comments or 0), words_total)
    local pct_words_comments = percent_or_zero(words_comments, words_total)
    local pct_words_annotations = percent_or_zero(words_annotations, words_total)
    local pct_words_whitespace = percent_or_zero(words_whitespace, words_total)

    local line = string.rep("-", 42 + 8 * (col_width + 3))
    print("\n=== Total Summary (alternate) ===")
    if percent_mode == "numbers" then print_legend_numbers() else print_legend_percent() end
    print(line)

    local header = "| " .. utils.fmt_cell("Files", 8) .. " |"
    for _, h in ipairs(build_header_cols_names()) do header = header .. " " .. utils.fmt_cell(h, col_width) .. " |" end
    print(header)
    print(line)

    local fv = format_value_factory(percent_mode)
    local cells = {}
    if percent_mode == "numbers" then
        table.insert(cells, fv(lines_total, percent_or_zero(lines_total, lines_total)))
        table.insert(cells, fv(lines_comments, percent_or_zero(lines_comments, lines_total)))
        table.insert(cells, fv(lines_annotations, percent_or_zero(lines_annotations, lines_total)))
        table.insert(cells, fv(lines_whitespace, percent_or_zero(lines_whitespace, lines_total)))

        table.insert(cells, fv(words_total, percent_or_zero(words_total, words_total)))
        table.insert(cells, fv(words_comments, percent_or_zero(words_comments, words_total)))
        table.insert(cells, fv(words_annotations, percent_or_zero(words_annotations, words_total)))
        table.insert(cells, fv(words_whitespace, percent_or_zero(words_whitespace, words_total)))
    else
        table.insert(cells, fv(t.lines_without_comments or 0, pct_lines_code))
        table.insert(cells, fv(lines_comments, pct_lines_comments))
        table.insert(cells, fv(lines_annotations, pct_lines_annotations))
        table.insert(cells, fv(lines_whitespace, pct_lines_whitespace))

        table.insert(cells, fv(t.words_without_comments or 0, pct_words_code))
        table.insert(cells, fv(words_comments, pct_words_comments))
        table.insert(cells, fv(words_annotations, pct_words_annotations))
        table.insert(cells, fv(words_whitespace, pct_words_whitespace))
    end

    local row = "| " .. utils.fmt_cell(t.total_files or 0, 8) .. " |"
    for _, c in ipairs(cells) do row = row .. " " .. utils.fmt_cell(c, col_width) .. " |" end
    print(row)
    print(line)
end

--- Print textual summary (human friendly).
---@param total_stats table
function M.print_text_summary(total_stats)
    local t = total_stats or {}
    print("\nScan summary:")
    print(string.format("  Files scanned: %d", t.total_files or 0))
    print(string.format("  Total lines:   %d", t.total_lines or 0))
    print(string.format("  Total words:   %d", t.total_words or 0))
end

-- Export same API as original printer: functions named to match cli expectations
return {
    print_file_stats = M.print_file_stats,
    print_folder_summary = M.print_folder_summary,
    print_total_summary = M.print_total_summary,
    print_text_summary = M.print_text_summary
}
