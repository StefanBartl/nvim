---@module 'config.neotree.open.window.controller.float_debug_steps'
---@brief Incremental float window testing - step by step debugging

local M = {}

local cfg = require("config.neotree").options

---Get Neo-tree command module
---@return table|nil, string|nil
function M.get_neo_cmd()
  local ok, NeoCmd = pcall(require, "neo-tree.command")
  if not ok then
    return nil, "neo-tree.command not loaded"
  end
  return NeoCmd, nil
end

---Find Neo-tree window
---@return integer|nil
function M.find_neotree_window()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(win) then
      local buf = vim.api.nvim_win_get_buf(win)
      if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].filetype == "neo-tree" then
        return win
      end
    end
  end
  return nil
end

-- ============================================================================
-- Test Runner
-- ============================================================================

---Run specific step
---@param step_number integer 1-9
function M.run_step(step_number)
  local step_func = require("config.neotree.open.window.controller.steps.float_step_" .. tostring(step_number))
  if not step_func then
    print(string.format("[ERROR] Step %d not found", step_number))
    return
  end

  print(string.format("\n========== RUNNING STEP %d ==========", step_number))

  step_func(function(success)
    print(string.format("[STEP %d] Callback result: %s", step_number, tostring(success)))
  end)
end

---Run all steps sequentially
function M.run_all_steps()
  local steps = { 1, 2, 3, 4, 5, 6, 7, 8, 9 }
  local current = 1

  local function run_next()
    if current > #steps then
      print("\n========== ALL STEPS COMPLETED ==========")
      return
    end

    local step = steps[current]
    current = current + 1

    M.run_step(step)

    -- Wait 2 seconds, then close and run next
    vim.defer_fn(function()
      -- Close current float
      local ok, NeoCmd = pcall(require, "neo-tree.command")
      if ok then
        pcall(NeoCmd.execute, { action = "close" })
      end

      -- Wait 500ms then next step
      vim.defer_fn(run_next, 500)
    end, 2000)
  end

  run_next()
end

return M
