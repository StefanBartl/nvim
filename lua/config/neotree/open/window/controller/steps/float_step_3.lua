local fs = require("config.neotree.open.window.controller.float_debug_steps")

-- ============================================================================
-- STEP 3: Execute + Schedule Focus
-- ============================================================================

---Execute + focus via vim.schedule
---@param callback fun(success: boolean)
return function (callback)
  print("[STEP 3] Execute + schedule focus")

  local NeoCmd, err = fs.get_neo_cmd()
  if not NeoCmd then
    print("[STEP 3] ERROR: " .. err)
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
    print("[STEP 3] Execute failed")
    callback(false)
    return
  end

  vim.schedule(function()
    local win = fs.find_neotree_window()
    if win then
      pcall(vim.api.nvim_set_current_win, win)
      print(string.format("[STEP 3] Focused window: %d", win))
    else
      print("[STEP 3] No window found")
    end
    callback(true)
  end)
end

