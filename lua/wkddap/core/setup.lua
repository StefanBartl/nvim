---@module 'wkddap.core.setup'
---@brief Core DAP setup and initialization

local M = {}

--- Setup core DAP functionality
---@param opts table Configuration options
---@return boolean success
function M.setup(opts)
  local ok, _ = pcall(require, "dap")
  if not ok then
    error("[wkddap.core] nvim-dap not installed")
    return false
  end

  -- Note: dap.set_log_level doesn't exist in nvim-dap
  -- Log level is controlled via vim.lsp.log_level or NVIM_DAP_LOG_LEVEL env var
  if opts.log_level and vim.env.NVIM_DAP_LOG_LEVEL then
    vim.env.NVIM_DAP_LOG_LEVEL = tostring(opts.log_level)
  end

  -- Load capabilities
  local ok_cap, capabilities = pcall(require, "wkddap.core.capabilities")
  if ok_cap then
    pcall(capabilities.detect)
  end

  -- Initialize state
  local ok_state, state = pcall(require, "wkddap.core.state")
  if ok_state then
    pcall(state.init)
  end

  return true
end

return M
