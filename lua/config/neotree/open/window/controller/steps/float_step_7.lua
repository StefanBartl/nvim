-- ============================================================================
-- STEP 7: Aggressive dual-phase guard (blocks BOTH renderer calls)
-- ============================================================================
local fs = require("config.neotree.open.window.controller.float_debug_steps")

---Aggressive guard that blocks ALL focus changes during float creation
---@param callback fun(success: boolean)
return function (callback)
  print("[STEP 7] Aggressive dual-phase guard")

  local NeoCmd, err = fs.get_neo_cmd()
  if not NeoCmd then
    print("[STEP 7] ERROR: " .. err)
    callback(false)
    return
  end

  -- CRITICAL: Lock ALL window changes for 600ms (covers both renderer calls)
  local focus_lock_active = true
  local neo_tree_win = nil
  local original_win = vim.api.nvim_get_current_win()

  local guard_group = vim.api.nvim_create_augroup("FloatAggressiveGuard", { clear = true })

  -- Block ANY WinEnter to non-neo-tree windows
  vim.api.nvim_create_autocmd("WinEnter", {
    group = guard_group,
    callback = function(ev)
      if not focus_lock_active then return end

      local entering_buf = ev.buf
      if not entering_buf or not vim.api.nvim_buf_is_valid(entering_buf) then
        return
      end

      local ft = vim.bo[entering_buf].filetype

      -- If entering neo-tree → remember this window
      if ft == "neo-tree" then
        local win = vim.api.nvim_get_current_win()
        neo_tree_win = win
        print(string.format("[STEP 7] Neo-tree window detected: %d", win))
        return
      end

      -- If entering non-neo-tree while we have a neo-tree window → BLOCK!
      if neo_tree_win and vim.api.nvim_win_is_valid(neo_tree_win) then
        print(string.format("[STEP 7] Blocking WinEnter to %s, forcing neo-tree", ft))
        vim.schedule(function()
          if focus_lock_active and neo_tree_win and vim.api.nvim_win_is_valid(neo_tree_win) then
            pcall(vim.api.nvim_set_current_win, neo_tree_win)
          end
        end)
      end
    end,
  })

  -- Block ANY WinLeave from neo-tree
  vim.api.nvim_create_autocmd("WinLeave", {
    group = guard_group,
    callback = function(ev)
      if not focus_lock_active then return end

      local leaving_buf = ev.buf
      if not leaving_buf or not vim.api.nvim_buf_is_valid(leaving_buf) then
        return
      end

      if vim.bo[leaving_buf].filetype == "neo-tree" then
        print("[STEP 7] Blocking WinLeave from neo-tree")
        vim.schedule(function()
          if focus_lock_active and neo_tree_win and vim.api.nvim_win_is_valid(neo_tree_win) then
            pcall(vim.api.nvim_set_current_win, neo_tree_win)
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
    vim.api.nvim_del_augroup_by_name("FloatAggressiveGuard")
    print("[STEP 7] Execute failed")
    callback(false)
    return
  end

  -- Keep guard active for 600ms (covers both renderer.lua calls)
  vim.defer_fn(function()
    focus_lock_active = false
    pcall(vim.api.nvim_del_augroup_by_name, "FloatAggressiveGuard")
    print("[STEP 7] Guard disabled after dual-phase")
    callback(true)
  end, 600)
end

