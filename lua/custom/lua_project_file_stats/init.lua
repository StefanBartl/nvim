---@module 'custom.lua_project_file_stats'
---@brief Main entry point for Lua Project File Statistics
---@description
--- Analyzes Lua files and other project documentation for code quality metrics.
--- Can be used from Neovim or CLI with flexible configuration.

-- =============================================================================
-- DEFAULT CONFIGURATION
-- =============================================================================
-- Control what gets analyzed and displayed by default.
-- These settings apply when running without explicit flags.
-- Modify this table to change default behavior without touching core logic.

---@type LuaProjectFileStats.DefaultConfig
local DEFAULT_CONFIG = {
  -- Analysis scope
  lua_files = true, -- Analyze Lua source files
  misc_files = true, -- Analyze Markdown, TXT, JSON files

  -- Output sections (Lua files)
  show_file_tables = true, -- Detailed file-level statistics
  show_folder_tables = true, -- Folder-level aggregates
  show_total_summary = true, -- Total summary table

  -- Advanced analysis
  show_ratios = true, -- Ratio analysis (comment%, annotation%, etc.)
  show_deviations = true, -- Deviations from global averages
  show_top_lists = true, -- Top-N lists (largest files/folders)

  -- Non-Lua files
  show_misc_detailed = true, -- Detailed list of misc files (vs. summary only)

  -- Display settings
  percent_mode = "both", -- "both" | "percent" | "numbers"
  reverse_order = true, -- Show summary first (vs. files first)
    top_n = 50, -- Number of items in top-N lists

  -- Filtering
  exclude_type_files_from_ratios = true, -- Exclude @types files from ratio analysis
}

-- =============================================================================
-- MODULE INITIALIZATION
-- =============================================================================

local utils = require("custom.lua_project_file_stats.utils")
local prints = require("custom.lua_project_file_stats.prints")
local misc_files = require("custom.lua_project_file_stats.misc_files")

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
    misc_files = nil,
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

---Scan directory and aggregate Lua file statistics
---@param root_dir string
---@param state LuaProjectFileStats.State
---@param exclude_type_files boolean|nil Exclude type definition files from ratio calculations
---@return boolean success
local function scan_lua_files(root_dir, state, exclude_type_files)
  local files = utils.get_lua_files(root_dir)
  if not files or #files == 0 then
    return false
  end

  state.folder_summary = {}
  state.total_stats = utils.create_empty_stats()
  state.total_stats.total_files = 0

  -- Load misc_files for type checking
  local misc_check = require("custom.lua_project_file_stats.misc_files")

  for _, file in ipairs(files) do
    -- Skip type files if requested
    if exclude_type_files and misc_check.is_type_file(file) then
      goto continue
    end

    local stats = utils.analyze_file(file)
    if stats then
      local rel_file = utils.relative_path(file, state.cwd)
      local folder = rel_file:match("(.+)/") or "."

      if not state.folder_summary[folder] then
        state.folder_summary[folder] = utils.create_empty_folder_stats()
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

    ::continue::
  end

  calculate_global_averages(state)
  return true
end

---Apply default configuration to runtime config
---@param config LuaProjectFileStats.Config
local function apply_defaults(config)
  -- Only apply defaults if flags haven't explicitly overridden them
  if not config.analyze_lua and not config.analyze_misc then
    config.analyze_lua = DEFAULT_CONFIG.lua_files
    config.analyze_misc = DEFAULT_CONFIG.misc_files
  end

  -- Construct fields_to_print from defaults if not explicitly set
  if #config.fields_to_print == 0 then
    if DEFAULT_CONFIG.show_file_tables then
      table.insert(config.fields_to_print, "files")
    end
    if DEFAULT_CONFIG.show_folder_tables then
      table.insert(config.fields_to_print, "folders")
    end
    if DEFAULT_CONFIG.show_total_summary then
      table.insert(config.fields_to_print, "summary")
    end
  end

  -- Apply other defaults if not overridden
  if config.show_ratios == nil then
    config.show_ratios = DEFAULT_CONFIG.show_ratios
  end
  if config.show_deviations == nil then
    config.show_deviations = DEFAULT_CONFIG.show_deviations
  end
  if config.show_misc_detailed == nil then
    config.show_misc_detailed = DEFAULT_CONFIG.show_misc_detailed
  end
end

---Run analysis with given config
---@param config LuaProjectFileStats.Config
function M.analyze(config)
  apply_defaults(config)

  local state = create_state()

  -- Handle single file mode
  if config.single_file_path then
    local stats = utils.analyze_file(config.single_file_path)
    if stats then
      prints.output("\n=== Single File Statistics ===", state)
      prints.output(str_fmt("File: %s", utils.relative_path(config.single_file_path, state.cwd)), state)
      prints.output(
        str_fmt(
          "Lines: %d (Code: %d, Comments: %d, Annotations: %d, Blank: %d)",
          stats.total_lines,
          stats.lines_without_comments,
          stats.comment_lines,
          stats.annotation_lines,
          stats.blank_lines
        ),
        state
      )
      prints.output(
        str_fmt(
          "Words: %d (Code: %d, Comments: %d, Annotations: %d)",
          stats.total_words,
          stats.words_without_comments,
          stats.words_in_comments,
          stats.words_in_annotations
        ),
        state
      )
    else
      prints.output("Error: Could not analyze file: " .. config.single_file_path, state)
    end
    return
  end

  -- Directory scan for Lua files
  local lua_success = false
  if config.analyze_lua then
    -- Use exclude_type_files when ratio analysis is enabled
    local exclude_types = config.show_ratios and DEFAULT_CONFIG.exclude_type_files_from_ratios
    lua_success = scan_lua_files(config.root_dir, state, exclude_types)
    if not lua_success then
      prints.output("Warning: No Lua files found in: " .. config.root_dir, state)
    end
  end

  -- Directory scan for miscellaneous files
  if config.analyze_misc then
    state.misc_files = misc_files.scan_misc_files(config.root_dir, state.cwd)
  end

  -- Print header
  prints.output("\n=== Project File Statistics Report ===", state)
  prints.output(str_fmt("Root: %s", config.root_dir), state)

  -- Check top-only mode
  local any_top_only = config.only_top_files_lines or config.only_top_files_words

  if any_top_only then
    -- Top-only mode: just print requested top-N lists
    if config.only_top_files_lines and lua_success then
      prints.print_top_n_files_by_lines(config.top_n, state)
    end
    if config.only_top_files_words and lua_success then
      prints.print_top_n_files_by_words(config.top_n, state)
    end
  else
    -- Normal output
    if lua_success then
      prints.output(str_fmt("Lua files analyzed: %d", state.total_stats.total_files), state)
      prints.output(str_fmt("Total Lua lines: %d\n", state.total_stats.total_lines), state)

      if config.reverse_order then
        -- Summary first
        prints.print_total_summary(config, state)
        if config.show_ratios then
          prints.print_folder_ratios_ascii(config.show_deviations, state)
          prints.print_top_n_folders_by_annotation_ratio(config.top_n, state)
          prints.print_ratio_guidelines(state)
        end
        prints.print_folder_summary_ascii(config, state)
        prints.print_file_stats_ascii(config, state)
      else
        -- Files first
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
      if DEFAULT_CONFIG.show_top_lists and config.top_n > 0 then
        prints.print_top_n_files_by_lines(config.top_n, state)
        prints.print_top_n_files_by_words(config.top_n, state)
      end

      -- Text summary
      prints.output("\n=== Lua Files Summary ===", state)
      prints.output(str_fmt("Files: %d", state.total_stats.total_files), state)
      prints.output(
        str_fmt(
          "Lines: Total=%d, Code=%d, Comments=%d, Annotations=%d, Blank=%d",
          state.total_stats.total_lines,
          state.total_stats.lines_without_comments,
          state.total_stats.comment_lines,
          state.total_stats.annotation_lines,
          state.total_stats.blank_lines
        ),
        state
      )
      prints.output(
        str_fmt(
          "Words: Total=%d, Code=%d, Comments=%d, Annotations=%d",
          state.total_stats.total_words,
          state.total_stats.words_without_comments,
          state.total_stats.words_in_comments,
          state.total_stats.words_in_annotations
        ),
        state
      )
    end

    -- Print miscellaneous files
    if config.analyze_misc and state.misc_files then
      misc_files.print_misc_summary(state.misc_files, state)
      if config.show_misc_detailed then
        misc_files.print_misc_files_detailed(state.misc_files, state)
      end
    end
  end

  -- Write output file if requested or default
  local output_file = config.output_file
  if not output_file or output_file == "" then
    -- Fallback: Neovim standard config path oder temporärer Pfad
    if utils.is_nvim then
      output_file = vim.fn.stdpath("config") .. "/luaFileStats.md"
    else
      local tmpdir = os.getenv("TMP") or os.getenv("TEMP") or "."
      output_file = tmpdir .. "/luaFileStats.md"
    end
  end

  local ok, err = prints.write_output_file(output_file, state)
  if ok then
    print(str_fmt("\n✓ Output written to: %s", output_file))
  else
    print(str_fmt("\n✗ Error writing output: %s", err or "unknown"))
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

-- =============================================================================
-- CLI MODE
-- =============================================================================

if not utils.is_nvim and arg then
  -- Parse CLI arguments
  local config = {
    root_dir = ".",
    reverse_order = false,
    percent_mode = DEFAULT_CONFIG.percent_mode,
    fields_to_print = {},
    single_file_path = nil,
    col_width = 7,
    top_n = DEFAULT_CONFIG.top_n,
    only_top_files_lines = false,
    only_top_files_words = false,
    show_ratios = nil,
    show_deviations = nil,
    output_file = nil,
    interactive = false,
    async = false,
    analyze_lua = nil,
    analyze_misc = nil,
    show_misc_detailed = nil,
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
    elseif a == "--lua-only" then
      config.analyze_lua = true
      config.analyze_misc = false
    elseif a == "--misc-only" then
      config.analyze_lua = false
      config.analyze_misc = true
    elseif a == "--no-misc" then
      config.analyze_misc = false
    elseif a == "--misc-detailed" then
      config.show_misc_detailed = true
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
