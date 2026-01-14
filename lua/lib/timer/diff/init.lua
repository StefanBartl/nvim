---@module 'lib.time.diff'
---@brief High-precision time measurement and interval tracking module.
---@description
--- Provides a lightweight, reusable timer object for measuring elapsed time
--- between code sections. Each call to `require("lib.time.diff")` returns a
--- fresh timer instance with independent state.
---
--- Key features:
--- - Nanosecond precision via `vim.uv.hrtime()` (default output)
--- - Multiple checkpoints with automatic interval calculation
--- - Dynamic property generation (diff.first, diff.second, ..., diff.last)
--- - Pretty-printed summary tables with configurable units
--- - Iterator support with custom labels and index display
--- - Metatable-based callable interface (`print(diff)`, `diff()`)
---
--- Usage:
---   local diff = require("lib.time.diff")
---   diff.start()
---   -- ... code block 1 ...
---   local t1 = diff.check()         -- First interval (nanoseconds)
---   local t2_ms = diff.check("ms")  -- Second interval (milliseconds)
---   print(diff.first)                -- Access first checkpoint
---   print(diff.last)                 -- Access last checkpoint
---   print(diff("ms"))                -- Print all checkpoints in ms
---   print(diff.pretty("ms"))         -- Formatted table in ms

local M = {}

--- Time unit names for formatting output.
---@alias TimeUnit "ns"|"us"|"ms"|"s"

--- Convert nanoseconds to the specified unit.
---@param ns number Nanoseconds
---@param unit TimeUnit Target unit
---@return number converted Converted value
---@private
local function convert_time(ns, unit)
  if unit == "ns" then
    return ns
  elseif unit == "us" then
    return ns / 1e3
  elseif unit == "ms" then
    return ns / 1e6
  elseif unit == "s" then
    return ns / 1e9
  else
    error("[lib.time.diff] Invalid unit: " .. tostring(unit), 2)
  end
end

--- Get unit suffix for display.
---@param unit TimeUnit
---@return string suffix Unit suffix
---@private
local function unit_suffix(unit)
  return unit or "ns"
end

--- Create a new timer instance with isolated state.
--- Automatically starts timing on creation.
---@return TimeDiff
local function create_timer()
  ---@class TimeDiff
  ---@field private _start number Initial timestamp (nanoseconds)
  ---@field private _checks number[] List of checkpoint timestamps (nanoseconds)
  ---@field private _index integer Iterator index for `next()`
  ---@field private _iter_label string|nil Custom label for iterator output
  ---@field private _iter_show_index boolean Whether to show index in iterator output
  local instance = {
    _start = 0,
    _checks = {},
    _index = 0,
    _iter_label = nil,
    _iter_show_index = false,
  }

  --- Start or reset the timer.
  --- Clears all previous checkpoints and sets a new baseline.
  ---@return nil
  function instance.start()
    instance._start = vim.uv.hrtime()
    instance._checks = {}
    instance._index = 0
    instance._iter_label = nil
    instance._iter_show_index = false
  end

  --- Record a checkpoint and return elapsed time since start.
  --- Can be called multiple times to measure intermediate intervals.
  ---@param unit? TimeUnit Unit for return value (default: "ns")
  ---@return number elapsed Elapsed time in specified unit
  function instance.check(unit)
    if instance._start == 0 then
      error("[lib.time.diff] Timer not started. Call `start()` first.", 2)
    end
    local now = vim.uv.hrtime()
    table.insert(instance._checks, now)
    local elapsed_ns = now - instance._start
    return convert_time(elapsed_ns, unit or "ns")
  end

  --- Get total elapsed time since start.
  --- Equivalent to the last checkpoint if `check()` was called.
  ---@param unit? TimeUnit Unit for return value (default: "ns")
  ---@return number|nil total Total time in specified unit, or nil if no checkpoints exist
  function instance.result(unit)
    if #instance._checks == 0 then
      return nil
    end
    local last = instance._checks[#instance._checks]
    local elapsed_ns = last - instance._start
    return convert_time(elapsed_ns, unit or "ns")
  end

  --- Get elapsed time of a specific checkpoint by index.
  --- Index is 1-based (Lua convention).
  ---@param idx integer Checkpoint index (1 = first check, 2 = second, etc.)
  ---@param unit? TimeUnit Unit for return value (default: "ns")
  ---@return number|nil elapsed Elapsed time in specified unit, or nil if index out of bounds
  function instance.get(idx, unit)
    if idx < 1 or idx > #instance._checks then
      return nil
    end
    local elapsed_ns = instance._checks[idx] - instance._start
    return convert_time(elapsed_ns, unit or "ns")
  end

  --- Iterator: Returns the next checkpoint sequentially.
  --- Resets to the beginning when all checkpoints are exhausted.
  ---@param label? string Custom label for this specific call (overrides iterator label)
  ---@param unit? TimeUnit Unit for time value (default: "ns")
  ---@return string|number|nil output Formatted string if label set, raw number otherwise, or nil if exhausted
  function instance.next(label, unit)
    instance._index = instance._index + 1
    if instance._index > #instance._checks then
      instance._index = 0
      return nil
    end

    local time_val = instance.get(instance._index, unit or "ns")
    local effective_label = label or instance._iter_label

    if not effective_label then
      return time_val
    end

    local suffix = unit_suffix(unit or "ns")
    if instance._iter_show_index then
      return string.format("%s %d: %.3f%s", effective_label, instance._index, time_val, suffix)
    else
      return string.format("%s %.3f%s", effective_label, time_val, suffix)
    end
  end

  --- Reset the iterator to the beginning.
  --- Optionally set a custom label and enable index display.
  ---@param label? string Custom label to prepend to each iterator output
  ---@param show_index? boolean Whether to include checkpoint index in output
  ---@return nil
  function instance.reset_iterator(label, show_index)
    instance._index = 0
    instance._iter_label = label
    instance._iter_show_index = show_index or false
  end

  --- Calculate statistics for all checkpoints.
  ---@return table stats Statistics object with min, max, avg, median, sum
  ---@private
  local function calculate_stats()
    if #instance._checks == 0 then
      return nil
    end

    -- Calculate deltas between consecutive checkpoints
    local deltas = {}
    local prev = instance._start
    for _, ts in ipairs(instance._checks) do
      table.insert(deltas, ts - prev)
      prev = ts
    end

    -- Find min and max
    local min_delta = math.huge
    local max_delta = -math.huge
    local sum_delta = 0

    for _, delta in ipairs(deltas) do
      if delta < min_delta then
        min_delta = delta
      end
      if delta > max_delta then
        max_delta = delta
      end
      sum_delta = sum_delta + delta
    end

    -- Calculate average
    local avg_delta = sum_delta / #deltas

    -- Calculate median
    local sorted_deltas = {}
    for _, d in ipairs(deltas) do
      table.insert(sorted_deltas, d)
    end
    table.sort(sorted_deltas)

    local median_delta
    local mid = math.floor(#sorted_deltas / 2)
    if #sorted_deltas % 2 == 0 then
      median_delta = (sorted_deltas[mid] + sorted_deltas[mid + 1]) / 2
    else
      median_delta = sorted_deltas[mid + 1]
    end

    return {
      min = min_delta,
      max = max_delta,
      avg = avg_delta,
      median = median_delta,
      sum = sum_delta,
      count = #deltas,
    }
  end

  --- Get the fastest (minimum) interval between checkpoints.
  ---@param unit? TimeUnit Unit for return value (default: "ns")
  ---@return number|nil fastest Fastest interval, or nil if fewer than 1 checkpoint
  function instance.fastest(unit)
    local stats = calculate_stats()
    if not stats then
      return nil
    end
    return convert_time(stats.min, unit or "ns")
  end

  --- Get the longest (maximum) interval between checkpoints.
  ---@param unit? TimeUnit Unit for return value (default: "ns")
  ---@return number|nil longest Longest interval, or nil if fewer than 1 checkpoint
  function instance.longest(unit)
    local stats = calculate_stats()
    if not stats then
      return nil
    end
    return convert_time(stats.max, unit or "ns")
  end

  --- Get the average interval between checkpoints.
  ---@param unit? TimeUnit Unit for return value (default: "ns")
  ---@return number|nil average Average interval, or nil if fewer than 1 checkpoint
  function instance.average(unit)
    local stats = calculate_stats()
    if not stats then
      return nil
    end
    return convert_time(stats.avg, unit or "ns")
  end

  --- Get the median interval between checkpoints.
  ---@param unit? TimeUnit Unit for return value (default: "ns")
  ---@return number|nil median Median interval, or nil if fewer than 1 checkpoint
  function instance.median(unit)
    local stats = calculate_stats()
    if not stats then
      return nil
    end
    return convert_time(stats.median, unit or "ns")
  end

  --- Calculate difference between two intervals.
  --- Accepts checkpoint indices, special keywords ("average", "fastest", "longest"),
  --- or direct time values. Always returns positive difference.
  ---@param iv1 integer|string|number First interval (index, keyword, or value)
  ---@param iv2 integer|string|number Second interval (index, keyword, or value)
  ---@param unit? TimeUnit Unit for return value (default: "ns")
  ---@return number|nil diff Absolute difference, or nil if invalid input
  function instance.calc_diff(iv1, iv2, unit)
    local function resolve_value(iv)
      local t = type(iv)
      if t == "number" then
        -- If it's a small integer, treat as index; otherwise as raw time value
        if iv == math.floor(iv) and iv >= 1 and iv <= #instance._checks then
          return instance._checks[iv] - instance._start
        else
          -- Assume it's already a time value in nanoseconds
          return iv
        end
      elseif t == "string" then
        local lower = iv:lower()
        if lower == "average" or lower == "avg" then
          local stats = calculate_stats()
          return stats and stats.avg or nil
        elseif lower == "fastest" or lower == "min" then
          local stats = calculate_stats()
          return stats and stats.min or nil
        elseif lower == "longest" or lower == "max" then
          local stats = calculate_stats()
          return stats and stats.max or nil
        elseif lower == "median" or lower == "med" then
          local stats = calculate_stats()
          return stats and stats.median or nil
        else
          return nil
        end
      else
        return nil
      end
    end

    local val1 = resolve_value(iv1)
    local val2 = resolve_value(iv2)

    if not val1 or not val2 then
      return nil
    end

    local diff_ns = math.abs(val1 - val2)
    return convert_time(diff_ns, unit or "ns")
  end

  --- Get standard deviation of intervals between checkpoints.
  ---@param unit? TimeUnit Unit for return value (default: "ns")
  ---@return number|nil stddev Standard deviation, or nil if fewer than 2 checkpoints
  function instance.stddev(unit)
    if #instance._checks < 2 then
      return nil
    end

    local stats = calculate_stats()
    if not stats then
      return nil
    end

    -- Calculate variance
    local variance = 0
    local prev = instance._start
    for _, ts in ipairs(instance._checks) do
      local delta = ts - prev
      variance = variance + (delta - stats.avg) ^ 2
      prev = ts
    end
    variance = variance / stats.count

    local stddev_ns = math.sqrt(variance)
    return convert_time(stddev_ns, unit or "ns")
  end

  --- Get coefficient of variation (CV) as percentage.
  --- CV = (stddev / mean) * 100
  ---@return number|nil cv Coefficient of variation (%), or nil if fewer than 2 checkpoints
  function instance.cv()
    local stats = calculate_stats()
    if not stats or stats.avg == 0 then
      return nil
    end

    local stddev_ns = instance.stddev("ns")
    if not stddev_ns then
      return nil
    end

    return (stddev_ns / stats.avg) * 100
  end

  --- Generate a summary string with all checkpoint times and statistics.
  ---@param unit? TimeUnit Unit for time values (default: "ns")
  ---@return string summary Human-readable summary
  function instance.results(unit)
    if #instance._checks == 0 then
      return "[lib.time.diff] No checkpoints recorded."
    end

    local u = unit or "ns"
    local suffix = unit_suffix(u)
    local parts = {}

    for i, ts in ipairs(instance._checks) do
      local elapsed = convert_time(ts - instance._start, u)
      table.insert(parts, string.format("Check %d: %.3f%s", i, elapsed, suffix))
    end

    local total = convert_time(instance._checks[#instance._checks] - instance._start, u)
    table.insert(parts, string.format("Total: %.3f%s", total, suffix))

    -- Add statistics if more than one checkpoint
    if #instance._checks > 0 then
      local fastest = instance.fastest(u)
      local longest = instance.longest(u)
      local avg = instance.average(u)

      table.insert(parts, string.format("Fastest: %.3f%s", fastest, suffix))
      table.insert(parts, string.format("Longest: %.3f%s", longest, suffix))
      table.insert(parts, string.format("Average: %.3f%s", avg, suffix))
      table.insert(parts, string.format("Range: %.3f%s", longest - fastest, suffix))
    end

    return table.concat(parts, " | ")
  end

  --- Generate a pretty-printed table suitable for `:messages` or notify.
  --- Columns: Index | Elapsed | Delta
  ---@param unit? TimeUnit Unit for time values (default: "ns")
  ---@return string formatted Multi-line formatted table
  function instance.pretty(unit)
    if #instance._checks == 0 then
      return "[lib.time.diff] No checkpoints to display."
    end

    local u = unit or "ns"
    local suffix = unit_suffix(u)

    local lines = {
      string.format("┌────────┬─────────────────┬─────────────────┐"),
      string.format("│ Index  │  Elapsed (%2s)  │   Delta (%2s)   │", suffix, suffix),
      string.format("├────────┼─────────────────┼─────────────────┤"),
    }

    local prev = instance._start
    for i, ts in ipairs(instance._checks) do
      local elapsed = convert_time(ts - instance._start, u)
      local delta = convert_time(ts - prev, u)
      prev = ts
      table.insert(
        lines,
        string.format("│ %6d │    %11.3f │    %11.3f │", i, elapsed, delta)
      )
    end

    local total = convert_time(instance._checks[#instance._checks] - instance._start, u)
    table.insert(lines, "├────────┴─────────────────┴─────────────────┤")
    table.insert(lines, string.format("│ Total: %11.3f%2s                  │", total, suffix))

    -- Add statistics section
    if #instance._checks > 0 then
      local fastest = instance.fastest(u)
      local longest = instance.longest(u)
      local avg = instance.average(u)
      local med = instance.median(u)
      local range = longest - fastest

      table.insert(lines, "├──────────────────────────────────────────────┤")
      table.insert(lines, "│ Statistics:                                  │")
      table.insert(lines, "├──────────────────────────────────────────────┤")
      table.insert(lines, string.format("│ Fastest Δ: %11.3f%2s                │", fastest, suffix))
      table.insert(lines, string.format("│ Longest Δ: %11.3f%2s                │", longest, suffix))
      table.insert(lines, string.format("│ Average Δ: %11.3f%2s                │", avg, suffix))
      table.insert(lines, string.format("│ Median Δ:  %11.3f%2s                │", med, suffix))
      table.insert(lines, string.format("│ Range:     %11.3f%2s                │", range, suffix))

      -- Add stddev and CV if available
      if #instance._checks >= 2 then
        local sd = instance.stddev(u)
        local cv = instance.cv()
        table.insert(lines, string.format("│ Std Dev:   %11.3f%2s                │", sd, suffix))
        table.insert(lines, string.format("│ CV:        %11.2f%%                   │", cv))
      end
    end

    table.insert(lines, "└──────────────────────────────────────────────┘")

    return table.concat(lines, "\n")
  end

  --- Metatable: Makes the instance callable and supports dynamic properties.
  --- Calling `diff()` or `diff(unit)` returns summary.
  --- Accessing `diff.first`, `diff.second`, etc. returns checkpoint values.
  ---@return string summary
  setmetatable(instance, {
    __call = function(_, unit)
      return instance.results(unit)
    end,
    __tostring = function()
      return instance.results()
    end,
    __index = function(tbl, key)
      -- Handle ordinal property access: first, second, third, ..., last
      local ordinals = {
        "first", "second", "third", "fourth", "fifth",
        "sixth", "seventh", "eighth", "ninth", "tenth"
      }

      for i, ordinal in ipairs(ordinals) do
        if key == ordinal then
          return instance.get(i)
        end
      end

      if key == "last" then
        return instance.result()
      end

      -- Fallback to raw table access for private fields
      return rawget(tbl, key)
    end,
  })

  -- Auto-start on creation
  instance.start()

  return instance
end

--- Factory function: Returns a new timer instance.
--- Each call creates an independent timer with its own state.
---@return TimeDiff
setmetatable(M, {
  __call = function()
    return create_timer()
  end,
})

return M
