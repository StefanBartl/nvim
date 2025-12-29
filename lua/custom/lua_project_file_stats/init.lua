---@module 'custom.lua_project_file_stats'
---@brief Main entry point for Lua Project File Statistics
---@description
--- Analyzes Lua files for code, comments, annotations, and words.
--- Can be used from Neovim or CLI.

local utils = require("custom.lua_project_file_stats.utils")
local prints = require("custom.lua_project_file_stats.prints")

local M = {}

local str_fmt = string.format

---Create initial state
---@return LuaProjectFileStats.State
local function create_state()
  return {
    folder_summary = {},
    total_stats = utils.create_empty_stats(),
    global_averages = {
      comment_ratio = 0,
      annotation_ratio = 0,
      doc_ratio = 0,
      code_ratio = 0,
      avg_lines_per_file = 0,
      annotation_to_comment_ratio = 0,
    },
    output_buffer = {},
    cwd = utils.get_cwd(),
  }
end

---Calculate global averages from all folders
---@param state LuaProjectFileStats.State
local function calculate_global_averages(state)
  local folder_count = 0
  local sum_comment = 0
  local sum_annotation = 0
  local sum_doc = 0
  local sum_code = 0
  local sum_lines_per_file = 0
  local sum_anno_to_comment = 0

  for _, stats in pairs(state.folder_summary) do
    local r = utils.compute_ratios(stats)
    sum_comment = sum_comment + r.comment_ratio
    sum_annotation = sum_annotation + r.annotation_ratio
    sum_doc = sum_doc + r.doc_ratio
    sum_code = sum_code + r.code_ratio
    sum_lines_per_file = sum_lines_per_file + r.avg_lines_per_file
    sum_anno_to_comment = sum_anno_to_comment + r.annotation_to_comment_ratio
    folder_count = folder_count + 1
  end

  if folder_count > 0 then
    state.global_averages.comment_ratio = sum_comment / folder_count
    state.global_averages.annotation_ratio = sum_annotation / folder_count
    state.global_averages.doc_ratio = sum_doc / folder_count
    state.global_averages.code_ratio = sum_code / folder_count
    state.global_averages.avg_lines_per_file = sum_lines_per_file / folder_count
    state.global_averages.annotation_to_comment_ratio = sum_anno_to_comment / folder_count
  end
end

---Scan directory and aggregate statistics
---@param root_dir string
---@param state LuaProjectFileStats.State
---@return boolean success
local function scan_dir(root_dir, state)
  local files = utils.get_lua_files(root_dir)
  if not files or #files == 0 then
    return false
  end

  state.folder_summary = {}
  state.total_stats = utils.create_empty_stats()
  state.total_stats.total_files = 0

  for _, file in ipairs(files) do
    local stats = utils.analyze_file(file)
    if stats then
      local rel_file = utils.relative_path(file, state.cwd)
      local folder = rel_file:match("(.+)/") or "."

      if not state.folder_summary[folder] then
        state.folder_summary[folder] = utils.create_empty_stats()
        state.folder_summary[folder].file_count = 0
        state.folder_summary[folder].files = {}
      end

      local f = state.folder_summary[folder]
      for k, v in pairs(stats) do
        f[k] = (f[k] or 0) + v
      end
      f.file_count = f.file_count + 1
      table.insert(f.files, { rel_file = rel_file, stats = stats })

      for k, v in pairs(stats) do
        state.total_stats[k] = (state.total_stats[k] or 0) + v
      end
      state.total_stats.total_files = state.total_stats.total_files + 1
    end
  end

  calculate_global_averages(state)
  return true
end

---Run analysis with given config
---@param config LuaProjectFileStats.Config
function M.analyze(config)
  local state = create_state()

  -- Handle single file mode
  if config.single_file_path then
    local stats = utils.analyze_file(config.single_file_path)
    if stats then
      prints.output("\n=== Single File Statistics ===", state)
      prints.output(str_fmt("File: %s", utils.relative_path(config.single_file_path, state.cwd)), state)
      prints.output(str_fmt(
        "Lines: %d (Code: %d, Comments: %d, Annotations: %d, Blank: %d)",
        stats.total_lines,
        stats.lines_without_comments,
        stats.comment_lines,
        stats.annotation_lines,
        stats.blank_lines
      ), state)
      prints.output(str_fmt(
        "Words: %d (Code: %d, Comments: %d, Annotations: %d)",
        stats.total_words,
        stats.words_without_comments,
        stats.words_in_comments,
        stats.words_in_annotations
      ), state)
    else
      prints.output("Error: Could not analyze file: " .. config.single_file_path, state)
    end
    return
  end

  -- Directory scan
  local success = scan_dir(config.root_dir, state)
  if not success then
    prints.output("Error: Could not scan directory: " .. config.root_dir, state)
    return
  end

  prints.output("\n=== Lua File Statistics Report ===", state)
  prints.output(str_fmt("Root: %s", config.root_dir), state)
  prints.output(str_fmt("Files analyzed: %d", state.total_stats.total_files), state)
  prints.output(str_fmt("Total lines: %d\n", state.total_stats.total_lines), state)

  -- Check top-only mode
  local any_top_only = config.only_top_files_lines or config.only_top_files_words

  if any_top_only then
    if config.only_top_files_lines then
      prints.print_top_n_files_by_lines(config.top_n, state)
    end
    if config.only_top_files_words then
      prints.print_top_n_files_by_words(config.top_n, state)
    end
  else
    -- Normal output
    if config.reverse_order then
      prints.print_total_summary(config, state)

      if config.show_ratios then
        prints.print_folder_ratios_ascii(config.show_deviations, state)
        prints.print_top_n_folders_by_annotation_ratio(config.top_n, state)
        prints.print_ratio_guidelines(state)
      end

      prints.print_folder_summary_ascii(config, state)
      prints.print_file_stats_ascii(config, state)
    else
      prints.print_file_stats_ascii(config, state)
      prints.print_folder_summary_ascii(config, state)

      if config.show_ratios then
        prints.print_folder_ratios_ascii(config.show_deviations, state)
        prints.print_top_n_folders_by_annotation_ratio(config.top_n, state)
        prints.print_ratio_guidelines(state)
      end

      prints.print_total_summary(config, state)
    end

    -- Top-N lists
    if config.top_n > 0 then
      prints.print_top_n_files_by_lines(config.top_n, state)
      prints.print_top_n_files_by_words(config.top_n, state)
    end

    -- Final text summary
    prints.output("\n=== Text Summary ===", state)
    prints.output(str_fmt("Analyzed files: %d", state.total_stats.total_files), state)
    prints.output(str_fmt(
      "Lines: Total=%d, Code=%d, Comments=%d, Annotations=%d, Blank=%d",
      state.total_stats.total_lines,
      state.total_stats.lines_without_comments,
      state.total_stats.comment_lines,
      state.total_stats.annotation_lines,
      state.total_stats.blank_lines
    ), state)
    prints.output(str_fmt(
      "Words: Total=%d, Code=%d, Comments=%d, Annotations=%d",
      state.total_stats.total_words,
      state.total_stats.words_without_comments,
      state.total_stats.words_in_comments,
      state.total_stats.words_in_annotations
    ), state)
  end

  -- Write output file if requested
  if config.output_file then
    local ok, err = prints.write_output_file(config.output_file, state)
    if ok then
      print(str_fmt("\n✓ Output written to: %s", config.output_file))
    else
      print(str_fmt("\n✗ Error writing output: %s", err or "unknown"))
    end
  end
end

---Setup Neovim integration
function M.setup()
  if not utils.is_nvim then
    error("setup() can only be called from Neovim")
  end

  local usercommands = require("custom.lua_project_file_stats.usercommands")
  usercommands.setup()
end

-- CLI mode detection and execution
if not utils.is_nvim and arg then
  -- Parse CLI arguments
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
    async = false,
  }

  for _, a in ipairs(arg) do
    if a == "--reverse" then
      config.reverse_order = true
    elseif a == "--percent-only" then
      config.percent_mode = "percent"
    elseif a == "--numbers-only" then
      config.percent_mode = "numbers"
    elseif a == "--ratios" then
      config.show_ratios = true
    elseif a == "--deviations" then
      config.show_deviations = true
    elseif a:match("^--fields=") then
      local val = a:sub(10)
      config.fields_to_print = {}
      for f in val:gmatch("([^,]+)") do
        table.insert(config.fields_to_print, f)
      end
    elseif a:match("^--file=") then
      config.single_file_path = a:sub(9)
    elseif a:match("^--colwidth=") then
      config.col_width = tonumber(a:sub(12)) or config.col_width
    elseif a:match("^--topn=") then
      config.top_n = tonumber(a:sub(8)) or config.top_n
    elseif a == "--top-files-lines-only" then
      config.only_top_files_lines = true
    elseif a == "--top-files-words-only" then
      config.only_top_files_words = true
    elseif a:match("^%-o") or a:match("^--output=") then
      if a:match("^%-o") and #a > 2 then
        config.output_file = a:sub(3)
      elseif a:match("^--output=") then
        config.output_file = a:sub(11)
      end
    elseif not a:match("^%-") then
      config.root_dir = a
    end
  end

  -- Execute with error handling
  local success, err = pcall(M.analyze, config)
  if not success then
    print("Fatal error: " .. tostring(err))
    os.exit(1)
  end
end

return M
