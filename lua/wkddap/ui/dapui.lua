---@module 'wkddap.ui.dapui'

local config = require("wkddap.config")

local M = {}

function M.setup()
  local ok_dapui, dapui = pcall(require, "dapui")
  if not ok_dapui then
    return false
  end

  local ok_dap, dap = pcall(require, "dap")
  if not ok_dap then
    return false
  end

  -- Initialize listeners if not present
  if not dap.listeners then
    dap.listeners = {
      before = {},
      after = {},
    }
  end

  if not dap.listeners.before then
    dap.listeners.before = {}
  end

  if not dap.listeners.after then
    dap.listeners.after = {}
  end

  -- Setup DAP UI with configuration
  dapui.setup({
    layouts = config.dapui_layout,
  })

  -- Initialize event listener tables if they don't exist
  dap.listeners.after.event_initialized = dap.listeners.after.event_initialized or {}
  dap.listeners.before.event_terminated = dap.listeners.before.event_terminated or {}
  dap.listeners.before.event_exited = dap.listeners.before.event_exited or {}

  -- Auto-open/close UI
  dap.listeners.after.event_initialized["dapui_config"] = function()
    dapui.open()
  end

  dap.listeners.before.event_terminated["dapui_config"] = function()
    dapui.close()
  end

  dap.listeners.before.event_exited["dapui_config"] = function()
    dapui.close()
  end

  return true
end

return M
