-- ============================================================================
-- STEP 9: Monkey-patch create_floating_window to prevent double-call
-- ============================================================================

local fs = require("config.neotree.open.window.controller.float_debug_steps")

---Intercept Neo-tree's create_floating_window to prevent recreation
---@param callback fun(success: boolean)
return function (callback)
  print("[STEP 9] Monkey-patching create_floating_window")

  local NeoCmd, err = fs.get_neo_cmd()
  if not NeoCmd then
    print("[STEP 9] ERROR: " .. err)
    callback(false)
    return
  end

  -- Try to patch renderer
  local ok_renderer, renderer = pcall(require, "neo-tree.ui.renderer")
  if not ok_renderer then
    print("[STEP 9] Could not load neo-tree.ui.renderer")
    callback(false)
    return
  end

  -- Store original function
  local original_create_float = renderer.create_floating_window
  local call_count = 0
  local first_win = nil

  -- Wrap function
  renderer.create_floating_window = function(state)
    call_count = call_count + 1
    print(string.format("[STEP 9] create_floating_window call #%d", call_count))

    if call_count == 1 then
      -- First call: create window normally
      first_win = original_create_float(state)
      print(string.format("[STEP 9] Created first window: %d", first_win or 0))
      return first_win
    else
      -- Second call: DON'T create new window, reuse first!
      print(string.format("[STEP 9] Reusing first window instead of creating new"))

      if first_win and vim.api.nvim_win_is_valid(first_win) then
        -- Just focus the existing window
        pcall(vim.api.nvim_set_current_win, first_win)
        return first_win
      else
        -- First window was closed, create new
        print("[STEP 9] First window invalid, creating new")
        return original_create_float(state)
      end
    end
  end

  -- Execute
  local ok = pcall(NeoCmd.execute, {
    source = "filesystem",
    action = "show",
    position = "float",
    toggle = false,
  })

  if not ok then
    renderer.create_floating_window = original_create_float
    print("[STEP 9] Execute failed")
    callback(false)
    return
  end

  -- Restore original after 2 seconds
  vim.defer_fn(function()
    renderer.create_floating_window = original_create_float
    print(string.format("[STEP 9] Restored original (was called %d times)", call_count))
    callback(true)
  end, 2000)
end

