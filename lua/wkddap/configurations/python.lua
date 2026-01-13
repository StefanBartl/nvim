---@module 'wkddap.configurations.python'

local M = {}

function M.load()
  local ok, dap = pcall(require, "dap")
  if not ok then return false end

  dap.configurations.python = {
    {
      type = "python",
      request = "launch",
      name = "Launch file",
      program = "${file}",
      pythonPath = function()
        local venv = vim.env.VIRTUAL_ENV
        if venv then
          return venv .. "/bin/python"
        else
          return "python3"
        end
      end,
    },
  }

  return true
end

return M

