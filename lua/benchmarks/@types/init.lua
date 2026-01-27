---@meta
---@module 'benchmarks.@types'

---@class Benchmarks.Config
---@field auto_commands boolean Setup user commands
---@field default_output? "notify"|"file"|"both"|"silent"
---@field default_format? "markdown"|"csv"|"json"

---@class Benchmarks.Options
---@field output? "notify"|"file"|"both"|"silent" Output mode
---@field format? "markdown"|"csv"|"json" Output format
---@field verbose? boolean? Print detailed progress
---@field file_path string? Custom file path (default: stdpath("data")/bench_reports/)

---@class Benchmarks.Result
---@field suite_name string
---@field timestamp string
---@field results table[]
---@field summary table
---@field success boolean

---@class Benchmarks.BaselineSuite.Result
---@field event string
---@field iterations integer
---@field total_ms number
---@field avg_ms number
---@field min_ms number
---@field max_ms number
---@field stddev_ms number
---@field timestamp string

-- AUDIT: Wird NICHT verwendet momentan !?!
---@class Benchmarks.BaselineSuite.Summary
---@field results Benchmarks.BaselineSuite.Result[]
---@field total_events integer
---@field baseline_file string
---@field nvim_version string

return {}
