---@module 'wkddap.keymaps'
---@brief DAP keyboard mappings

local M = {}

--- Setup default DAP keymaps
---@param opts table Configuration options
function M.setup(opts)
  local dap = require("dap")
  local prefix = opts.prefix or "<leader>d"

  local map = vim.keymap.set
  local desc = function(d)
    return { desc = "[DAP] " .. d, silent = true }
  end

  -- Session control
  map("n", prefix .. "c", dap.continue, desc("Continue"))
  map("n", prefix .. "s", dap.step_over, desc("Step Over"))
  map("n", prefix .. "i", dap.step_into, desc("Step Into"))
  map("n", prefix .. "o", dap.step_out, desc("Step Out"))
  map("n", prefix .. "t", dap.terminate, desc("Terminate"))
  map("n", prefix .. "r", dap.restart, desc("Restart"))

  -- Breakpoints
  map("n", prefix .. "b", dap.toggle_breakpoint, desc("Toggle Breakpoint"))
  map("n", prefix .. "B", function()
    dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
  end, desc("Conditional Breakpoint"))
  map("n", prefix .. "L", function()
    dap.set_breakpoint(nil, nil, vim.fn.input("Log message: "))
  end, desc("Log Point"))

  -- UI
  map("n", prefix .. "u", function()
    require("dapui").toggle()
  end, desc("Toggle UI"))
  map("n", prefix .. "e", function()
    require("dapui").eval()
  end, desc("Evaluate Expression"))
  map("v", prefix .. "e", function()
    require("dapui").eval()
  end, desc("Evaluate Selection"))

  -- REPL
  map("n", prefix .. "R", dap.repl.open, desc("Open REPL"))

  -- List views
  map("n", prefix .. "l", function()
    dap.list_breakpoints()
  end, desc("List Breakpoints"))
end

return M
