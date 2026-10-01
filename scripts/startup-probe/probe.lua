---@module 'startup-probe'
--- Startup probes for this config. One file, selectable probes, one report.
---
--- Runs BEFORE init.lua (`--cmd`), wraps what it measures, waits until the
--- editor is really up (VimEnter + PROBE_MS) and only then writes the report.
--- That last part matters: `-c` commands run BEFORE VimEnter, so anything
--- measured with `-c "... vim.wait(..)"` never sees the UIReady phases or the
--- post-VimEnter work (menu prewarm, VeryLazy plugins). See README.md.
---
---   PROBE=req,exe,rtp,stall,spawn,fs,lazy,marks,report   (default: these)
---   PROBE_MS=6000                                   ms to wait after VimEnter
---   PROBE_OUT=<path>                                report file (default: $TEMP/startup-probe.txt)
---
---   nvim --headless -l scripts/startup-probe/tui.lua                  with a UI
---   nvim --headless --cmd "luafile scripts/startup-probe/probe.lua"   without
---
--- A headless run has no UIEnter, so lazy.nvim never fires VeryLazy and every
--- plugin waiting for it stays unloaded. Measure through tui.lua unless the
--- question is about the time before VimEnter only.
---
--- Probes:
---   req     exclusive require time per module / namespace, top-level requires
---           that block for a long time, modules loaded
---   exe     vim.fn.executable / exepath calls: count, time, found or not
---   rtp     nvim_get_runtime_file calls (vim.loader recomputes the runtimepath
---           list on every 'runtimepath' change -- one call per plugin load)
---   stall   event-loop stalls (a 10 ms heartbeat that finds gaps > 60 ms) and
---           how busy the loop was per second, small gaps included
---   where   (opt-in, costs time) which code each stall belongs to
---   spawn   processes started through uv.spawn (vim.system, lazy.nvim, plugins)
---           plus vim.fn.system: spawn cost and blocking wait. Not seen:
---           jobstart, termopen, system()/systemlist() calls from Vimscript, :!
---   fs      other C-level calls that are cheap alone and not in bulk
---   lazy    what lazy.nvim loaded, why, and for how long
---   marks   when VimEnter / UIEnter / LazyDone / VeryLazy happened
---   report  the `startup` module's phase timeline (:StartupReport as text)
---
--- Overhead: every probe adds a wrapper, the totals are ~5-10 % too high with
--- all of them on. Compare runs of the SAME probe set, and read overlapping
--- numbers (a plugin's load time contains its requires and its exepath calls)
--- as evidence for a cause, never as terms of a sum.

local uv = vim.uv
local t_start = uv.hrtime()

local function now()
  return (uv.hrtime() - t_start) / 1e6
end

local wanted = {}
for name in (vim.env.PROBE or "req,exe,rtp,stall,spawn,fs,lazy,marks,report"):gmatch("[^,%s]+") do
  wanted[name] = true
end

local dumps = {} ---@type (fun(out: string[]))[]

--- The numbers a benchmark compares, written next to the report as JSON
--- (`<PROBE_OUT>.json`). bench.lua takes the median of these over several runs.
local summary = {} ---@type table<string, any>

---@param out string[]
---@param fmt string
local function add(out, fmt, ...)
  out[#out + 1] = fmt:format(...)
end

---@param tbl table
---@param name string
---@param around fun(orig: function, ...): ...
local function wrap(tbl, name, around)
  local orig = tbl[name]
  if type(orig) ~= "function" then
    return
  end
  tbl[name] = function(...)
    return around(orig, ...)
  end
end

-- ── req ─────────────────────────────────────────────────────────────────────
if wanted.req then
  local orig_require = require
  local stack, excl, count, top = {}, {}, {}, {}

  -- Re-raising below starts a new unwind, so the failing module's own frames
  -- would be gone for lazy.nvim's trace. Keep them in the message instead:
  -- once (the innermost wrapper wins) and never for "module not found", which
  -- plugins probe with pcall(require, ...) all the time.
  ---@param err any
  ---@return any
  local function with_chain(err)
    if
      type(err) == "string"
      and not err:find("stack traceback:", 1, true)
      and not err:find("^module '.-' not found")
    then
      return err .. "\n" .. debug.traceback("", 2)
    end
    return err
  end

  _G.require = function(name)
    if package.loaded[name] ~= nil then
      return orig_require(name)
    end
    local t0 = uv.hrtime()
    stack[#stack + 1] = { child = 0 }
    local ok, res = xpcall(orig_require, with_chain, name)
    local frame = table.remove(stack)
    local dt = uv.hrtime() - t0
    excl[name] = (excl[name] or 0) + (dt - frame.child)
    count[name] = (count[name] or 0) + 1
    if stack[#stack] then
      stack[#stack].child = stack[#stack].child + dt
    else
      top[#top + 1] = { name = name, at = (t0 - t_start) / 1e6, ms = dt / 1e6 }
    end
    if not ok then
      error(res, 0)
    end
    return res
  end

  dumps[#dumps + 1] = function(out)
    local rows, groups, total = {}, {}, 0
    for name, ns in pairs(excl) do
      rows[#rows + 1] = { name, ns / 1e6 }
      total = total + ns / 1e6
      local g = name:match("^[^%.]+")
      groups[g] = (groups[g] or 0) + ns / 1e6
    end
    table.sort(rows, function(a, b)
      return a[2] > b[2]
    end)
    add(out, "== req: %d modules loaded, %.0f ms exclusive require time", #rows, total)
    add(out, "-- top modules (exclusive ms)")
    for i = 1, math.min(#rows, 18) do
      add(out, "%8.1f  %s", rows[i][2], rows[i][1])
    end
    local g = {}
    for k, v in pairs(groups) do
      g[#g + 1] = { k, v }
    end
    table.sort(g, function(a, b)
      return a[2] > b[2]
    end)
    add(out, "-- top namespaces (exclusive ms)")
    for i = 1, math.min(#g, 12) do
      add(out, "%8.1f  %s", g[i][2], g[i][1])
    end
    table.sort(top, function(a, b)
      return a.ms > b.ms
    end)
    add(out, "-- top-level requires > 25 ms (inclusive wall, at = ms since start)")
    for i = 1, math.min(#top, 15) do
      if top[i].ms > 25 then
        add(out, "%8.1f  at %7.0f  %s", top[i].ms, top[i].at, top[i].name)
      end
    end
  end
end

-- ── exe ─────────────────────────────────────────────────────────────────────
if wanted.exe then
  local calls, total = {}, 0
  for _, fname in ipairs({ "executable", "exepath" }) do
    wrap(vim.fn, fname, function(orig, name, ...)
      local t0 = uv.hrtime()
      local r = orig(name, ...)
      local dt = (uv.hrtime() - t0) / 1e6
      total = total + dt
      local key = fname .. " " .. tostring(name)
      local c = calls[key]
      if not c then
        -- Who asked first: the caller of vim.fn.* (often a shared helper) and
        -- its caller. Levels 2 and 3, not 3 and 4: `wrap` tail-calls this
        -- function, and a tail call leaves no frame of its own behind. A caller
        -- that tail-calls vim.fn.* itself (`return vim.fn.exepath(cmd)`) is
        -- invisible too and LuaJIT keeps no marker for it, so the chain then
        -- starts one level higher: the helper is missing from it.
        local who = {}
        for level = 2, 3 do
          local info = debug.getinfo(level, "Sl")
          if info then
            local src = info.short_src:gsub("\\", "/"):gsub("^.-/([^/]+/lua/)", "%1")
            who[#who + 1] = ("%s:%d"):format(src, info.currentline)
          end
        end
        c = { n = 0, ms = 0, found = (r ~= 0 and r ~= ""), who = table.concat(who, " < ") }
        calls[key] = c
      end
      c.n, c.ms = c.n + 1, c.ms + dt
      return r
    end)
  end
  dumps[#dumps + 1] = function(out)
    local rows, misses, miss_ms = {}, 0, 0
    for k, c in pairs(calls) do
      rows[#rows + 1] = { k, c }
      if not c.found then
        misses, miss_ms = misses + 1, miss_ms + c.ms
      end
    end
    table.sort(rows, function(a, b)
      return a[2].ms > b[2].ms
    end)
    add(
      out,
      "== exe: %.0f ms in %d distinct calls, %d not found = %.0f ms",
      total,
      #rows,
      misses,
      miss_ms
    )
    for i = 1, math.min(#rows, 20) do
      add(
        out,
        "%8.1f ms  x%-3d found=%-5s %s",
        rows[i][2].ms,
        rows[i][2].n,
        tostring(rows[i][2].found),
        rows[i][1]
      )
      add(out, "              first from %s", rows[i][2].who)
    end
    add(
      out,
      "   (PATH entries: %d, PATHEXT entries: %d)",
      #vim.split(vim.env.PATH or "", ";", { trimempty = true }),
      #vim.split(vim.env.PATHEXT or "", ";", { trimempty = true })
    )
  end
end

-- ── rtp ─────────────────────────────────────────────────────────────────────
if wanted.rtp then
  local rows, sum = {}, 0
  wrap(vim.api, "nvim_get_runtime_file", function(orig, name, all)
    local t0 = uv.hrtime()
    local r = orig(name, all)
    local dt = (uv.hrtime() - t0) / 1e6
    sum = sum + dt
    rows[#rows + 1] = { name = tostring(name), n = #r, ms = dt, at = (t0 - t_start) / 1e6 }
    return r
  end)
  dumps[#dumps + 1] = function(out)
    local rtp_calls, rtp_ms, rtp_first = 0, 0, nil
    for _, r in ipairs(rows) do
      if r.name == "" then
        rtp_calls, rtp_ms = rtp_calls + 1, rtp_ms + r.ms
        rtp_first = rtp_first or r.n
      end
    end
    table.sort(rows, function(a, b)
      return a.ms > b.ms
    end)
    add(out, "== rtp: nvim_get_runtime_file %d calls, %.0f ms total", #rows, sum)
    add(
      out,
      '   of which name="" (the runtimepath list, vim.loader.get_rtp): %d calls, %.0f ms, %s entries at the first call',
      rtp_calls,
      rtp_ms,
      tostring(rtp_first)
    )
    for i = 1, math.min(#rows, 6) do
      add(
        out,
        "%8.1f ms  n=%-3d at %7.0f  name=%q",
        rows[i].ms,
        rows[i].n,
        rows[i].at,
        rows[i].name:sub(1, 40)
      )
    end
  end
end

-- ── stall ───────────────────────────────────────────────────────────────────
-- `beat` and `stalls` are shared with `where`, which attributes every stall.
local beat = nil ---@type number? ms of the last heartbeat
local stalls = {} ---@type { at: number, gap: number }[]
if wanted.where then
  wanted.stall = true
end
if wanted.stall then
  -- A stall is one gap > 60 ms. `busy` also counts the small ones (a process
  -- spawn is ~15 ms of main thread on Windows, fifty of them never show up as
  -- a stall): every gap above the timer's own jitter, summed per second. A gap
  -- is split over the seconds it covers, so no second can read more than 1000.
  local TICK, JITTER = 10, 16
  local first = nil ---@type number?
  local busy = {} ---@type table<integer, number>

  --- Busy time from..to (ms since `first`), spread over the second-long buckets
  --- it spans.
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

  local timer = uv.new_timer()
  timer:start(
    0,
    TICK,
    vim.schedule_wrap(function()
      local t = now()
      if beat and first then
        local gap = t - beat
        if gap > 60 then
          stalls[#stalls + 1] = { at = beat, gap = gap }
        end
        if gap > JITTER then
          -- The timer would have idled for TICK anyway: the rest is busy time.
          add_busy(beat - first + TICK, t - first)
        end
      else
        first = t
      end
      beat = t
    end)
  )
  dumps[#dumps + 1] = function(out)
    local sum, max = 0, 0
    for _, s in ipairs(stalls) do
      sum = sum + s.gap
      max = math.max(max, s.gap)
    end
    add(out, "== stall: %d event-loop stalls > 60 ms, %.0f ms blocked in total", #stalls, sum)
    local sorted = vim.list_slice(stalls)
    table.sort(sorted, function(a, b)
      return a.gap > b.gap
    end)
    for i = 1, math.min(#sorted, 8) do
      add(out, "%8.0f ms  starting at %7.0f", sorted[i].gap, sorted[i].at)
    end
    add(
      out,
      "-- loop busy per second (all gaps > %d ms), from the first heartbeat at %.0f ms",
      JITTER,
      first or 0
    )
    local busy_total, per_second = 0, {}
    for sec = 0, math.floor(((beat or 0) - (first or 0)) / 1000) do
      local ms = busy[sec] or 0
      busy_total = busy_total + ms
      per_second[#per_second + 1] = math.floor(ms + 0.5)
      add(out, "%8.0f ms  in second %d", ms, sec + 1)
    end
    summary.stall = {
      count = #stalls,
      sum = sum,
      max = max,
      busy = busy_total,
      busy_per_second = per_second,
      first_beat = first,
    }
  end
end

-- ── where ───────────────────────────────────────────────────────────────────
-- Which code a stall belongs to. A count hook samples the Lua stack while the
-- heartbeat is overdue and charges the time since the previous sample to that
-- stack. A blocking C call, or JIT-compiled Lua (neither calls the hook), shows
-- up as one long sample at the first code that runs 1000+ instructions after
-- it ended -- the NEXT function when the stall was the last thing a callback
-- did. Busy interpreted Lua shows up as many short samples. Sampling costs
-- time: do not compare the totals of a run with `where` to one without.
if wanted.where then
  local OVERDUE, EVERY, FRAMES = 60, 2, 9
  local last_sample = 0
  local samples = {} ---@type { at: number, ms: number, tb: string }[]
  debug.sethook(function()
    local t = now()
    if beat and t - beat > OVERDUE and t - last_sample >= EVERY then
      local from = math.max(last_sample, beat)
      samples[#samples + 1] = { at = from, ms = t - from, tb = debug.traceback("", 2) }
      last_sample = t
    end
  end, "", 1000)

  local NOISE = { "^%[C%]: in function 'require'", "^%[C%]: in function 'x?pcall'" }

  ---@param tb string
  ---@return string[] frames innermost first, paths cut down to `<plugin>/lua/...`
  local function frames(tb)
    local res = {}
    for line in tb:gmatch("[^\n]+") do
      local f = line:match("^%s+(.+)$")
      if f then
        local keep = true
        for _, pat in ipairs(NOISE) do
          keep = keep and not f:find(pat)
        end
        if keep then
          res[#res + 1] = (f:gsub("\\", "/"):gsub("^.-/([^/]+/lua/)", "%1"))
        end
      end
    end
    return res
  end

  ---@param fr string[]
  ---@return string owner the innermost frame that is neither Neovim nor lazy.nvim
  local function owner(fr)
    for _, f in ipairs(fr) do
      local ns = f:match("/lua/([^/:]+)/") or f:match("/lua/([^/:]+)%.lua")
      -- `runtime/lua/...` is Neovim's own tree (vim.lsp, vim.treesitter,
      -- vim.diagnostic when loaded from disk, editorconfig, man): not an owner.
      if ns and ns ~= "lazy" and not f:find("^runtime/lua/") then
        return f:find("^nvim/lua/") and ("config:" .. ns) or ns
      end
    end
    return "(neovim / lazy.nvim)"
  end

  ---@param tbl table<string, number>
  ---@return string[] keys sorted by value, largest first
  local function by_value(tbl)
    local keys = vim.tbl_keys(tbl)
    table.sort(keys, function(a, b)
      return tbl[a] > tbl[b]
    end)
    return keys
  end

  dumps[#dumps + 1] = function(out)
    debug.sethook()
    add(out, "== where: the stalls by owner and by stack (ms sampled, innermost frame first)")
    local total = {} ---@type table<string, number>
    for _, s in ipairs(stalls) do
      local owners, stacks, shown, sampled = {}, {}, {}, 0
      for _, e in ipairs(samples) do
        -- A sample belongs to the stall its midpoint falls into. Its start can be
        -- the closing heartbeat of the previous stall (the first sample of a stall
        -- right behind another one), which an inclusive test on the start would
        -- credit to both.
        local mid = e.at + e.ms / 2
        if mid > s.at and mid <= s.at + s.gap then
          local fr = frames(e.tb)
          local who = owner(fr)
          local key = table.concat(fr, "\n", 1, math.min(#fr, 3))
          owners[who] = (owners[who] or 0) + e.ms
          total[who] = (total[who] or 0) + e.ms
          stacks[key] = (stacks[key] or 0) + e.ms
          shown[key] = shown[key] or fr
          sampled = sampled + e.ms
        end
      end
      add(out, "-- stall %.0f ms at %.0f (%.0f ms sampled)", s.gap, s.at, sampled)
      local line = {}
      for i, who in ipairs(by_value(owners)) do
        if i <= 6 then
          line[#line + 1] = ("%s %.0f"):format(who, owners[who])
        end
      end
      add(out, "   owners: %s", table.concat(line, " · "))
      for i, key in ipairs(by_value(stacks)) do
        if i > 3 or stacks[key] < 20 then
          break
        end
        add(out, "   %6.0f ms in", stacks[key])
        for j = 1, math.min(#shown[key], FRAMES) do
          add(out, "          %s", shown[key][j])
        end
      end
    end
    add(out, "-- all stalls by owner")
    for i, who in ipairs(by_value(total)) do
      if i <= 12 then
        add(out, "%8.0f ms  %s", total[who], who)
      end
    end
    summary.where = total
  end
end

-- ── lazy ────────────────────────────────────────────────────────────────────
-- What lazy.nvim loaded, why, and for how long. Times include the plugin's
-- dependencies and everything its `config` required: they overlap.
if wanted.lazy then
  dumps[#dumps + 1] = function(out)
    local ok, config = pcall(require, "lazy.core.config")
    if not ok then
      add(out, "== lazy: lazy.nvim is not loaded")
      return
    end
    local rows, kinds, total = {}, {}, 0
    for name, plugin in pairs(config.plugins) do
      total = total + 1
      local l = plugin._ and plugin._.loaded
      if l then
        local kind, detail = "other", ""
        for _, k in ipairs({ "event", "ft", "cmd", "keys", "require", "start", "plugin", "source" }) do
          if l[k] then
            kind, detail = k, tostring(l[k])
            break
          end
        end
        kind = kind == "plugin" and "dependency" or kind
        kinds[kind] = (kinds[kind] or 0) + 1
        rows[#rows + 1] = { name = name, ms = (l.time or 0) / 1e6, kind = kind, detail = detail }
      end
    end
    table.sort(rows, function(a, b)
      return a.ms > b.ms
    end)
    local parts = {}
    for kind, n in pairs(kinds) do
      parts[#parts + 1] = ("%s %d"):format(kind, n)
    end
    table.sort(parts)
    add(out, "== lazy: %d of %d plugins loaded (%s)", #rows, total, table.concat(parts, ", "))
    for i = 1, math.min(#rows, 30) do
      local r = rows[i]
      add(out, "%8.1f ms  %-28s %s %s", r.ms, r.name, r.kind, r.detail:sub(1, 50))
    end
    summary.lazy = { loaded = #rows, total = total }
  end
end

-- ── spawn ───────────────────────────────────────────────────────────────────
if wanted.spawn then
  local log = {}
  wrap(vim, "system", function(orig, cmd, opts, on_exit)
    local t0 = uv.hrtime()
    local obj = orig(cmd, opts, on_exit)
    local e = {
      cmd = type(cmd) == "table" and table.concat(cmd, " ") or tostring(cmd),
      at = (t0 - t_start) / 1e6,
      spawn = (uv.hrtime() - t0) / 1e6,
      wait = 0,
    }
    log[#log + 1] = e
    local wait = obj.wait
    obj.wait = function(self, ...)
      local a = uv.hrtime()
      local r = wait(self, ...)
      e.wait = e.wait + (uv.hrtime() - a) / 1e6
      return r
    end
    return obj
  end)
  wrap(vim.fn, "system", function(orig, cmd, ...)
    local t0 = uv.hrtime()
    local r = orig(cmd, ...)
    log[#log + 1] = {
      cmd = "fn.system " .. (type(cmd) == "table" and table.concat(cmd, " ") or tostring(cmd)),
      at = (t0 - t_start) / 1e6,
      spawn = (uv.hrtime() - t0) / 1e6,
      wait = 0,
    }
    return r
  end)
  -- Every uv.spawn, whoever calls it: vim.system ends up here too, and
  -- lazy.nvim's checker (one git per plugin) only shows up here. NOT seen:
  -- jobstart, termopen, system(), systemlist() and `:!` (C-level, they never
  -- touch the Lua binding, and Vimscript callers bypass the vim.fn wrappers).
  -- The spawn itself runs on the main thread, ~15 ms each on Windows.
  local procs, procs_n, procs_ms = {}, 0, 0
  wrap(uv, "spawn", function(orig, path, opts, on_exit)
    local t0 = uv.hrtime()
    -- Three values: on failure uv.spawn answers `nil, message, name`.
    local handle, pid, errname = orig(path, opts, on_exit)
    local dt = (uv.hrtime() - t0) / 1e6
    local args = type(opts) == "table" and opts.args or {}
    local head = table.concat(args, " ", 1, math.min(#args, 2))
    local key = vim.fs.basename(tostring(path)) .. " " .. head
    local p = procs[key] or { n = 0, ms = 0, first = (t0 - t_start) / 1e6 }
    p.n, p.ms = p.n + 1, p.ms + dt
    procs[key] = p
    procs_n, procs_ms = procs_n + 1, procs_ms + dt
    return handle, pid, errname
  end)
  dumps[#dumps + 1] = function(out)
    add(
      out,
      "== spawn: %d processes via uv.spawn, %.0f ms of main thread spent spawning",
      procs_n,
      procs_ms
    )
    add(out, "-- not counted: jobstart, termopen, system()/systemlist(), :! (C-level)")
    local keys = vim.tbl_keys(procs)
    table.sort(keys, function(a, b)
      return procs[a].ms > procs[b].ms
    end)
    for i = 1, math.min(#keys, 12) do
      local p = procs[keys[i]]
      add(out, "%8.1f ms  x%-3d first at %7.0f  %s", p.ms, p.n, p.first, keys[i]:sub(1, 70))
    end
    table.sort(log, function(a, b)
      return a.spawn + a.wait > b.spawn + b.wait
    end)
    add(out, "-- through vim.system / vim.fn.system (blocking wait = :wait() on the main thread)")
    for i = 1, math.min(#log, 10) do
      local e = log[i]
      add(
        out,
        "spawn %6.1f ms  blocking wait %6.1f ms  at %7.0f  %s",
        e.spawn,
        e.wait,
        e.at,
        e.cmd:sub(1, 90)
      )
    end
    summary.spawn = { count = procs_n, ms = procs_ms }
  end
end

-- ── fs ──────────────────────────────────────────────────────────────────────
if wanted.fs then
  local acc = {}
  local function track(tbl, name, label)
    -- Forward exactly what `orig` returned, no padding with nils: callers such
    -- as table.insert(t, f()) or vim.fn.g(f()) are sensitive to the count.
    local function finish(t0, ...)
      local e = acc[label] or { n = 0, ms = 0 }
      e.n, e.ms = e.n + 1, e.ms + (uv.hrtime() - t0) / 1e6
      acc[label] = e
      return ...
    end
    wrap(tbl, name, function(orig, ...)
      return finish(uv.hrtime(), orig(...))
    end)
  end
  for _, n in ipairs({
    "glob",
    "globpath",
    "readdir",
    "readfile",
    "filereadable",
    "isdirectory",
    "getcompletion",
    "findfile",
    "finddir",
    "systemlist",
  }) do
    track(vim.fn, n, "fn." .. n)
  end
  for _, n in ipairs({
    "fs_stat",
    "fs_scandir",
    "fs_realpath",
    "fs_open",
    "fs_read",
    "fs_lstat",
    "fs_access",
  }) do
    track(uv, n, "uv." .. n)
  end
  track(vim.api, "nvim_exec2", "api.nvim_exec2")
  dumps[#dumps + 1] = function(out)
    local rows = {}
    for k, v in pairs(acc) do
      rows[#rows + 1] = { k, v }
    end
    table.sort(rows, function(a, b)
      return a[2].ms > b[2].ms
    end)
    add(out, "== fs: C-level calls (cheap alone, costly in bulk)")
    for i = 1, math.min(#rows, 10) do
      add(out, "%8.1f ms  x%-5d %s", rows[i][2].ms, rows[i][2].n, rows[i][1])
    end
  end
end

-- ── marks ───────────────────────────────────────────────────────────────────
if wanted.marks then
  local marks = {}
  vim.api.nvim_create_autocmd({ "VimEnter", "UIEnter" }, {
    callback = function(e)
      marks[#marks + 1] = { e.event, now() }
    end,
  })
  vim.api.nvim_create_autocmd("User", {
    pattern = { "VeryLazy", "LazyDone" },
    callback = function(e)
      marks[#marks + 1] = { "User " .. e.match, now() }
    end,
  })
  dumps[#dumps + 1] = function(out)
    add(out, "== marks (ms since the probe was loaded, i.e. since init.lua started)")
    summary.marks = {}
    for _, m in ipairs(marks) do
      add(out, "%8.0f  %s", m[2], m[1])
      summary.marks[m[1]:gsub("^User ", "")] = m[2]
    end
    if not summary.marks.VeryLazy then
      add(out, "          (no VeryLazy: lazy.nvim waits for UIEnter, which a headless run never")
      add(out, "           gets. Plugins on that event are missing from this run: use tui.lua)")
    end
  end
end

-- ── report ──────────────────────────────────────────────────────────────────
if wanted.report then
  dumps[#dumps + 1] = function(out)
    local ok, report = pcall(require, "startup.report")
    add(out, "== report: startup phases")
    if not ok then
      add(out, "   (startup.report not available: %s)", tostring(report))
      return
    end
    for _, line in ipairs(report.text_lines()) do
      out[#out + 1] = line
    end
    summary.phases = {}
    for _, mark in ipairs(require("startup").marks) do
      summary.phases[mark.label] = { at = mark.at, dur = mark.dur }
    end
  end
end

-- ── driver ──────────────────────────────────────────────────────────────────
vim.api.nvim_create_autocmd("VimEnter", {
  once = true,
  callback = function()
    vim.defer_fn(function()
      local out = {
        ("startup-probe: probes=%s, waited %s ms after VimEnter"):format(
          vim.env.PROBE or "all",
          vim.env.PROBE_MS or "6000"
        ),
        "",
      }
      for _, dump in ipairs(dumps) do
        local ok, err = pcall(dump, out)
        if not ok then
          out[#out + 1] = "probe failed: " .. tostring(err)
        end
        out[#out + 1] = ""
      end
      local path = vim.env.PROBE_OUT or ((vim.env.TEMP or "/tmp") .. "/startup-probe.txt")
      local wrote, err = pcall(function()
        vim.fn.writefile(out, path)
        summary.ui = #vim.api.nvim_list_uis() > 0
        vim.fn.writefile({ vim.json.encode(summary) }, path .. ".json")
      end)
      if not wrote then
        -- A scheduled callback that raises leaves the editor running forever:
        -- say why and quit with a failure instead (tui.lua passes the code on).
        io.stderr:write("startup-probe: " .. tostring(err) .. "\n")
        vim.cmd("1cquit")
      end
      vim.cmd("qa!")
    end, tonumber(vim.env.PROBE_MS) or 6000)
  end,
})
