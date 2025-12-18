---@module 'autocmds.patches.preprocessor'
---@brief Preprocessor for normalizing diff files across platforms.
---@description
--- Handles platform-specific diff formats, particularly Windows absolute paths.
--- Simplifies diff headers for reliable patch application.

local M = {}

local utils = require("autocmds.patches.utils")
local logger = require("autocmds.patches.logger")

--- Detect if diff has Windows-style absolute paths in headers
---@param content string
---@return boolean
local function has_windows_paths(content)
  -- Check for Windows drive letter patterns like C:\, D:\
  return content:match("^%-%-%-[%s]+[A-Za-z]:\\") ~= nil
    or content:match("\n%-%-%-[%s]+[A-Za-z]:\\") ~= nil
end

--- Simplify diff headers to use just target filename
--- This makes patch application more reliable across platforms
---@param content string Original diff content
---@param target string Target file path
---@return string normalized_content
---@return boolean was_normalized
function M.normalize_diff(content, target)
  logger.debug("Normalizing diff headers", { target = target })

  -- Get just the filename from target
  local target_filename = target:match("([^/\\]+)$")
  if not target_filename then
    logger.warn("Could not extract filename from target", { target = target })
    return content, false
  end

  local lines = vim.split(content, "\n", { plain = true })
  local normalized_lines = {}
  local changed = false

  for _, line in ipairs(lines) do
    if line:match("^%-%-%-") then
      -- Old file header: replace with simple filename
      table.insert(normalized_lines, "--- " .. target_filename)
      changed = true
    elseif line:match("^%+%+%+") then
      -- New file header: replace with simple filename
      table.insert(normalized_lines, "+++ " .. target_filename)
      changed = true
    else
      -- Keep all other lines (including @@, +, -, and context lines)
      table.insert(normalized_lines, line)
    end
  end

  local normalized_content = table.concat(normalized_lines, "\n")

  if changed then
    logger.debug("Diff headers normalized to target filename", {
      target_filename = target_filename,
      original_had_paths = has_windows_paths(content),
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

  local normalized, was_normalized = M.normalize_diff(content, target)

  if not was_normalized then
    -- No normalization needed, return original path
    return patch_path, nil
  end

  -- Create temporary file
  local temp_dir = vim.fn.stdpath("cache") .. "/patches/temp"
  local ok, dir_err = utils.ensure_dir(temp_dir)
  if not ok then
    return nil, "Failed to create temp directory: " .. (dir_err or "unknown")
  end

  local temp_file = temp_dir .. "/" .. vim.fn.fnamemodify(patch_path, ":t")

  local write_ok, write_err = utils.write_file(temp_file, normalized)
  if not write_ok then
    return nil, "Failed to write temp patch: " .. (write_err or "unknown")
  end

  logger.debug("Created temporary normalized patch", {
    original = patch_path,
    temp = temp_file,
  })

  return temp_file, nil
end

--- Cleanup temporary patch files
---@return nil
function M.cleanup_temp()
  local temp_dir = vim.fn.stdpath("cache") .. "/patches/temp"

  -- Remove all files in temp directory
  local files = vim.fn.glob(temp_dir .. "/*", false, true)
  for _, file in ipairs(files) do
    pcall(vim.loop.fs_unlink, file)
  end
end

return M
