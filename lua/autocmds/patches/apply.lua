---@module 'autocmds.patches.apply'
---@brief Asynchronous patch application engine.
---@description
--- Core module for applying patches non-blocking via vim.loop.spawn().
--- Handles concurrency, timeouts, and result aggregation.

local M = {}

local utils = require("autocmds.patches.utils")
local logger = require("autocmds.patches.logger")
local validate = require("autocmds.patches.validate")
local status = require("autocmds.patches.status")
local preprocessor = require("autocmds.patches.preprocessor")

local uv = vim.loop

-- Configuration
local DEFAULT_TIMEOUT_MS = 30000
local DEFAULT_CONCURRENCY = 3

--- Apply a single patch asynchronously
---@param entry PatchEntry
---@param callback fun(result: PatchResult)
---@return nil
local function apply_patch_async(entry, callback)
  local start_time = uv.now()
  local strip = entry.strip or 0
  local repo = entry.repo or utils.detect_repo(entry.target)

  -- Pre-check validation and status
  local pre_check = validate.pre_check(entry)

  if not pre_check.valid then
    callback({
      key = entry.key,
      repo = repo,
      enabled = entry.enabled ~= false,
      success = false,
      status = "failed",
      message = pre_check.error,
      timestamp = utils.get_timestamp(),
      duration_ms = nil,
    })
    return
  end

  if entry.enabled == false then
    callback({
      key = entry.key,
      repo = repo,
      enabled = false,
      success = false,
      status = "disabled",
      message = "Patch is disabled",
      timestamp = utils.get_timestamp(),
      duration_ms = nil,
    })
    return
  end

  if pre_check.already_applied then
    callback({
      key = entry.key,
      repo = repo,
      enabled = true,
      success = true,
      status = "already_applied",
      message = "Patch already applied (skipped)",
      timestamp = utils.get_timestamp(),
      duration_ms = uv.now() - start_time,
    })
    return
  end

  -- Full validation with already-applied check
  validate.validate_full(entry, function(validation)
    if not validation.valid then
      callback({
        key = entry.key,
        repo = repo,
        enabled = true,
        success = false,
        status = "failed",
        message = validation.error or "Validation failed",
        timestamp = utils.get_timestamp(),
        duration_ms = uv.now() - start_time,
      })
      return
    end

    if validation.already_applied then
      callback({
        key = entry.key,
        repo = repo,
        enabled = true,
        success = true,
        status = "already_applied",
        message = "Patch already applied (detected via dry-run)",
        timestamp = utils.get_timestamp(),
        duration_ms = uv.now() - start_time,
      })
      return
    end

    -- Build patch command
    -- First, try to normalize the patch file if needed (especially for Windows)
    local patch_file_to_use = entry.patch
    local temp_patch_created = false
    local strip_to_use = strip

    local temp_patch, prep_err = preprocessor.create_temp_patch(entry.patch, entry.target)
    if temp_patch then
      patch_file_to_use = temp_patch
      temp_patch_created = temp_patch ~= entry.patch

      if temp_patch_created then
        -- When we normalize, we use simple filenames, so strip=0
        strip_to_use = 0
        logger.debug("Using normalized patch file", {
          key = entry.key,
          original = entry.patch,
          normalized = temp_patch,
          strip = strip_to_use,
        })
      end
    elseif prep_err then
      logger.warn("Failed to normalize patch, using original", {
        key = entry.key,
        error = prep_err,
      })
    end

    local cmd = {
      "patch",
      "--forward",
      "--batch",
      "-p" .. strip_to_use,
      "-i", patch_file_to_use,
      entry.target,
    }

    logger.debug("Applying patch", {
      key = entry.key,
      repo = repo,
      command = table.concat(cmd, " "),
    })


---@class uv.pipe_t: userdata
---@field read_start fun(self: uv.pipe_t, callback: fun(err:any, data:string?))
---@field close fun(self: uv.pipe_t)
---@field is_closing fun(self: uv.pipe_t): boolean


    local stdout = uv.new_pipe(false)
    ---@cast stdout userdata|uv.uv_stream_t
    local stderr = uv.new_pipe(false)
    ---@cast stderr userdata|uv.uv_stream_t



    local stdout_chunks = {}
    local stderr_chunks = {}

    ---@type userdata|uv.uv_timer_t|nil
    local timeout_timer = uv.new_timer()
        ---@cast timeout_timer uv.uv_timer_t
    local timed_out = false
    local process_handle = nil

    -- Start timeout timer
    if timeout_timer then
      timeout_timer:start(DEFAULT_TIMEOUT_MS, 0, function()
        timed_out = true
        if process_handle and not process_handle:is_closing() then
          process_handle:kill("sigterm")
        end
      end)
    end

    -- Spawn patch process
    process_handle = uv.spawn("patch", {
      args = vim.list_slice(cmd, 2),
      stdio = { nil, stdout, stderr },
    }, function(code, _)
      -- Stop timeout timer
      if timeout_timer and not timeout_timer:is_closing() then
        timeout_timer:stop()
        timeout_timer:close()
      end

      -- Close pipes
      if stdout and not stdout:is_closing() then
        stdout:close()
      end
      if stderr and not stderr:is_closing() then
        stderr:close()
      end

      local duration = uv.now() - start_time

      if timed_out then
        logger.error("Patch timed out", { key = entry.key, repo = repo })
        callback({
          key = entry.key,
          repo = repo,
          enabled = true,
          success = false,
          status = "failed",
          message = string.format("Timeout after %dms", DEFAULT_TIMEOUT_MS),
          timestamp = utils.get_timestamp(),
          duration_ms = duration,
        })
        return
      end

      -- Check exit code
      if code ~= 0 then
        local stderr_output = table.concat(stderr_chunks)
        logger.error("Patch failed", {
          key = entry.key,
          repo = repo,
          exit_code = code,
          stderr = stderr_output,
        })
        callback({
          key = entry.key,
          repo = repo,
          enabled = true,
          success = false,
          status = "failed",
          message = stderr_output:gsub("%s+$", ""),
          timestamp = utils.get_timestamp(),
          duration_ms = duration,
        })
        return
      end

      -- Success
      logger.info("Patch applied", { key = entry.key, repo = repo })

      -- Update checksum in status
      local checksum = utils.compute_checksum(entry.patch)
      if checksum then
        status.update_checksum(entry.key, checksum)
      end

      callback({
        key = entry.key,
        repo = repo,
        enabled = true,
        success = true,
        status = "applied",
        message = "Applied successfully",
        timestamp = utils.get_timestamp(),
        duration_ms = duration,
      })
    end)

    if not process_handle then
      if timeout_timer and not timeout_timer:is_closing() then
        timeout_timer:stop()
        timeout_timer:close()
      end

      logger.error("Failed to spawn patch process", { key = entry.key })
      callback({
        key = entry.key,
        repo = repo,
        enabled = true,
        success = false,
        status = "failed",
        message = "Failed to spawn patch process",
        timestamp = utils.get_timestamp(),
        duration_ms = uv.now() - start_time,
      })
      return
    end

    -- Read stdout
    if stdout then
      stdout:read_start(function(_, data)
        if data then
          table.insert(stdout_chunks, data)
        end
      end)
    end

    -- Read stderr
    if stderr then
      stderr:read_start(function(_, data)
        if data then
          table.insert(stderr_chunks, data)
        end
      end)
    end
  end)
end

--- Apply multiple patches with concurrency limit
---@param entries PatchEntry[]
---@param callback fun(results: PatchResult[])
---@return nil
function M.apply_batch(entries, callback)
  local total = #entries
  local completed = 0
  local results = {}
  local active = 0
  local queue_index = 1

  if total == 0 then
    callback({})
    return
  end

  logger.info("Starting batch patch application", {
    total = total,
    concurrency = DEFAULT_CONCURRENCY,
  })

  local function process_next()
    if queue_index > total and active == 0 then
      -- All done
      logger.info("Batch complete", {
        total = total,
        succeeded = vim.tbl_count(vim.tbl_filter(function(r)
          return r.success
        end, results)),
        failed = vim.tbl_count(vim.tbl_filter(function(r)
          return not r.success and r.status ~= "disabled"
        end, results)),
      })
      callback(results)
      return
    end

    while active < DEFAULT_CONCURRENCY and queue_index <= total do
      local entry = entries[queue_index]
      queue_index = queue_index + 1
      active = active + 1

      apply_patch_async(entry, function(result)
        table.insert(results, result)
        status.update(result)
        completed = completed + 1
        active = active - 1

        logger.debug("Patch completed", {
          key = result.key,
          progress = string.format("%d/%d", completed, total),
        })

        vim.schedule(function()
          process_next()
        end)
      end)
    end
  end

  -- Start processing
  vim.schedule(function()
    process_next()
  end)
end

--- Apply all patches from a list
---@param patch_list PatchEntry[]
---@param callback fun(results: PatchResult[])
---@return nil
function M.apply_all(patch_list, callback)
  -- Sort by priority (descending)
  local sorted = vim.deepcopy(patch_list)
  table.sort(sorted, function(a, b)
    local pa = a.priority or 0
    local pb = b.priority or 0
    return pa > pb
  end)

  M.apply_batch(sorted, callback)
end

return M
