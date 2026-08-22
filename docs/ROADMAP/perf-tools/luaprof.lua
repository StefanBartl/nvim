-- luaprof.lua — sample the Lua stack to find what actually blocks the loop.
--
-- Wrapping known entry points (vim.lsp.handlers, vim.diagnostic.set) found
-- nothing, which means the blocking code is somewhere those wrappers do not
-- cover — Neovim-internal LSP machinery (semantic tokens are dispatched
-- outside vim.lsp.handlers), an autocmd callback, treesitter, whatever.
--
-- So stop guessing at entry points and sample instead: LuaJIT's profiler
-- interrupts every few milliseconds and records the current stack. Idle time
-- is not sampled (the VM is waiting in C), so a 300 ms block shows up as a
-- large, sharply-peaked pile of samples on one stack — which is exactly the
-- thing we are looking for.
--
-- Usage:
--   nvim --cmd "luafile <this file>" <somefile>
--
-- Writes luaprof.log and notifies. TOP_N hottest stacks, plus the stall list
-- so you can confirm the samples line up with the block you felt.

local uv = vim.uv or vim.loop

local SAMPLE_MS = 2
local INTERVAL_MS = 20
local STALL_MS = 80
local REPORT_AFTER_MS = 12000
local TOP_N = 12
local DEPTH = 10

local t0 = uv.hrtime()

-- ── stall detector (for correlation) ─────────────────────────────────────────
local stalls = {}
local last = t0
local timer = uv.new_timer()
timer:start(INTERVAL_MS, INTERVAL_MS, function()
  local n = uv.hrtime()
  local late = (n - last) / 1e6 - INTERVAL_MS
  last = n
  if late >= STALL_MS then
    stalls[#stalls + 1] = { at = (n - t0) / 1e9, late = late }
  end
end)

-- ── stack sampling ───────────────────────────────────────────────────────────
local ok_profile, profile = pcall(require, "jit.profile")
local counts, order, total = {}, {}, 0

if ok_profile then
  profile.start("i" .. SAMPLE_MS, function(th, samples, _)
    -- "pl" = source path + line, one frame per line, most recent first.
    local ok, stack = pcall(profile.dumpstack, th, "pl\n", DEPTH)
    if not ok or not stack then
      return
    end
    -- Drop this script's own stall-detector timer: it wakes every 20 ms, so it
    -- would otherwise sit at the top of the list as pure measurement noise.
    if stack:find("luaprof", 1, true) then
      return
    end
    if counts[stack] == nil then
      counts[stack] = 0
      order[#order + 1] = stack
    end
    counts[stack] = counts[stack] + samples
    total = total + samples
  end)
end

-- ── report ───────────────────────────────────────────────────────────────────
vim.defer_fn(function()
  timer:stop()
  if ok_profile then
    pcall(profile.stop)
  end

  local lines = {}

  lines[#lines + 1] = ("=== main-loop stalls (first %.0f s) ==="):format(REPORT_AFTER_MS / 1000)
  local blocked = 0
  for _, s in ipairs(stalls) do
    blocked = blocked + s.late
    lines[#lines + 1] = ("  at +%6.2f s   blocked %6.0f ms"):format(s.at, s.late)
  end
  lines[#lines + 1] = ("  ---- %d stall(s), %.0f ms total"):format(#stalls, blocked)
  lines[#lines + 1] = ""

  if not ok_profile then
    lines[#lines + 1] = "jit.profile unavailable — cannot sample (not LuaJIT?)"
  else
    table.sort(order, function(a, b)
      return counts[a] > counts[b]
    end)
    lines[#lines + 1] =
      ("=== hottest Lua stacks (%d samples x %d ms ~= %.0f ms of Lua) ==="):format(
        total,
        SAMPLE_MS,
        total * SAMPLE_MS
      )
    for i = 1, math.min(TOP_N, #order) do
      local stack = order[i]
      local n = counts[stack]
      lines[#lines + 1] = ("  [%2d] %4d samples  ~%5.0f ms"):format(i, n, n * SAMPLE_MS)
      local depth = 0
      for frame in stack:gmatch("[^\n]+") do
        depth = depth + 1
        lines[#lines + 1] = ("         %s"):format(frame)
        if depth >= DEPTH then
          break
        end
      end
    end
  end

  pcall(vim.fn.writefile, lines, "luaprof.log")
  -- The stack list is long; the file is the real artifact.
  vim.notify(
    table.concat(lines, "\n", 1, math.min(#lines, 60)) .. "\n\n(full report: luaprof.log)",
    vim.log.levels.WARN
  )
end, REPORT_AFTER_MS)
