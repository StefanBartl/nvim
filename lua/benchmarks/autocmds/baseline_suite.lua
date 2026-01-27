---@module 'benchmarks.autocmds.baseline_suite'
---@brief Baseline performance measurement for autocmd refactoring
---@description
--- Run this BEFORE refactoring to establish baseline metrics.
--- Usage: :lua require('benchmarks.autocmds.baseline_suite').run_all()

local M = {}

local api, uv, cmd, bo = vim.api, vim.uv or vim.loop, vim.cmd, vim.bo
local os_date = os.date
local tbl_insert = table.insert
local str_fmt = string.format
local nvim_buf_delete = api.nvim_buf_delete

local results = {}

--- High-precision timer wrapper
---@return number milliseconds
local function now_ms()
  return uv.hrtime() / 1e6
end

--- Calculate standard deviation
---@param samples number[]
---@param mean number
---@return number
local function stddev(samples, mean)
  local sum = 0
  for _, v in ipairs(samples) do
    sum = sum + (v - mean) ^ 2
  end
  return math.sqrt(sum / #samples)
end

--- Create test buffer with realistic content
---@return integer bufnr
local function create_test_buffer()
  local bufnr = api.nvim_create_buf(false, true)

  -- Simulate realistic file content (1000 lines)
  local lines = {}
  for i = 1, 1000 do
    lines[i] = str_fmt("-- Line %d: %s", i, string.rep("x", 80))
  end
  api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

  -- Set realistic options
  bo[bufnr].filetype = "lua"
  bo[bufnr].buftype = ""

  return bufnr
end

--- Benchmark a single event
---@param event_name string
---@param setup function?
---@param iterations integer?
---@return Benchmarks.BaselineSuite.Result
function M.bench_event(event_name, setup, iterations)
  iterations = iterations or 1000
  local samples = {}

  -- Setup phase
  if setup then setup() end

  -- Warmup (10% of iterations)
  for _ = 1, math.floor(iterations * 0.1) do
    cmd("doautocmd " .. event_name)
  end

  -- Actual benchmark
  for i = 1, iterations do
    local start = now_ms()
    cmd("doautocmd " .. event_name)
    local elapsed = now_ms() - start
    samples[i] = elapsed
  end

  -- Calculate statistics
  table.sort(samples)
  local total = 0
  for _, v in ipairs(samples) do
    total = total + v
  end
  local avg = total / iterations

  local result = {
    event = event_name,
    iterations = iterations,
    total_ms = total,
    avg_ms = avg,
    min_ms = samples[1],
    max_ms = samples[iterations],
    stddev_ms = stddev(samples, avg),
    timestamp = os_date("%Y-%m-%d %H:%M:%S"),
  }

  tbl_insert(results, result)

  ---@type Benchmarks.BaselineSuite.Result
  return result
end

--- Benchmark CursorMoved (critical hot path)
function M.bench_cursor_moved()
  local bufnr = create_test_buffer()
  local winid = api.nvim_get_current_win()

  local function setup()
    api.nvim_win_set_buf(winid, bufnr)
    api.nvim_win_set_cursor(winid, {500, 0})
  end

  local result = M.bench_event("CursorMoved", setup, 1000)

  nvim_buf_delete(bufnr, {force = true})
  return result
end

--- Benchmark BufEnter
function M.bench_buf_enter()
  local bufnr = create_test_buffer()

  local function setup()
    -- Simulate buffer switching
    cmd("buffer " .. bufnr)
  end

  local result = M.bench_event("BufEnter", setup, 500)

  nvim_buf_delete(bufnr, {force = true})
  return result
end

--- Benchmark BufWinEnter
function M.bench_buf_win_enter()
  local result = M.bench_event("BufWinEnter", function()
    create_test_buffer()
  end, 500)
  return result
end

--- Benchmark BufWritePre
function M.bench_buf_write_pre()
  local bufnr = create_test_buffer()
  bo[bufnr].modified = true

  local function setup()
    api.nvim_set_current_buf(bufnr)
  end

  local result = M.bench_event("BufWritePre", setup, 200)

  nvim_buf_delete(bufnr, {force = true})
  return result
end

--- Benchmark FileType
function M.bench_filetype()
  local result = M.bench_event("FileType", function()
    local bufnr = create_test_buffer()
    api.nvim_set_current_buf(bufnr)
  end, 200)
  return result
end

--- Benchmark ColorScheme
function M.bench_colorscheme()
  local result = M.bench_event("ColorScheme", nil, 100)
  return result
end

--- Format result as table row
---@param result Benchmarks.BaselineSuite.Result
---@return string
local function format_result(result)
  return str_fmt(
    "| %-20s | %6d | %8.3f | %8.3f | %8.3f | %8.3f | %8.3f |",
    result.event,
    result.iterations,
    result.total_ms,
    result.avg_ms,
    result.min_ms,
    result.max_ms,
    result.stddev_ms
  )
end

--- Generate markdown report
---@return string
local function generate_report()
  local lines = {
    "# Autocmd Baseline Performance Report",
    "",
    "**Timestamp:** " .. os_date("%Y-%m-%d %H:%M:%S"),
    "**Neovim Version:** " .. vim.version().major .. "." .. vim.version().minor .. "." .. vim.version().patch,
    "**System:** " .. uv.os_uname().sysname .. " " .. uv.os_uname().machine,
    "",
    "## Results",
    "",
    "| Event                | Iterations | Total (ms) | Avg (ms) | Min (ms) | Max (ms) | StdDev (ms) |",
    "|----------------------|------------|------------|----------|----------|----------|-------------|",
  }

  for _, result in ipairs(results) do
    tbl_insert(lines, format_result(result))
  end

  tbl_insert(lines, "")
  tbl_insert(lines, "## Raw Data (CSV)")
  tbl_insert(lines, "")
  tbl_insert(lines, "```csv")
  tbl_insert(lines, "event,iterations,total_ms,avg_ms,min_ms,max_ms,stddev_ms,timestamp")

  for _, result in ipairs(results) do
    tbl_insert(lines, str_fmt(
      "%s,%d,%.6f,%.6f,%.6f,%.6f,%.6f,%s",
      result.event,
      result.iterations,
      result.total_ms,
      result.avg_ms,
      result.min_ms,
      result.max_ms,
      result.stddev_ms,
      result.timestamp
    ))
  end

  tbl_insert(lines, "```")
  tbl_insert(lines, "")

  return table.concat(lines, "\n")
end

--- Save report to file
---@param filepath string
local function save_report(filepath)
  local report = generate_report()
  local file = io.open(filepath, "w")
  if not file then
    error("Failed to open file: " .. filepath)
  end
  file:write(report)
  file:close()
end

--- Run all benchmarks and save report
---@param silent boolean? Suppress print output
---@return string filepath, Benchmarks.BaselineSuite.Result[] results
function M.run_all(silent)
  if not silent then
    print("🚀 Starting baseline benchmark suite...")
    print("This will take ~2-3 minutes...")
    print("")
  end

  results = {} -- Reset

  local benchmarks = {
    { name = "CursorMoved (CRITICAL)", fn = M.bench_cursor_moved },
    { name = "BufEnter (HIGH)", fn = M.bench_buf_enter },
    { name = "BufWinEnter (HIGH)", fn = M.bench_buf_win_enter },
    { name = "BufWritePre (MEDIUM)", fn = M.bench_buf_write_pre },
    { name = "FileType (MEDIUM)", fn = M.bench_filetype },
    { name = "ColorScheme (LOW)", fn = M.bench_colorscheme },
  }

  for i, bench in ipairs(benchmarks) do
    if not silent then
      print(str_fmt("[%d/%d] Benchmarking %s...", i, #benchmarks, bench.name))
    end
    local result = bench.fn()
    if not silent then
      print(str_fmt("  ✓ Avg: %.3fms | Min: %.3fms | Max: %.3fms",
        result.avg_ms, result.min_ms, result.max_ms))
    end
  end

  if not silent then
    print("")
    print("📊 Generating report...")
  end

  local report_dir = vim.fn.stdpath("data") .. "/bench_reports"
  vim.fn.mkdir(report_dir, "p")

  local filepath = report_dir .. "/baseline_" .. os_date("%Y%m%d_%H%M%S") .. ".md"
  save_report(filepath)

  if not silent then
    print("✅ Report saved to: " .. filepath)
    print("")
    print("Summary:")
    print(generate_report())
  end

  return filepath, results
end

--- Quick benchmark for single event (for testing)
---@param event_name string
---@param iterations integer?
function M.quick(event_name, iterations)
  local result = M.bench_event(event_name, nil, iterations or 100)
  print(format_result(result))
  return result
end

return M
