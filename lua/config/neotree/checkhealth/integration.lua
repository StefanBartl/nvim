---@module 'config.neotree.checkhealth.integration'
---@brief Integration health checks

local M = {}

function M.check()
  vim.health.start("Integration Tests")

  -- Window management
  vim.health.info("Testing window lifecycle...")

  local state = require("config.neotree.state.windows")
  local initial = state.get_state()

  if not initial.open then
    vim.health.ok("Window state: closed (expected)")
  else
    vim.health.warn(string.format("Window state: open at %s (unexpected)", initial.position))
  end

  -- Semaphore
  local sem = require("config.neotree.open.window.controller.semaphore")
  local can_acquire = sem.acquire()
  if can_acquire then
    vim.health.ok("Semaphore: can acquire")
    sem.release()
  else
    vim.health.error("Semaphore: locked (should be available)")
  end

  -- File manager integration
  local ok_fm = pcall(require, "config.neotree.open.filemanager")
  if ok_fm then
    vim.health.ok("File manager integration available")
  else
    vim.health.warn("File manager integration not loaded")
  end

  -- System app integration
  local ok_sys = pcall(require, "config.neotree.open.system_app")
  if ok_sys then
    vim.health.ok("System app integration available")
  else
    vim.health.warn("System app integration not loaded")
  end

  -- Reveal controller
  local ok_reveal = pcall(require, "config.neotree.open.reveal.controller")
  if ok_reveal then
    vim.health.ok("Reveal controller loaded")
  else
    vim.health.warn("Reveal controller not loaded")
  end
end

return M
