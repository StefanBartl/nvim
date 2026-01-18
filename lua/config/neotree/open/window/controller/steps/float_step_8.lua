-- ============================================================================
-- STEP 8: Prevent window closure (block WinClosed event)
-- ============================================================================
local fs = require("config.neotree.open.window.controller.float_debug_steps")

---Prevent Neo-tree from closing the first float window
---@param callback fun(success: boolean)
return function (callback)
  print("[STEP 8] Preventing window closure")

  local NeoCmd, err = fs.get_neo_cmd()
  if not NeoCmd then
    print("[STEP 8] ERROR: " .. err)
    callback(false)
    return
  end

  local guard_active = true
  local first_neo_win = nil
  local guard_group = vim.api.nvim_create_augroup("FloatNoCloseGuard", { clear = true })

  -- Track first neo-tree window creation
  vim.api.nvim_create_autocmd("BufWinEnter", {
    group = guard_group,
    callback = function(ev)
      if not guard_active then return end

      if vim.bo[ev.buf].filetype == "neo-tree" then
        local win = vim.fn.bufwinid(ev.buf)
        if not first_neo_win and win > 0 then
          first_neo_win = win
          print(string.format("[STEP 8] First neo-tree window: %d", win))
        end
      end
    end,
  })

  -- CRITICAL: Block WinClosed for the first neo-tree window
  vim.api.nvim_create_autocmd("WinClosed", {
    group = guard_group,
    callback = function(ev)
      if not guard_active then return end

      local closed_win = tonumber(ev.match)

      if closed_win == first_neo_win then
        print(string.format("[STEP 8] ⚠ Blocking WinClosed for window %d", closed_win))

        -- HACK: Can't actually prevent WinClosed, but we can detect it
        -- and immediately re-open
        vim.schedule(function()
          if guard_active then
            print("[STEP 8] Window was closed - this causes the flicker!")
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
    guard_active = false
    vim.api.nvim_del_augroup_by_name("FloatNoCloseGuard")
    print("[STEP 8] Execute failed")
    callback(false)
    return
  end

  -- Keep monitoring for 1.5 seconds
  vim.defer_fn(function()
    guard_active = false
    pcall(vim.api.nvim_del_augroup_by_name, "FloatNoCloseGuard")
    print("[STEP 8] Guard disabled")
    callback(true)
  end, 1500)
end

