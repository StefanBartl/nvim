-- TESTS/startup/heartbeat_spec.lua -- `startup.heartbeat`: stall detection and busy time per
-- second from synthetic beat times (boundaries, split over seconds, empty input, busy seconds
-- limited to the window), start() honours the switch, stops and closes its timer handle after its
-- window, drops beats that were queued before the stop, and the :StartupReport section
-- (`startup.report.heartbeat_lines`) renders stalls, busy seconds and the recording state.

return function(H)
  local eq, ok, has, lacks = H.eq, H.ok, H.has, H.lacks

  local saved = {
    hb = package.loaded["startup.heartbeat"],
    report = package.loaded["startup.report"],
    switch = vim.g.startup_heartbeat,
  }

  ---@return table
  local function fresh()
    package.loaded["startup.heartbeat"] = nil
    return require("startup.heartbeat")
  end

  ---@param lines { text: string }[]
  ---@return string
  local function joined(lines)
    return table.concat(
      vim.tbl_map(function(l)
        return l.text
      end, lines),
      "\n"
    )
  end

  --- Timer handles in the loop that are open and not closing.
  ---@return integer
  local function live_timers()
    local n = 0
    vim.uv.walk(function(h)
      if h:get_type() == "timer" and not h:is_closing() then
        n = n + 1
      end
    end)
    return n
  end

  local done, err = pcall(function()
    local hb = fresh()

    -- ── analyse ────────────────────────────────────────────────────────────
    local empty = hb.analyse({})
    eq(empty.first, nil, "no beats: no first beat")
    eq(empty.stalls, {}, "no beats: no stalls")
    eq(empty.busy, {}, "no beats: no seconds")
    eq(empty.busy_total, 0, "no beats: nothing busy")

    -- 100 ms gap (stall), 20 ms gap (busy only), 790 ms gap (stall), 240 ms gap
    -- crossing the 1 s border (stall, split 30 / 200).
    local s = hb.analyse({ 100, 110, 120, 220, 230, 240, 260, 1050, 1060, 1300, 1310 })
    eq(s.first, 100, "first beat")
    eq(s.last, 1310, "last beat")
    eq(s.stalls, {
      { at = 120, gap = 100 },
      { at = 260, gap = 790 },
      { at = 1060, gap = 240 },
    }, "stalls in order, at = the beat before the gap")
    eq(s.stall_sum, 1130, "stall sum")
    eq(s.stall_max, 790, "longest stall")
    eq(s.busy, { 910, 200 }, "busy per second, a gap split over the seconds it covers")
    eq(s.busy_total, 1110, "busy total")

    local idle = {}
    for t = 0, 2500, 10 do
      idle[#idle + 1] = t
    end
    local i = hb.analyse(idle)
    eq(i.stalls, {}, "regular beats: no stall")
    eq(i.busy, { 0, 0, 0 }, "regular beats: every second listed, all idle")

    eq(#hb.analyse({ 0, 60 }).stalls, 0, "a gap of exactly 60 ms is not a stall")
    eq(#hb.analyse({ 0, 61 }).stalls, 1, "a gap above 60 ms is a stall")
    eq(hb.analyse({ 0, 16 }).busy, { 0 }, "a gap up to the jitter is not busy")
    eq(hb.analyse({ 0, 17 }).busy, { 7 }, "above the jitter: the gap minus one tick")
    eq(#hb.analyse({ 0, 40 }, { stall = 30 }).stalls, 1, "the stall threshold is an option")

    -- A finished recording ends with the first beat past its window; the second
    -- after the window holds only that beat's gap and is not listed.
    local past = {}
    for t = 0, 5990, 10 do
      past[#past + 1] = t
    end
    past[#past + 1] = 6400 -- a stall across the end of the window
    eq(#hb.analyse(past).busy, 7, "without a window: every second up to the last beat")
    local clipped = hb.analyse(past, { window = 6000 })
    eq(#clipped.busy, 6, "with the window: only its six seconds")
    eq(clipped.busy[6], 0, "busy past the window is not folded into the last second")
    eq(clipped.busy_total, 0, "the total is the sum of the listed seconds")
    eq(clipped.stall_max, 410, "the stall across the end is still counted as a stall")
    eq(#hb.analyse({ 0, 10, 20 }, { window = 6000 }).busy, 1, "a running window lists what it has")

    -- ── start ──────────────────────────────────────────────────────────────
    vim.g.startup_heartbeat = false
    hb = fresh()
    ok(not hb.start(), "switched off: start() does nothing")
    ok(not hb.state.started, "switched off: not marked as started")

    vim.g.startup_heartbeat = nil
    hb = fresh()
    local timers_before = live_timers()
    ok(hb.start({ window = 80 }), "start() arms the timer")
    ok(not hb.start(), "a second start() is a no-op")
    ok(hb.state.running, "recording right after start()")
    eq(live_timers(), timers_before + 1, "start() opens exactly one timer handle")
    ok(
      vim.wait(3000, function()
        return not hb.state.running
      end, 10),
      "the timer stops itself after its window"
    )
    local n = #hb.state.beats
    ok(n >= 2, "beats were recorded")
    ok(hb.state.beats[n] - hb.state.beats[1] >= 80, "recorded at least the window")
    vim.wait(100)
    eq(#hb.state.beats, n, "no beats after the window")
    eq(live_timers(), timers_before, "the timer handle is closed after the window")

    -- Beats that queue up while the loop runs libuv but no scheduled callbacks
    -- (a nested wait such as system() or jobwait(); here vim.wait with fast_only)
    -- are delivered in one burst afterwards. The first one past the window stops
    -- the timer; the rest must be dropped, not recorded (and must not close the
    -- handle a second time).
    hb = fresh()
    ok(hb.start({ window = 100 }), "start() for the backlog case")
    ok(
      vim.wait(2000, function()
        return #hb.state.beats > 0
      end, 1),
      "the first beat arrives"
    )
    local before_backlog = #hb.state.beats
    vim.wait(300, function()
      return false
    end, 10, true)
    ok(
      vim.wait(2000, function()
        return not hb.state.running
      end, 1),
      "the backlog closes the window"
    )
    vim.wait(50)
    eq(#hb.state.beats, before_backlog + 1, "only the beat that closes the window is recorded")
    eq(live_timers(), timers_before, "the backlog case closes its handle too")

    -- snapshot() limits the busy seconds to the recorded window.
    hb = fresh()
    local synthetic = {}
    for t = 0, 1010, 10 do
      synthetic[#synthetic + 1] = t
    end
    hb.state = { started = true, running = false, window = 1000, beats = synthetic }
    eq(#hb.snapshot().busy, 1, "snapshot() passes the window to analyse()")

    -- ── report section ─────────────────────────────────────────────────────
    package.loaded["startup.report"] = nil
    local report = require("startup.report")

    local done_state = { started = true, running = false, window = 6000, beats = {} }
    local text = joined(report.heartbeat_lines(s, done_state))
    has(text, "first heartbeat at 100 ms", "header names the first beat")
    has(text, "stalls > 60 ms       3, 1130 ms blocked, longest 790 ms", "stall summary")
    has(text, "790 ms  at     260 ms", "stalls are listed")
    -- Compare the stall rows themselves; the summary line above also says "790 ms".
    local row_790 = text:find("790 ms  at", 1, true)
    local row_240 = text:find("240 ms  at", 1, true)
    local row_100 = text:find("100 ms  at", 1, true)
    ok(row_790 and row_240 and row_100, "every stall has a row")
    ok(row_790 < row_240 and row_240 < row_100, "stall rows sorted longest first")
    has(text, "910 · 200 ms  (total 1110 ms)", "busy per second")
    has(text, "startup-probe", "points to the probe for attribution")
    lacks(text, "still recording", "finished window is not marked as running")

    local running = vim.tbl_extend("force", done_state, { running = true })
    has(joined(report.heartbeat_lines(s, running)), "(still recording)", "running window")

    local many = {}
    for k = 0, 7 do
      many[#many + 1] = k * 200
      many[#many + 1] = k * 200 + 10
    end
    local m = joined(report.heartbeat_lines(hb.analyse(many), done_state))
    has(m, "… 2 more", "only five stalls listed, the rest counted")

    local off = { started = false, running = false, window = 6000, beats = {} }
    has(joined(report.heartbeat_lines(hb.analyse({}), off)), "not recorded", "not started")
    has(
      joined(report.heartbeat_lines(hb.analyse({}), done_state)),
      "no heartbeat yet",
      "started, no beat arrived"
    )

    -- The full report carries the section.
    has(table.concat(report.text_lines(), "\n"), "Event loop", "section in report.lines()")
  end)

  package.loaded["startup.heartbeat"] = saved.hb
  package.loaded["startup.report"] = saved.report
  vim.g.startup_heartbeat = saved.switch
  if not done then
    error(err, 0)
  end
end
