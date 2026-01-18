-- ============================================================================
-- STEP 11: Inspect state object to find how to detect float
-- ============================================================================

---Inspect what parameters are actually passed
---@param callback fun(success: boolean)
return function  (callback)
  print("[STEP 11] Inspecting acquire_window parameters")

  local ok_cmd, NeoCmd = pcall(require, "neo-tree.command")
  if not ok_cmd then
    print("[STEP 11] ERROR: neo-tree.command not loaded")
    callback(false)
    return
  end

  local ok_renderer, renderer = pcall(require, "neo-tree.ui.renderer")
  if not ok_renderer then
    print("[STEP 11] Could not load neo-tree.ui.renderer")
    callback(false)
    return
  end

  local original_acquire = renderer.acquire_window
  if not original_acquire then
    print("[STEP 11] acquire_window not found")
    callback(false)
    return
  end

  local call_count = 0

  -- Wrap to inspect
  renderer.acquire_window = function(state, position, bufnr)
    call_count = call_count + 1

    print(string.format("\n[STEP 11] ===== Call #%d =====", call_count))
    print(string.format("  position arg: %s", vim.inspect(position)))
    print(string.format("  bufnr arg: %s", vim.inspect(bufnr)))

    if state then
      print("  state fields:")
      print(string.format("    state.id: %s", vim.inspect(state.id)))
      print(string.format("    state.position: %s", vim.inspect(state.position)))
      print(string.format("    state.current_position: %s", vim.inspect(state.current_position)))
      print(string.format("    state.window: %s", vim.inspect(state.window)))

      -- Check for float-specific fields
      local float_indicators = {}
      for k, v in pairs(state) do
        if type(k) == "string" and k:lower():match("float") then
          float_indicators[k] = v
        end
      end

      if next(float_indicators) then
        print("  Float-related fields found:")
        for k, v in pairs(float_indicators) do
          print(string.format("    %s: %s", k, vim.inspect(v)))
        end
      end
    else
      print("  state: nil")
    end

    -- Call original
    return original_acquire(state, position, bufnr)
  end

  print("[STEP 11] Patch installed, executing...")

  local ok = pcall(NeoCmd.execute, {
    source = "filesystem",
    action = "show",
    position = "float",
    toggle = false,
  })

  if not ok then
    renderer.acquire_window = original_acquire
    print("[STEP 11] Execute failed")
    callback(false)
    return
  end

  vim.defer_fn(function()
    renderer.acquire_window = original_acquire
    print(string.format("\n[STEP 11] Inspection complete (%d calls)", call_count))
    callback(true)
  end, 2000)
end

