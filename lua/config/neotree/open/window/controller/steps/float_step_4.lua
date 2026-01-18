-- ============================================================================
-- STEP 4: Execute + Defer Focus
-- ============================================================================

local fs = require("config.neotree.open.window.controller.float_debug_steps")

---Execute + focus via vim.defer_fn
---@param callback fun(success: boolean)
return function (callback)
  print("[STEP 4] Execute + defer focus (50ms)")

  local NeoCmd, err = fs.get_neo_cmd()
  if not NeoCmd then
    print("[STEP 4] ERROR: " .. err)
    callback(false)
    return
  end

  local ok = pcall(NeoCmd.execute, {
    source = "filesystem",
    action = "show",
    position = "float",
    toggle = false,
  })

  if not ok then
    print("[STEP 4] Execute failed")
    callback(false)
    return
  end

  vim.defer_fn(function()
    local win = fs.find_neotree_window()
    if win then
      pcall(vim.api.nvim_set_current_win, win)
      print(string.format("[STEP 4] Focused window: %d", win))
    else
      print("[STEP 4] No window found")
    end
    callback(true)
  end, 50)
end


