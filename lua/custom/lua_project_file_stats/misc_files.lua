---@module 'custom.lua_project_file_stats.misc_files'
---@brief Analysis of non-Lua files (Markdown, TXT, JSON)
---@description
--- Provides basic statistics for documentation and configuration files.
--- Focuses on file counts, line counts, and word counts without detailed parsing.

local utils = require("custom.lua_project_file_stats.utils")

local M = {}

---Check if a Lua file is a type definition file
---Type files are identified by:
---1. Path contains /@types/ or /types/
---2. OR filename is @types.lua or types.lua
---3. AND first line contains ---@meta
---4. AND second line @module contains '@types' or 'types'
---@param filepath string
---@return boolean
function M.is_type_file(filepath)
  if type(filepath) ~= "string" then
    return false
  end

  -- Normalize path separators
  local normalized = filepath:gsub("\\", "/")

  -- Check path-based criteria
  local path_match = normalized:match("/@types/")
    or normalized:match("/types/")
    or normalized:match("/@types%.lua$")
    or normalized:match("/types%.lua$")

  if not path_match then
    return false
  end

  -- Verify with file content
  local success, fh = pcall(io.open, filepath, "r")
  if not success or not fh then
    return false
  end

  local first_line = fh:read("*l")
  local second_line = fh:read("*l")
  fh:close()

  -- Check for @meta tag in first line
  if not first_line or not first_line:match("%-%-%-@meta") then
    return false
  end

  -- Check for @types or types in @module path
  if not second_line then
    return false
  end

  local has_types_in_module = second_line:match("%-%-%-@module")
    and (second_line:match("@types") or second_line:match("%.types"))

  return has_types_in_module ~= nil
end

local str_fmt = string.format
local tbl_insert = table.insert

---@class MiscFileStats
---@field file_count integer Number of files of this type
---@field total_lines integer Total lines across all files
---@field total_words integer Total words across all files
---@field files MiscFileInfo[] List of analyzed files

---@class MiscFileInfo
---@field rel_file string Relative path from cwd
---@field lines integer Line count
---@field words integer Word count

---@class MiscFilesState
---@field markdown MiscFileStats Statistics for Markdown files
---@field txt MiscFileStats Statistics for TXT/help files
---@field json MiscFileStats Statistics for JSON files

---Create empty misc file stats
---@return MiscFileStats
local function create_empty_misc_stats()
  return {
    file_count = 0,
    total_lines = 0,
    total_words = 0,
    files = {},
  }
end

---Analyze a single non-Lua file
---@param filepath string
---@return integer lines, integer words
local function analyze_misc_file(filepath)
  if type(filepath) ~= "string" then
    return 0, 0
  end

  local lines = 0
  local words = 0

  local success, fh = pcall(io.open, filepath, "r")
  if not success or not fh then
    return 0, 0
  end

  for line in fh:lines() do
    lines = lines + 1
    words = words + utils.count_words(line)
  end

  fh:close()
  return lines, words
end

---Get all files of specific type under directory
---@param dir string
---@param pattern string File extension pattern (e.g., "*.md")
---@return string[]|nil
local function get_files_by_pattern(dir, pattern)
  if type(dir) ~= "string" then
    return nil
  end

  local files = {}

  if utils.is_nvim then
    -- Use Neovim's fn.glob for better cross-platform support
    local search_pattern = dir .. "/**/" .. pattern
    local found = vim.fn.glob(search_pattern, false, true)

    for _, file in ipairs(found) do
      if not utils.should_ignore(file) then
        tbl_insert(files, file)
      end
    end
  else
    -- CLI mode: use system commands
    local ext = pattern:match("%.(%w+)$")
    if not ext then
      return nil
    end

    local cmd = 'dir "' .. dir .. '" /S /B /A:-D 2>nul'
    local success, p = pcall(io.popen, cmd)

    if not success or not p then
      return nil
    end

    for file in p:lines() do
      if file:match("%." .. ext .. "$") and not utils.should_ignore(file) then
        tbl_insert(files, file)
      end
    end

    p:close()
  end

  return files
end

---Scan directory for miscellaneous files
---@param root_dir string
---@param cwd string Current working directory for relative paths
---@return MiscFilesState
function M.scan_misc_files(root_dir, cwd)
  local state = {
    markdown = create_empty_misc_stats(),
    txt = create_empty_misc_stats(),
    json = create_empty_misc_stats(),
  }

  -- File type configurations
  local file_types = {
    { key = "markdown", pattern = "*.md" },
    { key = "txt", pattern = "*.txt" },
    { key = "json", pattern = "*.json" },
  }

  for _, ft in ipairs(file_types) do
    local files = get_files_by_pattern(root_dir, ft.pattern)
    if files and #files > 0 then
      for _, file in ipairs(files) do
        local lines, words = analyze_misc_file(file)
        if lines > 0 or words > 0 then
          local rel_file = utils.relative_path(file, cwd)
          local stats = state[ft.key]

          stats.file_count = stats.file_count + 1
          stats.total_lines = stats.total_lines + lines
          stats.total_words = stats.total_words + words

          tbl_insert(stats.files, {
            rel_file = rel_file,
            lines = lines,
            words = words,
          })
        end
      end
    end
  end

  return state
end

---Print miscellaneous files summary
---@param misc_state MiscFilesState
---@param state LuaProjectFileStats.State Main state for output buffer
function M.print_misc_summary(misc_state, state)
  local prints = require("custom.lua_project_file_stats.prints")
  local line = string.rep("-", 95)

  prints.output("\n=== Documentation & Config Files ===", state)
  prints.output(line, state)
  prints.output(str_fmt("| %-20s | %8s | %12s | %12s | %15s |",
    "Type", "Files", "Lines", "Words", "Avg Lines/File"), state)
  prints.output(line, state)

  local types = {
    { key = "markdown", label = "Markdown (*.md)" },
    { key = "txt", label = "Text/Help (*.txt)" },
    { key = "json", label = "JSON (*.json)" },
  }

  local total_files = 0
  local total_lines = 0
  local total_words = 0

  for _, t in ipairs(types) do
    local stats = misc_state[t.key]
    if stats.file_count > 0 then
      local avg_lines = stats.total_lines / stats.file_count
      prints.output(str_fmt("| %-20s | %8d | %12d | %12d | %15.1f |",
        t.label, stats.file_count, stats.total_lines, stats.total_words, avg_lines), state)

      total_files = total_files + stats.file_count
      total_lines = total_lines + stats.total_lines
      total_words = total_words + stats.total_words
    end
  end

  if total_files > 0 then
    prints.output(line, state)
    prints.output(str_fmt("| %-20s | %8d | %12d | %12d | %15.1f |",
      "Total", total_files, total_lines, total_words, total_lines / total_files), state)
  end

  prints.output(line, state)
end

---Print detailed list of miscellaneous files
---@param misc_state MiscFilesState
---@param state LuaProjectFileStats.State
function M.print_misc_files_detailed(misc_state, state)
  local prints = require("custom.lua_project_file_stats.prints")
  local line = string.rep("-", 95)

  local types = {
    { key = "markdown", label = "Markdown Files" },
    { key = "txt", label = "Text/Help Files" },
    { key = "json", label = "JSON Files" },
  }

  for _, t in ipairs(types) do
    local stats = misc_state[t.key]
    if stats.file_count > 0 then
      prints.output(str_fmt("\n=== %s ===", t.label), state)
      prints.output(line, state)
      prints.output(str_fmt("| %-60s | %12s | %12s |", "File", "Lines", "Words"), state)
      prints.output(line, state)

      for _, f in ipairs(stats.files) do
        prints.output(str_fmt("| %-60s | %12d | %12d |", f.rel_file, f.lines, f.words), state)
      end

      prints.output(line, state)
    end
  end
end

return M
