---@module 'lua_file_stats'
-- Lua script: relative paths, inline/block comment handling, annotations,
-- ASCII tables with optional percent display and text summary.

local IGNORE_DIRS = { ".git", "debuglog", "docs" }

local folder_summary = {}
local total_stats = {
    total_files = 0,
    total_lines = 0,
    lines_without_comments = 0,
    comment_lines = 0,
    lines_without_annotations = 0,
    annotation_lines = 0,
    total_words = 0,
    words_in_comments = 0,
    words_in_annotations = 0,
    words_without_comments = 0,
    words_without_annotations = 0
}

local percent_mode = "both"
local fields_to_print = { "files", "folders", "summary" }
local single_file_path = nil

-- Helpers
local function safe_number(n) return n or 0 end
local function percent(part, total) if not total or total==0 then return 0 end; return (part/total)*100 end
local function count_words(s) local c=0; for _ in s:gmatch("%S+") do c=c+1 end; return c end
local function should_ignore(path)
    for _,dir in ipairs(IGNORE_DIRS) do
        if path:lower():find(dir:lower()) then return true end
    end
    return false
end
local function tbl_contains(tbl,val)
    for _,v in ipairs(tbl) do if v==val then return true end end
    return false
end
-- local function pad_fmt(n) return "%-"..tostring(n).."s" end
local cwd = io.popen("cd"):read("*l")
cwd = cwd:gsub("\\","/")

local function relative_path(full_path)
    local p = full_path:gsub("\\","/")
    if p:sub(1,#cwd)==cwd then return p:sub(#cwd+2) end
    return p
end

-- Format with percent
local function format_value(number, perc)
    if percent_mode=="both" then
        return string.format("%d (%.1f%%)", safe_number(number), safe_number(perc))
    elseif percent_mode=="percent" then
        return string.format("%.1f%%", safe_number(perc))
    else
        return string.format("%d", safe_number(number))
    end
end

-- Compute percentages per file/folder
local function compute_percentages(stats)
    local lc_total = percent(stats.comment_lines, stats.total_lines)
    local la_total = percent(stats.annotation_lines, stats.total_lines)
    local lc_nocomment = percent(stats.lines_without_comments, stats.total_lines)
    local la_noanno = percent(stats.lines_without_annotations, stats.total_lines)
    local wc_total = percent(stats.words_in_comments, stats.total_words)
    local wa_total = percent(stats.words_in_annotations, stats.total_words)
    local wc_nocomment = percent(stats.words_without_comments, stats.total_words)
    local wa_noanno = percent(stats.words_without_annotations, stats.total_words)
    return lc_total, la_total, lc_nocomment, la_noanno, wc_total, wa_total, wc_nocomment, wa_noanno
end


-- Print legend (includes relative info)
-- local function print_legend()
--     print("Legend (percentages are relative to total lines or total words):")
--     print("Lines: L1=Total, L2=NoComments, L3=Comments, L4=NoAnnotations, L5=Annotations")
--     print("Words: W1=Total, W2=NoComments, W3=NoAnnotations, W4=Comments, W5=Annotations\n")
-- end

-- Analyze a single file
local function analyze_file(filepath)
    local total_lines, comment_lines, annotation_lines, lines_without_comments, lines_without_annotations = 0,0,0,0,0
    local total_words, words_in_comments, words_in_annotations, words_without_comments, words_without_annotations = 0,0,0,0,0
    local in_block_comment = false

    for line in io.lines(filepath) do
        total_lines = total_lines + 1
        local trimmed = line:match("^%s*(.-)%s*$")
        local code_part, comment_part = trimmed, ""

        if in_block_comment then
            comment_part = code_part
            code_part = ""
        elseif trimmed:match("^%-%-%[%[") then
            in_block_comment = true
            comment_part = code_part
            code_part = ""
        else
            local inline_pos = code_part:find("%-%-")
            if inline_pos then
                comment_part = code_part:sub(inline_pos)
                code_part = code_part:sub(1, inline_pos-1)
            elseif trimmed:match("^%-%-") then
                comment_part = code_part
                code_part = ""
            end
        end

        if in_block_comment and trimmed:match("%]%]") then in_block_comment=false end

        local is_annotation = comment_part:match("^%-%-%-%@")
        if is_annotation then annotation_lines = annotation_lines + 1 end

        if #comment_part>0 then
            comment_lines = comment_lines +1
            words_in_comments = words_in_comments + count_words(comment_part)
        end

        if #code_part>0 then
            lines_without_comments = lines_without_comments +1
            words_without_comments = words_without_comments + count_words(code_part)
        end

        if not is_annotation then
            lines_without_annotations = lines_without_annotations +1
            words_without_annotations = words_without_annotations + count_words(code_part)
        else
            words_in_annotations = words_in_annotations + count_words(comment_part)
        end

        total_words = total_words + count_words(code_part) + count_words(comment_part)
    end

    return {
        total_lines=total_lines,
        lines_without_comments=lines_without_comments,
        comment_lines=comment_lines,
        lines_without_annotations=lines_without_annotations,
        annotation_lines=annotation_lines,
        total_words=total_words,
        words_in_comments=words_in_comments,
        words_in_annotations=words_in_annotations,
        words_without_comments=words_without_comments,
        words_without_annotations=words_without_annotations
    }
end

-- Scan directory and aggregate stats
local function get_lua_files(dir)
    local files={}
    local p=io.popen('dir "'..dir..'" /S /B /A:-D')
    if not p then return end
    for file in p:lines() do
        if file:match("%.lua$") and not should_ignore(file) then table.insert(files,file) end
    end
    p:close()
    return files
end

local function scan_dir(root_dir)
    local files = get_lua_files(root_dir)
    if not files then return end
    local per_folder = {}
    for _, file in ipairs(files) do
        local stats = analyze_file(file)
        local rel_file = relative_path(file)
        local folder = rel_file:match("(.+)/") or "."

        if not per_folder[folder] then
            per_folder[folder]={total_lines=0,lines_without_comments=0,comment_lines=0,
                lines_without_annotations=0,annotation_lines=0,
                total_words=0,words_in_comments=0,words_in_annotations=0,
                words_without_comments=0,words_without_annotations=0,
                file_count=0,files={}
            }
        end
        local f=per_folder[folder]
        for k,v in pairs(stats) do f[k]=f[k]+v end
        f.file_count=f.file_count+1
        table.insert(f.files,{rel_file=rel_file, stats=stats})

        for k,v in pairs(stats) do total_stats[k]=total_stats[k]+v end
        total_stats.total_files=total_stats.total_files+1
    end
    folder_summary=per_folder
end

-- Column formatting
local col_width = 7
for _, a in ipairs(arg) do
    if a:match("^%-%-colwidth=") then col_width = tonumber(a:sub(12)) or col_width end
end

-- local header_file = pad_fmt(60)
-- local header_cols = table.concat({
--     pad_fmt(col_width), pad_fmt(col_width), pad_fmt(col_width), pad_fmt(col_width), pad_fmt(col_width),
--     pad_fmt(col_width), pad_fmt(col_width), pad_fmt(col_width), pad_fmt(col_width), pad_fmt(col_width)
-- }, "|")
--

-- Helper: format a single cell with given width
local function fmt_cell(value, width)
    return string.format("%-" .. tostring(width) .. "s", tostring(value))
end

-- Helper: format a row for file/folder lines (file column fixed 60 chars)
local function format_row_file_column(left, cells)
    -- left is the file/folder name (already relative), cells is an array of strings to place into columns
    local parts = { "| " .. fmt_cell(left, 60) .. " |" }
    for _, c in ipairs(cells) do
        table.insert(parts, " " .. fmt_cell(c, col_width) .. " |")
    end
    return table.concat(parts, "")
end

-- Build header columns names for L2..L5 and W2..W5
local function build_header_cols_names()
    -- returns an array of header names in the same order as values will appear
    -- L2,L3,L4,L5, W2,W3,W4,W5
    return { "L2", "L3", "L4", "L5", "W2", "W3", "W4", "W5" }
end

-- Print Single File Stats
local function print_single_file_stats_ascii()
    if not single_file_path then return end
    local line = string.rep("-", 60 + 8 * (col_width + 3)) -- approximate width
    print("=== Single File Stats ===")
    -- Legend adjusted (L1/W1 omitted because they are always 100%)
    print("Legend (percentages relative to total lines or total words):")
    print("Lines: L2=NoComments, L3=Comments, L4=NoAnnotations, L5=Annotations")
    print("Words: W2=NoComments, W3=NoAnnotations, W4=Comments, W5=Annotations\n")
    print(line)

    -- Header row
    local headers = build_header_cols_names()
    local header_row = format_row_file_column("File", headers)
    print(header_row)
    print(line)

    local stats = analyze_file(single_file_path)
    local rel_file = relative_path(single_file_path)
    -- compute_percentages must return: lc, la, lc_nc, la_na, wc, wa, wc_nc, wa_na
    local lc, la, lc_nc, la_na, wc, wa, wc_nc, wa_na = compute_percentages(stats)

    local cells = {
        -- Lines: L2 (no comments), L3 (comments), L4 (no annotations), L5 (annotations)
        format_value(stats.lines_without_comments, lc_nc),
        format_value(stats.comment_lines, lc),
        format_value(stats.lines_without_annotations, la_na),
        format_value(stats.annotation_lines, la),
        -- Words: W2 (no comments), W3 (no annotations), W4 (comments), W5 (annotations)
        format_value(stats.words_without_comments, wc_nc),
        format_value(stats.words_without_annotations, wa_na),
        format_value(stats.words_in_comments, wc),
        format_value(stats.words_in_annotations, wa)
    }

    print(format_row_file_column(rel_file, cells))
    print(line)
end

-- Print File Stats (per-file rows)
local function print_file_stats_ascii()
    if not tbl_contains(fields_to_print, "files") then return end
    local line = string.rep("-", 60 + 8 * (col_width + 3))
    print("=== File Stats ===")
    print("Legend (percentages relative to total lines or total words):")
    print("Lines: L2=NoComments, L3=Comments, L4=NoAnnotations, L5=Annotations")
    print("Words: W2=NoComments, W3=NoAnnotations, W4=Comments, W5=Annotations\n")
    print(line)

    -- Header
    local headers = build_header_cols_names()
    print(format_row_file_column("File", headers))
    print(line)

    -- Rows
    for _, f in pairs(folder_summary) do
        for _, file in ipairs(f.files) do
            local s = file.stats
            local lc, la, lc_nc, la_na, wc, wa, wc_nc, wa_na = compute_percentages(s)

            local cells = {
                format_value(s.lines_without_comments, lc_nc),
                format_value(s.comment_lines, lc),
                format_value(s.lines_without_annotations, la_na),
                format_value(s.annotation_lines, la),
                format_value(s.words_without_comments, wc_nc),
                format_value(s.words_without_annotations, wa_na),
                format_value(s.words_in_comments, wc),
                format_value(s.words_in_annotations, wa)
            }

            print(format_row_file_column(file.rel_file, cells))
        end
    end

    print(line)
end

-- Print Folder Summary
local function print_folder_summary_ascii()
    if not tbl_contains(fields_to_print, "folders") then return end
    local line = string.rep("-", 42 + 8 * (col_width + 3))
    print("\n=== Folder Summary ===")
    print("Legend (percentages relative to total lines or total words):")
    print("Lines: L2=NoComments, L3=Comments, L4=NoAnnotations, L5=Annotations")
    print("Words: W2=NoComments, W3=NoAnnotations, W4=Comments, W5=Annotations\n")
    print(line)

    -- Folder header: Folder (40) | Files (5) | then the 8 columns
    local header_parts = { "| " .. fmt_cell("Folder", 40) .. " | " .. fmt_cell("Files", 5) .. " |" }
    for _, h in ipairs(build_header_cols_names()) do
        table.insert(header_parts, " " .. fmt_cell(h, col_width) .. " |")
    end
    print(table.concat(header_parts, ""))
    print(line)

    for folder, stats in pairs(folder_summary) do
        local lc, la, lc_nc, la_na, wc, wa, wc_nc, wa_na = compute_percentages(stats)

        local cells = {
            format_value(stats.lines_without_comments, lc_nc),
            format_value(stats.comment_lines, lc),
            format_value(stats.lines_without_annotations, la_na),
            format_value(stats.annotation_lines, la),
            format_value(stats.words_without_comments, wc_nc),
            format_value(stats.words_without_annotations, wa_na),
            format_value(stats.words_in_comments, wc),
            format_value(stats.words_in_annotations, wa)
        }

        -- build row
        local row_parts = { "| " .. fmt_cell(folder, 40) .. " | " .. fmt_cell(stats.file_count, 5) .. " |" }
        for _, c in ipairs(cells) do
            table.insert(row_parts, " " .. fmt_cell(c, col_width) .. " |")
        end
        print(table.concat(row_parts, ""))
    end

    print(line)
end

-- Print Total Summary (L1/W1 removed: show only L2..L5 and W2..W5)
local function print_total_summary()
    if not tbl_contains(fields_to_print, "summary") then return end
    local t = total_stats
    local lc, la, lc_nc, la_na, wc, wa, wc_nc, wa_na = compute_percentages(t)
    local line = string.rep("-", 42 + 8 * (col_width + 3))
    print("\n=== Total Summary ===")
    print("Legend (percentages relative to total lines or total words):")
    print("Lines: L2=NoComments, L3=Comments, L4=NoAnnotations, L5=Annotations")
    print("Words: W2=NoComments, W3=NoAnnotations, W4=Comments, W5=Annotations\n")
    print(line)

    -- Header: Files | then 8 columns
    local header_parts = { "| " .. fmt_cell("Files", 8) .. " |" }
    for _, h in ipairs(build_header_cols_names()) do
        table.insert(header_parts, " " .. fmt_cell(h, col_width) .. " |")
    end
    print(table.concat(header_parts, ""))
    print(line)

    local cells = {
        format_value(t.lines_without_comments, lc_nc),
        format_value(t.comment_lines, lc),
        format_value(t.lines_without_annotations, la_na),
        format_value(t.annotation_lines, la),
        format_value(t.words_without_comments, wc_nc),
        format_value(t.words_without_annotations, wa_na),
        format_value(t.words_in_comments, wc),
        format_value(t.words_in_annotations, wa)
    }

    local row_parts = { "| " .. fmt_cell(t.total_files, 8) .. " |" }
    for _, c in ipairs(cells) do
        table.insert(row_parts, " " .. fmt_cell(c, col_width) .. " |")
    end
    print(table.concat(row_parts, ""))
    print(line)
end

-- Text summary unchanged
local function print_text_summary()
    print("\n=== Text Summary ===")
    local t = total_stats
    print(string.format("Analyzed files: %d", t.total_files))
    print(string.format("Lines: Total=%d, WithoutComments=%d, Comments=%d, WithoutAnnotations=%d, Annotations=%d",
        t.total_lines,t.lines_without_comments,t.comment_lines,t.lines_without_annotations,t.annotation_lines))
    print(string.format("Words: Total=%d, WithoutComments=%d, Comments=%d, WithoutAnnotations=%d, Annotations=%d",
        t.total_words,t.words_without_comments,t.words_in_comments,t.words_without_annotations,t.words_in_annotations))
end

-- Main
local root_dir = "."
local reverse_order = false

for _, a in ipairs(arg) do
    if a=="--reverse" then reverse_order=true
    elseif a=="--percent-only" then percent_mode="percent"
    elseif a=="--numbers-only" then percent_mode="numbers"
    elseif a:match("^%-%-fields=") then
        local val=a:sub(10)
        fields_to_print={}
        for f in val:gmatch("([^,]+)") do table.insert(fields_to_print,f) end
    elseif a:match("^%-%-file=") then
        single_file_path=a:sub(9)
    elseif a:match("^%-%-colwidth=") then
        col_width = tonumber(a:sub(12)) or col_width
    else
        root_dir=a
    end
end

if single_file_path then
    folder_summary = { ["."] = { files={{rel_file=relative_path(single_file_path), stats=analyze_file(single_file_path)}} } }
    print_single_file_stats_ascii()
else
    scan_dir(root_dir)
    if reverse_order then
        print_total_summary()
        print_folder_summary_ascii()
        print_file_stats_ascii()
    else
        print_file_stats_ascii()
        print_folder_summary_ascii()
        print_total_summary()
    end
    print_text_summary()
end
