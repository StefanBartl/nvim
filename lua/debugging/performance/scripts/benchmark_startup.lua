---@module 'debugging.performance.scripts.benchmark_startup'
---@brief Measures startup time, UI enter time, memory usage, and plugin metrics

-- Store start time and initial memory immediately
local start_time = vim.loop.hrtime()
local start_memory = collectgarbage("count")

-- Ensure we're in the main event loop
vim.schedule(function()
  -- Wait for lazy.nvim and other plugins to fully initialize
  vim.defer_fn(function()
    local startup_ms = 0.0
    local ui_enter_ms = 0.0
    local memory_kb = 0.0
    local plugin_count = 0
    local slow_plugins = {}

    -- Method 1: Try Lazy.nvim stats first (most accurate)
    pcall(function()
      local lazy = require("lazy")
      if lazy and lazy.stats then
        local stats = lazy.stats()
        if stats and stats.startuptime and stats.startuptime > 0 then
          startup_ms = stats.startuptime
        end
        if stats and stats.count then
          plugin_count = stats.count
        end
      end
    end)

    -- Method 2: Parse --startuptime file
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
          startup_ms = last_time
        end
      end
    end

    -- Method 3: Calculate from hrtime if still no data
    if startup_ms == 0.0 then
      local elapsed_ns = vim.loop.hrtime() - start_time
      startup_ms = elapsed_ns / 1000000 -- ns to ms
    end

    -- UI Enter time: always calculated from start
    local ui_elapsed_ns = vim.loop.hrtime() - start_time
    ui_enter_ms = ui_elapsed_ns / 1000000

    -- Memory usage calculation
    collectgarbage("collect")
    local current_memory = collectgarbage("count")
    memory_kb = current_memory - start_memory

    -- Collect slow plugin data
    pcall(function()
      local lazy_ok, lazy_core = pcall(require, "lazy.core.config")
      if lazy_ok and lazy_core and lazy_core.plugins then
        for _, plugin in ipairs(lazy_core.plugins) do
          -- Get plugin name safely
          local plugin_name = plugin.name or plugin[1] or "unknown"

          -- Check if plugin is loaded and has timing info
          if plugin._ and plugin._.loaded and plugin._.loaded.time then
            local load_time_ns = plugin._.loaded.time
            -- Convert from nanoseconds to milliseconds
            local load_time_ms = load_time_ns / 1000000

            if load_time_ms > 10 then -- Plugins slower than 10ms
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
    print(string.format("%.2f,%.2f,%.2f,%d,%s",
      startup_ms, ui_enter_ms, memory_kb, plugin_count, slow_plugins_json))

    -- Force flush and quit
    io.flush()
    vim.cmd("qa!")
  end, 300) -- Reduced timeout for faster runs
end)
