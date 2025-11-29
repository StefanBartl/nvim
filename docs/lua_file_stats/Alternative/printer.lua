---@module 'lua_file_stats.printer'
---Printing functions: ASCII tables and textual summary.
---printer consumes folder_summary/total_stats and does NOT require cli; all state passed explicitly.

local utils = require("lua_file_stats.utils")
local compute = require("lua_file_stats.compute")
local M = {}

--- Build header columns names: L1..L5, W1..W5.
---used by multiple printers.
local function build_header_cols_names()
    return { "L1", "L2", "L3", "L4", "L5", "W1", "W2", "W3", "W4", "W5" }
end

--- Format factory using percent_mode.
---percent_mode in { "both", "percent", "numbers" }.
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

--- Print legend.
---explains column meaning.
local function print_legend()
    print("Legend (percentages relative to total lines or total words):")
    print("Lines: L1=NoComments, L2=Comments, L3=NoAnnotations, L4=Annotations, L5=Whitespace")
    print("Words: W1=NoComments, W2=NoAnnotations, W3=Comments, W4=Annotations, W5=Whitespace\n")
end

--- Print file stats (ASCII table).
---folder_summary is table returned by scanner.scan_dir.
---@param folder_summary table
---@param _total_stats table
---@param cfg table { col_width=7, percent_mode="both", fields_to_print = {...} }
function M.print_file_stats(folder_summary, _total_stats, cfg)
    cfg = cfg or {}
    _total_stats = _total_stats
    local col_width = cfg.col_width or 7
    local percent_mode = cfg.percent_mode or "both"
    if cfg.fields_to_print and not utils.tbl_contains(cfg.fields_to_print, "files") then return end

    local line = string.rep("-", 60 + 10 * (col_width + 3))
    print("=== File Stats ===")
    print_legend()
    print(line)

    local headers = build_header_cols_names()
    -- file column fixed 60
    local header_row = "| " .. utils.fmt_cell("File", 60) .. " |"
    for _, h in ipairs(headers) do header_row = header_row .. " " .. utils.fmt_cell(h, col_width) .. " |" end
    print(header_row)
    print(line)

    local fv = format_value_factory(percent_mode)
    for _, f in pairs(folder_summary) do
        for _, file in ipairs(f.files) do
            local s = file.stats
            local p_no_comments, p_comments, p_no_annotations, p_annotations, p_blank,
                  pw_no_comments, pw_no_annotations, pw_comments, pw_annotations, pw_blank =
                  compute.compute_percentages(s)

            local cells = {
                fv(s.lines_without_comments, p_no_comments),
                fv(s.comment_lines, p_comments),
                fv(s.lines_without_annotations, p_no_annotations),
                fv(s.annotation_lines, p_annotations),
                fv(s.blank_lines, p_blank),
                fv(s.words_without_comments, pw_no_comments),
                fv(s.words_without_annotations, pw_no_annotations),
                fv(s.words_in_comments, pw_comments),
                fv(s.words_in_annotations, pw_annotations),
                fv(s.words_in_blank, pw_blank)
            }

            local row = "| " .. utils.fmt_cell(file.rel_file, 60) .. " |"
            for _, c in ipairs(cells) do row = row .. " " .. utils.fmt_cell(c, col_width) .. " |" end
            print(row)
        end
    end

    print(line)
end

--- Print folder summary (ASCII table).
---shows per-folder aggregated figures.
---@param folder_summary table
---@param _total_stats table
---@param cfg table
function M.print_folder_summary(folder_summary, _total_stats, cfg)
    cfg = cfg or {}
    _total_stats = _total_stats
    local col_width = cfg.col_width or 7
    local percent_mode = cfg.percent_mode or "both"
    if cfg.fields_to_print and not utils.tbl_contains(cfg.fields_to_print, "folders") then return end

    local line = string.rep("-", 42 + 10 * (col_width + 3))
    print("\n=== Folder Summary ===")
    print_legend()
    print(line)

    local header = "| " .. utils.fmt_cell("Folder", 40) .. " | " .. utils.fmt_cell("Files", 5) .. " |"
    for _, h in ipairs(build_header_cols_names()) do header = header .. " " .. utils.fmt_cell(h, col_width) .. " |" end
    print(header)
    print(line)

    local fv = format_value_factory(percent_mode)
    for folder, stats in pairs(folder_summary) do
        local p_no_comments, p_comments, p_no_annotations, p_annotations, p_blank,
              pw_no_comments, pw_no_annotations, pw_comments, pw_annotations, pw_blank =
              compute.compute_percentages(stats)

        local cells = {
            fv(stats.lines_without_comments, p_no_comments),
            fv(stats.comment_lines, p_comments),
            fv(stats.lines_without_annotations, p_no_annotations),
            fv(stats.annotation_lines, p_annotations),
            fv(stats.blank_lines, p_blank),
            fv(stats.words_without_comments, pw_no_comments),
            fv(stats.words_without_annotations, pw_no_annotations),
            fv(stats.words_in_comments, pw_comments),
            fv(stats.words_in_annotations, pw_annotations),
            fv(stats.words_in_blank, pw_blank)
        }

        local row = "| " .. utils.fmt_cell(folder, 40) .. " | " .. utils.fmt_cell(stats.file_count, 5) .. " |"
        for _, c in ipairs(cells) do row = row .. " " .. utils.fmt_cell(c, col_width) .. " |" end
        print(row)
    end

    print(line)
end

--- Print total summary (aggregated).
---prints totals across scanned tree.
---@param total_stats table
---@param cfg table
function M.print_total_summary(total_stats, cfg)
    cfg = cfg or {}
    local col_width = cfg.col_width or 7
    local percent_mode = cfg.percent_mode or "both"
    if cfg.fields_to_print and not utils.tbl_contains(cfg.fields_to_print, "summary") then return end

    local t = total_stats
    local p_no_comments, p_comments, p_no_annotations, p_annotations, p_blank,
          pw_no_comments, pw_no_annotations, pw_comments, pw_annotations, pw_blank =
          compute.compute_percentages(t)

    local line = string.rep("-", 42 + 10 * (col_width + 3))
    print("\n=== Total Summary ===")
    print_legend()
    print(line)

    local header = "| " .. utils.fmt_cell("Files", 8) .. " |"
    for _, h in ipairs(build_header_cols_names()) do header = header .. " " .. utils.fmt_cell(h, col_width) .. " |" end
    print(header)
    print(line)

    local fv = format_value_factory(percent_mode)
    local cells = {
        fv(t.lines_without_comments, p_no_comments),
        fv(t.comment_lines, p_comments),
        fv(t.lines_without_annotations, p_no_annotations),
        fv(t.annotation_lines, p_annotations),
        fv(t.blank_lines, p_blank),
        fv(t.words_without_comments, pw_no_comments),
        fv(t.words_without_annotations, pw_no_annotations),
        fv(t.words_in_comments, pw_comments),
        fv(t.words_in_annotations, pw_annotations),
        fv(t.words_in_blank, pw_blank)
    }

    local row = "| " .. utils.fmt_cell(t.total_files, 8) .. " |"
    for _, c in ipairs(cells) do row = row .. " " .. utils.fmt_cell(c, col_width) .. " |" end
    print(row)
    print(line)
end

--- Print textual summary (human friendly).
---small multi-line summary at end.
---@param total_stats table
function M.print_text_summary(total_stats)
    local t = total_stats or {}
    print("\nScan summary:")
    print(string.format("  Files scanned: %d", t.total_files or 0))
    print(string.format("  Total lines:   %d", t.total_lines or 0))
    print(string.format("  Total words:   %d", t.total_words or 0))
end

return {
    print_file_stats = M.print_file_stats,
    print_folder_summary = M.print_folder_summary,
    print_total_summary = M.print_total_summary,
    print_text_summary = M.print_text_summary
}
