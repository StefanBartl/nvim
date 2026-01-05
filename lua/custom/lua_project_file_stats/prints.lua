---@module 'custom.lua_project_file_stats.prints'
---@brief Output and formatting functions

local utils = require("custom.lua_project_file_stats.utils")

local M = {}

local str_fmt, rep = string.format, string.rep
local tbl_insert, tbl_concat, tbl_sort = table.insert, table.concat, table.sort
local tbl_contains = utils.tbl_contains

-- Output buffer for file writing
M.output_buffer = {}

---Print to console and buffer
---@param text string
---@param state LuaProjectFileStats.State
function M.output(text, state)
  print(text)
  if #state.output_buffer < 100000 then
    tbl_insert(state.output_buffer, text)
  end
end

---Write output buffer to file
---@param filename string
---@param state LuaProjectFileStats.State
---@return boolean success
---@return string|nil error
function M.write_output_file(filename, state)
  if type(filename) ~= "string" or filename == "" then
    return false, "Invalid filename"
  end

  local success, handle = pcall(io.open, filename, "w")
  if not success or not handle then
    return false, "Could not open file: " .. filename
  end

  for _, line in ipairs(state.output_buffer) do
    handle:write(line .. "\n")
  end

  handle:close()
  return true, nil
end

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
---@return string[]
local function build_header_cols_names()
  return { "L1", "L2", "L3", "L4", "L5", "W1", "W2", "W3", "W4", "W5" }
end

---Print legend
---@param state LuaProjectFileStats.State
function M.print_legend(state)
  M.output("Legend (percentages relative to total lines or total words):", state)
  M.output("Lines: L1=NoComments, L2=Comments, L3=NoAnnotations, L4=Annotations, L5=Whitespace", state)
  M.output("Words: W1=NoComments, W2=NoAnnotations, W3=Comments, W4=Annotations, W5=Whitespace", state)
  M.output("", state)
end

---Print folder ratios with deviations
---@param show_deviations boolean
---@param state LuaProjectFileStats.State
function M.print_folder_ratios_ascii(show_deviations, state)
  local line = rep("-", 130)
  M.output("\n=== Folder Ratios ===", state)
  M.output("(Type definition files excluded from ratio analysis)", state)

  if show_deviations then
    M.output(str_fmt(
      "\nGlobal Averages: Comm=%.1f%%, Anno=%.1f%%, Doc=%.1f%%, Code=%.1f%%, L/File=%.1f, A/C=%.2f",
      state.global_averages.comment_ratio * 100,
      state.global_averages.annotation_ratio * 100,
      state.global_averages.doc_ratio * 100,
      state.global_averages.code_ratio * 100,
      state.global_averages.avg_lines_per_file,
      state.global_averages.annotation_to_comment_ratio
    ), state)
  end

  M.output(line, state)

  if show_deviations then
    M.output(str_fmt(
      "| %-40s | %6s | %8s | %6s | %8s | %6s | %8s | %6s | %8s | %8s | %6s |",
      "Folder", "Comm%", "Delta", "Anno%", "Delta", "Doc%", "Delta", "Code%", "Delta", "L/File", "A/C"
    ), state)
  else
    M.output(str_fmt(
      "| %-40s | %6s | %6s | %6s | %6s | %8s | %6s |",
      "Folder", "Comm%", "Anno%", "Doc%", "Code%", "L/File", "A/C"
    ), state)
  end

  M.output(line, state)

  for folder, stats in pairs(state.folder_summary) do
    local r = utils.compute_ratios(stats)

    if show_deviations then
      M.output(str_fmt(
        "| %-40s | %6.1f | %8s | %6.1f | %8s | %6.1f | %8s | %6.1f | %8s | %8.1f | %6.2f |",
        folder,
        r.comment_ratio * 100,
        utils.format_deviation(r.comment_ratio, state.global_averages.comment_ratio),
        r.annotation_ratio * 100,
        utils.format_deviation(r.annotation_ratio, state.global_averages.annotation_ratio),
        r.doc_ratio * 100,
        utils.format_deviation(r.doc_ratio, state.global_averages.doc_ratio),
        r.code_ratio * 100,
        utils.format_deviation(r.code_ratio, state.global_averages.code_ratio),
        r.avg_lines_per_file,
        r.annotation_to_comment_ratio
      ), state)
    else
      M.output(str_fmt(
        "| %-40s | %6.1f | %6.1f | %6.1f | %6.1f | %8.1f | %6.2f |",
        folder,
        r.comment_ratio * 100,
        r.annotation_ratio * 100,
        r.doc_ratio * 100,
        r.code_ratio * 100,
        r.avg_lines_per_file,
        r.annotation_to_comment_ratio
      ), state)
    end
  end

  M.output(line, state)
end

---Print file statistics table
---@param config LuaProjectFileStats.Config
---@param state LuaProjectFileStats.State
function M.print_file_stats_ascii(config, state)
  if not tbl_contains(config.fields_to_print, "files") then
    return
  end

  local line = rep("-", 60 + 10 * (config.col_width + 3))
  M.output("\n=== File Statistics ===", state)
  M.print_legend(state)
  M.output(line, state)

  local headers = build_header_cols_names()
  M.output(format_row_file_column("File", headers, config.col_width), state)
  M.output(line, state)

  for _, f in pairs(state.folder_summary) do
    for _, file in ipairs(f.files) do
      local s = file.stats
      local p_no_comments, p_comments, p_no_annotations, p_annotations, p_blank,
            pw_no_comments, pw_no_annotations, pw_comments, pw_annotations, pw_blank =
        utils.compute_percentages(s)

      local cells = {
        utils.format_value(s.lines_without_comments, p_no_comments, config.percent_mode),
        utils.format_value(s.comment_lines, p_comments, config.percent_mode),
        utils.format_value(s.lines_without_annotations, p_no_annotations, config.percent_mode),
        utils.format_value(s.annotation_lines, p_annotations, config.percent_mode),
        utils.format_value(s.blank_lines, p_blank, config.percent_mode),
        utils.format_value(s.words_without_comments, pw_no_comments, config.percent_mode),
        utils.format_value(s.words_without_annotations, pw_no_annotations, config.percent_mode),
        utils.format_value(s.words_in_comments, pw_comments, config.percent_mode),
        utils.format_value(s.words_in_annotations, pw_annotations, config.percent_mode),
        utils.format_value(s.words_in_blank, pw_blank, config.percent_mode),
      }

      M.output(format_row_file_column(file.rel_file, cells, config.col_width), state)
    end
  end

  M.output(line, state)
end

---Print folder summary table
---@param config LuaProjectFileStats.Config
---@param state LuaProjectFileStats.State
function M.print_folder_summary_ascii(config, state)
  if not tbl_contains(config.fields_to_print, "folders") then
    return
  end

  local line = rep("-", 42 + 10 * (config.col_width + 3))
  M.output("\n=== Folder Summary ===", state)
  M.print_legend(state)
  M.output(line, state)

  local header_parts = { "| " .. fmt_cell("Folder", 40) .. " | " .. fmt_cell("Files", 5) .. " |" }
  for _, h in ipairs(build_header_cols_names()) do
    tbl_insert(header_parts, " " .. fmt_cell(h, config.col_width) .. " |")
  end
  M.output(tbl_concat(header_parts, ""), state)
  M.output(line, state)

  for folder, stats in pairs(state.folder_summary) do
    local p_no_comments, p_comments, p_no_annotations, p_annotations, p_blank,
          pw_no_comments, pw_no_annotations, pw_comments, pw_annotations, pw_blank =
      utils.compute_percentages(stats)

    local cells = {
      utils.format_value(stats.lines_without_comments, p_no_comments, config.percent_mode),
      utils.format_value(stats.comment_lines, p_comments, config.percent_mode),
      utils.format_value(stats.lines_without_annotations, p_no_annotations, config.percent_mode),
      utils.format_value(stats.annotation_lines, p_annotations, config.percent_mode),
      utils.format_value(stats.blank_lines, p_blank, config.percent_mode),
      utils.format_value(stats.words_without_comments, pw_no_comments, config.percent_mode),
      utils.format_value(stats.words_without_annotations, pw_no_annotations, config.percent_mode),
      utils.format_value(stats.words_in_comments, pw_comments, config.percent_mode),
      utils.format_value(stats.words_in_annotations, pw_annotations, config.percent_mode),
      utils.format_value(stats.words_in_blank, pw_blank, config.percent_mode),
    }

    local row_parts = { "| " .. fmt_cell(folder, 40) .. " | " .. fmt_cell(stats.file_count, 5) .. " |" }
    for _, c in ipairs(cells) do
      tbl_insert(row_parts, " " .. fmt_cell(c, config.col_width) .. " |")
    end
    M.output(tbl_concat(row_parts, ""), state)
  end

  M.output(line, state)
end

---Print total summary
---@param config LuaProjectFileStats.Config
---@param state LuaProjectFileStats.State
function M.print_total_summary(config, state)
  if not tbl_contains(config.fields_to_print, "summary") then
    return
  end

  local t = state.total_stats
  local p_no_comments, p_comments, p_no_annotations, p_annotations, p_blank,
        pw_no_comments, pw_no_annotations, pw_comments, pw_annotations, pw_blank =
    utils.compute_percentages(t)

  local line = rep("-", 42 + 10 * (config.col_width + 3))
  M.output("\n=== Total Summary ===", state)
  M.print_legend(state)
  M.output(line, state)

  local header_parts = { "| " .. fmt_cell("Files", 8) .. " |" }
  for _, h in ipairs(build_header_cols_names()) do
    tbl_insert(header_parts, " " .. fmt_cell(h, config.col_width) .. " |")
  end
  M.output(tbl_concat(header_parts, ""), state)
  M.output(line, state)

  local cells = {
    utils.format_value(t.lines_without_comments, p_no_comments, config.percent_mode),
    utils.format_value(t.comment_lines, p_comments, config.percent_mode),
    utils.format_value(t.lines_without_annotations, p_no_annotations, config.percent_mode),
    utils.format_value(t.annotation_lines, p_annotations, config.percent_mode),
    utils.format_value(t.blank_lines, p_blank, config.percent_mode),
    utils.format_value(t.words_without_comments, pw_no_comments, config.percent_mode),
    utils.format_value(t.words_without_annotations, pw_no_annotations, config.percent_mode),
    utils.format_value(t.words_in_comments, pw_comments, config.percent_mode),
    utils.format_value(t.words_in_annotations, pw_annotations, config.percent_mode),
    utils.format_value(t.words_in_blank, pw_blank, config.percent_mode),
  }

  local row_parts = { "| " .. fmt_cell(t.total_files, 8) .. " |" }
  for _, c in ipairs(cells) do
    tbl_insert(row_parts, " " .. fmt_cell(c, config.col_width) .. " |")
  end
  M.output(tbl_concat(row_parts, ""), state)
  M.output(line, state)
end

---Print top-N files by lines
---@param n integer
---@param state LuaProjectFileStats.State
function M.print_top_n_files_by_lines(n, state)
  local files = {}
  for _, folder in pairs(state.folder_summary) do
    for _, f in ipairs(folder.files) do
      tbl_insert(files, { rel = f.rel_file, stats = f.stats })
    end
  end

  tbl_sort(files, function(a, b)
    return (a.stats.total_lines or 0) > (b.stats.total_lines or 0)
  end)

  M.output(str_fmt("\n=== Top %d Files by Lines ===", n), state)
  local line = rep("-", 95)
  M.output(line, state)
  M.output(str_fmt("| %3s | %-60s | %9s | %9s |", "No", "File", "Lines", "Share"), state)
  M.output(line, state)

  local total = state.total_stats.total_lines or 0
  for i = 1, math.min(n, #files) do
    local item = files[i]
    local lines = item.stats.total_lines or 0
    local share = utils.percent(lines, total)
    M.output(str_fmt("| %3d | %-60s | %9d | %8.2f%% |", i, item.rel, lines, share), state)
  end
  M.output(line, state)
end

---Print top-N files by words
---@param n integer
---@param state LuaProjectFileStats.State
function M.print_top_n_files_by_words(n, state)
  local files = {}
  for _, folder in pairs(state.folder_summary) do
    for _, f in ipairs(folder.files) do
      tbl_insert(files, { rel = f.rel_file, stats = f.stats })
    end
  end

  tbl_sort(files, function(a, b)
    return (a.stats.total_words or 0) > (b.stats.total_words or 0)
  end)

  M.output(str_fmt("\n=== Top %d Files by Words ===", n), state)
  local line = rep("-", 95)
  M.output(line, state)
  M.output(str_fmt("| %3s | %-60s | %9s | %9s |", "No", "File", "Words", "Share"), state)
  M.output(line, state)

  local total = state.total_stats.total_words or 0
  for i = 1, math.min(n, #files) do
    local item = files[i]
    local words = item.stats.total_words or 0
    local share = utils.percent(words, total)
    M.output(str_fmt("| %3d | %-60s | %9d | %8.2f%% |", i, item.rel, words, share), state)
  end
  M.output(line, state)
end

---Print top-N folders by annotation ratio
---@param n integer
---@param state LuaProjectFileStats.State
function M.print_top_n_folders_by_annotation_ratio(n, state)
  local list = {}
  for folder, stats in pairs(state.folder_summary) do
    local r = utils.compute_ratios(stats)
    tbl_insert(list, {
      folder = folder,
      ratio = r.annotation_ratio,
      lines = stats.total_lines,
    })
  end

  tbl_sort(list, function(a, b)
    return a.ratio > b.ratio
  end)

  M.output(str_fmt("\n=== Top %d Folders by Annotation Ratio ===", n), state)
  M.output("(Type definition files excluded from this ranking)", state)
  local line = rep("-", 80)
  M.output(line, state)
  M.output(str_fmt("| %3s | %-40s | %8s | %8s |", "No", "Folder", "Anno%", "Lines"), state)
  M.output(line, state)

  for i = 1, math.min(n, #list) do
    local e = list[i]
    M.output(str_fmt("| %3d | %-40s | %7.2f | %8d |", i, e.folder, e.ratio * 100, e.lines), state)
  end

  M.output(line, state)
end

---Print ratio guidelines
---@param state LuaProjectFileStats.State
function M.print_ratio_guidelines(state)
  M.output([[

=== Optimal Ratio Guidelines (Heuristic) ===

Metric                     Typical Range    Interpretation
-------------------------- ---------------- ------------------------------------------------------------
Comment Ratio              15% – 30%        Healthy explanation density. Below 10% often under-documented.
Annotation Ratio           5% – 12%         Strong LuaLS/EmmyLua usage. Above 15% = API-heavy modules.
Documentation Ratio        20% – 40%        Combined comments + annotations for maintainability.
Code Ratio                 55% – 75%        Effective executable logic density.
Avg Lines per File         80 – 200         Modular structure indicator.
Annotation/Comment Ratio   0.20 – 0.50      Balance between semantic and technical documentation.

Note: Type definition files (/@types/, /types/, @types.lua, types.lua) are excluded from ratio calculations
      as they naturally have very high annotation ratios (70-90%) and would skew the results.
]], state)
end

return M
