---@module 'benchmarks'
---@brief Benchmark suite initialization
---@description
--- Single entry point for all benchmarks.
--- Usage in your init.lua:
---   require("benchmarks").setup()
---   :BenchAll

local M = {}

local config = {
  auto_commands = true,
  default_output = "both",
  default_format = "markdown",
}

--- Setup benchmarking system
---@param opts Benchmarks.Config?
function M.setup(opts)
  config = vim.tbl_deep_extend("force", config, opts or {})

  if config.auto_commands then
    require("benchmarks.main").setup_commands()
  end
end

--- Quick access to main module
---@return table
function M.main()
  return require("benchmarks.main")
end

--- Quick access to autocmds suite
---@return table
function M.autocmds()
  return {
    baseline = require("benchmarks.autocmds.baseline_suite"),
    phase0 = require("benchmarks.autocmds.phase0_tests"),
  }
end

--- Run all benchmarks with default config
---@return Benchmarks.Result[]
function M.run_all()
  return require("benchmarks.main").run_all({
    output = config.default_output,
    format = config.default_format,
    verbose = true,
  })
end

return M
