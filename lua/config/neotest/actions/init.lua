---@module 'config.neotest.actions'
--- Centralized Neotest actions usable by keymaps, usercommands and menus.

local notify = require("lib.nvim.notify").create("[config.neotest.actions]")

local M = {}

--- Safely require neotest
---@return table|nil neotest
local function get_neotest()
  local ok, neotest = pcall(require, "neotest")
  if not ok then
    notify.error("Neotest not loaded")
    return nil
  end
  return neotest
end

--- Run nearest test
function M.run_nearest()
  local neotest = get_neotest()
  if not neotest or not neotest.run or not neotest.run.run then
    return
  end
  neotest.run.run()
end

--- Run all tests in current file
function M.run_file()
  local neotest = get_neotest()
  if not neotest or not neotest.run or not neotest.run.run then
    return
  end
  neotest.run.run(vim.fn.expand("%"))
end

--- Run all tests in project root
function M.run_all()
  local neotest = get_neotest()
  if not neotest or not neotest.run or not neotest.run.run then
    return
  end
  pcall(neotest.run.run, vim.fn.getcwd())
end

--- Debug nearest test using DAP
function M.debug_nearest()
  local neotest = get_neotest()
  if not neotest or not neotest.run or not neotest.run.run then
    return
  end
  neotest.run.run({ strategy = "dap" })
end

--- Toggle summary window
function M.toggle_summary()
  local neotest = get_neotest()
  if not neotest or not neotest.summary then
    return
  end
  neotest.summary.toggle()
end

--- Open output of last test
function M.open_output()
  local neotest = get_neotest()
  if not neotest or not neotest.output then
    return
  end
  neotest.output.open({ enter = true })
end

--- Toggle output panel
function M.toggle_output_panel()
  local neotest = get_neotest()
  if not neotest or not neotest.output_panel then
    return
  end
  neotest.output_panel.toggle()
end

--- Stop running tests
function M.stop()
  local neotest = get_neotest()
  if not neotest or not neotest.run or not neotest.run.stop then
    return
  end
  neotest.run.stop()
end

--- Toggle watch mode
function M.toggle_watch()
  local neotest = get_neotest()
  if not neotest or not neotest.watch then
    return
  end
  neotest.watch.toggle()
end

return M

