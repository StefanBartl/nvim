---@module 'lua_file_stats_new'
-- Lua script: relative paths, inline/block comment handling, annotations,
-- ASCII tables with optional percent display, text summary, top-N lists, and folder-sorted views.
-- English comments inside code.

local IGNORE_DIRS = { ".git", "debuglog", "docs" }

-- Aggregates for results
local folder_summary = {}
local total_stats = {
    total_files = 0,
    total_lines = 0,
    lines_without_comments = 0,
    comment_lines = 0,
    lines_without_annotations = 0,
    annotation_lines = 0,
    blank_lines = 0,               -- whitespace-only lines
    total_words = 0,
    words_in_comments = 0,
    words_in_annotations = 0,
    words_without_comments = 0,
    words_without_annotations = 0,
    words_in_blank = 0            -- words on blank lines (usually 0)
}

-- Output mode settings (default: both numbers and percents)
local percent_mode = "both" -- "both" | "percent" | "numbers"
local fields_to_print = { "files", "folders", "summary" } -- which tables to print by default
local single_file_path = nil

-- Top-N settings and top-only flags
local top_n = 25
local top_n_specified = false
local only_top_files_lines = false
local only_top_files_words = false
local only_top_folders_lines = false
local only_top_folders_words = false

-- Helpers (English comments)
local function safe_number(n) return n or 0 end
local function percent(part, total) if not total or total == 0 then return 0 end; return (part/total)*100 end
local function count_words(s) local c=0; if not s then return 0 end; for _ in s:gmatch("%S+") do c=c+1 end; return c end
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

local cwd = io.popen("cd"):read("*l")
cwd = cwd and cwd:gsub("\\","/") or ""

local function relative_path(full_path)
    local p = full_path:gsub("\\","/")
    if cwd ~= "" and p:sub(1,#cwd) == cwd then return p:sub(#cwd+2) end
    return p
end

-- Format with percent (English comments)
local function format_value(number, perc)
    if percent_mode == "both" then
        return string.format("%d (%.1f%%)", safe_number(number), safe_number(perc))
    elseif percent_mode == "percent" then
        return string.format("%.1f%%", safe_number(perc))
    else
        return string.format("%d", safe_number(number))
    end
end

-- Compute percentages (adjusted ordering and includes blank)
-- Returns:
-- p_no_comments, p_comments, p_no_annotations, p_annotations, p_blank,
-- pw_no_comments, pw_no_annotations, pw_comments, pw_annotations, pw_blank
local function compute_percentages(stats)
    local total_lines = stats.total_lines or 0
    local total_words = stats.total_words or 0

    local p_no_comments    = percent(stats.lines_without_comments or 0, total_lines)
    local p_comments       = percent(stats.comment_lines or 0, total_lines)
    local p_no_annotations = percent(stats.lines_without_annotations or 0, total_lines)
    local p_annotations    = percent(stats.annotation_lines or 0, total_lines)
    local p_blank          = percent(stats.blank_lines or 0, total_lines)

    local pw_no_comments   = percent(stats.words_without_comments or 0, total_words)
    local pw_no_annotations= percent(stats.words_without_annotations or 0, total_words)
    local pw_comments      = percent(stats.words_in_comments or 0, total_words)
    local pw_annotations   = percent(stats.words_in_annotations or 0, total_words)
    local pw_blank         = percent(stats.words_in_blank or 0, total_words)

    return p_no_comments, p_comments, p_no_annotations, p_annotations, p_blank,
           pw_no_comments, pw_no_annotations, pw_comments, pw_annotations, pw_blank
end

-- Analyze a single file (adds blank lines and words_in_blank)
local function analyze_file(filepath)
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

    local in_block_comment = false

    local fh, _ = io.open(filepath, "r")
    if not fh then
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

    for line in fh:lines() do
        total_lines = total_lines + 1
        local trimmed = line:match("^%s*(.-)%s*$") or ""

        if trimmed == "" then
            blank_lines = blank_lines + 1
            words_in_blank = words_in_blank + 0
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
                words_in_comments = words_in_comments + count_words(comment_part)
            end

            if #code_part > 0 then
                lines_without_comments = lines_without_comments + 1
                words_without_comments = words_without_comments + count_words(code_part)
            end

            if not is_annotation then
                lines_without_annotations = lines_without_annotations + 1
                words_without_annotations = words_without_annotations + count_words(code_part)
            else
                words_in_annotations = words_in_annotations + count_words(comment_part)
            end

            total_words = total_words + count_words(code_part) + count_words(comment_part)
        end
    end

    fh:close()

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

-- Get Lua files (Windows-compatible 'dir' used)
local function get_lua_files(dir)
    local files = {}
    local p = io.popen('dir "' .. dir .. '" /S /B /A:-D')
    if not p then return nil end
    for file in p:lines() do
        if file:match("%.lua$") and not should_ignore(file) then table.insert(files, file) end
    end
    p:close()
    return files
end

-- Scan directory and aggregate
local function scan_dir(root_dir)
    local files = get_lua_files(root_dir)
    if not files then return end
    local per_folder = {}
    for _, file in ipairs(files) do
        local stats = analyze_file(file)
        local rel_file = relative_path(file)
        local folder = rel_file:match("(.+)/") or "."

        if not per_folder[folder] then
            per_folder[folder] = {
                total_lines = 0, lines_without_comments = 0, comment_lines = 0,
                lines_without_annotations = 0, annotation_lines = 0, blank_lines = 0,
                total_words = 0, words_in_comments = 0, words_in_annotations = 0,
                words_without_comments = 0, words_without_annotations = 0, words_in_blank = 0,
                file_count = 0, files = {}
            }
        end

        local f = per_folder[folder]
        for k, v in pairs(stats) do
            if f[k] == nil then f[k] = v else f[k] = f[k] + v end
        end
        f.file_count = f.file_count + 1
        table.insert(f.files, { rel_file = rel_file, stats = stats })

        for k, v in pairs(stats) do
            if total_stats[k] == nil then total_stats[k] = v else total_stats[k] = total_stats[k] + v end
        end
        total_stats.total_files = total_stats.total_files + 1
    end
    folder_summary = per_folder
end

-- Column formatting
local col_width = 7
for _, a in ipairs(arg) do
    if a:match("^%-%-colwidth=") then col_width = tonumber(a:sub(12)) or col_width end
end

-- Helper: format a single cell with given width
local function fmt_cell(value, width)
    return string.format("%-" .. tostring(width) .. "s", tostring(value))
end

-- Helper: format a row for file/folder lines (file column fixed 60 chars)
local function format_row_file_column(left, cells)
    local parts = { "| " .. fmt_cell(left, 60) .. " |" }
    for _, c in ipairs(cells) do
        table.insert(parts, " " .. fmt_cell(c, col_width) .. " |")
    end
    return table.concat(parts, "")
end

-- Build header columns names: L1..L5, W1..W5 (new numbering includes blank)
local function build_header_cols_names()
    -- L1 = NoComments, L2 = Comments, L3 = NoAnnotations, L4 = Annotations, L5 = Whitespace
    -- W1 = NoComments, W2 = NoAnnotations, W3 = Comments, W4 = Annotations, W5 = Whitespace
    return { "L1", "L2", "L3", "L4", "L5", "W1", "W2", "W3", "W4", "W5" }
end

-- Print legend (adjusted)
local function print_legend()
    print("Legend (percentages relative to total lines or total words):")
    print("Lines: L1=NoComments, L2=Comments, L3=NoAnnotations, L4=Annotations, L5=Whitespace")
    print("Words: W1=NoComments, W2=NoAnnotations, W3=Comments, W4=Annotations, W5=Whitespace\n")
    print("Note: percentages in a file/folder table are relative to that file/folder total. For totals, percentages are relative to the whole scan.")
end

-- Print Single File Stats
local function print_single_file_stats_ascii()
    if not single_file_path then return end
    local line = string.rep("-", 60 + 10 * (col_width + 3))
    print("=== Single File Stats ===")
    print_legend()
    print(line)

    local headers = build_header_cols_names()
    print(format_row_file_column("File", headers))
    print(line)

    local stats = analyze_file(single_file_path)
    local rel_file = relative_path(single_file_path)
    local p_no_comments, p_comments, p_no_annotations, p_annotations, p_blank,
          pw_no_comments, pw_no_annotations, pw_comments, pw_annotations, pw_blank =
          compute_percentages(stats)

    local cells = {
        -- Lines: L1..L5
        format_value(stats.lines_without_comments, p_no_comments),
        format_value(stats.comment_lines, p_comments),
        format_value(stats.lines_without_annotations, p_no_annotations),
        format_value(stats.annotation_lines, p_annotations),
        format_value(stats.blank_lines, p_blank),
        -- Words: W1..W5
        format_value(stats.words_without_comments, pw_no_comments),
        format_value(stats.words_without_annotations, pw_no_annotations),
        format_value(stats.words_in_comments, pw_comments),
        format_value(stats.words_in_annotations, pw_annotations),
        format_value(stats.words_in_blank, pw_blank)
    }

    print(format_row_file_column(rel_file, cells))
    print(line)
end

-- Print File Stats (per-file rows)
local function print_file_stats_ascii()
    if not tbl_contains(fields_to_print, "files") then return end
    local line = string.rep("-", 60 + 10 * (col_width + 3))
    print("=== File Stats ===")
    print_legend()
    print(line)

    local headers = build_header_cols_names()
    print(format_row_file_column("File", headers))
    print(line)

    for _, f in pairs(folder_summary) do
        for _, file in ipairs(f.files) do
            local s = file.stats
            local p_no_comments, p_comments, p_no_annotations, p_annotations, p_blank,
                  pw_no_comments, pw_no_annotations, pw_comments, pw_annotations, pw_blank =
                  compute_percentages(s)

            local cells = {
                format_value(s.lines_without_comments, p_no_comments),
                format_value(s.comment_lines, p_comments),
                format_value(s.lines_without_annotations, p_no_annotations),
                format_value(s.annotation_lines, p_annotations),
                format_value(s.blank_lines, p_blank),
                format_value(s.words_without_comments, pw_no_comments),
                format_value(s.words_without_annotations, pw_no_annotations),
                format_value(s.words_in_comments, pw_comments),
                format_value(s.words_in_annotations, pw_annotations),
                format_value(s.words_in_blank, pw_blank)
            }

            print(format_row_file_column(file.rel_file, cells))
        end
    end

    print(line)
end

-- Print Folder Summary
local function print_folder_summary_ascii()
    if not tbl_contains(fields_to_print, "folders") then return end
    local line = string.rep("-", 42 + 10 * (col_width + 3))
    print("\n=== Folder Summary ===")
    print_legend()
    print(line)

    -- Folder header: Folder (40) | Files (5) | then the 10 columns
    local header_parts = { "| " .. fmt_cell("Folder", 40) .. " | " .. fmt_cell("Files", 5) .. " |" }
    for _, h in ipairs(build_header_cols_names()) do
        table.insert(header_parts, " " .. fmt_cell(h, col_width) .. " |")
    end
    print(table.concat(header_parts, ""))
    print(line)

    for folder, stats in pairs(folder_summary) do
        local p_no_comments, p_comments, p_no_annotations, p_annotations, p_blank,
              pw_no_comments, pw_no_annotations, pw_comments, pw_annotations, pw_blank =
              compute_percentages(stats)

        local cells = {
            format_value(stats.lines_without_comments, p_no_comments),
            format_value(stats.comment_lines, p_comments),
            format_value(stats.lines_without_annotations, p_no_annotations),
            format_value(stats.annotation_lines, p_annotations),
            format_value(stats.blank_lines, p_blank),
            format_value(stats.words_without_comments, pw_no_comments),
            format_value(stats.words_without_annotations, pw_no_annotations),
            format_value(stats.words_in_comments, pw_comments),
            format_value(stats.words_in_annotations, pw_annotations),
            format_value(stats.words_in_blank, pw_blank)
        }

        local row_parts = { "| " .. fmt_cell(folder, 40) .. " | " .. fmt_cell(stats.file_count, 5) .. " |" }
        for _, c in ipairs(cells) do
            table.insert(row_parts, " " .. fmt_cell(c, col_width) .. " |")
        end
        print(table.concat(row_parts, ""))
    end

    print(line)
end

-- Helpers to build flattened lists for top-N computations
local function gather_all_files()
    local list = {}
    for _, folder in pairs(folder_summary) do
        for _, f in ipairs(folder.files) do
            table.insert(list, { rel = f.rel_file, stats = f.stats })
        end
    end
    return list
end

local function gather_all_folders()
    local list = {}
    for folder, stats in pairs(folder_summary) do
        table.insert(list, { folder = folder, stats = stats })
    end
    return list
end

-- Print Top-N lists: files / folders by lines or words
local function print_top_n_files_by_lines(n)
    n = n or top_n
    local files = gather_all_files()
    table.sort(files, function(a,b) return (a.stats.total_lines or 0) > (b.stats.total_lines or 0) end)
    print("\n=== Top " .. n .. " Files by Lines (Share of total lines) ===")
    local line = string.rep("-", 6 + 60 + 20)
    print(line)
    print(string.format("| %3s | %-60s | %-9s | %-9s |", "No", "File", "Lines", "Share"))
    print(line)
    local total = total_stats.total_lines or 0
    for i=1, math.min(n, #files) do
        local item = files[i]
        local lines = item.stats.total_lines or 0
        local share = percent(lines, total)
        print(string.format("| %3d | %-60s | %9d | %8.2f%% |", i, item.rel, lines, share))
    end
    print(line)
end

local function print_top_n_files_by_words(n)
    n = n or top_n
    local files = gather_all_files()
    table.sort(files, function(a,b) return (a.stats.total_words or 0) > (b.stats.total_words or 0) end)
    print("\n=== Top " .. n .. " Files by Words (Share of total words) ===")
    local line = string.rep("-", 6 + 60 + 20)
    print(line)
    print(string.format("| %3s | %-60s | %-9s | %-9s |", "No", "File", "Words", "Share"))
    print(line)
    local total = total_stats.total_words or 0
    for i=1, math.min(n, #files) do
        local item = files[i]
        local words = item.stats.total_words or 0
        local share = percent(words, total)
        print(string.format("| %3d | %-60s | %9d | %8.2f%% |", i, item.rel, words, share))
    end
    print(line)
end

local function print_top_n_folders_by_lines(n)
    n = n or top_n
    local folders = gather_all_folders()
    table.sort(folders, function(a,b) return (a.stats.total_lines or 0) > (b.stats.total_lines or 0) end)
    print("\n=== Top " .. n .. " Folders by Lines (Share of total lines) ===")
    local line = string.rep("-", 6 + 40 + 20)
    print(line)
    print(string.format("| %3s | %-40s | %-9s | %-9s |", "No", "Folder", "Lines", "Share"))
    print(line)
    local total = total_stats.total_lines or 0
    for i=1, math.min(n, #folders) do
        local item = folders[i]
        local lines = item.stats.total_lines or 0
        local share = percent(lines, total)
        print(string.format("| %3d | %-40s | %9d | %8.2f%% |", i, item.folder, lines, share))
    end
    print(line)
end

local function print_top_n_folders_by_words(n)
    n = n or top_n
    local folders = gather_all_folders()
    table.sort(folders, function(a,b) return (a.stats.total_words or 0) > (b.stats.total_words or 0) end)
    print("\n=== Top " .. n .. " Folders by Words (Share of total words) ===")
    local line = string.rep("-", 6 + 40 + 20)
    print(line)
    print(string.format("| %3s | %-40s | %-9s | %-9s |", "No", "Folder", "Words", "Share"))
    print(line)
    local total = total_stats.total_words or 0
    for i=1, math.min(n, #folders) do
        local item = folders[i]
        local words = item.stats.total_words or 0
        local share = percent(words, total)
        print(string.format("| %3d | %-40s | %9d | %8.2f%% |", i, item.folder, words, share))
    end
    print(line)
end

-- New: Print ALL folders sorted by total lines, with per-folder absolute lines and percentage relative to total_lines (root)
local function print_all_folders_sorted_by_lines()
    local folders = gather_all_folders()
    table.sort(folders, function(a,b) return (a.stats.total_lines or 0) > (b.stats.total_lines or 0) end)
    print("\n=== All Folders Sorted by Lines (Share of root total lines) ===")
    local line = string.rep("-", 6 + 40 + 20)
    print(line)
    print(string.format("| %3s | %-40s | %-12s | %-9s |", "No", "Folder", "Lines (abs)", "Share"))
    print(line)
    local total = total_stats.total_lines or 0
    for i=1, #folders do
        local item = folders[i]
        local lines = item.stats.total_lines or 0
        local share = percent(lines, total)
        print(string.format("| %3d | %-40s | %12d | %8.2f%% |", i, item.folder, lines, share))
    end
    print(line)
end

-- New: Print ALL folders sorted by percentage share (equivalent order but explicitly uses share)
local function print_all_folders_sorted_by_percent()
    local folders = gather_all_folders()
    local total = total_stats.total_lines or 0
    table.sort(folders, function(a,b)
        local pa = percent((a.stats.total_lines or 0), total)
        local pb = percent((b.stats.total_lines or 0), total)
        return pa > pb
    end)
    print("\n=== All Folders Sorted by Percentage Share of Root Total Lines ===")
    local line = string.rep("-", 6 + 40 + 20)
    print(line)
    print(string.format("| %3s | %-40s | %-12s | %-9s |", "No", "Folder", "Lines (abs)", "Share"))
    print(line)
    for i=1, #folders do
        local item = folders[i]
        local lines = item.stats.total_lines or 0
        local share = percent(lines, total)
        print(string.format("| %3d | %-40s | %12d | %8.2f%% |", i, item.folder, lines, share))
    end
    print(line)
end

-- Print Total Summary (aggregated) with 10 columns as configured
local function print_total_summary()
    if not tbl_contains(fields_to_print, "summary") then return end
    local t = total_stats
    local p_no_comments, p_comments, p_no_annotations, p_annotations, p_blank,
          pw_no_comments, pw_no_annotations, pw_comments, pw_annotations, pw_blank =
          compute_percentages(t)
    local line = string.rep("-", 42 + 10 * (col_width + 3))
    print("\n=== Total Summary ===")
    print_legend()
    print(line)

    -- Header: Files | then 10 columns
    local header_parts = { "| " .. fmt_cell("Files", 8) .. " |" }
    for _, h in ipairs(build_header_cols_names()) do
        table.insert(header_parts, " " .. fmt_cell(h, col_width) .. " |")
    end
    print(table.concat(header_parts, ""))
    print(line)

    local cells = {
        format_value(t.lines_without_comments, p_no_comments),
        format_value(t.comment_lines, p_comments),
        format_value(t.lines_without_annotations, p_no_annotations),
        format_value(t.annotation_lines, p_annotations),
        format_value(t.blank_lines, p_blank),
        format_value(t.words_without_comments, pw_no_comments),
        format_value(t.words_without_annotations, pw_no_annotations),
        format_value(t.words_in_comments, pw_comments),
        format_value(t.words_in_annotations, pw_annotations),
        format_value(t.words_in_blank, pw_blank)
    }

    local row_parts = { "| " .. fmt_cell(t.total_files, 8) .. " |" }
    for _, c in ipairs(cells) do
        table.insert(row_parts, " " .. fmt_cell(c, col_width) .. " |")
    end
    print(table.concat(row_parts, ""))
    print(line)
end

-- Text summary printed at end (includes whitespace counts)
local function print_text_summary()
    print("\n=== Text Summary ===")
    local t = total_stats
    print(string.format("Analyzed files: %d", t.total_files))
    print(string.format("Lines: Total=%d, WithoutComments=%d, Comments=%d, WithoutAnnotations=%d, Annotations=%d, Whitespace=%d",
        t.total_lines, t.lines_without_comments, t.comment_lines, t.lines_without_annotations, t.annotation_lines, t.blank_lines))
    print(string.format("Words: Total=%d, WithoutComments=%d, Comments=%d, WithoutAnnotations=%d, Annotations=%d, Whitespace=%d",
        t.total_words, t.words_without_comments, t.words_in_comments, t.words_without_annotations, t.words_in_annotations, t.words_in_blank))
end

-- Argument parsing: supports many flags including --top-only variants and --folders-sorted-only
local root_dir = "."
local reverse_order = false

for _, a in ipairs(arg) do
    if a == "--reverse" then reverse_order = true
    elseif a == "--percent-only" or a == "--percentage-only" then percent_mode = "percent"
    elseif a == "--numbers-only" then percent_mode = "numbers"
    elseif a:match("^%-%-fields=") then
        local val = a:sub(10)
        fields_to_print = {}
        for f in val:gmatch("([^,]+)") do table.insert(fields_to_print, f) end
    elseif a:match("^%-%-file=") then
        single_file_path = a:sub(9)
    elseif a:match("^%-%-colwidth=") then
        col_width = tonumber(a:sub(12)) or col_width
    -- inside the arg loop, replace the existing --topn handling with:
    elseif a:match("^%-%-topn=") then
        top_n = tonumber(a:sub(8)) or top_n
        top_n_specified = true
    elseif a == "--top-files-lines-only" then
        only_top_files_lines = true
    elseif a == "--top-files-words-only" then
        only_top_files_words = true
    elseif a == "--top-folders-lines-only" then
        only_top_folders_lines = true
    elseif a == "--top-folders-words-only" then
        only_top_folders_words = true
    elseif a == "--folders-sorted-only" then
        -- special shortcut: print all folders sorted by lines only
        only_top_folders_lines = true
    else
        root_dir = a
    end
end

-- Determine mode: if any top-only flag is set, we will only print the requested top lists.
local any_top_only = only_top_files_lines or only_top_files_words or only_top_folders_lines or only_top_folders_words

-- Main execution
if single_file_path then
    -- single-file mode: analyze only specified file
    local stats = analyze_file(single_file_path)
    folder_summary = { ["."] = { files = { { rel_file = relative_path(single_file_path), stats = stats } }, file_count = 1 } }

    print_single_file_stats_ascii()
    -- single file textual summary
    do
        local t = stats
        print("\n=== Single File Text Summary ===")
        print(string.format("File: %s", relative_path(single_file_path)))
        print(string.format("Lines: Total=%d, WithoutComments=%d, Comments=%d, WithoutAnnotations=%d, Annotations=%d, Whitespace=%d",
            t.total_lines, t.lines_without_comments, t.comment_lines, t.lines_without_annotations, t.annotation_lines, t.blank_lines))
        print(string.format("Words: Total=%d, WithoutComments=%d, Comments=%d, WithoutAnnotations=%d, Annotations=%d, Whitespace=%d",
            t.total_words, t.words_without_comments, t.words_in_comments, t.words_without_annotations, t.words_in_annotations, t.words_in_blank))
    end
else
    -- full directory scan
    scan_dir(root_dir)

    if any_top_only then
        -- Only print requested top lists (and nothing else)
        if only_top_files_lines then
            print_top_n_files_by_lines(top_n)
        end
        if only_top_files_words then
            print_top_n_files_by_words(top_n)
        end
        if only_top_folders_lines then
            -- If user asked for folders sorted only, print full folder-sorted list if no top_n requested
            if top_n_specified then
                -- keep behavior: if only_top_folders_lines was passed along with --topn, print top-n folders by lines
                print_top_n_folders_by_lines(top_n)
            else
                -- print all folders sorted by lines if no topN requested
            end
                print_all_folders_sorted_by_lines()
        end
        if only_top_folders_words then
            print_top_n_folders_by_words(top_n)
        end
        -- exit after top-only output
        return
    end

    -- Normal full output (respect reverse order)
    if reverse_order then
        print_total_summary()
        print_folder_summary_ascii()
        print_file_stats_ascii()
    else
        print_file_stats_ascii()
        print_folder_summary_ascii()
        print_total_summary()
    end

    -- Additional Top-N sections (sorted, numbered, show share of overall)
    print_top_n_files_by_lines(top_n)
    print_top_n_files_by_words(top_n)
    print_top_n_folders_by_lines(top_n)
    print_top_n_folders_by_words(top_n)

    -- New: full folder-sorted views
    print_all_folders_sorted_by_lines()
    print_all_folders_sorted_by_percent()

    print_text_summary()
end
