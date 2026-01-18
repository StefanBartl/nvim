-- ============================================================================
-- STEP 10: Monkey-patch acquire_window (der tatsächliche Entry-Point)
-- ============================================================================

---Patch acquire_window statt create_floating_window
---@param callback fun(success: boolean)
return function (callback)
  print("[STEP 10] Monkey-patching acquire_window")

  local ok_cmd, NeoCmd = pcall(require, "neo-tree.command")
  if not ok_cmd then
    print("[STEP 10] ERROR: neo-tree.command not loaded")
    callback(false)
    return
  end

  -- Try to patch renderer
  local ok_renderer, renderer = pcall(require, "neo-tree.ui.renderer")
  if not ok_renderer then
    print("[STEP 10] Could not load neo-tree.ui.renderer")
    callback(false)
    return
  end

  -- Store original function
  local original_acquire = renderer.acquire_window
  if not original_acquire then
    print("[STEP 10] acquire_window not found in renderer")
    callback(false)
    return
  end

  local call_count = 0
  local first_win = nil
  local first_state_id = nil

  -- Wrap function
  renderer.acquire_window = function(state, position, bufnr)
    call_count = call_count + 1
    print(string.format("[STEP 10] acquire_window call #%d (pos=%s)", call_count, position or "nil"))

    -- Only patch float position
    if position ~= "float" then
      print("[STEP 10] Not float, using original")
      return original_acquire(state, position, bufnr)
    end

    if call_count == 1 then
      -- First call: create window normally
      first_win = original_acquire(state, position, bufnr)
      first_state_id = state.id
      print(string.format("[STEP 10] Created first float window: %d (state=%s)", first_win or 0, first_state_id or "nil"))
      return first_win
    else
      -- Second call: Check if first window still valid
      print(string.format("[STEP 10] Second call detected, checking first window: %d", first_win or 0))

      if first_win and vim.api.nvim_win_is_valid(first_win) then
        print("[STEP 10] ✓ First window still valid, reusing instead of creating new")
        -- Just focus the existing window
        pcall(vim.api.nvim_set_current_win, first_win)
        return first_win
      else
        -- First window was closed, create new
        print("[STEP 10] ✗ First window invalid, creating new")
        local new_win = original_acquire(state, position, bufnr)
        first_win = new_win
        return new_win
      end
    end
  end

  print("[STEP 10] Patch installed, executing...")

  -- Execute
  local ok = pcall(NeoCmd.execute, {
    source = "filesystem",
    action = "show",
    position = "float",
    toggle = false,
  })

  if not ok then
    renderer.acquire_window = original_acquire
    print("[STEP 10] Execute failed")
    callback(false)
    return
  end

  -- Restore original after 2 seconds
  vim.defer_fn(function()
    renderer.acquire_window = original_acquire
    print(string.format("[STEP 10] Restored original (was called %d times, win=%d)",
      call_count, first_win or 0))
    callback(true)
  end, 2000)
end
