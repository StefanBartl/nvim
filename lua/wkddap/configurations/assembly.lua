---@module 'wkddap.configurations.assembly'

local M = {}

function M.load()
  local ok, dap = pcall(require, "dap")
  if not ok then
    return false
  end

  for _, ft in ipairs({ "asm", "nasm", "gas" }) do
    dap.configurations[ft] = {
      {
        name = "Launch",
        type = "gdb",
        request = "launch",
        program = function()
          return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
        end,
        cwd = "${workspaceFolder}",
        stopAtBeginningOfMainSubprogram = false,
      },
    }
  end

  return true
end

return M
