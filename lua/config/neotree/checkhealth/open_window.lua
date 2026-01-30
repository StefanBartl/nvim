---@module 'config.neotree.checkhealth.open_window'
---@brief Window controller health checks (updated for custom float)

local M = {}

function M.check()
  vim.health.start("Window Controller")

  -- Controller
  local ok_ctrl = pcall(require, "config.neotree.open.window.controller")
  if ok_ctrl then
    vim.health.ok("Controller loaded")
  else
    vim.health.error("Controller not loadable")
    return
  end

  -- Semaphore
  local ok_sem, sem = pcall(require, "config.neotree.open.window.controller.semaphore")
  if ok_sem then
    vim.health.ok("Semaphore module loaded")

    local status = sem.status()
    if status.available then
      vim.health.ok(string.format("Semaphore available (waiting: %d)", status.waiting))
    else
      vim.health.warn(string.format("Semaphore locked (waiting: %d)", status.waiting))
    end
  else
    vim.health.error("Semaphore module not loadable")
  end

  -- State machine
  local ok_sm = pcall(require, "config.neotree.open.window.controller.state_machine")
  if ok_sm then
    vim.health.ok("State machine loaded")
  else
    vim.health.error("State machine not loadable")
  end

  -- Executor
  local ok_exec = pcall(require, "config.neotree.open.window.controller.executor")
  if ok_exec then
    vim.health.ok("Executor loaded (with custom float support)")
  else
    vim.health.error("Executor not loadable")
  end

  -- Position utils
  local ok_pos = pcall(require, "config.neotree.open.window.controller.position")
  if ok_pos then
    vim.health.ok("Position utils loaded")
  else
    vim.health.error("Position utils not loadable")
  end

  -- Error handler
  local ok_err, err_handler = pcall(require, "config.neotree.open.window.controller.error_handler")
  if ok_err then
    vim.health.ok("Error handler loaded")

    local stats = err_handler.get_stats()
    if vim.tbl_count(stats) == 0 then
      vim.health.ok("No errors logged")
    else
      for context, count in pairs(stats) do
        vim.health.warn(string.format("%s: %d errors", context, count))
      end
    end
  else
    vim.health.warn("Error handler not loaded")
  end

  -- Legacy float module (should still exist for state tracking)
  local ok_legacy_float, legacy_float = pcall(require, "config.neotree.open.window.float")
  if ok_legacy_float then
    vim.health.ok("Legacy float state module loaded")

    local float_state = legacy_float.get_state()
    vim.health.info("Legacy float state:")
    vim.health.info("  open: " .. tostring(float_state.open))
  else
    vim.health.warn("Legacy float module not loaded")
  end

  -- Integration test
  vim.health.start("Custom Float Integration")
end

return M
