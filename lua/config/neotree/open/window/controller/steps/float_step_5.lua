-- ============================================================================
-- STEP 5: WinLeave Guard + Execute + Immediate Focus
-- ============================================================================

local fs = require("config.neotree.open.window.controller.float_debug_steps")

---WinLeave guard BEFORE execute + immediate focus
---@param callback fun(success: boolean)
return function (callback)
  print("[STEP 5] WinLeave guard + execute + immediate focus")

  local NeoCmd, err = fs.get_neo_cmd()
  if not NeoCmd then
    print("[STEP 5] ERROR: " .. err)
    callback(false)
    return
  end

  -- Install guard
  local focus_lock_active = true
  local guard_group = vim.api.nvim_create_augroup("FloatDebugGuard", { clear = true })

  vim.api.nvim_create_autocmd("WinLeave", {
    group = guard_group,
    callback = function(ev)
      if not focus_lock_active then return end

      local leaving_buf = ev.buf
      if not leaving_buf or not vim.api.nvim_buf_is_valid(leaving_buf) then
        return
      end

      if vim.bo[leaving_buf].filetype == "neo-tree" then
        print("[STEP 5] WinLeave detected - preventing blur")
        vim.schedule(function()
          if focus_lock_active then
            local neo_win = fs.find_neotree_window()
            if neo_win and vim.api.nvim_win_is_valid(neo_win) then
              pcall(vim.api.nvim_set_current_win, neo_win)
              print("[STEP 5] Guard re-focused window")
            end
          end
        end)
      end
    end,
  })

  -- Execute
  local ok = pcall(NeoCmd.execute, {
    source = "filesystem",
    action = "show",
    position = "float",
    toggle = false,
  })

  if not ok then
    focus_lock_active = false
    vim.api.nvim_del_augroup_by_name("FloatDebugGuard")
    print("[STEP 5] Execute failed")
    callback(false)
    return
  end

  -- Immediate focus
  local win = M.find_neotree_window()
  if win then
    pcall(vim.api.nvim_set_current_win, win)
    print(string.format("[STEP 5] Focused window: %d", win))
  end

  -- Cleanup guard after 200ms
  vim.defer_fn(function()
    focus_lock_active = false
    pcall(vim.api.nvim_del_augroup_by_name, "FloatDebugGuard")
    print("[STEP 5] Guard disabled")
  end, 200)

  callback(true)
end

