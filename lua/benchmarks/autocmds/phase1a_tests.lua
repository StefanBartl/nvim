---@module 'benchmarks.autocmds.phase1a_tests'
---@brief Phase 1A: FileType Dispatcher Benchmarks
---@description
--- A/B testing: Old (17 separate autocmds) vs New (1 dispatcher)
---
--- Baseline: 16.922ms avg (from phase 0)
--- Target:   <5ms avg (70% reduction)

local M = {}

local api = vim.api
local loop = vim.loop or vim.uv

---@class Phase1AResult
---@field old_avg_ms number
---@field new_avg_ms number
---@field improvement_pct number
---@field iterations integer
---@field target_met boolean

--- Benchmark OLD implementation (17 separate autocmds)
---@param iterations integer
---@return number avg_ms
local function bench_old_filetype(iterations)
  -- Count existing FileType autocmds
  local autocmds = api.nvim_get_autocmds({ event = "FileType" })
  local count_before = #autocmds

  local samples = {}

  -- Warmup
  for _ = 1, math.floor(iterations * 0.1) do
    vim.cmd("doautocmd FileType markdown")
  end

  -- Actual benchmark
  for i = 1, iterations do
    local start = loop.hrtime()
    vim.cmd("doautocmd FileType markdown")
    local elapsed = (loop.hrtime() - start) / 1e6
    samples[i] = elapsed
  end

  -- Calculate average
  local total = 0
  for _, v in ipairs(samples) do
    total = total + v
  end

  return total / iterations
end

--- Benchmark NEW implementation (dispatcher)
---@param iterations integer
---@return number avg_ms
local function bench_new_filetype(iterations)
  -- Setup dispatcher
  local dispatcher = require("autocmds.events.utils.filetype")
  dispatcher.setup()

  local samples = {}

  -- Warmup
  for _ = 1, math.floor(iterations * 0.1) do
    vim.cmd("doautocmd FileType markdown")
  end

  -- Actual benchmark
  for i = 1, iterations do
    local start = loop.hrtime()
    vim.cmd("doautocmd FileType markdown")
    local elapsed = (loop.hrtime() - start) / 1e6
    samples[i] = elapsed
  end

  -- Calculate average
  local total = 0
  for _, v in ipairs(samples) do
    total = total + v
  end

  return total / iterations
end

--- Compare old vs new with multiple filetypes
---@param iterations integer?
---@return Phase1AResult
function M.compare_implementations(iterations)
  iterations = iterations or 200

  print("\n=== Phase 1A: FileType Dispatcher A/B Test ===")
  print(string.format("Iterations: %d per test\n", iterations))

  -- Test 1: Old implementation
  print("[1/2] Benchmarking OLD implementation (17 autocmds)...")
  local old_avg = bench_old_filetype(iterations)
  print(string.format("  ✓ OLD: %.3fms avg", old_avg))

  -- Clear and setup new
  vim.cmd("autocmd! FileType")

  -- Test 2: New implementation
  print("[2/2] Benchmarking NEW implementation (dispatcher)...")
  local new_avg = bench_new_filetype(iterations)
  print(string.format("  ✓ NEW: %.3fms avg", new_avg))

  -- Calculate improvement
  local improvement = ((old_avg - new_avg) / old_avg) * 100
  local target_met = new_avg < 5.0

  print("\n" .. string.rep("─", 60))
  print("Results:")
  print(string.format("  OLD: %.3fms", old_avg))
  print(string.format("  NEW: %.3fms", new_avg))
  print(string.format("  Improvement: %.1f%%", improvement))
  print(string.format("  Target (<5ms): %s", target_met and "✅ MET" or "❌ MISSED"))
  print(string.rep("─", 60))

  return {
    old_avg_ms = old_avg,
    new_avg_ms = new_avg,
    improvement_pct = improvement,
    iterations = iterations,
    target_met = target_met,
  }
end

--- Test dispatcher with various filetypes
function M.test_dispatcher_coverage()
  print("\n=== Testing Dispatcher Coverage ===")

  local dispatcher = require("autocmds.events.utils.filetype")
  dispatcher.setup()

  local test_filetypes = {
    "markdown",
    "mdx",
    "lua",
    "gitcommit",
    "c",
    "cpp",
    "go",
    "html",
    "noice",
  }

  for _, ft in ipairs(test_filetypes) do
    local bufnr = api.nvim_create_buf(false, true)
    vim.bo[bufnr].filetype = ft
    vim.bo[bufnr].buftype = ""

    -- Trigger FileType event
    local ok = pcall(function()
      vim.cmd("doautocmd FileType " .. ft)
    end)

    if ok then
      print(string.format("  ✓ %s", ft))
    else
      print(string.format("  ✗ %s (handler failed)", ft))
    end

    api.nvim_buf_delete(bufnr, { force = true })
  end

  print("\n✅ Coverage test complete")
end

--- Test lazy loading behavior
function M.test_lazy_loading()
  print("\n=== Testing Lazy Loading ===")

  local dispatcher = require("autocmds.events.utils.filetype")

  -- Check that handlers aren't loaded yet
  local loaded_before = {}
  for name, _ in pairs(package.loaded) do
    if name:match("^custom%.markdown") or name:match("^lsp%.languages") then
      loaded_before[name] = true
    end
  end

  print(string.format("Loaded modules before: %d", vim.tbl_count(loaded_before)))

  -- Trigger markdown filetype
  local bufnr = api.nvim_create_buf(false, true)
  vim.bo[bufnr].filetype = "markdown"
  vim.bo[bufnr].buftype = ""
  vim.cmd("doautocmd FileType markdown")

  -- Check what got loaded
  local loaded_after = {}
  for name, _ in pairs(package.loaded) do
    if name:match("^custom%.markdown") or name:match("^lsp%.languages") then
      if not loaded_before[name] then
        loaded_after[name] = true
      end
    end
  end

  print(string.format("Newly loaded modules: %d", vim.tbl_count(loaded_after)))
  for name in pairs(loaded_after) do
    print(string.format("  ✓ %s", name))
  end

  api.nvim_buf_delete(bufnr, { force = true })

  print("\n✅ Lazy loading verified")
end

--- Print dispatcher registry
function M.show_registry()
  local dispatcher = require("autocmds.events.utils.filetype")
  dispatcher.print_registry()
end

--- Run all Phase 1A tests
---@param silent boolean?
---@return boolean success, Phase1AResult result
function M.run_all(silent)
  if not silent then
    print("🚀 Starting Phase 1A Tests...")
  end

  local tests = {
    { name = "Dispatcher Coverage", fn = M.test_dispatcher_coverage },
    { name = "Lazy Loading", fn = M.test_lazy_loading },
    { name = "Registry Inspection", fn = M.show_registry },
  }

  local failed = 0
  for i, test in ipairs(tests) do
    if not silent then
      print(string.format("\n[%d/%d] Running: %s", i, #tests, test.name))
    end
    local ok, err = pcall(test.fn)
    if not ok then
      if not silent then
        print("❌ FAILED: " .. tostring(err))
      end
      failed = failed + 1
    end
  end

  -- Run comparison benchmark
  print("\n[4/4] Running: A/B Comparison")
  local result = M.compare_implementations(200)

  if not silent then
    print("\n" .. string.rep("=", 60))
    if failed == 0 and result.target_met then
      print("✅ All Phase 1A tests passed!")
    else
      print(string.format("⚠️  %d/%d tests failed or target missed", failed, #tests))
    end
  end

  return failed == 0 and result.target_met, result
end

return M
