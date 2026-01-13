---@module 'wkddap.core.capabilities'

local M = {}

---@type table<string, boolean>
M._features = {}

function M.detect()
  -- Check for nvim-dap
  M._features.dap = pcall(require, "dap")

  -- Check for UI plugins
  M._features.dapui = pcall(require, "dapui")
  M._features.virtual_text = pcall(require, "nvim-dap-virtual-text")

  return M._features
end

function M.has(feature)
  return M._features[feature] == true
end

return M
