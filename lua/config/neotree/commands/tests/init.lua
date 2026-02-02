---@module 'config.neotree.commands.tests'
--- Neotest-specific commands for Neo-tree integration

local notify = require("lib.notify").create("[neotree.tests]")

local M = {}

--- Get test position from Neo-tree node
---@param state table Neo-tree state
---@return string|nil position_id Neotest position ID
local function get_test_position(state)
  local node = state.tree:get_node()
  if not node then
    notify.warn("No node selected")
    return nil
  end

  -- Check if node has test metadata
  if node.extra and node.extra.neotest_id then
    return node.extra.neotest_id
  end

  -- Fallback: try to get position from path
  if node.path then
    return node.path
  end

  notify.warn("No test position found for node")
  return nil
end

--- Run test at cursor position
---@param state table Neo-tree state
function M.run_test(state)
  local pos = get_test_position(state)
  if not pos then
    return
  end

  local neotest = require("neotest")
  if not neotest or not neotest.run then
    notify.error("Neotest not available")
    return
  end

  neotest.run.run(pos)
  notify.info("Running test: " .. vim.fn.fnamemodify(pos, ":t"))
end

--- Debug test at cursor position
---@param state table Neo-tree state
function M.debug_test(state)
  local pos = get_test_position(state)
  if not pos then
    return
  end

  local neotest = require("neotest")
  if not neotest or not neotest.run then
    notify.error("Neotest not available")
    return
  end

  neotest.run.run({ pos, strategy = "dap" })
  notify.info("Debugging test: " .. vim.fn.fnamemodify(pos, ":t"))
end

--- Show test output
---@param state table Neo-tree state
function M.output(state)
  local pos = get_test_position(state)
  if not pos then
    return
  end

  local neotest = require("neotest")
  if not neotest or not neotest.output then
    notify.error("Neotest not available")
    return
  end

  neotest.output.open({ enter = true, position_id = pos })
end

--- Show short test output
---@param state table Neo-tree state
function M.short_output(state)
  local pos = get_test_position(state)
  if not pos then
    return
  end

  local neotest = require("neotest")
  if not neotest or not neotest.output then
    notify.error("Neotest not available")
    return
  end

  neotest.output.open({ enter = false, short = true, position_id = pos })
end

--- Watch test at cursor position
---@param state table Neo-tree state
function M.watch_test(state)
  local pos = get_test_position(state)
  if not pos then
    return
  end

  local neotest = require("neotest")
  if not neotest or not neotest.watch then
    notify.error("Neotest not available")
    return
  end

  neotest.watch.toggle(pos)
  notify.info("Toggled watch for: " .. vim.fn.fnamemodify(pos, ":t"))
end

--- Stop running test
---@param state table Neo-tree state
function M.stop_test(state)
  local neotest = require("neotest")
  if not neotest or not neotest.run or not neotest.run.stop then
    notify.error("Neotest not available")
    return
  end

  neotest.run.stop()
  notify.info("Stopped running tests")
end

--- Refresh test tree
---@param state table Neo-tree state
function M.refresh(state)
  local neotest = require("neotest")
  if not neotest or not neotest.state then
    notify.error("Neotest not available")
    return
  end

  -- Force refresh of test positions
  pcall(neotest.state.clear)

  vim.defer_fn(function()
    -- Refresh Neo-tree display
    require("neo-tree.sources.manager").refresh("tests")
    notify.info("Test tree refreshed")
  end, 500)
end

return M
