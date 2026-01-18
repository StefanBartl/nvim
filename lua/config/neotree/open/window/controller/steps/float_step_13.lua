-- ============================================================================
-- STEP 13: Patch mit WinClosed-basiertem Cleanup (nicht Timeout)
-- ============================================================================


---Patch acquire_window with WinClosed-based cleanup
---@param callback fun(success: boolean)
return function (callback)
  print("[STEP 13] Float patch with WinClosed cleanup")
  local fs = require("config.neotree.open.window.controller.float_debug_steps")
  local cfg = require("config.neotree").options

  local NeoCmd, err = fs.get_neo_cmd()
  if not NeoCmd then
    print("[STEP 13] ERROR: " .. err)
    callback(false)
    return
  end

  local state = require("config.neotree.state.windows")
  local tree_state = require("config.neotree.state.tree")
  local buffer_utils = require("config.neotree.utils.buffer")

  -- Update state
  state.set_open("float", "filesystem", cfg.restore_last_position and "restore" or "reveal")

  local ctx = buffer_utils.get_buffer_context()

  -- Get renderer module
  local ok_renderer, renderer = pcall(require, "neo-tree.ui.renderer")
  if not ok_renderer then
    print("[STEP 13] ERROR: Could not load renderer")
    callback(false)
    return
  end

  -- Store original function
  local original_acquire = renderer.acquire_window
  local first_float_win = nil
  local patch_active = true

  -- Monkey-patch acquire_window
  renderer.acquire_window = function(state_arg, pos_arg, bufnr_arg)
    if not patch_active then
      return original_acquire(state_arg, pos_arg, bufnr_arg)
    end

    local is_float = state_arg and state_arg.current_position == "float"

    if not is_float then
      return original_acquire(state_arg, pos_arg, bufnr_arg)
    end

    -- Float handling: reuse first window
    if not first_float_win then
      first_float_win = original_acquire(state_arg, pos_arg, bufnr_arg)
      print(string.format("[STEP 13] ✓ Created float window: %d", first_float_win or 0))
      return first_float_win
    else
      if first_float_win and vim.api.nvim_win_is_valid(first_float_win) then
        print(string.format("[STEP 13] ✓ Reusing float window: %d", first_float_win))
        pcall(vim.api.nvim_set_current_win, first_float_win)
        return first_float_win
      else
        -- First window closed, create new
        print("[STEP 13] ✗ Window was closed, creating new")
        first_float_win = original_acquire(state_arg, pos_arg, bufnr_arg)
        return first_float_win
      end
    end
  end

  local exec_opts = {
    source = "filesystem",
    action = "show",
    position = "float",
    toggle = false,
    reveal = not cfg.restore_last_position,
  }

  if not cfg.restore_last_position and ctx then
    exec_opts.reveal_file = ctx.file
    exec_opts.dir = ctx.dir
  end

  print("[STEP 13] Executing with patch active...")

  -- Execute with patch active
  local ok_exec = pcall(NeoCmd.execute, exec_opts)

  if not ok_exec then
    patch_active = false
    renderer.acquire_window = original_acquire
    state.set_closed("float_open_failed")
    print("[STEP 13] Execute failed")
    callback(false)
    return
  end

  vim.schedule(function()
    local win = fs.find_neotree_window()

    if not win or not vim.api.nvim_win_is_valid(win) then
      patch_active = false
      renderer.acquire_window = original_acquire
      state.set_closed("float_not_found")
      print("[STEP 13] No window found")
      callback(false)
      return
    end

    -- Focus window
    pcall(vim.api.nvim_set_current_win, win)
    print(string.format("[STEP 13] Focused window: %d", win))

    -- State restore
    if cfg.restore_last_position then
      local ok_mgr, manager = pcall(require, "neo-tree.sources.manager")
      if ok_mgr then
        local neo_state = manager.get_state("filesystem")
        if neo_state and neo_state.tree then
          tree_state.restore_state(neo_state.tree)
        end
      end
    end

    -- CRITICAL: Cleanup patch on WinClosed, not timeout
    local cleanup_patch = function()
      patch_active = false
      renderer.acquire_window = original_acquire
      print("[STEP 13] Float patch disabled (WinClosed)")
    end

    -- Register cleanup on window close
    vim.api.nvim_create_autocmd("WinClosed", {
      pattern = tostring(win),
      once = true,
      callback = function()
        vim.schedule(function()
          cleanup_patch()
        end)
      end,
    })

    print(string.format("[STEP 13] Registered WinClosed cleanup for window %d", win))

    require("config.neotree.open.window.float").set_open_state(true)
    callback(true)
  end)
end
