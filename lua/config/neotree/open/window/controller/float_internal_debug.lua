---@module 'config.neotree.open.window.controller.float_internal_debug'
---@brief Debug Neo-tree's internal float window creation

local M = {}

---Track all window/buffer focus changes + window creation/deletion
local focus_log = {}

---Start tracking focus changes
function M.start_tracking()
  focus_log = {}

  local group = vim.api.nvim_create_augroup("FloatFocusTracker", { clear = true })

  -- Track every window enter
  vim.api.nvim_create_autocmd("WinEnter", {
    group = group,
    callback = function(ev)
      local win = vim.api.nvim_get_current_win()
      local buf = vim.api.nvim_win_get_buf(win)
      local ft = vim.bo[buf].filetype

      table.insert(focus_log, {
        event = "WinEnter",
        time = vim.loop.hrtime(),
        win = win,
        buf = buf,
        ft = ft,
        stack = debug.traceback("", 2):match("(.-)\n[^\n]*$") or "",
      })
    end,
  })

  -- Track every window leave
  vim.api.nvim_create_autocmd("WinLeave", {
    group = group,
    callback = function(ev)
      local buf = ev.buf
      local ft = vim.bo[buf].filetype

      table.insert(focus_log, {
        event = "WinLeave",
        time = vim.loop.hrtime(),
        buf = buf,
        ft = ft,
        stack = debug.traceback("", 2):match("(.-)\n[^\n]*$") or "",
      })
    end,
  })

  -- Track buffer enter
  vim.api.nvim_create_autocmd("BufEnter", {
    group = group,
    callback = function(ev)
      local ft = vim.bo[ev.buf].filetype
      local win = vim.api.nvim_get_current_win()

      table.insert(focus_log, {
        event = "BufEnter",
        time = vim.loop.hrtime(),
        win = win,
        buf = ev.buf,
        ft = ft,
      })
    end,
  })

  -- NEW: Track window creation
  vim.api.nvim_create_autocmd("WinNew", {
    group = group,
    callback = function(ev)
      local win = vim.api.nvim_get_current_win()

      table.insert(focus_log, {
        event = "WinNew",
        time = vim.loop.hrtime(),
        win = win,
        buf = vim.api.nvim_win_get_buf(win),
      })
    end,
  })

  -- NEW: Track window close
  vim.api.nvim_create_autocmd("WinClosed", {
    group = group,
    callback = function(ev)
      table.insert(focus_log, {
        event = "WinClosed",
        time = vim.loop.hrtime(),
        win = tonumber(ev.match), -- Window ID that was closed
      })
    end,
  })

  -- NEW: Track buffer changes in window
  vim.api.nvim_create_autocmd("BufWinEnter", {
    group = group,
    callback = function(ev)
      local win = vim.fn.bufwinid(ev.buf)

      table.insert(focus_log, {
        event = "BufWinEnter",
        time = vim.loop.hrtime(),
        win = win,
        buf = ev.buf,
        ft = vim.bo[ev.buf].filetype,
      })
    end,
  })

  print("[FloatDebug] Enhanced tracking started - captures window lifecycle")
end

---Stop tracking
function M.stop_tracking()
  pcall(vim.api.nvim_del_augroup_by_name, "FloatFocusTracker")
  print(string.format("[FloatDebug] Tracking stopped - captured %d events", #focus_log))
end

---Show the focus log with enhanced window tracking
function M.show_log()
  if #focus_log == 0 then
    print("[FloatDebug] No events captured")
    return
  end

  print("\n========== ENHANCED FOCUS EVENT LOG ==========")

  local start_time = focus_log[1].time

  for i, entry in ipairs(focus_log) do
    local elapsed_ms = (entry.time - start_time) / 1e6

    local info
    if entry.event == "WinClosed" then
      info = string.format("win=%d CLOSED", entry.win or 0)
    elseif entry.event == "WinNew" then
      info = string.format("win=%-4d buf=%-3d NEW", entry.win or 0, entry.buf or 0)
    else
      info = string.format(
        "win=%-4s buf=%-3d ft=%-15s",
        tostring(entry.win or "-"),
        entry.buf or 0,
        entry.ft or ""
      )
    end

    print(string.format(
      "[%3d] +%6.2fms | %-12s | %s",
      i,
      elapsed_ms,
      entry.event,
      info
    ))

    -- Show stack for key events
    if entry.stack and entry.stack ~= "" and (entry.event == "WinLeave" or entry.event == "WinEnter") then
      local lines = vim.split(entry.stack, "\n")
      for _, line in ipairs(lines) do
        if line:match("neo%-tree") then
          print(string.format("      └─ %s", line))
        end
      end
    end
  end

  print("==============================================\n")
end

---Clear the log
function M.clear_log()
  focus_log = {}
  print("[FloatDebug] Log cleared")
end

---Analyze the log for flicker pattern with window lifecycle
function M.analyze_flicker()
  if #focus_log < 2 then
    print("[FloatDebug] Not enough events to analyze")
    return
  end

  print("\n========== ENHANCED FLICKER ANALYSIS ==========")

  -- Collect window IDs
  local window_ids = {}
  for _, entry in ipairs(focus_log) do
    if entry.win and entry.win > 0 then
      window_ids[entry.win] = true
    end
  end

  print(string.format("Total events: %d", #focus_log))
  print(string.format("Unique windows: %d", vim.tbl_count(window_ids)))

  -- Check for window creation/deletion
  local new_wins = {}
  local closed_wins = {}
  for _, entry in ipairs(focus_log) do
    if entry.event == "WinNew" then
      table.insert(new_wins, entry)
    elseif entry.event == "WinClosed" then
      table.insert(closed_wins, entry)
    end
  end

  if #new_wins > 0 then
    print(string.format("\nWindow creations: %d", #new_wins))
    for _, e in ipairs(new_wins) do
      local elapsed_ms = (e.time - focus_log[1].time) / 1e6
      print(string.format("  +%.2fms - win=%d", elapsed_ms, e.win))
    end
  end

  if #closed_wins > 0 then
    print(string.format("\nWindow closures: %d", #closed_wins))
    for _, e in ipairs(closed_wins) do
      local elapsed_ms = (e.time - focus_log[1].time) / 1e6
      print(string.format("  +%.2fms - win=%d", elapsed_ms, e.win))
    end
  end

  -- Check neo-tree specific
  local neo_tree_events = {}
  for i, entry in ipairs(focus_log) do
    if entry.ft == "neo-tree" then
      table.insert(neo_tree_events, entry)
    end
  end

  print(string.format("\nNeo-tree events: %d", #neo_tree_events))

  if #neo_tree_events >= 2 then
    print("\nNeo-tree focus sequence:")
    for i, entry in ipairs(neo_tree_events) do
      local elapsed_ms = (entry.time - focus_log[1].time) / 1e6
      print(string.format(
        "  [%d] +%6.2fms - %-12s win=%-4s buf=%-3d",
        i,
        elapsed_ms,
        entry.event,
        tostring(entry.win or "-"),
        entry.buf or 0
      ))
    end

    -- Check for multiple windows
    local neo_wins = {}
    for _, e in ipairs(neo_tree_events) do
      if e.win then
        neo_wins[e.win] = true
      end
    end

    local win_count = vim.tbl_count(neo_wins)
    if win_count > 1 then
      print(string.format("\n⚠ MULTIPLE NEO-TREE WINDOWS: %d", win_count))
      print("Window IDs: " .. table.concat(vim.tbl_keys(neo_wins), ", "))
    end

    -- Check for WinLeave → WinEnter pattern
    local flickers = 0
    for i = 1, #neo_tree_events - 1 do
      if neo_tree_events[i].event == "WinLeave"
         and neo_tree_events[i + 1].event == "WinEnter" then
        local gap_ms = (neo_tree_events[i + 1].time - neo_tree_events[i].time) / 1e6
        print(string.format(
          "\n⚠ FLICKER DETECTED: WinLeave → WinEnter (gap: %.2fms)",
          gap_ms
        ))
        flickers = flickers + 1
      end
    end

    if flickers == 0 then
      print("\n✓ No WinLeave→WinEnter flicker pattern")
    end
  end

  print("===============================================\n")
end

---Convenience function: Track → Open Float → Stop → Analyze
function M.test_float_open()
  M.start_tracking()

  print("\n[FloatDebug] Opening float in 1 second...")
  print("[FloatDebug] Watch your bufferline!\n")

  vim.defer_fn(function()
    -- Use Step 1 (minimal)
    require("config.neotree.open.window.controller.float_debug_steps").float_step_1(function()
      -- Wait for window to settle
      vim.defer_fn(function()
        M.stop_tracking()
        M.show_log()
        M.analyze_flicker()
      end, 500)
    end)
  end, 1000)
end

return M
