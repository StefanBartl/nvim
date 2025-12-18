---@module 'autocmds.patches.validate'
---@brief Pre-flight validation and dry-run checks for patches.
---@description
--- Validates patch entries before application and detects already-applied patches.

local M = {}

local utils = require("autocmds.patches.utils")
local logger = require("autocmds.patches.logger")
local status = require("autocmds.patches.status")

local uv = vim.loop

--- Validate patch file syntax and accessibility
---@param entry PatchEntry
---@return ValidationResult
local function validate_patch_file(entry)
  -- Check file exists
  if not utils.file_exists(entry.patch) then
    return {
      valid = false,
      error = string.format("Patch file not found: %s", entry.patch),
    }
  end

  -- Check file is readable
  local content, err = utils.read_file(entry.patch)
  if not content then
    return {
      valid = false,
      error = string.format("Cannot read patch file: %s", err or "unknown"),
    }
  end

  -- Basic syntax check: must contain unified diff markers
  -- Support both standard Unix format and Windows absolute path format
  local has_diff_header = content:match("^diff ") ~= nil
  local has_unix_marker = content:match("\n%-%-%-") ~= nil or content:match("^%-%-%-") ~= nil
  local has_windows_marker = content:match("\n%-%-%-[%s]+[A-Za-z]:\\") ~= nil
    or content:match("^%-%-%-[%s]+[A-Za-z]:\\") ~= nil

  if not (has_diff_header or has_unix_marker or has_windows_marker) then
    return {
      valid = false,
      error = "Patch file does not appear to be a valid unified diff",
    }
  end

  return { valid = true }
end

--- Validate target file
---@param entry PatchEntry
---@return ValidationResult
local function validate_target_file(entry)
  if not utils.file_exists(entry.target) then
    return {
      valid = false,
      error = string.format("Target file not found: %s", entry.target),
    }
  end

  -- Check target is writable (approximate check)
  local stat = uv.fs_stat(entry.target)
  if not stat then
    return {
      valid = false,
      error = "Cannot access target file",
    }
  end

  return { valid = true }
end

--- Check if patch is already applied using reverse dry-run
---@param entry PatchEntry
---@param callback fun(result: ValidationResult)
---@return nil
local function check_already_applied_async(entry, callback)
  local strip = entry.strip or 0

  -- Build reverse dry-run command
  local cmd = {
    "patch",
    "--dry-run",
    "--reverse",
    "--batch",
    "--silent",
    "-p" .. strip,
    "-i",
    entry.patch,
    entry.target,
  }

  ---@type userdata|uv.uv_stream_t|nil
  local stdout = uv.new_pipe(false)
  ---@type userdata|uv.uv_stream_t|nil
  local stderr = uv.new_pipe(false)

  local stdout_data = {}
  local stderr_data = {}

  local handle
  uv.spawn("patch", {
    args = vim.list_slice(cmd, 2),
    stdio = { nil, stdout, stderr },
    env = {},
    cwd = "",
    uid = "",
    gid = "",
    verbatim = false,
    detached = false,
    hide = false,
  }, function(code, _)
    if stdout and not stdout:is_closing() then
      stdout:close()
    end
    if stderr and not stderr:is_closing() then
      stderr:close()
    end

    -- code == 0 means reverse would succeed = already applied
    local already_applied = (code == 0)

    callback({
      valid = true,
      already_applied = already_applied,
    })
  end)

  if not handle then
    callback({
      valid = false,
      error = "Failed to spawn patch process",
    })
    return
  end

  -- Read stdout/stderr (we discard them for dry-run)
  if stdout then
    stdout:read_start(function(_, data)
      if data then
        table.insert(stdout_data, data)
      end
    end)
  end

  if stderr then
    stderr:read_start(function(_, data)
      if data then
        table.insert(stderr_data, data)
      end
    end)
  end
end

--- Validate patch entry (synchronous checks only)
---@param entry PatchEntry
---@return ValidationResult
function M.validate_entry(entry)
  -- Type checks
  if type(entry) ~= "table" then
    return { valid = false, error = "Entry is not a table" }
  end

  if type(entry.key) ~= "string" or entry.key == "" then
    return { valid = false, error = "Entry key is missing or invalid" }
  end

  if type(entry.patch) ~= "string" or entry.patch == "" then
    return { valid = false, error = "Patch path is missing" }
  end

  if type(entry.target) ~= "string" or entry.target == "" then
    return { valid = false, error = "Target path is missing" }
  end

  -- Validate patch file
  local patch_result = validate_patch_file(entry)
  if not patch_result.valid then
    return patch_result
  end

  -- Validate target file
  local target_result = validate_target_file(entry)
  if not target_result.valid then
    return target_result
  end

  return { valid = true }
end

--- Full validation with async already-applied check
---@param entry PatchEntry
---@param callback fun(result: ValidationResult)
---@return nil
function M.validate_full(entry, callback)
  -- First do synchronous validation
  local sync_result = M.validate_entry(entry)
  if not sync_result.valid then
    callback(sync_result)
    return
  end

  -- Then check if already applied
  check_already_applied_async(entry, function(async_result)
    if not async_result.valid then
      callback(async_result)
      return
    end

    callback({
      valid = true,
      already_applied = async_result.already_applied,
    })
  end)
end

--- Validate entry and check status cache
---@param entry PatchEntry
---@return ValidationResult
function M.pre_check(entry)
  -- Basic validation
  local validation = M.validate_entry(entry)
  if not validation.valid then
    return validation
  end

  -- Check if disabled
  if entry.enabled == false then
    return {
      valid = true,
      already_applied = false, -- Will be marked as disabled, not applied
    }
  end

  -- Check status cache
  local status_entry = status.get(entry.key)
  if status_entry and status_entry.status == "applied" then
    -- Check if checksum matches
    local checksum = utils.compute_checksum(entry.patch)
    if checksum and checksum == status_entry.checksum then
      logger.debug("Patch already applied (checksum match)", {
        key = entry.key,
      })
      return {
        valid = true,
        already_applied = true,
      }
    end
  end

  return { valid = true, already_applied = false }
end

return M
