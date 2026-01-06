---@module 'debugging.performance'
---@brief Performance benchmarking module with commands and HTML reporting

local M = {}

-- Configuration
local config = {
  script_dir = vim.fn.stdpath("config") .. "/lua/debugging/performance/scripts",
  results_dir = vim.fn.stdpath("config") .. "/lua/debugging/performance/results",
  csv_dir = vim.fn.stdpath("config") .. "/lua/debugging/performance/results/csv",
  html_dir = vim.fn.stdpath("config") .. "/lua/debugging/performance/results/html",
  default_runs = 15,
}

-- Ensure directories exist
local function ensure_dirs()
  for _, dir in ipairs({ config.results_dir, config.csv_dir, config.html_dir }) do
    vim.fn.mkdir(dir, "p")
  end
end

-- Get benchmark script path based on OS
local function get_benchmark_script()
  local is_windows = vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1
  return config.script_dir .. (is_windows and "/benchmark_nvim.ps1" or "/benchmark_nvim.sh")
end

-- Run benchmark
function M.run_benchmark(opts)
  opts = opts or {}
  local runs = opts.runs or config.default_runs
  local skip_warmup = opts.skip_warmup or false
  local debug = opts.debug or false

  ensure_dirs()

  local script = get_benchmark_script()
  if vim.fn.filereadable(script) ~= 1 then
    vim.notify("Benchmark script not found: " .. script, vim.log.levels.ERROR)
    return
  end

  -- Open terminal split to show live output
  vim.cmd("split")
  vim.cmd("resize 15")
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(0, buf)
  vim.bo[buf].bufhidden = "wipe"

  local cmd
  if vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
    cmd = {
      "powershell",
      "-NoProfile",
      "-ExecutionPolicy",
      "Bypass",
      "-File",
      script,
      "-Runs",
      tostring(runs),
    }
    if skip_warmup then
      table.insert(cmd, "-SkipWarmup")
    end
    if debug then
      table.insert(cmd, "-Debug")
    end
  else
    cmd = { script, tostring(runs) }
    if skip_warmup then
      table.insert(cmd, "--skip-warmup")
    end
    if debug then
      table.insert(cmd, "--debug")
    end
  end

  vim.notify("Starting benchmark with " .. runs .. " runs...", vim.log.levels.INFO)

  local output_lines = {}

  vim.fn.termopen(cmd, {
    on_stdout = function(_, data)
      for _, line in ipairs(data) do
        if line ~= "" then
          table.insert(output_lines, line)
        end
      end
    end,
    on_exit = function(_, code)
      vim.schedule(function()
        if code == 0 then
          vim.notify("✅ Benchmark completed successfully! Check results above.", vim.log.levels.INFO)
          -- Auto-close terminal after 3 seconds
          vim.defer_fn(function()
            if vim.api.nvim_buf_is_valid(buf) then
              vim.api.nvim_buf_delete(buf, { force = true })
            end
          end, 3000)
        else
          vim.notify("❌ Benchmark failed with code " .. code, vim.log.levels.ERROR)
          vim.notify("Terminal will stay open. Press 'q' to close.", vim.log.levels.WARN)
          -- Make terminal buffer deletable with 'q'
          vim.api.nvim_buf_set_keymap(buf, "n", "q", ":bdelete!<CR>", { noremap = true, silent = true })
        end
      end)
    end,
  })

  -- Make it easier to close terminal
  vim.api.nvim_buf_set_keymap(buf, "n", "q", ":bdelete!<CR>", { noremap = true, silent = true })
  vim.api.nvim_buf_set_keymap(buf, "n", "<Esc>", ":bdelete!<CR>", { noremap = true, silent = true })
end

-- Get list of benchmark CSV files
local function get_benchmark_files()
  local files = vim.fn.glob(config.csv_dir .. "/nvim_benchmark_*.csv", false, true)
  table.sort(files, function(a, b)
    return a > b
  end) -- Sort newest first
  return files
end

-- Parse CSV file (FIXED: handles both comma and dot decimal separators)
local function parse_csv(filepath)
  local file = io.open(filepath, "r")
  if not file then
    vim.notify("Failed to open CSV: " .. filepath, vim.log.levels.ERROR)
    return nil
  end

  local lines = {}
  for line in file:lines() do
    table.insert(lines, line)
  end
  file:close()

  if #lines < 2 then
    vim.notify("CSV file has insufficient data: " .. filepath, vim.log.levels.WARN)
    return nil
  end

  -- Parse data rows (skip header)
  local data = { startup = {}, uienter = {}, memory = {} }
  local parse_count = 0

  for i = 2, #lines do
    -- Match both formats: "1","652,75","1003,34","745,53" or "1","652.75","1003.34","745.53"
    local run, startup, uienter, memory = lines[i]:match('"([^"]+)","([^"]+)","([^"]+)","([^"]+)"')

    if run and startup and uienter then
      -- Normalize decimal separator: replace comma with dot
      startup = startup:gsub(",", ".")
      uienter = uienter:gsub(",", ".")
      memory = memory and memory:gsub(",", ".") or "0"

      -- Convert to numbers
      local s = tonumber(startup)
      local u = tonumber(uienter)
      local m = tonumber(memory)

      if s and u and m then
        table.insert(data.startup, s)
        table.insert(data.uienter, u)
        table.insert(data.memory, m)
        parse_count = parse_count + 1
      else
        vim.notify(string.format("Failed to parse line %d: %s", i, lines[i]), vim.log.levels.DEBUG)
      end
    end
  end

  if parse_count == 0 then
    vim.notify("No valid data rows parsed from CSV", vim.log.levels.ERROR)
    return nil
  end

  vim.notify(string.format("Successfully parsed %d data rows", parse_count), vim.log.levels.DEBUG)
  return data
end

-- Calculate statistics
local function calc_stats(values)
  if #values == 0 then
    return { mean = 0, median = 0, min = 0, max = 0, stddev = 0 }
  end

  local sorted = vim.deepcopy(values)
  table.sort(sorted)

  local sum = 0
  for _, v in ipairs(sorted) do
    sum = sum + v
  end
  local mean = sum / #sorted

  local median
  if #sorted % 2 == 1 then
    median = sorted[math.ceil(#sorted / 2)]
  else
    median = (sorted[#sorted / 2] + sorted[#sorted / 2 + 1]) / 2
  end

  local variance = 0
  for _, v in ipairs(sorted) do
    variance = variance + (v - mean) ^ 2
  end
  variance = variance / #sorted
  local stddev = math.sqrt(variance)

  return {
    mean = math.floor(mean * 100 + 0.5) / 100,
    median = math.floor(median * 100 + 0.5) / 100,
    min = sorted[1],
    max = sorted[#sorted],
    stddev = math.floor(stddev * 100 + 0.5) / 100,
  }
end

-- Generate HTML report
function M.generate_html_report(filepath)
  local data = parse_csv(filepath)
  if not data then
    vim.notify("Failed to parse CSV: " .. filepath, vim.log.levels.ERROR)
    return
  end

  local startup_stats = calc_stats(data.startup)
  local uienter_stats = calc_stats(data.uienter)
  local memory_stats = calc_stats(data.memory)

  -- Debug output
  vim.notify(string.format("Stats - Startup: %.2f ms, UI: %.2f ms, Memory: %.2f KB",
    startup_stats.mean, uienter_stats.mean, memory_stats.mean), vim.log.levels.DEBUG)

  -- Try to load metadata for plugin info
  local meta_path = filepath:gsub("%.csv$", "_meta.json")
  local slow_plugins = {}
  local plugin_count = 0

  pcall(function()
    local meta_file = io.open(meta_path, "r")
    if meta_file then
      local meta_content = meta_file:read("*all")
      meta_file:close()
      local meta = vim.fn.json_decode(meta_content)
      if meta and meta.plugins then
        plugin_count = meta.plugins.average_count or 0
        slow_plugins = meta.plugins.slow_plugins or {}
      end
    end
  end)

  -- Get last 5 benchmarks for comparison
  local files = get_benchmark_files()
  local comparisons = {}
  for i = 2, math.min(6, #files) do
    if files[i] ~= filepath then -- Don't compare with self
      local prev_data = parse_csv(files[i])
      if prev_data then
        local prev_startup = calc_stats(prev_data.startup)
        local prev_uienter = calc_stats(prev_data.uienter)
        local prev_memory = calc_stats(prev_data.memory)

        if prev_startup.mean > 0 and prev_uienter.mean > 0 and prev_memory.mean > 0 then
          local startup_diff = ((startup_stats.mean - prev_startup.mean) / prev_startup.mean) * 100
          local uienter_diff = ((uienter_stats.mean - prev_uienter.mean) / prev_uienter.mean) * 100
          local memory_diff = ((memory_stats.mean - prev_memory.mean) / prev_memory.mean) * 100

          table.insert(comparisons, {
            file = vim.fn.fnamemodify(files[i], ":t"),
            startup_diff = startup_diff,
            uienter_diff = uienter_diff,
            memory_diff = memory_diff,
          })
        end
      end
    end
  end

  -- Generate HTML
  local filename = vim.fn.fnamemodify(filepath, ":t:r")
  local html_path = config.html_dir .. "/" .. filename .. ".html"

  local html = [[
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Neovim Benchmark Report - ]]
    .. filename
    .. [[</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            padding: 2rem;
            min-height: 100vh;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background: white;
            border-radius: 20px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            overflow: hidden;
        }
        header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 3rem 2rem;
            text-align: center;
        }
        h1 { font-size: 2.5rem; margin-bottom: 0.5rem; }
        .subtitle { opacity: 0.9; font-size: 1.1rem; }
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 2rem;
            padding: 2rem;
        }
        .stat-card {
            background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%);
            padding: 2rem;
            border-radius: 15px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.1);
        }
        .stat-title {
            font-size: 1.2rem;
            font-weight: 600;
            color: #667eea;
            margin-bottom: 1.5rem;
        }
        .metric {
            display: flex;
            justify-content: space-between;
            padding: 0.75rem 0;
            border-bottom: 1px solid rgba(0,0,0,0.1);
        }
        .metric:last-child { border-bottom: none; }
        .metric-label { font-weight: 500; color: #555; }
        .metric-value { font-weight: 700; color: #333; }
        .comparisons {
            padding: 2rem;
            background: #f9fafb;
        }
        .comparison-title {
            font-size: 1.5rem;
            font-weight: 700;
            color: #333;
            margin-bottom: 1.5rem;
            text-align: center;
        }
        .comparison-grid {
            display: grid;
            gap: 1rem;
        }
        .comparison-item {
            background: white;
            padding: 1.5rem;
            border-radius: 10px;
            box-shadow: 0 5px 15px rgba(0,0,0,0.08);
            display: grid;
            grid-template-columns: 2fr 1fr 1fr 1fr;
            gap: 1rem;
            align-items: center;
        }
        .file-name {
            font-weight: 600;
            color: #555;
            font-size: 0.9rem;
        }
        .diff {
            display: flex;
            align-items: center;
            gap: 0.5rem;
            font-weight: 700;
            font-size: 1.1rem;
        }
        .diff.positive { color: #10b981; }
        .diff.negative { color: #ef4444; }
        .arrow {
            font-size: 1.5rem;
        }
        footer {
            text-align: center;
            padding: 2rem;
            color: #999;
            font-size: 0.9rem;
        }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1>🚀 Neovim Performance Report</h1>
            <p class="subtitle">]]
    .. filename
    .. [[</p>
        </header>

        <div class="stats-grid">
            <div class="stat-card">
                <div class="stat-title">⚡ Startup Time</div>
                <div class="metric">
                    <span class="metric-label">Mean</span>
                    <span class="metric-value">]]
    .. startup_stats.mean
    .. [[ ms</span>
                </div>
                <div class="metric">
                    <span class="metric-label">Median</span>
                    <span class="metric-value">]]
    .. startup_stats.median
    .. [[ ms</span>
                </div>
                <div class="metric">
                    <span class="metric-label">Min</span>
                    <span class="metric-value">]]
    .. startup_stats.min
    .. [[ ms</span>
                </div>
                <div class="metric">
                    <span class="metric-label">Max</span>
                    <span class="metric-value">]]
    .. startup_stats.max
    .. [[ ms</span>
                </div>
                <div class="metric">
                    <span class="metric-label">StdDev</span>
                    <span class="metric-value">]]
    .. startup_stats.stddev
    .. [[ ms</span>
                </div>
            </div>

            <div class="stat-card">
                <div class="stat-title">🎨 UI Enter Time</div>
                <div class="metric">
                    <span class="metric-label">Mean</span>
                    <span class="metric-value">]]
    .. uienter_stats.mean
    .. [[ ms</span>
                </div>
                <div class="metric">
                    <span class="metric-label">Median</span>
                    <span class="metric-value">]]
    .. uienter_stats.median
    .. [[ ms</span>
                </div>
                <div class="metric">
                    <span class="metric-label">Min</span>
                    <span class="metric-value">]]
    .. uienter_stats.min
    .. [[ ms</span>
                </div>
                <div class="metric">
                    <span class="metric-label">Max</span>
                    <span class="metric-value">]]
    .. uienter_stats.max
    .. [[ ms</span>
                </div>
                <div class="metric">
                    <span class="metric-label">StdDev</span>
                    <span class="metric-value">]]
    .. uienter_stats.stddev
    .. [[ ms</span>
                </div>
            </div>

            <div class="stat-card">
                <div class="stat-title">💾 Memory Usage</div>
                <div class="metric">
                    <span class="metric-label">Mean</span>
                    <span class="metric-value">]]
    .. memory_stats.mean
    .. [[ KB</span>
                </div>
                <div class="metric">
                    <span class="metric-label">Median</span>
                    <span class="metric-value">]]
    .. memory_stats.median
    .. [[ KB</span>
                </div>
                <div class="metric">
                    <span class="metric-label">Min</span>
                    <span class="metric-value">]]
    .. memory_stats.min
    .. [[ KB</span>
                </div>
                <div class="metric">
                    <span class="metric-label">Max</span>
                    <span class="metric-value">]]
    .. memory_stats.max
    .. [[ KB</span>
                </div>
                <div class="metric">
                    <span class="metric-label">StdDev</span>
                    <span class="metric-value">]]
    .. memory_stats.stddev
    .. [[ KB</span>
                </div>
            </div>

            <div class="stat-card">
                <div class="stat-title">🔌 Plugins</div>
                <div class="metric">
                    <span class="metric-label">Total Loaded</span>
                    <span class="metric-value">]]
    .. plugin_count
    .. [[</span>
                </div>
                <div class="metric">
                    <span class="metric-label">Slow Plugins</span>
                    <span class="metric-value">]]
    .. #slow_plugins
    .. [[</span>
                </div>
            </div>
        </div>
]]

  -- Add slow plugins section
  if #slow_plugins > 0 then
    html = html
      .. [[
        <div class="comparisons">
            <h2 class="comparison-title">🐌 Slowest Plugins (> 10ms)</h2>
            <div class="comparison-grid">
]]

    for i, plugin in ipairs(slow_plugins) do
      if i <= 10 then
        html = html
          .. string.format(
            [[
                <div class="comparison-item">
                    <div class="file-name">%s</div>
                    <div class="diff negative">
                        <span>%.2f ms</span>
                    </div>
                    <div class="diff">
                        <span>%d runs</span>
                    </div>
                </div>
]],
            plugin.Name,
            plugin.AvgTime,
            plugin.Occurrences
          )
      end
    end

    html = html
      .. [[
            </div>
        </div>
]]
  end

  if #comparisons > 0 then
    html = html
      .. [[
        <div class="comparisons">
            <h2 class="comparison-title">📊 Comparison with Previous Benchmarks</h2>
            <div class="comparison-grid">
]]

    for _, comp in ipairs(comparisons) do
      local startup_class = comp.startup_diff < 0 and "positive" or "negative"
      local startup_arrow = comp.startup_diff < 0 and "↓" or "↑"
      local uienter_class = comp.uienter_diff < 0 and "positive" or "negative"
      local uienter_arrow = comp.uienter_diff < 0 and "↓" or "↑"
      local memory_class = comp.memory_diff < 0 and "positive" or "negative"
      local memory_arrow = comp.memory_diff < 0 and "↓" or "↑"

      html = html
        .. string.format(
          [[
                <div class="comparison-item">
                    <div class="file-name">%s</div>
                    <div class="diff %s">
                        <span class="arrow">%s</span>
                        <span>%.1f%%</span>
                    </div>
                    <div class="diff %s">
                        <span class="arrow">%s</span>
                        <span>%.1f%%</span>
                    </div>
                    <div class="diff %s">
                        <span class="arrow">%s</span>
                        <span>%.1f%%</span>
                    </div>
                </div>
]],
          comp.file,
          startup_class,
          startup_arrow,
          math.abs(comp.startup_diff),
          uienter_class,
          uienter_arrow,
          math.abs(comp.uienter_diff),
          memory_class,
          memory_arrow,
          math.abs(comp.memory_diff)
        )
    end

    html = html
      .. [[
            </div>
        </div>
]]
  end

  html = html
    .. [[
        <footer>
            Generated by Neovim Performance Benchmarking Tool
        </footer>
    </div>
</body>
</html>
]]

  local file = io.open(html_path, "w")
  if file then
    file:write(html)
    file:close()
    vim.notify("HTML report generated: " .. html_path, vim.log.levels.INFO)

    -- Open in browser
    local open_cmd
    if vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
      open_cmd = "start"
    elseif vim.fn.has("mac") == 1 then
      open_cmd = "open"
    else
      open_cmd = "xdg-open"
    end
    vim.fn.system(open_cmd .. ' "' .. html_path .. '"')
  else
    vim.notify("Failed to write HTML report", vim.log.levels.ERROR)
  end
end

-- Show file picker for HTML generation
function M.select_and_generate_html()
  local files = get_benchmark_files()
  if #files == 0 then
    vim.notify("No benchmark files found", vim.log.levels.WARN)
    return
  end

  local items = {}
  for i, file in ipairs(files) do
    local name = vim.fn.fnamemodify(file, ":t")
    table.insert(items, string.format("%d. %s", i, name))
  end

  vim.ui.select(items, {
    prompt = "Select benchmark to generate HTML report:",
  }, function(_, idx)
    if idx then
      M.generate_html_report(files[idx])
    end
  end)
end

-- Setup commands
function M.setup()
  ensure_dirs()

  vim.api.nvim_create_user_command("BenchmarkRun", function(opts)
    local runs = tonumber(opts.args) or config.default_runs
    M.run_benchmark({ runs = runs })
  end, {
    nargs = "?",
    desc = "Run Neovim startup benchmark (default: 15 runs)",
  })

  vim.api.nvim_create_user_command("BenchmarkRunDebug", function(opts)
    local runs = tonumber(opts.args) or config.default_runs
    M.run_benchmark({ runs = runs, debug = true })
  end, {
    nargs = "?",
    desc = "Run benchmark with debug output",
  })

  vim.api.nvim_create_user_command("BenchmarkHtml", function()
    M.select_and_generate_html()
  end, {
    desc = "Generate HTML report from benchmark results",
  })

  -- Test command to verify setup
  vim.api.nvim_create_user_command("BenchmarkTest", function()
    local script = get_benchmark_script()
    local lua_script = config.script_dir .. "/benchmark_startup.lua"

    vim.notify("🔍 Benchmark Test Results:", vim.log.levels.INFO)
    vim.notify("  Script exists: " .. (vim.fn.filereadable(script) == 1 and "✅" or "❌ " .. script), vim.log.levels.INFO)
    vim.notify("  Lua script exists: " .. (vim.fn.filereadable(lua_script) == 1 and "✅" or "❌ " .. lua_script), vim.log.levels.INFO)
    vim.notify("  CSV dir exists: " .. (vim.fn.isdirectory(config.csv_dir) == 1 and "✅" or "❌ " .. config.csv_dir), vim.log.levels.INFO)
    vim.notify("  HTML dir exists: " .. (vim.fn.isdirectory(config.html_dir) == 1 and "✅" or "❌ " .. config.html_dir), vim.log.levels.INFO)

    -- Count existing benchmarks
    local files = get_benchmark_files()
    vim.notify("  Existing benchmarks: " .. #files, vim.log.levels.INFO)
  end, {
    desc = "Test benchmark setup and show diagnostics",
  })
end

return M
