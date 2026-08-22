-- stall.lua — report main-loop stalls after startup.
--
-- A libuv timer that measures its OWN lateness. If the timer asks to be woken
-- every 20 ms and comes back 900 ms late, the loop was blocked for 900 ms — no
-- matter what blocked it. That is the key difference from `:profile`, which
-- only sees Vimscript/Lua function calls and is blind to libuv callbacks (the
-- very thing a filesystem scan runs in).
--
-- Load it BEFORE the config so the timer is already ticking during startup:
--   nvim --cmd "luafile <this file>" <somefile>
--
-- After REPORT_AFTER_MS it prints a report and writes ./stalls.log.

local uv = vim.uv or vim.loop

local INTERVAL_MS = 20 -- how often the timer wants to run
local STALL_MS = 80 -- only report lateness above this
local REPORT_AFTER_MS = 12000 -- collect for this long, then report

local t0 = uv.hrtime()
local last = t0
local stalls = {}

local timer = uv.new_timer()
timer:start(INTERVAL_MS, INTERVAL_MS, function()
  local now = uv.hrtime()
  local late = (now - last) / 1e6 - INTERVAL_MS
  last = now
  if late >= STALL_MS then
    stalls[#stalls + 1] = { at = (now - t0) / 1e9, late = late }
  end
end)

vim.defer_fn(function()
  timer:stop()

  local total = 0
  local lines = {
    ("=== main-loop stalls >= %d ms (first %.0f s) ==="):format(STALL_MS, REPORT_AFTER_MS / 1000),
  }
  for _, s in ipairs(stalls) do
    total = total + s.late
    lines[#lines + 1] = ("  at +%6.2f s   blocked %7.0f ms"):format(s.at, s.late)
  end
  if #stalls == 0 then
    lines[#lines + 1] = "  none — the loop stayed responsive"
  else
    lines[#lines + 1] = ("  ---- %d stall(s), %.0f ms blocked in total"):format(#stalls, total)
  end

  pcall(vim.fn.writefile, lines, "stalls.log")
  vim.notify(table.concat(lines, "\n"), vim.log.levels.WARN)
end, REPORT_AFTER_MS)
