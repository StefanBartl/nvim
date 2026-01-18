-- ============================================================================
-- STEP 6: Full Stack (wie aktuell in executor.lua)
-- ============================================================================
local fs = require("config.neotree.open.window.controller.float_debug_steps")

---Full implementation with state, reveal, etc.
---@param callback fun(success: boolean)
return function (callback)
  print("[STEP 6] Full stack implementation")

  local state = require("config.neotree.state.windows")
  local tree_state = require("config.neotree.state.tree")
  local buffer_utils = require("config.neotree.utils.buffer")

  local NeoCmd, err = fs.get_neo_cmd()
  if not NeoCmd then
    print("[STEP 6] ERROR: " .. err)
    callback(false)
    return
  end

  -- Update state
  state.set_open("float", "filesystem", cfg.restore_last_position and "restore" or "reveal")

  -- Get context
  local ctx = buffer_utils.get_buffer_context()

  -- Install guard
  local focus_lock_active = true
  local guard_group = vim.api.nvim_create_augroup("FloatDebugGuard6", { clear = true })

  vim.api.nvim_create_autocmd("WinLeave", {
    group = guard_group,
    callback = function(ev)
      if not focus_lock_active then return end

      local leaving_buf = ev.buf
      if not leaving_buf or not vim.api.nvim_buf_is_valid(leaving_buf) then
        return
      end

      if vim.bo[leaving_buf].filetype == "neo-tree" then
        print("[STEP 6] WinLeave guard triggered")
        vim.schedule(function()
          if focus_lock_active then
            local neo_win = fs.find_neotree_window()
            if neo_win and vim.api.nvim_win_is_valid(neo_win) then
              pcall(vim.api.nvim_set_current_win, neo_win)
            end
          end
        end)
      end
    end,
  })

  -- Exec opts with reveal
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

  -- Execute
  local ok = pcall(NeoCmd.execute, exec_opts)

  if not ok then
    focus_lock_active = false
    vim.api.nvim_del_augroup_by_name("FloatDebugGuard6")
    state.set_closed("float_open_failed")
    print("[STEP 6] Execute failed")
    callback(false)
    return
  end

  vim.schedule(function()
    local win = fs.find_neotree_window()
    if not win then
      focus_lock_active = false
      vim.api.nvim_del_augroup_by_name("FloatDebugGuard6")
      state.set_closed("float_not_found")
      print("[STEP 6] No window found")
      callback(false)
      return
    end

    pcall(vim.api.nvim_set_current_win, win)

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

    -- Cleanup
    vim.defer_fn(function()
      focus_lock_active = false
      pcall(vim.api.nvim_del_augroup_by_name, "FloatDebugGuard6")
      print("[STEP 6] Guard disabled")
    end, 200)

    require("config.neotree.open.window.float").set_open_state(true)
    callback(true)
  end)
end

