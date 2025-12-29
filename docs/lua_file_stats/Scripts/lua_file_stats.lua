---@module 'lua_file_stats'
-- Lua script: relative paths, inline/block comment handling, annotations,
-- ASCII tables with optional percent display, text summary, top-N lists, and flags to print only top lists.
-- All function and inline comments in English. Designed to be run from CLI (not requiring Neovim).

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
  blank_lines = 0, -- whitespace-only lines
  total_words = 0,
  words_in_comments = 0,
  words_in_annotations = 0,
  words_without_comments = 0,
  words_without_annotations = 0,
  words_in_blank = 0, -- words on blank lines (usually 0)
}

-- Output mode settings (default: both numbers and percents)
local percent_mode = "both" -- "both" | "percent" | "numbers"
local fields_to_print = { "files", "folders", "summary" } -- which tables to print by default
local single_file_path = nil

-- Top-N settings and top-only flags
local top_n = 25
local only_top_files_lines = false
local only_top_files_words = false

local function safe_number(n)
  return n or 0
end
local function percent(part, total)
  if not total or total == 0 then
    return 0
  end
  return (part / total) * 100
end
local function count_words(s)
  local c = 0
  if not s then
    return 0
  end
  for _ in s:gmatch("%S+") do
    c = c + 1
  end
  return c
end
local function should_ignore(path)
  for _, dir in ipairs(IGNORE_DIRS) do
    if path:lower():find(dir:lower()) then
      return true
    end
  end
  return false
end
local function tbl_contains(tbl, val)
  for _, v in ipairs(tbl) do
    if v == val then
      return true
    end
  end
  return false
end

-- Get current working directory (Windows-friendly)
local cwd = io.popen("cd"):read("*l")
cwd = cwd and cwd:gsub("\\", "/") or ""

-- Compute relative path from cwd if possible
local function relative_path(full_path)
  local p = full_path:gsub("\\", "/")
  if cwd ~= "" and p:sub(1, #cwd) == cwd then
    return p:sub(#cwd + 2)
  end
  return p
end

-- Format displayed value depending on percent_mode
local function format_value(number, perc)
  if percent_mode == "both" then
    return string.format("%d (%.1f%%)", safe_number(number), safe_number(perc))
  elseif percent_mode == "percent" then
    return string.format("%.1f%%", safe_number(perc))
  else
    return string.format("%d", safe_number(number))
  end
end

-- Compute percentages for a stats table.
-- Returns:
-- p_no_comments, p_comments, p_no_annotations, p_annotations, p_blank,
-- pw_no_comments, pw_no_annotations, pw_comments, pw_annotations, pw_blank
local function compute_percentages(stats)
  local total_lines = stats.total_lines or 0
  local total_words = stats.total_words or 0

  local p_no_comments = percent(stats.lines_without_comments or 0, total_lines)
  local p_comments = percent(stats.comment_lines or 0, total_lines)
  local p_no_annotations = percent(stats.lines_without_annotations or 0, total_lines)
  local p_annotations = percent(stats.annotation_lines or 0, total_lines)
  local p_blank = percent(stats.blank_lines or 0, total_lines)

  local pw_no_comments = percent(stats.words_without_comments or 0, total_words)
  local pw_no_annotations = percent(stats.words_without_annotations or 0, total_words)
  local pw_comments = percent(stats.words_in_comments or 0, total_words)
  local pw_annotations = percent(stats.words_in_annotations or 0, total_words)
  local pw_blank = percent(stats.words_in_blank or 0, total_words)

  return p_no_comments,
    p_comments,
    p_no_annotations,
    p_annotations,
    p_blank,
    pw_no_comments,
    pw_no_annotations,
    pw_comments,
    pw_annotations,
    pw_blank
end

-- Compute derived ratios for a stats table (module / folder level).
-- All ratios are line-based and normalized to [0,1].
---@param stats table
---@return table ratios
local function compute_ratios(stats)
  local total = stats.total_lines or 0
  local comments = stats.comment_lines or 0
  local annotations = stats.annotation_lines or 0
  local code = stats.lines_without_comments or 0
  local files = stats.file_count or 1

  return {
    comment_ratio = total > 0 and comments / total or 0,
    annotation_ratio = total > 0 and annotations / total or 0,
    doc_ratio = total > 0 and (comments + annotations) / total or 0,
    code_ratio = total > 0 and code / total or 0,
    avg_lines_per_file = files > 0 and total / files or 0,
    annotation_to_comment_ratio = comments > 0 and annotations / comments or 0,
  }
end

-- Analyze a single Lua file.
-- Counts: total lines, blank lines, comment lines, annotation lines, code lines,
-- and words in each segment. Handles inline (-- ...) and block (--[[ ... ]]) comments.
---@param filepath string
---@return table stats
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
    -- Return zeroed stats on failure to open
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
      words_in_blank = 0,
    }
  end

  for line in fh:lines() do
    total_lines = total_lines + 1
    local trimmed = line:match("^%s*(.-)%s*$") or ""

    if trimmed == "" then
      -- blank / whitespace-only line
      blank_lines = blank_lines + 1
      words_in_blank = words_in_blank + 0
    else
      local code_part, comment_part = trimmed, ""

      if in_block_comment then
        -- We are inside an open block comment: treat whole line as comment
        comment_part = code_part
        code_part = ""
        if trimmed:find("%]%]") then
          in_block_comment = false
        end
      elseif trimmed:match("^%-%-%[%[") then
        -- Opening block comment
        in_block_comment = true
        comment_part = code_part
        code_part = ""
      else
        -- Inline comments or full-line single-line comments
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
    words_in_blank = words_in_blank,
  }
end

-- Retrieve all Lua files under dir using Windows 'dir' command
---@param dir string
---@return table|nil files
local function get_lua_files(dir)
  local files = {}
  local cmd = 'dir "' .. dir .. '" /S /B /A:-D'
  local p = io.popen(cmd)
  if not p then
    return nil
  end
  for file in p:lines() do
    if file:match("%.lua$") and not should_ignore(file) then
      table.insert(files, file)
    end
  end
  p:close()
  return files
end

-- Scan directory and aggregate per-folder and global totals.
---@param root_dir string
local function scan_dir(root_dir)
  local files = get_lua_files(root_dir)
  if not files then
    return
  end
  local per_folder = {}
  for _, file in ipairs(files) do
    local stats = analyze_file(file)
    local rel_file = relative_path(file)
    local folder = rel_file:match("(.+)/") or "."

    if not per_folder[folder] then
      per_folder[folder] = {
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
        words_in_blank = 0,
        file_count = 0,
        files = {},
      }
    end

    local f = per_folder[folder]
    -- aggregate per-folder
    for k, v in pairs(stats) do
      if f[k] == nil then
        f[k] = v
      else
        f[k] = f[k] + v
      end
    end
    f.file_count = f.file_count + 1
    table.insert(f.files, { rel_file = rel_file, stats = stats })

    -- aggregate total_stats
    for k, v in pairs(stats) do
      if total_stats[k] == nil then
        total_stats[k] = v
      else
        total_stats[k] = total_stats[k] + v
      end
    end
    total_stats.total_files = total_stats.total_files + 1
  end
  folder_summary = per_folder
end

-- Column formatting
local col_width = 7
for _, a in ipairs(arg) do
  if a:match("^%-%-colwidth=") then
    col_width = tonumber(a:sub(12)) or col_width
  end
end

-- Helper: format a single cell with given width (left aligned)
local function fmt_cell(value, width)
  return string.format("%-" .. tostring(width) .. "s", tostring(value))
end

-- Format a row where left column is a long file/folder name (60 chars)
local function format_row_file_column(left, cells)
  local parts = { "| " .. fmt_cell(left, 60) .. " |" }
  for _, c in ipairs(cells) do
    table.insert(parts, " " .. fmt_cell(c, col_width) .. " |")
  end
  return table.concat(parts, "")
end

-- Build header column names: L1..L5, W1..W5 (new numbering includes blank)
-- L1 = NoComments, L2 = Comments, L3 = NoAnnotations, L4 = Annotations, L5 = Whitespace
-- W1 = NoComments, W2 = NoAnnotations, W3 = Comments, W4 = Annotations, W5 = Whitespace
local function build_header_cols_names()
  return { "L1", "L2", "L3", "L4", "L5", "W1", "W2", "W3", "W4", "W5" }
end

-- Print legend describing numbering and what percentages are relative to
local function print_legend()
  print("Legend (percentages relative to total lines or total words):")
  print("Lines: L1=NoComments, L2=Comments, L3=NoAnnotations, L4=Annotations, L5=Whitespace")
  print("Words: W1=NoComments, W2=NoAnnotations, W3=Comments, W4=Annotations, W5=Whitespace\n")
  print(
    "Note: percentages in each table are computed relative to the table's totals (e.g. file's total lines or words)."
  )
end

-- Print Single File Stats (table)
local function print_single_file_stats_ascii()
  if not single_file_path then
    return
  end
  local line = string.rep("-", 60 + 10 * (col_width + 3))
  print("=== Single File Stats ===")
  print_legend()
  print(line)

  local headers = build_header_cols_names()
  print(format_row_file_column("File", headers))
  print(line)

  local stats = analyze_file(single_file_path)
  local rel_file = relative_path(single_file_path)
  local p_no_comments, p_comments, p_no_annotations, p_annotations, p_blank, pw_no_comments, pw_no_annotations, pw_comments, pw_annotations, pw_blank =
    compute_percentages(stats)

  local cells = {
    -- Lines L1..L5
    format_value(stats.lines_without_comments, p_no_comments),
    format_value(stats.comment_lines, p_comments),
    format_value(stats.lines_without_annotations, p_no_annotations),
    format_value(stats.annotation_lines, p_annotations),
    format_value(stats.blank_lines, p_blank),
    -- Words W1..W5
    format_value(stats.words_without_comments, pw_no_comments),
    format_value(stats.words_without_annotations, pw_no_annotations),
    format_value(stats.words_in_comments, pw_comments),
    format_value(stats.words_in_annotations, pw_annotations),
    format_value(stats.words_in_blank, pw_blank),
  }

  print(format_row_file_column(rel_file, cells))
  print(line)
end

-- Print per-file table for all files
local function print_file_stats_ascii()
  if not tbl_contains(fields_to_print, "files") then
    return
  end
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
      local p_no_comments, p_comments, p_no_annotations, p_annotations, p_blank, pw_no_comments, pw_no_annotations, pw_comments, pw_annotations, pw_blank =
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
        format_value(s.words_in_blank, pw_blank),
      }

      print(format_row_file_column(file.rel_file, cells))
    end
  end

  print(line)
end

-- Print per-folder summary table
local function print_folder_summary_ascii()
  if not tbl_contains(fields_to_print, "folders") then
    return
  end
  local line = string.rep("-", 42 + 10 * (col_width + 3))
  print("\n=== Folder Summary ===")
  print_legend()
  print(line)

  -- Header: Folder (40) | Files (5) | 10 columns
  local header_parts = { "| " .. fmt_cell("Folder", 40) .. " | " .. fmt_cell("Files", 5) .. " |" }
  for _, h in ipairs(build_header_cols_names()) do
    table.insert(header_parts, " " .. fmt_cell(h, col_width) .. " |")
  end
  print(table.concat(header_parts, ""))
  print(line)

  for folder, stats in pairs(folder_summary) do
    local p_no_comments, p_comments, p_no_annotations, p_annotations, p_blank, pw_no_comments, pw_no_annotations, pw_comments, pw_annotations, pw_blank =
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
      format_value(stats.words_in_blank, pw_blank),
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

-- Print Top-N lists: files / folders by lines or words.
-- Each row: ranking, path, absolute count, share of global total
local function print_top_n_files_by_lines(n)
  n = n or top_n
  local files = gather_all_files()
  -- sort by stats.total_lines descending
  table.sort(files, function(a, b)
    return (a.stats.total_lines or 0) > (b.stats.total_lines or 0)
  end)
  print("\n=== Top " .. n .. " Files by Lines (Share of total lines) ===")
  local line = string.rep("-", 6 + 60 + 20)
  print(line)
  print(string.format("| %3s | %-60s | %-9s | %-9s |", "No", "File", "Lines", "Share"))
  print(line)
  local total = total_stats.total_lines or 0
  for i = 1, math.min(n, #files) do
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
  table.sort(files, function(a, b)
    return (a.stats.total_words or 0) > (b.stats.total_words or 0)
  end)
  print("\n=== Top " .. n .. " Files by Words (Share of total words) ===")
  local line = string.rep("-", 6 + 60 + 20)
  print(line)
  print(string.format("| %3s | %-60s | %-9s | %-9s |", "No", "File", "Words", "Share"))
  print(line)
  local total = total_stats.total_words or 0
  for i = 1, math.min(n, #files) do
    local item = files[i]
    local words = item.stats.total_words or 0
    local share = percent(words, total)
    print(string.format("| %3d | %-60s | %9d | %8.2f%% |", i, item.rel, words, share))
  end
  print(line)
end

-- Print per-folder ratio summary table
local function print_folder_ratios_ascii()
  local line = string.rep("-", 110)
  print("\n=== Folder Ratios ===")
  print(line)
  print(
    string.format(
      "| %-40s | %6s | %6s | %6s | %6s | %8s | %6s |",
      "Folder",
      "Comm%",
      "Anno%",
      "Doc%",
      "Code%",
      "L/File",
      "A/C"
    )
  )
  print(line)

  for folder, stats in pairs(folder_summary) do
    local r = compute_ratios(stats)
    print(
      string.format(
        "| %-40s | %6.1f | %6.1f | %6.1f | %6.1f | %8.1f | %6.2f |",
        folder,
        r.comment_ratio * 100,
        r.annotation_ratio * 100,
        r.doc_ratio * 100,
        r.code_ratio * 100,
        r.avg_lines_per_file,
        r.annotation_to_comment_ratio
      )
    )
  end

  print(line)
end

local function print_top_n_folders_by_annotation_ratio(n)
  n = n or top_n
  local list = {}

  for folder, stats in pairs(folder_summary) do
    local r = compute_ratios(stats)
    table.insert(list, {
      folder = folder,
      ratio = r.annotation_ratio,
      lines = stats.total_lines,
    })
  end

  table.sort(list, function(a, b)
    return a.ratio > b.ratio
  end)

  print("\n=== Top " .. n .. " Folders by Annotation Ratio ===")
  local line = string.rep("-", 80)
  print(line)
  print(string.format("| %3s | %-40s | %8s | %8s |", "No", "Folder", "Anno%", "Lines"))
  print(line)

  for i = 1, math.min(n, #list) do
    local e = list[i]
    print(string.format("| %3d | %-40s | %7.2f | %8d |", i, e.folder, e.ratio * 100, e.lines))
  end

  print(line)
end

-- Print Total Summary table (aggregated) with 10 columns as configured
local function print_total_summary()
  if not tbl_contains(fields_to_print, "summary") then
    return
  end
  local t = total_stats
  local p_no_comments, p_comments, p_no_annotations, p_annotations, p_blank, pw_no_comments, pw_no_annotations, pw_comments, pw_annotations, pw_blank =
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
    format_value(t.words_in_blank, pw_blank),
  }

  local row_parts = { "| " .. fmt_cell(t.total_files, 8) .. " |" }
  for _, c in ipairs(cells) do
    table.insert(row_parts, " " .. fmt_cell(c, col_width) .. " |")
  end
  print(table.concat(row_parts, ""))
  print(line)
end

-- Print heuristic guidelines for interpreting ratio values.
-- This is informational output only and does not affect any calculations.
local function print_ratio_note()
  print([[
Optimal Ratio Guidelines (heuristic, not strict rules)

These ratios describe typical, well-balanced Lua module characteristics in a mature Neovim / plugin-style codebase.
They are intended as orientation values to help interpret the statistics, not as hard quality thresholds.

Line-based ratios (per module / folder):

Metric                     Typical Range        Interpretation
-------------------------- -------------------- ------------------------------------------------------------
Comment Ratio              15% – 30%            Healthy explanation density. Below 10% is often under-documented,
                                                above 35% can indicate verbose or redundant comments.

Annotation Ratio           5% – 12%              Strong LuaLS / EmmyLua usage. Below 3% suggests weak typing,
                                                above 15% usually means API-heavy or interface modules.

Documentation Ratio        20% – 40%             Combined comments + annotations. Indicates overall readability
                                                and long-term maintainability.

Code Ratio                 55% – 75%             Effective executable logic. Very low values imply documentation-
                                                dominated modules; very high values may reduce approachability.

Average Lines per File     80 – 200              Indicates modular structure. Higher values suggest refactoring
                                                opportunities; very low values may indicate over-fragmentation.

Annotation / Comment Ratio 0.20 – 0.50           Balance between semantic explanation and technical typing.
                                                Higher values mean type-driven documentation (APIs, callbacks).

General interpretation notes:

- High annotation ratio with moderate comment ratio usually indicates public-facing or reusable modules.
- High comment ratio with low annotation ratio often appears in complex logic or orchestration code.
- Strong deviations from the global average are more interesting than absolute values.
- Consistency within a module matters more than matching global "ideal" numbers.

Use these ratios to identify architectural hotspots, refactoring candidates, and documentation asymmetries,
not to enforce uniformity across unrelated modules.
]])
end

-- Text ummary printed at end (unchanged but includes whitespace counts)
local function print_text_summary()
  print("\n=== Text Summary ===")
  local t = total_stats
  print(string.format("Analyzed files: %d", t.total_files))
  print(
    string.format(
      "Lines: Total=%d, WithoutComments=%d, Comments=%d, WithoutAnnotations=%d, Annotations=%d, Whitespace=%d",
      t.total_lines,
      t.lines_without_comments,
      t.comment_lines,
      t.lines_without_annotations,
      t.annotation_lines,
      t.blank_lines
    )
  )
  print(
    string.format(
      "Words: Total=%d, WithoutComments=%d, Comments=%d, WithoutAnnotations=%d, Annotations=%d, Whitespace=%d",
      t.total_words,
      t.words_without_comments,
      t.words_in_comments,
      t.words_without_annotations,
      t.words_in_annotations,
      t.words_in_blank
    )
  )
end

-- Argument parsing
local root_dir = "."
local reverse_order = false
local ratios = false

for _, a in ipairs(arg) do
  if a == "--reverse" then
    reverse_order = true
  elseif a == "--percent-only" or a == "--percentage-only" then
    percent_mode = "percent"
  elseif a == "--numbers-only" then
    percent_mode = "numbers"
  elseif a == "--ratios" then
    ratios = true
  elseif a:match("^%-%-fields=") then
    local val = a:sub(10)
    fields_to_print = {}
    for f in val:gmatch("([^,]+)") do
      table.insert(fields_to_print, f)
    end
  elseif a:match("^%-%-file=") then
    single_file_path = a:sub(9)
  elseif a:match("^%-%-colwidth=") then
    col_width = tonumber(a:sub(12)) or col_width
  elseif a:match("^%-%-topn=") then
    top_n = tonumber(a:sub(8)) or top_n
  elseif a == "--top-files-lines-only" then
    only_top_files_lines = true
  elseif a == "--top-files-words-only" then
    only_top_files_words = true
  else
    root_dir = a
  end
end

-- Determine mode: if any top-only flag is set, we will only print the requested top lists.
local any_top_only = only_top_files_lines or only_top_files_words

-- Main execution
if single_file_path then
  -- single-file mode: analyze only specified file; still support top-only? top-only doesn't make sense here.
  local stats = analyze_file(single_file_path)
  folder_summary =
    { ["."] = { files = { { rel_file = relative_path(single_file_path), stats = stats } }, file_count = 1 } }

  print_single_file_stats_ascii()
  -- single file textual summary
  do
    local t = stats
    print("\n=== Single File Text Summary ===")
    print(string.format("File: %s", relative_path(single_file_path)))
    print(
      string.format(
        "Lines: Total=%d, WithoutComments=%d, Comments=%d, WithoutAnnotations=%d, Annotations=%d, Whitespace=%d",
        t.total_lines,
        t.lines_without_comments,
        t.comment_lines,
        t.lines_without_annotations,
        t.annotation_lines,
        t.blank_lines
      )
    )
    print(
      string.format(
        "Words: Total=%d, WithoutComments=%d, Comments=%d, WithoutAnnotations=%d, Annotations=%d, Whitespace=%d",
        t.total_words,
        t.words_without_comments,
        t.words_in_comments,
        t.words_without_annotations,
        t.words_in_annotations,
        t.words_in_blank
      )
    )
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
    -- exit after top-only output
    return
  end

  if reverse_order then
    print_total_summary()

    if ratios then
      print_folder_ratios_ascii()
      print_top_n_folders_by_annotation_ratio(top_n)
      print_ratio_note()
    end

    print_folder_summary_ascii()
    print_file_stats_ascii()
  else
    print_file_stats_ascii()
    print_folder_summary_ascii()

    if ratios then
      print_folder_ratios_ascii()
      print_top_n_folders_by_annotation_ratio(top_n)
      print_ratio_note()
    end

    print_total_summary()
  end

  -- Final textual summary
  print_text_summary()
end
