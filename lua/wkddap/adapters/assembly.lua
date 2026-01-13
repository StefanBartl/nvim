---@module 'wkddap.adapters.assembly'

local M = {}

function M.setup()
  local ok_dap, dap = pcall(require, "dap")
  if not ok_dap then return false end

  -- GDB adapter
  dap.adapters.gdb = {
    type = "executable",
    command = "gdb",
    args = { "-i", "dap" },
  }

  return true
end

return M

