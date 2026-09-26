---@module 'startup-probe'
--- Startup probes for this config. One file, selectable probes, one report.
---
--- Runs BEFORE init.lua (`--cmd`), wraps what it measures, waits until the
--- editor is really up (VimEnter + PROBE_MS) and only then writes the report.
--- That last part matters: `-c` commands run BEFORE VimEnter, so anything
--- measured with `-c "... vim.wait(..)"` never sees the UIReady phases or the
--- post-VimEnter work (menu prewarm, VeryLazy plugins). See README.md.
---
---   PROBE=req,exe,rtp,stall,spawn,fs,marks,report   (default: all)
---   PROBE_MS=6000                                   ms to wait after VimEnter
---   PROBE_OUT=<path>                                report file (default: $TEMP/startup-probe.txt)
---
---   nvim --headless --cmd "luafile scripts/startup-probe/probe.lua"
---
--- Probes:
---   req     exclusive require time per module / namespace, top-level requires
---           that block for a long time, modules loaded
---   exe     vim.fn.executable / exepath calls: count, time, found or not
---   rtp     nvim_get_runtime_file calls (vim.loader recomputes the runtimepath
---           list on every 'runtimepath' change -- one call per plugin load)
---   stall   event-loop stalls (a 10 ms heartbeat that finds gaps > 60 ms)
---   spawn   vim.system / vim.fn.system: spawn cost and blocking wait
---   fs      other C-level calls that are cheap alone and not in bulk
---   marks   when VimEnter / UIEnter / LazyDone happened
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
for name in (vim.env.PROBE or "req,exe,rtp,stall,spawn,fs,marks,report"):gmatch("[^,%s]+") do
  wanted[name] = true
end

local dumps = {} ---@type (fun(out: string[]))[]

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
  _G.require = function(name)
    if package.loaded[name] ~= nil then
      return orig_require(name)
    end
    local t0 = uv.hrtime()
    stack[#stack + 1] = { child = 0 }
    local ok, res = pcall(orig_require, name)
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
      local c = calls[key] or { n = 0, ms = 0, found = (r ~= 0 and r ~= "") }
      c.n, c.ms = c.n + 1, c.ms + dt
      calls[key] = c
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
if wanted.stall then
  local last, stalls = nil, {}
  local timer = uv.new_timer()
  timer:start(
    0,
    10,
    vim.schedule_wrap(function()
      local t = now()
      if last and t - last > 60 then
        stalls[#stalls + 1] = { at = last, gap = t - last }
      end
      last = t
    end)
  )
  dumps[#dumps + 1] = function(out)
    local sum = 0
    for _, s in ipairs(stalls) do
      sum = sum + s.gap
    end
    add(out, "== stall: %d event-loop stalls > 60 ms, %.0f ms blocked in total", #stalls, sum)
    table.sort(stalls, function(a, b)
      return a.gap > b.gap
    end)
    for i = 1, math.min(#stalls, 8) do
      add(out, "%8.0f ms  starting at %7.0f", stalls[i].gap, stalls[i].at)
    end
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
  dumps[#dumps + 1] = function(out)
    table.sort(log, function(a, b)
      return a.spawn + a.wait > b.spawn + b.wait
    end)
    add(out, "== spawn: %d processes", #log)
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
  end
end

-- ── fs ──────────────────────────────────────────────────────────────────────
if wanted.fs then
  local acc = {}
  local function track(tbl, name, label)
    wrap(tbl, name, function(orig, ...)
      local t0 = uv.hrtime()
      local a, b, c, d = orig(...)
      local e = acc[label] or { n = 0, ms = 0 }
      e.n, e.ms = e.n + 1, e.ms + (uv.hrtime() - t0) / 1e6
      acc[label] = e
      return a, b, c, d
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
    for _, m in ipairs(marks) do
      add(out, "%8.0f  %s", m[2], m[1])
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
      vim.fn.writefile(out, path)
      vim.cmd("qa!")
    end, tonumber(vim.env.PROBE_MS) or 6000)
  end,
})
