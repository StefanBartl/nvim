---@module 'benchmarks.main'
---@brief Unified benchmarking interface
---@description
--- Central entry point for all benchmark suites.
--- Supports multiple output formats: notify, file, return table.

local notify = require("lib.notify").create("[benchmarks]")

local M = {}

local tbl_insert, tbl_concat = table.insert, table.concat
local str_fmt = string.format
local nvim_create_user_command = vim.api.nvim_create_user_command

local default_opts = {
  output = "both",
  format = "markdown",
  verbose = true,
  DEFAULT_REPORT_DIR =  vim.fn.stdpath("config") .. "/docs/BENCHMARKS/reports"
}

--- Format timestamp
---@return string
local function timestamp()
  return tostring(os.date("%Y-%m-%d %H:%M:%S"))
end

--- Get report directory
---@return string
local function get_report_dir()
  local dir = default_opts.DEFAULT_REPORT_DIR
  vim.fn.mkdir(dir, "p")
  return dir
end

--- Format results as markdown
---@param result Benchmarks.Result
---@return string
local function format_markdown(result)
  local lines = {
    "# " .. result.suite_name,
    "",
    "**Timestamp:** " .. result.timestamp,
    "**Status:** " .. (result.success and "✅ PASSED" or "❌ FAILED"),
    "",
  }

  if result.summary then
    tbl_insert(lines, "## Summary")
    tbl_insert(lines, "")
    for k, v in pairs(result.summary) do
      tbl_insert(lines, str_fmt("- **%s:** %s", k, tostring(v)))
    end
    tbl_insert(lines, "")
  end

  if result.results and #result.results > 0 then
    tbl_insert(lines, "## Detailed Results")
    tbl_insert(lines, "")
    tbl_insert(lines, "| Metric | Value |")
    tbl_insert(lines, "|--------|-------|")
    for _, item in ipairs(result.results) do
      for k, v in pairs(item) do
        tbl_insert(lines, str_fmt("| %s | %s |", k, tostring(v)))
      end
    end
  end

  return tbl_concat(lines, "\n")
end

--- Format results as CSV
---@param result Benchmarks.Result
---@return string
local function format_csv(result)
  local lines = {
    "suite,timestamp,success",
    str_fmt("%s,%s,%s", result.suite_name, result.timestamp, result.success),
    "",
  }

  if result.results and #result.results > 0 then
    -- Extract all unique keys
    local keys = {}
    for _, item in ipairs(result.results) do
      for k in pairs(item) do
        if not vim.tbl_contains(keys, k) then
          tbl_insert(keys, k)
        end
      end
    end

    tbl_insert(lines, tbl_concat(keys, ","))
    for _, item in ipairs(result.results) do
      local values = {}
      for _, k in ipairs(keys) do
        tbl_insert(values, tostring(item[k] or ""))
      end
      tbl_insert(lines, tbl_concat(values, ","))
    end
  end

  return tbl_concat(lines, "\n")
end

--- Format results as JSON
---@param result Benchmarks.Result
---@return string
local function format_json(result)
  return vim.json.encode(result)
end

--- Write results to file
---@param content string
---@param filename string
---@return string filepath
local function write_to_file(content, filename)
  local dir = get_report_dir()
  local filepath = dir .. "/" .. filename

  local file = io.open(filepath, "w")
  if not file then
    error("Failed to open file: " .. filepath)
  end

  file:write(content)
  file:close()

  return filepath
end

--- Show results via notify
---@param result Benchmarks.Result
---@param content string
local function show_notify(result, content)
  local level = result.success and "info" or "error"
  local icon = result.success and "✅" or "❌"

  -- Truncate content for notify (max 500 chars)
  local summary = content:sub(1, 500)
  if #content > 500 then
    summary = summary .. "\n\n[Truncated. See report file for full results]"
  end

  notify[level](str_fmt("%s %s\n\n%s", icon, result.suite_name, summary))
end

--- Run benchmark suite
---@param suite_name string
---@param run_fn function Function that returns Benchmarks.Result
---@param opts Benchmarks.Options?
---@return Benchmarks.Result
function M.run_suite(suite_name, run_fn, opts)
  opts = vim.tbl_deep_extend("force", default_opts, opts or {})

  if opts.verbose then
    notify.info("🚀 Running benchmark: " .. suite_name)
  end

  local start_time = vim.loop.hrtime()
  local success, result = pcall(run_fn)
  local elapsed = (vim.loop.hrtime() - start_time) / 1e6 -- ms

  if not success then
    result = {
      suite_name = suite_name,
      timestamp = timestamp(),
      success = false,
      results = {},
      summary = { error = tostring(result) },
    }
  end

  result.suite_name = suite_name
  result.timestamp = timestamp()
  result.summary = result.summary or {}
  result.summary.duration_ms = str_fmt("%.2f", elapsed)

  -- Format content
  local content
  if opts.format == "markdown" then
    content = format_markdown(result)
  elseif opts.format == "csv" then
    content = format_csv(result)
  elseif opts.format == "json" then
    content = format_json(result)
  end

  -- Handle output
  if opts.output == "file" or opts.output == "both" then
    local ext = opts.format == "json" and ".json" or (opts.format == "csv" and ".csv" or ".md")
    local filename = str_fmt("%s_%s%s",
      suite_name:lower():gsub("%s+", "_"),
      os.date("%Y%m%d_%H%M%S"),
      ext
    )

    local filepath = write_to_file(content, filename)
    result.summary.report_file = filepath

    if opts.verbose then
      notify.info("📄 Report saved: " .. filepath)
    end
  end

  if opts.output == "notify" or opts.output == "both" then
    show_notify(result, content)
  end

  return result
end

--- Run autocmds baseline suite
---@param opts Benchmarks.Options?
---@return Benchmarks.Result
function M.autocmds_baseline(opts)
  local suite = require("benchmarks.autocmds.baseline_suite")

  return M.run_suite("Autocmds Baseline", function()
    local filepath = suite.run_all()

    return {
      success = true,
      results = suite.results or {},
      summary = {
        total_events = #(suite.results or {}),
        report_file = filepath,
      },
    }
  end, opts)
end

--- Run Phase 0 tests
---@param opts Benchmarks.Options?
---@return Benchmarks.Result
function M.phase0_tests(opts)
  local suite = require("benchmarks.autocmds.phase0_tests")

  return M.run_suite("Phase 0 Tests", function()
    local success = suite.run_all()

    return {
      success = success,
      results = {},
      summary = {
        buffer_ctx_stats = require("autocmds.benchmarks.context.buffer").get_stats(),
        window_ctx_stats = require("autocmds.benchmarks.context.window").get_stats(),
      },
    }
  end, opts)
end

--- Run all benchmark suites
---@param opts Benchmarks.Options?
---@return Benchmarks.Result[]
function M.run_all(opts)
  local results = {}

  tbl_insert(results, M.autocmds_baseline(opts))
  tbl_insert(results, M.phase0_tests(opts))

  -- Summary
  local total = #results
  local passed = 0
  for _, r in ipairs(results) do
    if r.success then passed = passed + 1 end
  end

  notify.info(str_fmt("📊 Benchmark Summary: %d/%d suites passed", passed, total))

  return results
end

--- User commands
function M.setup_commands()
  nvim_create_user_command("BenchAutocmdsBaseline", function()
    M.autocmds_baseline({ output = "both", verbose = true })
  end, { desc = "Run autocmds baseline benchmarks" })

  nvim_create_user_command("BenchPhase0", function()
    M.phase0_tests({ output = "both", verbose = true })
  end, { desc = "Run Phase 0 tests" })

  nvim_create_user_command("BenchAll", function()
    M.run_all({ output = "both", verbose = true })
  end, { desc = "Run all benchmarks" })
end

return M
