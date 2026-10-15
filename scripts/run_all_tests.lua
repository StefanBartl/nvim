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
-- Exit code: 0 every repo green, 1 at least one repo red, 3 infrastructure error (a repo without a
-- runner or without testing.nvim, an IR that is missing or unreadable, a run that timed out). An
-- infrastructure error is never reported as success and wins over red: the verdict cannot be trusted.
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

---@param name string
---@return string|nil
local function arg_of(name)
  for _, a in ipairs(_G.arg or {}) do
    local v = a:match("^%-%-" .. name .. "=(.*)$")
    if v then
      return v
    end
  end
  return nil
end

---@return string
local function find_bash()
  if not is_windows then
    return "bash"
  end
  -- `bash` on PATH is often the WSL one, which sees none of these paths.
  for _, candidate in ipairs({
    vim.env.BASH,
    "C:/Program Files/Git/bin/bash.exe",
    "C:/Program Files/Git/usr/bin/bash.exe",
  }) do
    if candidate and candidate ~= "" and uv.fs_stat(candidate) then
      return candidate
    end
  end
  return vim.fn.exepath("bash")
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
    io.stderr:write(
      "run_all_tests: cannot load plugins.personal.core.export: " .. tostring(export) .. "\n"
    )
    os.exit(3)
  end
  local list, err = export.projects()
  if err then
    io.stderr:write("run_all_tests: " .. tostring(err) .. "\n")
    os.exit(3)
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
  local res = vim
    .system({ bash, "-c", script, "run_all_tests", ir_file }, {
      cwd = p.dir,
      text = true,
      timeout = timeout_ms,
    })
    :wait()
  local secs = (uv.hrtime() - started) / 1e9

  ---@type RunRow
  local row = { repo = p.name, kind = "infra", counts = {}, secs = secs, note = "" }
  -- `wait()` gives nothing at all for a process killed by the timeout (observed on Windows)
  if not res or res.signal ~= 0 or res.code == 124 then
    row.note = ("timed out after %d s"):format(timeout_ms / 1000)
    return row
  end
  local f = io.open(ir_file, "rb")
  local raw = f and f:read("*a")
  if f then
    f:close()
  end
  os.remove(ir_file)
  local ok, ir = pcall(vim.json.decode, raw or "")
  if not raw or raw == "" or not ok or type(ir) ~= "table" or type(ir.summary) ~= "table" then
    local tail = vim.trim(
      ((res.stderr or "") ~= "" and res.stderr or res.stdout or ""):match("([^\n]*)%s*$") or ""
    )
    row.note = ("no result IR (exit %s): %s"):format(tostring(res.code), tail:sub(1, 60))
    return row
  end
  for _, s in ipairs(STATUSES) do
    row.counts[s] = ir.summary[s] or 0
  end
  local bad = row.counts.fail + row.counts.error + row.counts.timeout + row.counts.crash
  if res.code == 0 and bad == 0 then
    row.kind = "ok"
  elseif res.code == 1 or bad > 0 then
    -- a red run exits 1 and still wrote its IR
    row.kind = res.code == 0 and "infra" or "red"
    row.note = res.code == 0 and "exit 0 but the IR holds failures" or ""
  else
    row.note = "exit " .. tostring(res.code)
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
  local res = vim
    .system({ bash, "-c", script, "run_all_tests", vim.v.progpath }, {
      cwd = p.dir,
      text = true,
      timeout = timeout_ms,
      env = { LIB_NVIM_PATH = lib, LIB_NVIM_DIR = lib },
    })
    :wait()
  if not res then
    return {
      repo = p.name,
      kind = "infra",
      counts = {},
      secs = (uv.hrtime() - started) / 1e9,
      note = "own runner: timed out",
    }
  end
  local out = (res.stdout or "") .. (res.stderr or "")
  ---@type RunRow
  local row = {
    repo = p.name,
    kind = "infra",
    counts = {},
    secs = (uv.hrtime() - started) / 1e9,
    note = "own runner",
  }
  if res.signal ~= 0 or res.code == 124 then
    row.note = "own runner: timed out"
  elseif res.code == 0 and out:find(sentinel, 1, true) then
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
  local only = {}
  local only_arg = arg_of("only")
  if only_arg then
    for name in only_arg:gmatch("[^,]+") do
      only[name] = true
    end
  end
  local timeout_ms = (tonumber(arg_of("timeout")) or 900) * 1000
  local bash = find_bash()
  if bash == "" then
    io.stderr:write("run_all_tests: no bash found\n")
    os.exit(3)
  end

  local rows = {} ---@type RunRow[]
  for _, p in ipairs(projects()) do
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

main()
