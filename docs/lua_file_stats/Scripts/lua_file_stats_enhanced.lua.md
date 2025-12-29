---@module 'lua_file_stats_enhanced'
---@brief Enhanced Lua statistics script with interactive mode, output file support, and deviation tracking
---@description
--- Analyzes Lua files for comments, annotations, code, and words.
--- Features:
--- - Interactive mode for user-guided configuration
--- - File output support
--- - Deviation tracking from global averages
--- - Improved error handling and type safety
--- - Modular design following project coding standards

local read = io.read
local sort = table.sort
local str_fmt, rep = string.format, string.rep
local tbl_insert, tbl_concat = table.insert, table.concat
local IGNORE_DIRS = { ".git", "debuglog", "docs" }


-- ============================================================================
-- Type Definitions & State
-- ============================================================================

---@class LuaProjectFileStats.Stats
---@field total_lines integer
---@field lines_without_comments integer
---@field comment_lines integer
---@field lines_without_annotations integer
---@field annotation_lines integer
---@field blank_lines integer
---@field total_words integer
---@field words_in_comments integer
---@field words_in_annotations integer
---@field words_without_comments integer
---@field words_without_annotations integer
---@field words_in_blank integer

---@class LuaProjectFileStats.FolderStats : LuaProjectFileStats.Stats
---@field file_count integer
---@field files table[]

---@class LuaProjectFileStats.Config
---@field root_dir string
---@field reverse_order boolean
---@field percent_mode "both"|"percent"|"numbers"
---@field fields_to_print string[]
---@field single_file_path string|nil
---@field col_width integer
---@field top_n integer
---@field only_top_files_lines boolean
---@field only_top_files_words boolean
---@field show_ratios boolean
---@field show_deviations boolean
---@field output_file string|nil
---@field interactive boolean

-- Global state
local folder_summary = {}
local total_stats = {
  total_files = 0,
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

local global_averages = {
  comment_ratio = 0,
  annotation_ratio = 0,
  doc_ratio = 0,
  code_ratio = 0,
  avg_lines_per_file = 0,
  annotation_to_comment_ratio = 0,
}

-- Output buffer for file writing
local output_buffer = {}

-- ============================================================================
-- Utility Functions
-- ============================================================================

---Safe number conversion
---@param n any
---@return number
local function safe_number(n)
  return tonumber(n) or 0
end

---Calculate percentage
---@param part number
---@param total number
---@return number
local function percent(part, total)
  if not total or total == 0 then
    return 0
  end
  return (part / total) * 100
end

---Count words in a string
---@param s string|nil
---@return integer
local function count_words(s)
  if not s or type(s) ~= "string" then
    return 0
  end
  local c = 0
  for _ in s:gmatch("%S+") do
    c = c + 1
  end
  return c
end

---Check if path should be ignored
---@param path string
---@return boolean
local function should_ignore(path)
  if type(path) ~= "string" then
    return true
  end
  for _, dir in ipairs(IGNORE_DIRS) do
    if path:lower():find(dir:lower(), 1, true) then
      return true
    end
  end
  return false
end

---Check if table contains value
---@param tbl table
---@param val any
---@return boolean
local function tbl_contains(tbl, val)
  for _, v in ipairs(tbl) do
    if v == val then
      return true
    end
  end
  return false
end

---Get current working directory (cross-platform)
---@return string
local function get_cwd()
  local success, handle = pcall(io.popen, "cd")
  if not success or not handle then
    return ""
  end
  local result = handle:read("*l") or ""
  handle:close()
  return result:gsub("\\", "/")
end

local cwd = get_cwd()

---Compute relative path from cwd
---@param full_path string
---@return string
local function relative_path(full_path)
  if type(full_path) ~= "string" then
    return ""
  end
  local p = full_path:gsub("\\", "/")
  if cwd ~= "" and p:sub(1, #cwd) == cwd then
    return p:sub(#cwd + 2)
  end
  return p
end

-- ============================================================================
-- Output Management
-- ============================================================================

---Print to console and optionally to buffer
---@param text string
local function output(text)
  print(text)
  if #output_buffer < 100000 then -- prevent memory overflow
    tbl_insert(output_buffer, text)
  end
end

---Write output buffer to file
---@param filename string
---@return boolean success
---@return string|nil error
local function write_output_file(filename)
  if type(filename) ~= "string" or filename == "" then
    return false, "Invalid filename"
  end

  local success, handle = pcall(io.open, filename, "w")
  if not success or not handle then
    return false, "Could not open file: " .. filename
  end

  for _, line in ipairs(output_buffer) do
    handle:write(line .. "\n")
  end

  handle:close()
  return true, nil
end

-- ============================================================================
-- Interactive Mode
-- ============================================================================

---Ask yes/no question
---@param question string
---@param default boolean
---@return boolean
local function ask_yes_no(question, default)
  local default_text = default and "[Y/n]" or "[y/N]"
  output(question .. " " .. default_text .. ": ")
  local answer = read()

  if not answer or answer == "" then
    return default
  end

  local lower = answer:lower()
  return lower == "y" or lower == "yes"
end

---Ask for number input
---@param question string
---@param default number
---@param min number|nil
---@param max number|nil
---@return number
local function ask_number(question, default, min, max)
  output(str_fmt("%s [%d]: ", question, default))
  local answer = read()

  if not answer or answer == "" then
    return default
  end

  local num = tonumber(answer)
  if not num then
    return default
  end

  if min and num < min then
    return min
  end
  if max and num > max then
    return max
  end

  return num
end

---Ask for text input
---@param question string
---@param default string
---@return string
local function ask_text(question, default)
  output(str_fmt("%s [%s]: ", question, default))
  local answer = read()

  if not answer or answer == "" then
    return default
  end

  return answer
end

---Ask for multiple choice
---@param question string
---@param options table
---@param default string
---@return string
local function ask_choice(question, options, default)
  output(question)
  for i, opt in ipairs(options) do
    local marker = (opt == default) and " (default)" or ""
    output(str_fmt("  %d) %s%s", i, opt, marker))
  end
  output("Choice: ")

  local answer = read()
  if not answer or answer == "" then
    return default
  end

  local num = tonumber(answer)
  if num and num >= 1 and num <= #options then
    return options[num]
  end

  return default
end

---Run interactive configuration
---@return LuaProjectFileStats.Config
local function interactive_mode()
  output("\n=== Interactive LuaProjectFileStats.Configuration Mode ===\n")

  local config = {
    root_dir = ".",
    reverse_order = false,
    percent_mode = "both",
    fields_to_print = { "files", "folders", "summary" },
    single_file_path = nil,
    col_width = 7,
    top_n = 25,
    only_top_files_lines = false,
    only_top_files_words = false,
    show_ratios = false,
    show_deviations = true,
    output_file = nil,
    interactive = true,
  }

  -- Ask for root directory
  config.root_dir = ask_text("Root directory to analyze", ".")

  -- Single file mode?
  if ask_yes_no("Analyze single file instead of directory?", false) then
    config.single_file_path = ask_text("File path", "")
  else
    -- Directory analysis options
    config.reverse_order = ask_yes_no("Reverse output order (summary first)?", false)

    -- Percent mode
    config.percent_mode = ask_choice(
      "Display mode:",
      { "both", "percent", "numbers" },
      "both"
    )

    -- Fields to print
    local print_files = ask_yes_no("Print per-file statistics?", true)
    local print_folders = ask_yes_no("Print per-folder statistics?", true)
    local print_summary = ask_yes_no("Print total summary?", true)

    config.fields_to_print = {}
    if print_files then tbl_insert(config.fields_to_print, "files") end
    if print_folders then tbl_insert(config.fields_to_print, "folders") end
    if print_summary then tbl_insert(config.fields_to_print, "summary") end

    -- Ratios and deviations
    config.show_ratios = ask_yes_no("Show ratio analysis?", false)
    config.show_deviations = ask_yes_no("Show deviations from global average?", true)

    -- Top-N lists
    local show_top = ask_yes_no("Show top-N lists?", false)
    if show_top then
      config.top_n = ask_number("How many items in top-N lists?", 25, 1, 100)
      config.only_top_files_lines = ask_yes_no("Show ONLY top files by lines?", false)
      config.only_top_files_words = ask_yes_no("Show ONLY top files by words?", false)
    end

    -- Column width
    config.col_width = ask_number("Column width for tables", 7, 5, 20)
  end

  -- Output file
  if ask_yes_no("Save output to file?", false) then
    config.output_file = ask_text("Output filename", "lua_stats_output.txt")
  end

  output("\n=== LuaProjectFileStats.Configuration Complete ===\n")
  return config
end

-- ============================================================================
-- Statistics Calculation
-- ============================================================================

---Format displayed value
---@param number number
---@param perc number
---@param mode string
---@return string
local function format_value(number, perc, mode)
  local n = safe_number(number)
  local p = safe_number(perc)

  if mode == "both" then
    return str_fmt("%d (%.1f%%)", n, p)
  elseif mode == "percent" then
    return str_fmt("%.1f%%", p)
  else
    return str_fmt("%d", n)
  end
end

---Compute percentages for stats
---@param stats LuaProjectFileStats.Stats
---@return number, number, number, number, number, number, number, number, number, number
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

  return p_no_comments, p_comments, p_no_annotations, p_annotations, p_blank,
         pw_no_comments, pw_no_annotations, pw_comments, pw_annotations, pw_blank
end

---Compute ratios for stats
---@param stats LuaProjectFileStats.FolderStats|LuaProjectFileStats.Stats
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

---Calculate global averages from all folders
local function calculate_global_averages()
  local folder_count = 0
  local sum_comment = 0
  local sum_annotation = 0
  local sum_doc = 0
  local sum_code = 0
  local sum_lines_per_file = 0
  local sum_anno_to_comment = 0

  for _, stats in pairs(folder_summary) do
    local r = compute_ratios(stats)
    sum_comment = sum_comment + r.comment_ratio
    sum_annotation = sum_annotation + r.annotation_ratio
    sum_doc = sum_doc + r.doc_ratio
    sum_code = sum_code + r.code_ratio
    sum_lines_per_file = sum_lines_per_file + r.avg_lines_per_file
    sum_anno_to_comment = sum_anno_to_comment + r.annotation_to_comment_ratio
    folder_count = folder_count + 1
  end

  if folder_count > 0 then
    global_averages.comment_ratio = sum_comment / folder_count
    global_averages.annotation_ratio = sum_annotation / folder_count
    global_averages.doc_ratio = sum_doc / folder_count
    global_averages.code_ratio = sum_code / folder_count
    global_averages.avg_lines_per_file = sum_lines_per_file / folder_count
    global_averages.annotation_to_comment_ratio = sum_anno_to_comment / folder_count
  end
end

---Format deviation from average
---@param value number
---@param average number
---@return string
local function format_deviation(value, average)
  local delta = value - average
  local sign = delta >= 0 and "+" or ""
  return str_fmt("%s%.1f%%", sign, delta * 100)
end

-- ============================================================================
-- File Analysis
-- ============================================================================

---Analyze a single Lua file
---@param filepath string
---@return LuaProjectFileStats.Stats|nil
local function analyze_file(filepath)
  if type(filepath) ~= "string" then
    return nil
  end

  local stats = {
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

  local success, fh = pcall(io.open, filepath, "r")
  if not success or not fh then
    return stats
  end

  local in_block_comment = false

  for line in fh:lines() do
    stats.total_lines = stats.total_lines + 1
    local trimmed = line:match("^%s*(.-)%s*$") or ""

    if trimmed == "" then
      stats.blank_lines = stats.blank_lines + 1
    else
      local code_part, comment_part = trimmed, ""

      if in_block_comment then
        comment_part = code_part
        code_part = ""
        if trimmed:find("%]%]") then
          in_block_comment = false
        end
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
        stats.annotation_lines = stats.annotation_lines + 1
      end

      if #comment_part > 0 then
        stats.comment_lines = stats.comment_lines + 1
        stats.words_in_comments = stats.words_in_comments + count_words(comment_part)
      end

      if #code_part > 0 then
        stats.lines_without_comments = stats.lines_without_comments + 1
        stats.words_without_comments = stats.words_without_comments + count_words(code_part)
      end

      if not is_annotation then
        stats.lines_without_annotations = stats.lines_without_annotations + 1
        stats.words_without_annotations = stats.words_without_annotations + count_words(code_part)
      else
        stats.words_in_annotations = stats.words_in_annotations + count_words(comment_part)
      end

      stats.total_words = stats.total_words + count_words(code_part) + count_words(comment_part)
    end
  end

  fh:close()
  return stats
end

---Get all Lua files under directory (Windows compatible)
---@param dir string
---@return table|nil
local function get_lua_files(dir)
  if type(dir) ~= "string" then
    return nil
  end

  local files = {}
  local cmd = 'dir "' .. dir .. '" /S /B /A:-D 2>nul'
  local success, p = pcall(io.popen, cmd)

  if not success or not p then
    return nil
  end

  for file in p:lines() do
    if file:match("%.lua$") and not should_ignore(file) then
      tbl_insert(files, file)
    end
  end

  p:close()
  return files
end

---Scan directory and aggregate statistics
---@param root_dir string
---@return boolean success
local function scan_dir(root_dir)
  local files = get_lua_files(root_dir)
  if not files then
    return false
  end

  local per_folder = {}

  for _, file in ipairs(files) do
    local stats = analyze_file(file)
    if stats then
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
      for k, v in pairs(stats) do
        f[k] = (f[k] or 0) + v
      end
      f.file_count = f.file_count + 1
      tbl_insert(f.files, { rel_file = rel_file, stats = stats })

      for k, v in pairs(stats) do
        total_stats[k] = (total_stats[k] or 0) + v
      end
      total_stats.total_files = total_stats.total_files + 1
    end
  end

  folder_summary = per_folder
  calculate_global_averages()
  return true
end

-- ============================================================================
-- Output Functions
-- ============================================================================

---Format cell with width
---@param value string|number|any
---@param width integer
---@return string
local function fmt_cell(value, width)
  return str_fmt("%-" .. tostring(width) .. "s", tostring(value))
end

---Format row with file column
---@param left string
---@param cells table
---@param col_width integer
---@return string
local function format_row_file_column(left, cells, col_width)
  local parts = { "| " .. fmt_cell(left, 60) .. " |" }
  for _, c in ipairs(cells) do
    tbl_insert(parts, " " .. fmt_cell(c, col_width) .. " |")
  end
  return tbl_concat(parts, "")
end

---Build header column names
---@return table
local function build_header_cols_names()
  return { "L1", "L2", "L3", "L4", "L5", "W1", "W2", "W3", "W4", "W5" }
end

---Print legend
local function print_legend()
  output("Legend (percentages relative to total lines or total words):")
  output("Lines: L1=NoComments, L2=Comments, L3=NoAnnotations, L4=Annotations, L5=Whitespace")
  output("Words: W1=NoComments, W2=NoAnnotations, W3=Comments, W4=Annotations, W5=Whitespace")
  output("")
end

---Print folder ratios with deviations
---@param show_deviations boolean
local function print_folder_ratios_ascii(show_deviations)
  local line = rep("-", 130)
  output("\n=== Folder Ratios ===")

  if show_deviations then
    output(str_fmt(
      "\nGlobal Averages: Comm=%.1f%%, Anno=%.1f%%, Doc=%.1f%%, Code=%.1f%%, L/File=%.1f, A/C=%.2f",
      global_averages.comment_ratio * 100,
      global_averages.annotation_ratio * 100,
      global_averages.doc_ratio * 100,
      global_averages.code_ratio * 100,
      global_averages.avg_lines_per_file,
      global_averages.annotation_to_comment_ratio
    ))
  end

  output(line)

  if show_deviations then
    output(str_fmt(
      "| %-40s | %6s | %8s | %6s | %8s | %6s | %8s | %6s | %8s | %8s | %6s |",
      "Folder", "Comm%", "Δ", "Anno%", "Δ", "Doc%", "Δ", "Code%", "Δ", "L/File", "A/C"
    ))
  else
    output(str_fmt(
      "| %-40s | %6s | %6s | %6s | %6s | %8s | %6s |",
      "Folder", "Comm%", "Anno%", "Doc%", "Code%", "L/File", "A/C"
    ))
  end

  output(line)

  for folder, stats in pairs(folder_summary) do
    local r = compute_ratios(stats)

    if show_deviations then
      output(str_fmt(
        "| %-40s | %6.1f | %8s | %6.1f | %8s | %6.1f | %8s | %6.1f | %8s | %8.1f | %6.2f |",
        folder,
        r.comment_ratio * 100,
        format_deviation(r.comment_ratio, global_averages.comment_ratio),
        r.annotation_ratio * 100,
        format_deviation(r.annotation_ratio, global_averages.annotation_ratio),
        r.doc_ratio * 100,
        format_deviation(r.doc_ratio, global_averages.doc_ratio),
        r.code_ratio * 100,
        format_deviation(r.code_ratio, global_averages.code_ratio),
        r.avg_lines_per_file,
        r.annotation_to_comment_ratio
      ))
    else
      output(str_fmt(
        "| %-40s | %6.1f | %6.1f | %6.1f | %6.1f | %8.1f | %6.2f |",
        folder,
        r.comment_ratio * 100,
        r.annotation_ratio * 100,
        r.doc_ratio * 100,
        r.code_ratio * 100,
        r.avg_lines_per_file,
        r.annotation_to_comment_ratio
      ))
    end
  end

  output(line)
end

-- ============================================================================
-- Additional Output Functions
-- ============================================================================

---Print file statistics table
---@param config LuaProjectFileStats.Config
local function print_file_stats_ascii(config)
  if not tbl_contains(config.fields_to_print, "files") then
    return
  end

  local line = rep("-", 60 + 10 * (config.col_width + 3))
  output("\n=== File Statistics ===")
  print_legend()
  output(line)

  local headers = build_header_cols_names()
  output(format_row_file_column("File", headers, config.col_width))
  output(line)

  for _, f in pairs(folder_summary) do
    for _, file in ipairs(f.files) do
      local s = file.stats
      local p_no_comments, p_comments, p_no_annotations, p_annotations, p_blank,
            pw_no_comments, pw_no_annotations, pw_comments, pw_annotations, pw_blank =
        compute_percentages(s)

      local cells = {
        format_value(s.lines_without_comments, p_no_comments, config.percent_mode),
        format_value(s.comment_lines, p_comments, config.percent_mode),
        format_value(s.lines_without_annotations, p_no_annotations, config.percent_mode),
        format_value(s.annotation_lines, p_annotations, config.percent_mode),
        format_value(s.blank_lines, p_blank, config.percent_mode),
        format_value(s.words_without_comments, pw_no_comments, config.percent_mode),
        format_value(s.words_without_annotations, pw_no_annotations, config.percent_mode),
        format_value(s.words_in_comments, pw_comments, config.percent_mode),
        format_value(s.words_in_annotations, pw_annotations, config.percent_mode),
        format_value(s.words_in_blank, pw_blank, config.percent_mode),
      }

      output(format_row_file_column(file.rel_file, cells, config.col_width))
    end
  end

  output(line)
end

---Print folder summary table
---@param config LuaProjectFileStats.Config
local function print_folder_summary_ascii(config)
  if not tbl_contains(config.fields_to_print, "folders") then
    return
  end

  local line = rep("-", 42 + 10 * (config.col_width + 3))
  output("\n=== Folder Summary ===")
  print_legend()
  output(line)

  local header_parts = { "| " .. fmt_cell("Folder", 40) .. " | " .. fmt_cell("Files", 5) .. " |" }
  for _, h in ipairs(build_header_cols_names()) do
    tbl_insert(header_parts, " " .. fmt_cell(h, config.col_width) .. " |")
  end
  output(tbl_concat(header_parts, ""))
  output(line)

  for folder, stats in pairs(folder_summary) do
    local p_no_comments, p_comments, p_no_annotations, p_annotations, p_blank,
          pw_no_comments, pw_no_annotations, pw_comments, pw_annotations, pw_blank =
      compute_percentages(stats)

    local cells = {
      format_value(stats.lines_without_comments, p_no_comments, config.percent_mode),
      format_value(stats.comment_lines, p_comments, config.percent_mode),
      format_value(stats.lines_without_annotations, p_no_annotations, config.percent_mode),
      format_value(stats.annotation_lines, p_annotations, config.percent_mode),
      format_value(stats.blank_lines, p_blank, config.percent_mode),
      format_value(stats.words_without_comments, pw_no_comments, config.percent_mode),
      format_value(stats.words_without_annotations, pw_no_annotations, config.percent_mode),
      format_value(stats.words_in_comments, pw_comments, config.percent_mode),
      format_value(stats.words_in_annotations, pw_annotations, config.percent_mode),
      format_value(stats.words_in_blank, pw_blank, config.percent_mode),
    }

    local row_parts = { "| " .. fmt_cell(folder, 40) .. " | " .. fmt_cell(stats.file_count, 5) .. " |" }
    for _, c in ipairs(cells) do
      tbl_insert(row_parts, " " .. fmt_cell(c, config.col_width) .. " |")
    end
    output(tbl_concat(row_parts, ""))
  end

  output(line)
end

---Print total summary
---@param config LuaProjectFileStats.Config
local function print_total_summary(config)
  if not tbl_contains(config.fields_to_print, "summary") then
    return
  end

  local t = total_stats
  local p_no_comments, p_comments, p_no_annotations, p_annotations, p_blank,
        pw_no_comments, pw_no_annotations, pw_comments, pw_annotations, pw_blank =
    compute_percentages(t)

  local line = rep("-", 42 + 10 * (config.col_width + 3))
  output("\n=== Total Summary ===")
  print_legend()
  output(line)

  local header_parts = { "| " .. fmt_cell("Files", 8) .. " |" }
  for _, h in ipairs(build_header_cols_names()) do
    tbl_insert(header_parts, " " .. fmt_cell(h, config.col_width) .. " |")
  end
  output(tbl_concat(header_parts, ""))
  output(line)

  local cells = {
    format_value(t.lines_without_comments, p_no_comments, config.percent_mode),
    format_value(t.comment_lines, p_comments, config.percent_mode),
    format_value(t.lines_without_annotations, p_no_annotations, config.percent_mode),
    format_value(t.annotation_lines, p_annotations, config.percent_mode),
    format_value(t.blank_lines, p_blank, config.percent_mode),
    format_value(t.words_without_comments, pw_no_comments, config.percent_mode),
    format_value(t.words_without_annotations, pw_no_annotations, config.percent_mode),
    format_value(t.words_in_comments, pw_comments, config.percent_mode),
    format_value(t.words_in_annotations, pw_annotations, config.percent_mode),
    format_value(t.words_in_blank, pw_blank, config.percent_mode),
  }

  local row_parts = { "| " .. fmt_cell(t.total_files, 8) .. " |" }
  for _, c in ipairs(cells) do
    tbl_insert(row_parts, " " .. fmt_cell(c, config.col_width) .. " |")
  end
  output(tbl_concat(row_parts, ""))
  output(line)
end

---Gather all files for top-N
---@return table
local function gather_all_files()
  local list = {}
  for _, folder in pairs(folder_summary) do
    for _, f in ipairs(folder.files) do
      tbl_insert(list, { rel = f.rel_file, stats = f.stats })
    end
  end
  return list
end

---Print top-N files by lines
---@param n integer
local function print_top_n_files_by_lines(n)
  local files = gather_all_files()
  sort(files, function(a, b)
    return (a.stats.total_lines or 0) > (b.stats.total_lines or 0)
  end)

  output(str_fmt("\n=== Top %d Files by Lines ===", n))
  local line = rep("-", 95)
  output(line)
  output(str_fmt("| %3s | %-60s | %9s | %9s |", "No", "File", "Lines", "Share"))
  output(line)

  local total = total_stats.total_lines or 0
  for i = 1, math.min(n, #files) do
    local item = files[i]
    local lines = item.stats.total_lines or 0
    local share = percent(lines, total)
    output(str_fmt("| %3d | %-60s | %9d | %8.2f%% |", i, item.rel, lines, share))
  end
  output(line)
end

---Print top-N files by words
---@param n integer
local function print_top_n_files_by_words(n)
  local files = gather_all_files()
  sort(files, function(a, b)
    return (a.stats.total_words or 0) > (b.stats.total_words or 0)
  end)

  output(str_fmt("\n=== Top %d Files by Words ===", n))
  local line = rep("-", 95)
  output(line)
  output(str_fmt("| %3s | %-60s | %9s | %9s |", "No", "File", "Words", "Share"))
  output(line)

  local total = total_stats.total_words or 0
  for i = 1, math.min(n, #files) do
    local item = files[i]
    local words = item.stats.total_words or 0
    local share = percent(words, total)
    output(str_fmt("| %3d | %-60s | %9d | %8.2f%% |", i, item.rel, words, share))
  end
  output(line)
end

---Print top-N folders by annotation ratio
---@param n integer
local function print_top_n_folders_by_annotation_ratio(n)
  local list = {}
  for folder, stats in pairs(folder_summary) do
    local r = compute_ratios(stats)
    tbl_insert(list, {
      folder = folder,
      ratio = r.annotation_ratio,
      lines = stats.total_lines,
    })
  end

  sort(list, function(a, b)
    return a.ratio > b.ratio
  end)

  output(str_fmt("\n=== Top %d Folders by Annotation Ratio ===", n))
  local line = rep("-", 80)
  output(line)
  output(str_fmt("| %3s | %-40s | %8s | %8s |", "No", "Folder", "Anno%", "Lines"))
  output(line)

  for i = 1, math.min(n, #list) do
    local e = list[i]
    output(str_fmt("| %3d | %-40s | %7.2f | %8d |", i, e.folder, e.ratio * 100, e.lines))
  end

  output(line)
end

---Print ratio guidelines
local function print_ratio_guidelines()
  output([[

=== Optimal Ratio Guidelines (Heuristic) ===

These ratios describe typical, well-balanced Lua module characteristics in a mature codebase.
They are orientation values to help interpret statistics, not strict quality thresholds.

Metric                     Typical Range    Interpretation
-------------------------- ---------------- ------------------------------------------------------------
Comment Ratio              15% – 30%        Healthy explanation density. Below 10% often under-documented,
                                            above 35% can indicate verbose or redundant comments.

Annotation Ratio           5% – 12%         Strong LuaLS/EmmyLua usage. Below 3% suggests weak typing,
                                            above 15% usually means API-heavy or interface modules.

Documentation Ratio        20% – 40%        Combined comments + annotations. Indicates overall readability
                                            and long-term maintainability.

Code Ratio                 55% – 75%        Effective executable logic. Very low values imply documentation-
                                            dominated modules; very high values may reduce approachability.

Average Lines per File     80 – 200         Indicates modular structure. Higher values suggest refactoring
                                            opportunities; very low values may indicate over-fragmentation.

Annotation/Comment Ratio   0.20 – 0.50      Balance between semantic explanation and technical typing.
                                            Higher values mean type-driven documentation (APIs, callbacks).

Use these ratios to identify architectural hotspots, refactoring candidates, and documentation
asymmetries. Consistency within a module matters more than matching global "ideal" numbers.
]])
end

-- ============================================================================
-- Main Execution
-- ============================================================================

---Parse command line arguments
---@return LuaProjectFileStats.Config
local function parse_args()
  local config = {
    root_dir = ".",
    reverse_order = false,
    percent_mode = "both",
    fields_to_print = { "files", "folders", "summary" },
    single_file_path = nil,
    col_width = 7,
    top_n = 25,
    only_top_files_lines = false,
    only_top_files_words = false,
    show_ratios = false,
    show_deviations = false,
    output_file = nil,
    interactive = false,
  }

  for _, a in ipairs(arg) do
    if a == "-i" or a == "--interactive" then
      config.interactive = true
      return config  -- Return immediately, ignore other flags
    elseif a == "--reverse" then
      config.reverse_order = true
    elseif a == "--percent-only" or a == "--percentage-only" then
      config.percent_mode = "percent"
    elseif a == "--numbers-only" then
      config.percent_mode = "numbers"
    elseif a == "--ratios" then
      config.show_ratios = true
    elseif a == "--deviations" then
      config.show_deviations = true
    elseif a:match("^%-%-fields=") then
      local val = a:sub(10)
      config.fields_to_print = {}
      for f in val:gmatch("([^,]+)") do
        tbl_insert(config.fields_to_print, f)
      end
    elseif a:match("^%-%-file=") then
      config.single_file_path = a:sub(9)
    elseif a:match("^%-%-colwidth=") then
      config.col_width = tonumber(a:sub(12)) or config.col_width
    elseif a:match("^%-%-topn=") then
      config.top_n = tonumber(a:sub(8)) or config.top_n
    elseif a == "--top-files-lines-only" then
      config.only_top_files_lines = true
    elseif a == "--top-files-words-only" then
      config.only_top_files_words = true
    elseif a:match("^%-o") or a:match("^%-%-output=") then
      if a:match("^%-o") and #a > 2 then
        config.output_file = a:sub(3)
      elseif a:match("^%-%-output=") then
        config.output_file = a:sub(11)
      end
    elseif not a:match("^%-") then
      config.root_dir = a
    end
  end

  return config
end

---Main entry point
local function main()
  local config = parse_args()

  -- Interactive mode overrides everything
  if config.interactive then
    config = interactive_mode()
  end

  -- Execute analysis
  if config.single_file_path then
    local stats = analyze_file(config.single_file_path)
    if stats then
      output("\n=== Single File Statistics ===")
      output(str_fmt("File: %s", relative_path(config.single_file_path)))
      output(str_fmt("Lines: %d (Code: %d, Comments: %d, Annotations: %d, Blank: %d)",
        stats.total_lines,
        stats.lines_without_comments,
        stats.comment_lines,
        stats.annotation_lines,
        stats.blank_lines
      ))
      output(str_fmt("Words: %d (Code: %d, Comments: %d, Annotations: %d)",
        stats.total_words,
        stats.words_without_comments,
        stats.words_in_comments,
        stats.words_in_annotations
      ))
    end
  else
    local success = scan_dir(config.root_dir)
    if not success then
      output("Error: Could not scan directory: " .. config.root_dir)
      return
    end

    output("\n=== Lua File Statistics Report ===")
    output(str_fmt("Root: %s", config.root_dir))
    output(str_fmt("Files analyzed: %d", total_stats.total_files))
    output(str_fmt("Total lines: %d\n", total_stats.total_lines))

    -- Check if only top lists should be shown
    local any_top_only = config.only_top_files_lines or config.only_top_files_words

    if any_top_only then
      if config.only_top_files_lines then
        print_top_n_files_by_lines(config.top_n)
      end
      if config.only_top_files_words then
        print_top_n_files_by_words(config.top_n)
      end
    else
      -- Normal output mode
      if config.reverse_order then
        -- Summary first
        print_total_summary(config)

        if config.show_ratios then
          print_folder_ratios_ascii(config.show_deviations)
          print_top_n_folders_by_annotation_ratio(config.top_n)
          print_ratio_guidelines()
        end

        print_folder_summary_ascii(config)
        print_file_stats_ascii(config)
      else
        -- Files first (default)
        print_file_stats_ascii(config)
        print_folder_summary_ascii(config)

        if config.show_ratios then
          print_folder_ratios_ascii(config.show_deviations)
          print_top_n_folders_by_annotation_ratio(config.top_n)
          print_ratio_guidelines()
        end

        print_total_summary(config)
      end

      -- Top-N lists if requested (but not in top-only mode)
      if config.top_n > 0 and not any_top_only then
        print_top_n_files_by_lines(config.top_n)
        print_top_n_files_by_words(config.top_n)
      end

      -- Final text summary
      output("\n=== Text Summary ===")
      output(str_fmt("Analyzed files: %d", total_stats.total_files))
      output(str_fmt(
        "Lines: Total=%d, Code=%d, Comments=%d, Annotations=%d, Blank=%d",
        total_stats.total_lines,
        total_stats.lines_without_comments,
        total_stats.comment_lines,
        total_stats.annotation_lines,
        total_stats.blank_lines
      ))
      output(str_fmt(
        "Words: Total=%d, Code=%d, Comments=%d, Annotations=%d",
        total_stats.total_words,
        total_stats.words_without_comments,
        total_stats.words_in_comments,
        total_stats.words_in_annotations
      ))
    end
  end

  -- Write to file if requested
  if config.output_file then
    local success, err = write_output_file(config.output_file)
    if success then
      print(str_fmt("\n✓ Output written to: %s", config.output_file))
    else
      print(str_fmt("\n✗ Error writing output file: %s", err or "unknown"))
    end
  end
end

-- Execute with error handling
local success, err = pcall(main)
if not success then
  print("Fatal error: " .. tostring(err))
  os.exit(1)
end
