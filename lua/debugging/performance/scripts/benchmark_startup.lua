---@module 'debugging.performance.scripts.benchmark_startup'
---@brief Measures startup time, UI enter time, memory usage, and plugin metrics

-- Store start time and initial memory immediately
local start_time = vim.loop.hrtime()
local start_memory = collectgarbage("count")

-- Measure function with timeout protection
local function measure_with_timeout(callback, timeout_ms)
  local done = false
  local result = nil

  vim.defer_fn(function()
    if not done then
      done = true
      io.write("TIMEOUT\n")
      io.flush()
      vim.cmd("qa!")
    end
  end, timeout_ms or 1000)

  vim.schedule(function()
    if not done then
      local ok, err = pcall(function()
        result = callback()
      end)

      if not ok then
        io.write("ERROR: " .. tostring(err) .. "\n")
      end

      done = true
    end
  end)
end

-- Main measurement logic
local function perform_measurement()
  local startup_ms = 0.0
  local ui_enter_ms = 0.0
  local memory_kb = 0.0
  local plugin_count = 0
  local slow_plugins = {}

  -- Calculate UI Enter time first (most reliable)
  local ui_elapsed_ns = vim.loop.hrtime() - start_time
  ui_enter_ms = ui_elapsed_ns / 1000000

  -- Method 1: Try Lazy.nvim stats (most accurate for startup)
  local lazy_ok, lazy_stats = pcall(function()
    local lazy = require("lazy")
    if lazy and lazy.stats then
      local stats = lazy.stats()
      if stats and stats.startuptime and stats.startuptime > 0 then
        startup_ms = stats.startuptime
      end
      if stats and stats.count then
        plugin_count = stats.count
      end
      return true
    end
    return false
  end)

  -- Method 2: Parse --startuptime file if Lazy failed
  if startup_ms == 0.0 then
    local startuptime_file = vim.env.NVIM_STARTUPTIME_FILE
    if startuptime_file and vim.fn.filereadable(startuptime_file) == 1 then
      local file = io.open(startuptime_file, "r")
      if file then
        local content = file:read("*all")
        file:close()

        -- Find the last timing entry (total startup time)
        local last_time = 0.0
        for line in content:gmatch("[^\r\n]+") do
          -- Format: "  123.456  012.345: event description"
          local time_str = line:match("^%s*(%d+%.%d+)%s+%d+%.%d+:")
          if time_str then
            local parsed = tonumber(time_str)
            if parsed and parsed > last_time then
              last_time = parsed
            end
          end
        end
        if last_time > 0 then
          startup_ms = last_time
        end
      end
    end
  end

  -- Method 3: Use UI Enter time as fallback (less accurate but safe)
  if startup_ms == 0.0 then
    startup_ms = ui_enter_ms
  end

  -- Memory usage calculation
  collectgarbage("collect")
  collectgarbage("collect") -- Double collect for accuracy
  local current_memory = collectgarbage("count")
  memory_kb = math.max(0, current_memory - start_memory)

  -- Collect slow plugin data (best effort, don't fail on errors)
  pcall(function()
    local lazy_core_ok, lazy_core = pcall(require, "lazy.core.config")
    if lazy_core_ok and lazy_core and lazy_core.plugins then
      for _, plugin in ipairs(lazy_core.plugins) do
        local plugin_name = plugin.name or plugin[1] or "unknown"

        if plugin._ and plugin._.loaded and plugin._.loaded.time then
          local load_time_ns = plugin._.loaded.time
          local load_time_ms = load_time_ns / 1000000

          if load_time_ms > 10 then
            table.insert(slow_plugins, {
              name = tostring(plugin_name),
              time = string.format("%.2f", load_time_ms)
            })
          end
        end
      end

      -- Sort by time descending
      table.sort(slow_plugins, function(a, b)
        return tonumber(a.time) > tonumber(b.time)
      end)
    end
  end)

  -- Output format: startup_ms,ui_enter_ms,memory_kb,plugin_count,slow_plugins_json
  local slow_plugins_json = vim.fn.json_encode(slow_plugins)

  -- Ensure values are reasonable
  startup_ms = math.max(0, startup_ms)
  ui_enter_ms = math.max(0, ui_enter_ms)
  memory_kb = math.max(0, memory_kb)
  plugin_count = math.max(0, plugin_count)

  io.write(string.format("%.2f,%.2f,%.2f,%d,%s\n",
    startup_ms, ui_enter_ms, memory_kb, plugin_count, slow_plugins_json))
  io.flush()
end

-- Wait for initialization with exponential backoff
local attempts = 0
local max_attempts = 10
local base_delay = 50

local function try_measure()
  attempts = attempts + 1

  -- Check if we should proceed
  local ready = false
  pcall(function()
    -- Check if lazy.nvim is available and loaded
    local lazy = package.loaded["lazy"]
    if lazy and lazy.stats then
      local stats = lazy.stats()
      if stats and stats.startuptime then
        ready = true
      end
    end
  end)

  if ready or attempts >= max_attempts then
    -- Perform measurement
    local ok, err = pcall(perform_measurement)
    if not ok then
      io.write("ERROR: " .. tostring(err) .. "\n")
      io.flush()
    end

    -- Exit after brief delay
    vim.defer_fn(function()
      vim.cmd("qa!")
    end, 50)
  else
    -- Exponential backoff: wait longer each time
    local delay = base_delay * (2 ^ (attempts - 1))
    vim.defer_fn(try_measure, math.min(delay, 500))
  end
end

-- Start the measurement process after scheduler
vim.schedule(function()
  -- Give plugins time to fully initialize
  vim.defer_fn(try_measure, 100)
end)
