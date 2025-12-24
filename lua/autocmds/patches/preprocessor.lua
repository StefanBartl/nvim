---@module 'autocmds.patches.preprocessor'
---@brief Preprocessor for normalizing diff files across platforms.

local M = {}

local utils = require("autocmds.patches.utils")
local logger = require("autocmds.patches.logger")

--- Detect if diff has Windows-style absolute paths in headers
---@param content string
---@return boolean
local function has_windows_paths(content)
  return content:match("^%-%-%-[%s]+[A-Za-z]:\\") ~= nil or content:match("\n%-%-%-[%s]+[A-Za-z]:\\") ~= nil
end

--- Aggressively normalize line endings and whitespace
---@param content string Content with potentially mixed line endings
---@return string normalized_content Content with Unix line endings only
local function normalize_line_endings(content)
  -- Step 1: Replace all CRLF with LF
  content = content:gsub("\r\n", "\n")

  -- Step 2: Replace remaining CR with LF
  content = content:gsub("\r", "\n")

  -- Step 3: Remove trailing whitespace from each line
  local lines = {}
  for line in content:gmatch("([^\n]*)\n?") do
    -- only remove CR, never trim spaces
    line = line:gsub("\r$", "")
    table.insert(lines, line)
  end

  -- Step 4: Ensure single trailing newline
  local normalized = table.concat(lines, "\n")

  -- Remove multiple trailing newlines, add exactly one
  normalized = normalized:gsub("\n+$", "") .. "\n"

  return normalized
end

--- Validate patch structure after normalization
---@param content string Normalized diff content
---@return boolean valid
---@return string? error
local function validate_patch_structure(content)
  local lines = vim.split(content, "\n", { plain = true })

  -- Check for required diff markers
  local has_header = false
  local has_hunk = false

  for i, line in ipairs(lines) do
    -- Check for diff/--- headers
    if line:match("^%-%-%-") or line:match("^%+%+%+") or line:match("^diff ") then
      has_header = true
    end

    -- Check for hunk headers
    if line:match("^@@") then
      has_hunk = true

      -- Validate hunk header format
      if not line:match("^@@ %-\\d+(,\\d+)? %+\\d+(,\\d+)? @@") then
        return false, string.format("Malformed hunk header at line %d: '%s'", i, line)
      end
    end

    -- maybe wrong
    -- -- Check for invalid empty context after hunk header
    -- if i > 1 and lines[i - 1]:match("^@@") and line == "" then
    --   return false, string.format("Empty line immediately after hunk header at line %d", i)
    -- end
  end

  if not has_header then
    return false, "No diff header found (---/+++/diff)"
  end

  if not has_hunk then
    return false, "No hunk header found (@@)"
  end

  return true
end

--- Simplify diff headers to use just target filename
---@param content string Original diff content
---@param target string Target file path
---@return string normalized_content
---@return boolean was_normalized
function M.normalize_diff(content, target)
  -- First normalize line endings aggressively
  local original_size = #content
  content = normalize_line_endings(content)

  logger.debug("Line endings normalized", {
    original_size = original_size,
    normalized_size = #content,
    reduction = original_size - #content,
  })

  if not has_windows_paths(content) then
    -- Validate even if no Windows paths
    local valid, err = validate_patch_structure(content)
    if not valid then
      logger.warn("Patch validation failed", { error = err })
    end
    return content, false
  end

  logger.debug("Normalizing diff headers", {
    target = target,
    original_size = #content,
  })

  local target_filename = target:match("([^/\\]+)$")
  if not target_filename then
    logger.warn("Could not extract filename from target", { target = target })
    return content, false
  end

  -- Split on normalized newlines
  local lines = vim.split(content, "\n", { plain = true, trimempty = false })
  local normalized_lines = {}
  local changed = false

  for _, line in ipairs(lines) do
    if line:match("^%-%-%-") then
      table.insert(normalized_lines, "--- " .. target_filename)
      changed = true
    elseif line:match("^%+%+%+") then
      table.insert(normalized_lines, "+++ " .. target_filename)
      changed = true
    else
      -- Keep line as-is (already trimmed)
      table.insert(normalized_lines, line)
    end
  end

  local normalized_content = table.concat(normalized_lines, "\n")

  -- Ensure single trailing newline
  if not normalized_content:match("\n$") then
    normalized_content = normalized_content .. "\n"
  end

  if changed then
    -- Validate after normalization
    local valid, err = validate_patch_structure(normalized_content)
    if not valid then
      logger.error("Normalized patch is invalid", {
        target_filename = target_filename,
        error = err,
      })
      return content, false -- Return original if normalization broke it
    end

    logger.debug("Diff normalized successfully", {
      target_filename = target_filename,
      lines_processed = #lines,
      output_size = #normalized_content,
    })
  end

  return normalized_content, changed
end

--- Create a temporary normalized patch file
---@param patch_path string Original patch file path
---@param target string Target file path
---@return string|nil temp_path Temporary file path
---@return string|nil error
function M.create_temp_patch(patch_path, target)
  local content, err = utils.read_file(patch_path)
  if not content then
    return nil, "Failed to read patch: " .. (err or "unknown")
  end

  -- Log original characteristics
  local has_crlf = content:match("\r\n") ~= nil
  local has_cr_only = content:match("\r") ~= nil and not has_crlf

  logger.debug("Preprocessing patch file", {
    path = patch_path,
    size = #content,
    has_crlf = has_crlf,
    has_cr_only = has_cr_only,
  })

  local normalized, was_normalized = M.normalize_diff(content, target)

  if not was_normalized then
    return patch_path, nil
  end

  -- Create temporary directory
  local temp_dir = vim.fn.stdpath("cache") .. "/patches/temp"
  local ok, dir_err = utils.ensure_dir(temp_dir)
  if not ok then
    return nil, "Failed to create temp directory: " .. (dir_err or "unknown")
  end

  local temp_file = temp_dir .. "/" .. vim.fn.fnamemodify(patch_path, ":t")

  -- Write with explicit Unix line endings
  local write_ok, write_err = utils.write_file(temp_file, normalized)
  if not write_ok then
    return nil, "Failed to write temp patch: " .. (write_err or "unknown")
  end

  logger.debug("Normalized patch written", {
    original = patch_path,
    temp = temp_file,
    original_size = #content,
    normalized_size = #normalized,
  })

  return temp_file, nil
end

--- Cleanup temporary patch files
---@return nil
function M.cleanup_temp()
  local temp_dir = vim.fn.stdpath("cache") .. "/patches/temp"
  local files = vim.fn.glob(temp_dir .. "/*", false, true)
  for _, file in ipairs(files) do
    pcall(vim.loop.fs_unlink, file)
  end
end

return M
