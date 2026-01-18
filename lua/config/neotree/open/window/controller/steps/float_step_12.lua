-- ============================================================================
-- STEP 12: Patch acquire_window mit korrekter Float-Erkennung
-- ============================================================================

---Patch acquire_window using state.current_position to detect float
---@param callback fun(success: boolean)
return function (callback)
  print("[STEP 12] Monkey-patching acquire_window (using state.current_position)")

  local ok_cmd, NeoCmd = pcall(require, "neo-tree.command")
  if not ok_cmd then
    print("[STEP 12] ERROR: neo-tree.command not loaded")
    callback(false)
    return
  end

  local ok_renderer, renderer = pcall(require, "neo-tree.ui.renderer")
  if not ok_renderer then
    print("[STEP 12] Could not load neo-tree.ui.renderer")
    callback(false)
    return
  end

  local original_acquire = renderer.acquire_window
  if not original_acquire then
    print("[STEP 12] acquire_window not found")
    callback(false)
    return
  end

  local call_count = 0
  local first_float_win = nil

  -- Wrap function
  renderer.acquire_window = function(state, position, bufnr)
    call_count = call_count + 1

    -- Check if this is a float operation
    local is_float = state and state.current_position == "float"

    print(string.format("[STEP 12] Call #%d - is_float=%s, current_position=%s",
      call_count,
      tostring(is_float),
      state and tostring(state.current_position) or "nil"
    ))

    if not is_float then
      -- Not float, use original
      return original_acquire(state, position, bufnr)
    end

    -- Float handling
    if not first_float_win then
      -- First float call: create window normally
      first_float_win = original_acquire(state, position, bufnr)
      print(string.format("[STEP 12] ✓ Created first float window: %d", first_float_win or 0))
      return first_float_win
    else
      -- Subsequent float call: Check if first window still valid
      if first_float_win and vim.api.nvim_win_is_valid(first_float_win) then
        print(string.format("[STEP 12] ✓ Reusing existing float window: %d", first_float_win))
        -- Just focus the existing window
        pcall(vim.api.nvim_set_current_win, first_float_win)
        return first_float_win
      else
        -- First window was closed, create new
        print("[STEP 12] ✗ First float window invalid, creating new")
        first_float_win = original_acquire(state, position, bufnr)
        return first_float_win
      end
    end
  end

  print("[STEP 12] Patch installed, executing...")

  local ok = pcall(NeoCmd.execute, {
    source = "filesystem",
    action = "show",
    position = "float",
    toggle = false,
  })

  if not ok then
    renderer.acquire_window = original_acquire
    print("[STEP 12] Execute failed")
    callback(false)
    return
  end

  -- Restore original after 2 seconds
  vim.defer_fn(function()
    renderer.acquire_window = original_acquire
    print(string.format("[STEP 12] Restored original (total calls: %d, float window: %d)",
      call_count,
      first_float_win or 0
    ))
    callback(true)
  end, 2000)
end

