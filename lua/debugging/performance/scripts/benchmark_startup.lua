---@module 'debugging.performance.scripts.benchmark_startup'
---@brief Measures startup time and UI enter time

-- Store start time immediately
local start_time = vim.loop.hrtime()

-- Use vim.schedule to ensure we're in the event loop
vim.schedule(function()
  -- Shorter delay to prevent hangs
  vim.defer_fn(function()
    local startup_time = 0.0
    local ui_enter_time = 0.0

    -- Method 1: Parse startuptime file (most reliable for startup)
    local startuptime_file = vim.env.NVIM_STARTUPTIME_FILE
    if startuptime_file and vim.fn.filereadable(startuptime_file) == 1 then
      local file = io.open(startuptime_file, "r")
      if file then
        local content = file:read("*all")
        file:close()

        -- Find the last timing entry (total startup time)
        local last_time = 0.0
        local uienter_time = nil

        for line in content:gmatch("[^\r\n]+") do
          -- Format: "  123.456  012.345: something"
          local time_str = line:match("^%s*(%d+%.%d+)%s+%d+%.%d+:")
          if time_str then
            local parsed = tonumber(time_str)
            if parsed and parsed > last_time then
              last_time = parsed
            end
          end

          -- Look specifically for UIEnter event
          if line:match("UIEnter") then
            local ui_time = line:match("^%s*(%d+%.%d+)%s+%d+%.%d+:")
            if ui_time then
              uienter_time = tonumber(ui_time)
            end
          end
        end

        startup_time = last_time

        -- If we found UIEnter event, use that
        if uienter_time then
          ui_enter_time = uienter_time
        end
      end
    end

    -- Method 2: Try Lazy.nvim stats (if available)
    pcall(function()
      local lazy = require("lazy")
      if lazy and lazy.stats then
        local stats = lazy.stats()
        if stats and stats.startuptime and stats.startuptime > 0 then
          -- Lazy's startuptime is already in ms
          startup_time = stats.startuptime
        end
      end
    end)

    -- Method 3: Calculate UI enter time from hrtime if not found
    if ui_enter_time == 0.0 then
      -- Calculate elapsed time since script start in milliseconds
      local elapsed_ns = vim.loop.hrtime() - start_time
      ui_enter_time = elapsed_ns / 1000000  -- Convert nanoseconds to milliseconds
    end

    -- Fallback: if still no startup time, use UI enter time
    if startup_time == 0.0 and ui_enter_time > 0.0 then
      startup_time = ui_enter_time
    end

    -- Output format: startup_ms,ui_enter_ms
    -- Use io.write to ensure immediate output
    io.write(string.format("%.2f,%.2f\n", startup_time, ui_enter_time))
    io.flush()

    -- Force quit immediately
    vim.cmd("qa!")
  end, 500)  -- Reduced to 500ms
end)
