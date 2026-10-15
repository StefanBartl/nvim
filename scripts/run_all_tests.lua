-- Run the test suite of every personal plugin and print one row per repo.
--
-- Started by `scripts/run_all_tests.sh` (`nvim -l`). Each migrated repo is run through its own
-- `scripts/test.sh --json <ir>` and the machine-readable result (the IR of testing.nvim: `summary`
-- counts per status) is read back; no sentinel is grepped and no runner is searched for.
--
-- The list of repos is not rebuilt here from a directory glob: it is what the config already knows,
-- `plugins.personal.core.export.projects()` ({ name, repo, dir } of every enabled personal plugin
-- with a checkout on this machine). This script stays in nvim-config/scripts because it depends on
-- that checkout layout (TOOL-PLACEMENT.md, case 5); testing.nvim itself knows nothing of it.
--
-- Exit code: 0 every repo green, 1 at least one repo red, 2 usage error, 3 infrastructure error (a
-- repo without a runner or without testing.nvim, an IR that is missing or unreadable or contradicts
-- the exit code, a run that timed out, a name in --only that is no repo, any error of this script).
-- An infrastructure error is never reported as success and wins over red: the verdict cannot be trusted.
--
-- Usage:  nvim -l scripts/run_all_tests.lua [--only=a.nvim,b.nvim] [--timeout=SECONDS]
--
-- Exceptions, on purpose:
--   * lib.nvim keeps its own runner (decision of 2026-10-06, "Bootstrap circle"): `TESTS/run.lua`,
--     verdict by exit code and the sentinel `LIB_TESTS_OK`.
--   * replacer.nvim has no specs: listed as such, not as a failure.

local uv = vim.uv or vim.loop
local is_windows = vim.fn.has("win32") == 1

--- Repos that have no tests at all (not an infrastructure error).
local NO_SPECS = { ["replacer.nvim"] = true }
--- Repos whose suite runs on its own runner, not on testing.nvim.
local OWN_RUNNER = { ["lib.nvim"] = "LIB_TESTS_OK" }

local STATUSES = { "pass", "fail", "error", "skip", "xfail", "xpass", "timeout", "crash" }

---@param message string
---@param code integer
local function die(message, code)
  io.stderr:write("run_all_tests: " .. message .. "\n")
  os.exit(code)
end

--- The options: `--only=a,b` and `--timeout=SECONDS`, nothing else. A value that cannot be read is
--- refused: a mistyped `--only` that fell back to "every repo" would start a 20 minute run.
---@return table<string, boolean> only
---@return integer timeout_ms
local function parse_args()
  local only, timeout_ms = {}, 900 * 1000
  for _, a in ipairs(_G.arg or {}) do
    local names = a:match("^%-%-only=(.*)$")
    local seconds = a:match("^%-%-timeout=(.*)$")
    if names then
      for name in names:gmatch("[^,]+") do
        only[name] = true
      end
      if next(only) == nil then
        die("--only needs at least one repo name (--only=a.nvim,b.nvim)", 2)
      end
    elseif seconds then
      local n = tonumber(seconds)
      if not n or n ~= n or n <= 0 then
        die("--timeout needs a number of seconds above zero, got '" .. seconds .. "'", 2)
      end
      timeout_ms = math.floor(n * 1000)
    else
      die("unknown argument '" .. a .. "' (usage: [--only=a.nvim,b.nvim] [--timeout=SECONDS])", 2)
    end
  end
  return only, timeout_ms
end

---@return string
local function find_bash()
  if not is_windows then
    return "bash"
  end
  -- `bash` on PATH is often the WSL one, which sees none of these paths.
  for _, candidate in ipairs({
    "C:/Program Files/Git/bin/bash.exe",
    "C:/Program Files/Git/usr/bin/bash.exe",
    "C:/Program Files (x86)/Git/bin/bash.exe",
  }) do
    if uv.fs_stat(candidate) then
      return candidate
    end
  end
  local found = vim.fn.exepath("bash")
  if found:lower():find("system32", 1, true) then
    die("only the WSL bash was found (" .. found .. "); install Git for Windows", 3)
  end
  return found
end

---@return table[] projects
local function projects()
  local config_dir = vim.env.NVIM_CONFIG_DIR
  if not config_dir or config_dir == "" then
    config_dir = vim.fn.stdpath("config")
  end
  local lib = vim.env.LIB_NVIM_DIR
  if not lib or lib == "" then
    lib = (vim.env.REPOS_DIR or "") .. "/lib.nvim"
  end
  vim.opt.rtp:append(config_dir)
  vim.opt.rtp:append(lib)
  local ok, export = pcall(require, "plugins.personal.core.export")
  if not ok then
    die("cannot load plugins.personal.core.export: " .. tostring(export), 3)
  end
  local list, err = export.projects()
  if err then
    die(tostring(err), 3)
  end
  if type(list) ~= "table" then
    die("export.projects() returned no list", 3)
  end
  return list
end

---@param path string
---@return boolean
local function exists(path)
  return uv.fs_stat(path) ~= nil
end

---@class RunRow
---@field repo string
---@field kind "ok"|"red"|"infra"|"none"
---@field counts table<string, integer|string>
---@field secs number
---@field note string

--- Run `argv` and wait at most `timeout_ms`. On a timeout the whole process tree is stopped (the editor that
--- `test.sh` started is a grandchild and would otherwise run on into the next repo) and nil comes back.
---@param argv string[]
---@param opts table
---@param timeout_ms integer
---@return table|nil result  # nil: timed out
local function spawn(argv, opts, timeout_ms)
  local done, res = false, nil
  local obj = vim.system(argv, vim.tbl_extend("force", opts, { text = true }), function(r)
    res, done = r, true
  end)
  vim.wait(timeout_ms, function()
    return done
  end, 50)
  if done then
    return res
  end
  if is_windows then
    -- by the PID of our own child, with its children: never by image name
    vim.system({ "taskkill", "/PID", tostring(obj.pid), "/T", "/F" }):wait(10000)
  end
  pcall(obj.kill, obj, 9)
  vim.wait(5000, function()
    return done
  end, 50)
  return nil
end

--- One repo through `scripts/test.sh --json`.
---@param p table
---@param bash string
---@param timeout_ms integer
---@return RunRow
local function run_testing(p, bash, timeout_ms)
  local ir_file = vim.fn.tempname() .. "-" .. p.name .. ".json"
  local started = uv.hrtime()
  -- The editor's RPC socket must not leak into the child: a spec could reach back into this session.
  local script = 'unset NVIM NVIM_LISTEN_ADDRESS; exec bash scripts/test.sh --json "$1"'
  local res = spawn({ bash, "-c", script, "run_all_tests", ir_file }, { cwd = p.dir }, timeout_ms)
  local secs = (uv.hrtime() - started) / 1e9

  ---@type RunRow
  local row = { repo = p.name, kind = "infra", counts = {}, secs = secs, note = "" }
  local raw
  local f = io.open(ir_file, "rb")
  if f then
    raw = f:read("*a")
    f:close()
  end
  os.remove(ir_file) -- on every path, a timed out run included
  if not res or res.signal ~= 0 or res.code == 124 then
    row.note = ("timed out after %d s"):format(timeout_ms / 1000)
    return row
  end
  -- JSON null stays out of the tables (`luanil`): a null count must not pass for a number
  local ok, ir = pcall(vim.json.decode, raw or "", { luanil = { object = true, array = true } })
  if not raw or raw == "" or not ok or type(ir) ~= "table" or type(ir.summary) ~= "table" then
    local tail = vim.trim(
      ((res.stderr or "") ~= "" and res.stderr or res.stdout or ""):match("([^\n]*)%s*$") or ""
    )
    row.note = ("no result IR (exit %s): %s"):format(tostring(res.code), tail:sub(1, 60))
    return row
  end
  for _, s in ipairs(STATUSES) do
    local v = ir.summary[s]
    if v ~= nil and type(v) ~= "number" then
      row.counts = {}
      row.note = "the IR holds a non-number for '" .. s .. "'"
      return row
    end
    row.counts[s] = v or 0
  end
  local bad = row.counts.fail + row.counts.error + row.counts.timeout + row.counts.crash
  if res.code == 0 and bad == 0 then
    row.kind = "ok"
  elseif res.code == 0 then
    row.note = "exit 0 but the IR holds failures"
  elseif res.code == 1 and bad > 0 then
    row.kind = "red" -- a red run exits 1 and still wrote its IR
  elseif res.code == 1 then
    row.note = "exit 1 but the IR holds no failure"
  else
    row.note = "exit " .. tostring(res.code) .. " (the runner's own error)"
  end
  return row
end

--- lib.nvim: its own runner, verdict by exit code and sentinel.
---@param p table
---@param sentinel string
---@param timeout_ms integer
---@param bash string
---@return RunRow
local function run_own(p, sentinel, timeout_ms, bash)
  local started = uv.hrtime()
  local lib = p.dir
  -- the same RPC-socket hygiene as `run_testing`; nvim's own path is handed over as an argument
  local script =
    'unset NVIM NVIM_LISTEN_ADDRESS; exec "$1" -n --clean --headless -u NONE -c "set rtp+=." -l TESTS/run.lua'
  local res = spawn(
    { bash, "-c", script, "run_all_tests", vim.v.progpath },
    { cwd = p.dir, env = { LIB_NVIM_PATH = lib, LIB_NVIM_DIR = lib } },
    timeout_ms
  )
  ---@type RunRow
  local row = {
    repo = p.name,
    kind = "infra",
    counts = {},
    secs = (uv.hrtime() - started) / 1e9,
    note = "own runner",
  }
  if not res or res.signal ~= 0 or res.code == 124 then
    row.note = "own runner: timed out"
    return row
  end
  local out = (res.stdout or "") .. (res.stderr or "")
  if res.code == 0 and out:find(sentinel, 1, true) then
    row.kind = "ok"
  elseif out:find("spec(s) failed", 1, true) then
    row.kind = "red"
    row.note = "own runner: "
      .. (out:match("(%d+) spec%(s%) failed") or "?")
      .. " spec file(s) failed"
  else
    row.note = "own runner: no verdict (exit " .. tostring(res.code) .. ")"
  end
  return row
end

local function main()
  local only, timeout_ms = parse_args()
  local bash = find_bash()
  if bash == "" then
    die("no bash found", 3)
  end

  local known = {}
  local rows = {} ---@type RunRow[]
  for _, p in ipairs(projects()) do
    known[p.name] = true
    if next(only) == nil or only[p.name] then
      local row
      if NO_SPECS[p.name] then
        row = { repo = p.name, kind = "none", counts = {}, secs = 0, note = "no specs" }
      elseif OWN_RUNNER[p.name] then
        row = run_own(p, OWN_RUNNER[p.name], timeout_ms, bash)
      elseif not exists(p.dir .. "/scripts/test.sh") then
        row = {
          repo = p.name,
          kind = "infra",
          counts = {},
          secs = 0,
          note = exists(p.dir .. "/TESTS") and "TESTS/ but no scripts/test.sh"
            or "no runner (no scripts/test.sh)",
        }
      else
        row = run_testing(p, bash, timeout_ms)
      end
      rows[#rows + 1] = row
      -- shown as they finish: a full run takes a while
      io.stdout:write(("  ... %s: %s\n"):format(row.repo, row.kind))
      io.stdout:flush()
    end
  end

  -- a name that is no repo (a typo) must not turn into "nothing ran, all green"
  local unknown = {}
  for name in pairs(only) do
    if not known[name] then
      unknown[#unknown + 1] = name
    end
  end
  table.sort(unknown)
  if #unknown > 0 then
    rows[#rows + 1] = {
      repo = table.concat(unknown, ","),
      kind = "infra",
      counts = {},
      secs = 0,
      note = "--only names no repo of export.projects()",
    }
  end
  if #rows == 0 then
    die("no repo to run: export.projects() is empty", 3)
  end

  local labels = { ok = "green", red = "RED", infra = "INFRA", none = "-" }
  local head_cells = {}
  for _, st in ipairs(STATUSES) do
    head_cells[#head_cells + 1] = ("%5s"):format(st)
  end
  io.stdout:write(
    ("\n%-24s %-6s %s %6s  %s\n"):format(
      "repo",
      "result",
      table.concat(head_cells, " "),
      "secs",
      "note"
    )
  )
  local any_red, any_infra = false, false
  local totals = {}
  for _, s in ipairs(STATUSES) do
    totals[s] = 0
  end
  for _, row in ipairs(rows) do
    local cells = {}
    for _, s in ipairs(STATUSES) do
      local v = row.counts[s]
      cells[#cells + 1] = ("%5s"):format(v == nil and "-" or tostring(v))
      if type(v) == "number" then
        totals[s] = totals[s] + v
      end
    end
    io.stdout:write(
      ("%-24s %-6s %s %6.1f  %s\n"):format(
        row.repo,
        labels[row.kind],
        table.concat(cells, " "),
        row.secs,
        row.note
      )
    )
    any_red = any_red or row.kind == "red"
    any_infra = any_infra or row.kind == "infra"
  end
  local tcells = {}
  for _, s in ipairs(STATUSES) do
    tcells[#tcells + 1] = ("%5d"):format(totals[s])
  end
  io.stdout:write(("%-24s %-6s %s\n"):format("TOTAL", "", table.concat(tcells, " ")))

  if any_infra then
    io.stdout:write("\nINFRASTRUCTURE ERROR: at least one repo could not be judged (exit 3).\n")
    os.exit(3)
  elseif any_red then
    io.stdout:write("\nRED (exit 1).\n")
    os.exit(1)
  end
  io.stdout:write("\nALL GREEN\n")
  os.exit(0)
end

-- Any error of this script is an infrastructure error, never the "red" exit code 1 that nvim uses for it.
local ok, err = xpcall(main, debug.traceback)
if not ok then
  io.stderr:write("run_all_tests: internal error: " .. tostring(err) .. "\n")
  os.exit(3)
end
