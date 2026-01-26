---@module 'custom.function_index.core.indexer'
---@brief Core indexing logic using ripgrep
---@description
--- This module orchestrates the indexing process: building ripgrep
--- commands, executing them asynchronously, parsing results, and
--- coordinating with the cache module.

local notify = require("lib.notify").create("[custom.function_index.core.indexer]")

local M = {}

local patterns_mod = require("custom.function_index.core.patterns")
local parser_mod = require("custom.function_index.core.parser")
local cache_mod = require("custom.function_index.core.cache")

--- Build ripgrep command arguments for a specific language
---@param config table
---@param language string
---@param pattern string
---@return string[] # Command arguments
local function build_rg_command_for_language(config, language, pattern)
  local cmd = { "rg" }

  -- Output format
  cmd[#cmd + 1] = "--vimgrep"
  cmd[#cmd + 1] = "--no-heading"

  -- Use PCRE2 for complex patterns
  cmd[#cmd + 1] = "--pcre2"

  -- Type filtering (file extensions)
  local ext_map = patterns_mod.get_extensions({ [language] = true })
  for _, ext in ipairs(ext_map) do
    cmd[#cmd + 1] = "--glob"
    cmd[#cmd + 1] = "*." .. ext
  end

  -- Exclude patterns
  for _, excl_pattern in ipairs(config.indexing.exclude_patterns) do
    cmd[#cmd + 1] = "--glob"
    cmd[#cmd + 1] = "!" .. excl_pattern
  end

  -- Max file size
  if config.indexing.max_file_size_kb > 0 then
    cmd[#cmd + 1] = "--max-filesize"
    cmd[#cmd + 1] = tostring(config.indexing.max_file_size_kb) .. "K"
  end

  -- Follow symlinks
  if config.indexing.follow_symlinks then
    cmd[#cmd + 1] = "--follow"
  end

  -- Pattern
  cmd[#cmd + 1] = pattern

  -- Search current directory
  cmd[#cmd + 1] = "."

  return cmd
end

--- Execute ripgrep command synchronously
---@param cmd string[] # Command arguments
---@return string[] # Output lines
---@return integer # Exit code
local function execute_rg_sync(cmd)
  local output = vim.fn.systemlist(cmd)
  local exit_code = vim.v.shell_error
  return output, exit_code
end

--- Build index by running ripgrep and parsing output
---@param config table
---@return table[] # Parsed entries
---@return string[] # Errors encountered
---@return IndexerState # Indexing statistics
function M.build_index(config)
  local start_time = os.time()

  -- Check for ripgrep
  if vim.fn.executable("rg") ~= 1 then
    return {}, { "ripgrep (rg) is not installed or not in PATH" }, {
      entries = {},
      total_files = 0,
      total_functions = 0,
      errors = { "ripgrep not found" },
      started_at = start_time,
      finished_at = os.time(),
    }
  end

  -- Get enabled languages and patterns
  local enabled_langs = {}
  for lang, enabled in pairs(config.languages) do
    if enabled then
      enabled_langs[#enabled_langs + 1] = lang
    end
  end

  if #enabled_langs == 0 then
    return {}, { "No languages enabled" }, {
      entries = {},
      total_files = 0,
      total_functions = 0,
      errors = { "No languages enabled" },
      started_at = start_time,
      finished_at = os.time(),
    }
  end

  -- Collect all lines from all language searches
  local all_lines = {}
  local all_errors = {}

  -- Search per language for better reliability
  local patterns_list = patterns_mod.get_patterns(config.languages)
  local processed_patterns = {}

  for _, pat_entry in ipairs(patterns_list) do
    local key = pat_entry.language .. ":" .. pat_entry.pattern
    if not processed_patterns[key] then
      processed_patterns[key] = true

      local cmd = build_rg_command_for_language(config, pat_entry.language, pat_entry.pattern)

      notify.debug("Searching " .. pat_entry.language .. " files...")

      local lines, exit_code = execute_rg_sync(cmd)

      if exit_code == 0 then
        for _, line in ipairs(lines) do
          all_lines[#all_lines + 1] = line
        end
      elseif exit_code ~= 1 then
        -- Exit code 1 means no matches (not an error)
        all_errors[#all_errors + 1] = string.format(
          "%s search failed with exit code %d",
          pat_entry.language,
          exit_code
        )
      end
    end
  end

  notify.debug(string.format("ripgrep found %d lines total", #all_lines))

  -- Parse output
  local entries, parse_errors = parser_mod.parse_ripgrep_output(all_lines, config.languages)

  for _, err in ipairs(parse_errors) do
    all_errors[#all_errors + 1] = err
  end

  -- Calculate statistics
  local files = {}
  for _, entry in ipairs(entries) do
    files[entry.filename] = true
  end

  local file_count = 0
  for _ in pairs(files) do
    file_count = file_count + 1
  end

  local state = {
    entries = entries,
    total_files = file_count,
    total_functions = #entries,
    errors = all_errors,
    started_at = start_time,
    finished_at = os.time(),
  }

  return entries, all_errors, state
end

--- Get or build index (with caching)
---@param config table
---@param force_rebuild boolean|nil # Force rebuild even if cache valid
---@return table[] # Function entries
---@return string|nil # Error or cache status message
function M.get_index(config, force_rebuild)
  -- Try to load from cache
  if not force_rebuild then
    local cached_entries, cache_msg = cache_mod.load(config)
    if cached_entries then
      return cached_entries, "Loaded " .. #cached_entries .. " entries from cache"
    end

    -- Cache invalid/missing, build new index
    if cache_msg then
      notify.info("Cache invalid: " .. cache_msg .. ". Rebuilding index...")
    end
  end

  -- Build fresh index
  local entries, errors, state = M.build_index(config)

  -- Report errors if any
  if #errors > 0 then
    notify.warn(string.format( "Index built with %d errors (found %d functions in %d files)", #errors, state.total_functions, state.total_files ))
  end

  -- Save to cache
  if #entries > 0 then
    local ok, err = cache_mod.save(config, entries)
    if not ok then
      notify.warn("Failed to save cache: " .. tostring(err))
    end
  end

  local duration = state.finished_at - state.started_at
  local msg = string.format(
    "Indexed %d functions in %d files (%ds)",
    state.total_functions,
    state.total_files,
    duration
  )

  return entries, msg
end

--- Clear cache and rebuild index
---@param config table
---@return table[]
---@return string|nil # Status message
function M.rebuild_index(config)
  local ok, err = cache_mod.clear(config)
  if not ok then
    notify.warn("Failed to clear cache: " .. tostring(err))
  end

  return M.get_index(config, true)
end

return M
