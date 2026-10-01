---@module 'startup-probe.bench'
--- Several probed starts, then median / min / max of the numbers that say
--- whether a change made the start faster. One run swings by ±40 ms and a cold
--- one by a factor of 2-3: never compare single runs.
---
---   nvim --headless -l scripts/startup-probe/bench.lua [runs] [tui|headless] [args...]
---
--- Defaults: 5 runs, `tui` (see tui.lua for why headless misses VeryLazy).
--- Further arguments go to the probed Neovim, which makes an A/B without
--- touching the config possible: `... 5 tui --cmd "lua vim.g.some_switch = false"`.
--- PROBE defaults to `stall,marks,report`, the cheapest set that yields these
--- numbers; PROBE_MS is passed through. The first run is a warm-up and is not
--- counted.

local runs = tonumber(arg[1]) or 5
local mode = arg[2] or "tui"
assert(mode == "tui" or mode == "headless", "mode is `tui` or `headless`")

local here = debug.getinfo(1, "S").source:sub(2):gsub("\\", "/"):match("^(.*)/[^/]*$")
local out = vim.fn.tempname():gsub("\\", "/") .. ".txt"

local cmd = mode == "tui" and { vim.v.progpath, "--headless", "-l", here .. "/tui.lua" }
  or { vim.v.progpath, "--headless", "--cmd", "luafile " .. here .. "/probe.lua" }
for i = 3, #arg do
  cmd[#cmd + 1] = arg[i]
end
local env = { PROBE = vim.env.PROBE or "stall,marks,report", PROBE_OUT = out }

---@param summary table the decoded `<PROBE_OUT>.json` of one run
---@return table<string, number>
local function metrics(summary)
  local m = {}
  for name, at in pairs(summary.marks or {}) do
    m[name] = at
  end
  local ready = 0
  for _, phase in pairs(summary.phases or {}) do
    if type(phase.at) == "number" and type(phase.dur) == "number" then
      ready = math.max(ready, phase.at + phase.dur)
    end
  end
  m["last phase done"] = ready > 0 and ready or nil
  local stall = summary.stall or {}
  m["stalls > 60 ms"] = stall.count
  m["stalls, sum"] = stall.sum
  m["stalls, longest"] = stall.max
  m["loop busy, sum"] = stall.busy
  for sec, ms in ipairs(stall.busy_per_second or {}) do
    if sec <= 4 then
      m[("loop busy, second %d"):format(sec)] = ms
    end
  end
  return m
end

local ORDER = {
  "LazyDone",
  "VimEnter",
  "UIEnter",
  "last phase done",
  "VeryLazy",
  "stalls > 60 ms",
  "stalls, sum",
  "stalls, longest",
  "loop busy, sum",
  "loop busy, second 1",
  "loop busy, second 2",
  "loop busy, second 3",
  "loop busy, second 4",
}

local samples = {} ---@type table<string, number[]>
for run = 0, runs do
  vim.fn.delete(out .. ".json")
  local res = vim.system(cmd, { env = env, text = true }):wait()
  local ok, lines = pcall(vim.fn.readfile, out .. ".json")
  if res.code ~= 0 or not ok then
    io.stderr:write(("run %d failed (exit %d): %s\n"):format(run, res.code, res.stderr or ""))
    os.exit(1)
  end
  if run > 0 then
    for name, value in pairs(metrics(vim.json.decode(table.concat(lines)))) do
      samples[name] = samples[name] or {}
      table.insert(samples[name], value)
    end
  end
end
vim.fn.delete(out)
vim.fn.delete(out .. ".json")

print(("startup-probe bench: %d runs, %s, PROBE=%s"):format(runs, mode, env.PROBE))
print(("%-22s %9s %9s %9s"):format("", "median", "min", "max"))
for _, name in ipairs(ORDER) do
  local values = samples[name]
  if values then
    table.sort(values)
    local n = #values
    local median = n % 2 == 1 and values[(n + 1) / 2] or (values[n / 2] + values[n / 2 + 1]) / 2
    print(("%-22s %9.0f %9.0f %9.0f"):format(name, median, values[1], values[n]))
  end
end
