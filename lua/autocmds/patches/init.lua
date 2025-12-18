---@module 'autocmds.patches'
---@brief Public API for automatic patch application system.
---@description
--- This module provides the main entry points for patch management:
--- - Asynchronous patch application
--- - Status queries
--- - Log access
--- - Lazy.nvim integration
---
--- All operations are non-blocking and execute asynchronously.

local M = {}

local notify, levels, schedule = vim.notify, vim.log.levels, vim.schedule

-- Lazy-load submodules
local apply, status, logger, utils, validate

local function ensure_modules()
  if not apply then
    apply = require("autocmds.patches.apply")
    status = require("autocmds.patches.status")
    logger = require("autocmds.patches.logger")
    utils = require("autocmds.patches.utils")
    validate = require("autocmds.patches.validate")
  end
end

-- Configuration (with defaults)
---@type PatchConfig
local config = {
  max_concurrency = 3,
  timeout_ms = 30000,
  verbose = false,
  notify = true,
  lazy_update_delay_ms = 500,
}

--- Setup configuration
---@param opts? PatchConfig
---@return nil
function M.setup(opts)
  opts = opts or {}

  -- Merge with defaults
  config.max_concurrency = opts.max_concurrency or config.max_concurrency
  config.timeout_ms = opts.timeout_ms or config.timeout_ms
  config.verbose = opts.verbose or config.verbose
  config.notify = opts.notify ~= nil and opts.notify or config.notify
  config.lazy_update_delay_ms = opts.lazy_update_delay_ms or config.lazy_update_delay_ms

  -- Initialize submodules
  ensure_modules()
  logger.setup(config)
  status.init()

  logger.info("Patch system initialized", {
    config = {
      concurrency = config.max_concurrency,
      timeout = config.timeout_ms,
      verbose = config.verbose,
    },
  })

end

--- Get patch registry
---@return PatchEntry[]
local function get_patch_list()
  local ok, patches = pcall(require, "autocmds.patches.paths")
  if not ok or type(patches) ~= "table" then
    logger.error("Failed to load patch registry", { error = patches })
    return {}
  end
  return patches
end

--- Filter patches by criteria
---@param patches PatchEntry[]
---@param opts? { repos?: string[], keys?: string[] }
---@return PatchEntry[]
local function filter_patches(patches, opts)
  if not opts then
    return patches
  end

  local repo_set = utils.to_set(opts.repos)
  local key_set = utils.to_set(opts.keys)

  if not repo_set and not key_set then
    return patches
  end

  local filtered = {}
  for _, entry in ipairs(patches) do
    local repo = entry.repo or utils.detect_repo(entry.target)

    if repo_set and not repo_set[repo] then
      goto continue
    end

    if key_set and not key_set[entry.key] then
      goto continue
    end

    table.insert(filtered, entry)

    ::continue::
  end

  return filtered
end

--- Show notification summary
---@param results PatchResult[]
---@return nil
local function show_summary(results)
  if not config.notify then
    return
  end

  local succeeded = 0
  local failed = 0
  local skipped = 0
  local disabled = 0

  for _, result in ipairs(results) do
    if result.status == "disabled" then
      disabled = disabled + 1
    elseif result.status == "already_applied" then
      skipped = skipped + 1
    elseif result.success then
      succeeded = succeeded + 1
    else
      failed = failed + 1
    end
  end

  local total_attempted = succeeded + failed

  if total_attempted == 0 and skipped > 0 then
    -- All already applied
    logger.info("All patches already applied", { count = skipped })
    return
  end

  if failed > 0 then
    schedule(function()
      notify(
        string.format("[patches] %d applied, %d failed, %d skipped", succeeded, failed, skipped),
        levels.WARN
      )
    end)
  elseif succeeded > 0 then
    schedule(function()
      notify(string.format("[patches] %d applied successfully", succeeded), levels.INFO)
    end)
  end
end

--- Apply patches asynchronously with optional filtering
---@param opts? { repos?: string[], keys?: string[], callback?: fun(results: PatchResult[]) }
---@return nil
function M.apply_async(opts)
  ensure_modules()

  opts = opts or {}
  local callback = opts.callback

  local patches = get_patch_list()
  local filtered = filter_patches(patches, opts)

  if #filtered == 0 then
    logger.warn("No patches to apply")
    if callback then
      callback({})
    end
    return
  end

  logger.info("Starting async patch application", {
    total = #filtered,
    filtered = opts.repos or opts.keys ~= nil,
  })

  apply.apply_all(filtered, function(results)
    show_summary(results)

    if callback then
      callback(results)
    end
  end)
end

--- Apply all registered patches asynchronously
---@param callback? fun(results: PatchResult[])
---@return nil
function M.apply_all_async(callback)
  M.apply_async({ callback = callback })
end

--- Validate all patches (dry-run)
---@param callback? fun(results: table[])
---@return nil
function M.validate_all(callback)
  ensure_modules()

  local patches = get_patch_list()
  local results = {}

  for _, entry in ipairs(patches) do
    local validation = validate.validate_entry(entry)
    table.insert(results, {
      key = entry.key,
      repo = entry.repo or utils.detect_repo(entry.target),
      valid = validation.valid,
      error = validation.error,
    })
  end

  logger.info("Validation complete", {
    total = #patches,
    valid = vim.tbl_count(vim.tbl_filter(function(r)
      return r.valid
    end, results)),
  })

  if callback then
    callback(results)
  end
end

--- Get status with optional filtering
---@param opts? StatusQuery
---@return StatusEntry[]
function M.get_status(opts)
  ensure_modules()
  return status.query(opts)
end

--- List all registered patches
---@return PatchEntry[]
function M.list()
  return get_patch_list()
end

--- Show recent logs
---@param opts? { level?: LogLevel, limit?: integer }
---@return LogEntry[]
function M.get_logs(opts)
  ensure_modules()
  return logger.get_recent(opts)
end

--- Clear status cache
---@return boolean success
function M.clear_status()
  ensure_modules()
  return status.clear()
end

--- Open log file in a new buffer
---@return nil
function M.show_logs_buffer()
  ensure_modules()
  local log_path = logger.get_log_path()

  if not utils.file_exists(log_path) then
    notify("[patches] No log file found", levels.WARN)
    return
  end

  schedule(function()
    vim.cmd("vsplit " .. vim.fn.fnameescape(log_path))
    vim.bo.filetype = "json"
    vim.bo.readonly = true
  end)
end

--- Deprecated: synchronous apply (blocks Neovim)
---@deprecated Use apply_all_async instead
---@return nil
function M.apply_all()
  schedule(function()
    notify("[patches] apply_all() is deprecated, use apply_all_async() instead", levels.WARN)
  end)
  M.apply_all_async()
end

--- Deprecated: synchronous apply with filters
---@deprecated Use apply_async instead
---@param opts { repos?: string[], keys?: string[] }
---@return nil
function M.apply(opts)
  schedule(function()
    notify("[patches] apply() is deprecated, use apply_async() instead", levels.WARN)
  end)
  M.apply_async(opts)
end

-- Auto-initialize with default config
M.setup()

-- Integration with Lazy.nvim
local group = vim.api.nvim_create_augroup("LocalPluginPatches", { clear = true })

-- Debounce-Timer für LazyUpdate
local lazy_update_timer = nil
local LAZY_UPDATE_DEBOUNCE_MS = 1000

vim.api.nvim_create_autocmd("User", {
  group = group,
  pattern = "LazyUpdate",
  callback = function()
    logger.info("LazyUpdate detected, scheduling patch application")

    -- Cancel existing timer if present
    if lazy_update_timer then
      lazy_update_timer:stop()
      lazy_update_timer:close()
    end

    -- Create new debounced timer
    lazy_update_timer = vim.loop.new_timer()
    lazy_update_timer:start(LAZY_UPDATE_DEBOUNCE_MS, 0, function()
      lazy_update_timer:stop()
      lazy_update_timer:close()
      lazy_update_timer = nil

      schedule(function()
        M.apply_all_async(function(results)
          logger.info("LazyUpdate patch application complete", {
            total = #results,
          })
        end)
      end)
    end)
  end,
  desc = "Auto-apply patches after Lazy.nvim update (debounced)",
})

return M
