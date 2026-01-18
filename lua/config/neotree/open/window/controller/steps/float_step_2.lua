local fs = require("config.neotree.open.window.controller.float_debug_steps")

-- ============================================================================
-- STEP 2: Execute + Immediate Focus
-- ============================================================================

---Execute + sofortiger Focus (kein schedule)
---@param callback fun(success: boolean)
return function (callback)
  print("[STEP 2] Execute + immediate focus")

  local NeoCmd, err = fs.get_neo_cmd()
  if not NeoCmd then
    print("[STEP 2] ERROR: " .. err)
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
    print("[STEP 2] Execute failed")
    callback(false)
    return
  end

  -- SOFORTIGER Focus (kein schedule/defer)
  local win = fs.find_neotree_window()
  if win then
    pcall(vim.api.nvim_set_current_win, win)
    print(string.format("[STEP 2] Focused window: %d", win))
  else
    print("[STEP 2] No window found")
  end

  callback(true)
end

