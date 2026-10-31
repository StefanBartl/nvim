---@module 'startup.heartbeat'
--- In-process event-loop heartbeat for the first seconds of a session.
---
--- A 10 ms `vim.uv` timer (delivered through `vim.schedule`, like the `stall`
--- probe of scripts/startup-probe) records when each beat actually arrived. A
--- beat can only arrive when the main loop is free, so the wall-clock gap
--- between two beats is the time the loop was blocked. The timer stops and
--- closes itself after `WINDOW` ms; until then it costs one tiny callback per
--- tick (a table append), well below the run-to-run noise of a start.
---
--- What this answers: "how many stalls > 60 ms, how long, and how busy was the
--- loop per second" in the session that is running right now, shown by
--- :StartupReport. What it does not answer: who owns a stall. Attribution
--- (plugin, stack) needs the wrappers of scripts/startup-probe (`PROBE=…,where`),
--- which cost too much to run in every session.
---
--- The computation (`analyse`) is pure and mirrors the `stall` probe, so the two
--- read the same way: a stall is one gap > 60 ms; busy time counts every gap
--- above the timer's own jitter, minus the tick it would have idled anyway, and
--- is split over the seconds (counted from the first beat) that it covers.
---
--- Switch off for an A/B run: `--cmd "lua vim.g.startup_heartbeat = false"`
--- (or `--cmd "let g:startup_heartbeat = 0"`; `false` and `0` both switch it off).

local M = {}

M.TICK = 10 -- ms between beats
M.JITTER = 16 -- gaps up to this are the timer's own jitter, not busy time
M.STALL = 60 -- a gap above this is a stall
M.WINDOW = 6000 -- ms recorded after the first beat

---@class Startup.Heartbeat.State
---@field started boolean   start() armed a timer in this session
---@field running boolean   the timer is still recording
---@field window number     ms recorded after the first beat
---@field beats number[]    ms since vim.g.start_time at which each beat arrived

---@type Startup.Heartbeat.State
M.state = { started = false, running = false, window = M.WINDOW, beats = {} }

---@class Startup.Heartbeat.Stall
---@field at number   ms since start of the beat before the gap
---@field gap number  ms the loop was blocked

---@class Startup.Heartbeat.Stats
---@field first number|nil              ms since start of the first beat
---@field last number|nil               ms since start of the last beat
---@field stalls Startup.Heartbeat.Stall[]  chronological
---@field stall_sum number              ms, all stalls together
---@field stall_max number              ms, the longest stall
---@field busy number[]                 busy ms per second; [1] is the second after `first`
---@field busy_total number             ms, sum of `busy`

---@class Startup.Heartbeat.Opts
---@field tick? number
---@field jitter? number
---@field stall? number
---@field window? number  ms; `busy` lists only the seconds that start inside it

--- Turn beat arrival times into stalls and busy time per second. Pure.
---@param beats number[]  ascending arrival times in ms
---@param opts? Startup.Heartbeat.Opts
---@return Startup.Heartbeat.Stats
function M.analyse(beats, opts)
  opts = opts or {}
  local tick = opts.tick or M.TICK
  local jitter = opts.jitter or M.JITTER
  local stall = opts.stall or M.STALL

  ---@type Startup.Heartbeat.Stats
  local res = {
    first = beats[1],
    last = beats[#beats],
    stalls = {},
    stall_sum = 0,
    stall_max = 0,
    busy = {},
    busy_total = 0,
  }
  if #beats == 0 then
    return res
  end

  local first = beats[1]
  local busy = {} ---@type table<integer, number>

  --- Busy time from..to (ms since `first`), spread over the second-long
  --- buckets it spans, so no second can read more than 1000.
  ---@param from number
  ---@param to number
  local function add_busy(from, to)
    while from < to do
      local sec = math.floor(from / 1000)
      local upto = math.min(to, (sec + 1) * 1000)
      busy[sec] = (busy[sec] or 0) + (upto - from)
      from = upto
    end
  end

  for i = 2, #beats do
    local prev, t = beats[i - 1], beats[i]
    local gap = t - prev
    if gap > stall then
      res.stalls[#res.stalls + 1] = { at = prev, gap = gap }
      res.stall_sum = res.stall_sum + gap
      res.stall_max = math.max(res.stall_max, gap)
    end
    if gap > jitter then
      -- The timer would have idled for one tick anyway: the rest is busy time.
      add_busy(prev - first + tick, t - first)
    end
  end

  local last_sec = math.floor((res.last - first) / 1000)
  if opts.window then
    -- Recording stops at the first beat past the window, so the second after it
    -- would only hold that beat's gap: list the window's own seconds.
    last_sec = math.min(last_sec, math.max(1, math.ceil(opts.window / 1000)) - 1)
  end
  for sec = 0, last_sec do
    local ms = busy[sec] or 0
    res.busy[sec + 1] = ms
    res.busy_total = res.busy_total + ms
  end
  return res
end

--- Start recording. Call once, as early as possible in init.lua; the first beat
--- arrives when the loop first gets control. No-op when already started or when
--- `vim.g.startup_heartbeat` is `false` or `0` (Vimscript `let g:startup_heartbeat = 0`).
---@param opts? { window?: number }
---@return boolean started
function M.start(opts)
  local switch = vim.g.startup_heartbeat
  if switch == false or switch == 0 or M.state.started then
    return false
  end
  local uv = vim.uv
  local timer = uv.new_timer()
  if not timer then
    return false
  end

  local t0 = vim.g.start_time or uv.hrtime()
  local beats = {} ---@type number[]
  local state = {
    started = true,
    running = true,
    window = (opts and opts.window) or M.WINDOW,
    beats = beats,
  }
  M.state = state

  timer:start(
    0,
    M.TICK,
    vim.schedule_wrap(function()
      -- A beat scheduled before stop() can still be delivered after it.
      if not state.running then
        return
      end
      local t = (uv.hrtime() - t0) / 1e6
      beats[#beats + 1] = t
      if t - beats[1] >= state.window then
        state.running = false
        timer:stop()
        timer:close()
      end
    end)
  )
  return true
end

--- Stats of what has been recorded so far (busy seconds limited to the window),
--- plus the recording state.
---@return Startup.Heartbeat.Stats stats, Startup.Heartbeat.State state
function M.snapshot()
  return M.analyse(M.state.beats, { window = M.state.window }), M.state
end

return M
