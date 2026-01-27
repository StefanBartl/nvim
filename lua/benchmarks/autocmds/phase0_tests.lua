---@module 'bench.phase0_tests'
---@brief Phase 0 validation tests
---@description
--- Tests context factories and cache infrastructure.
--- Run after implementing Phase 0, before moving to Phase 1.

local M = {}

local api, bo = vim.api, vim.bo
local str_fmt = string.format
local hrtime = vim.loop.hrtime
local nvim_buf_set_lines, nvim_create_buf, nvim_buf_delete = api.nvim_buf_set_lines, api.nvim_create_buf, api.nvim_buf_delete

--- Test buffer context
function M.test_buffer_context()
  print("\n=== Testing Buffer Context ===")

  local buffer_ctx = require("autocmds.benchmarks.context.buffer")

  -- Create test buffer
  local bufnr = nvim_create_buf(false, true)
  local lines = {}
  for i = 1, 100 do
    lines[i] = "Line " .. i
  end
  nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  bo[bufnr].filetype = "lua"
  vim.bo[bufnr].buftype = ""
  vim.bo[bufnr].modifiable = true

  -- Test 1: Context creation
  local ctx = buffer_ctx.get(bufnr)
  assert(ctx.bufnr == bufnr, "Buffer number mismatch")
  assert(ctx.filetype == "lua", "Filetype mismatch")
  assert(ctx.line_count == 100, "Line count mismatch")
  print("✓ Context creation")

  -- Test 2: Cache hit
  local ctx2 = buffer_ctx.get(bufnr)
  assert(ctx == ctx2, "Cache miss on second access")
  print("✓ Cache hit")

  -- Test 3: Lazy line loading
  local lines_loaded = ctx.lines
  assert(#lines_loaded == 100, "Lines not loaded correctly")
  print("✓ Lazy line loading")

  -- Test 4: Cache invalidation on change
  nvim_buf_set_lines(bufnr, 0, 1, false, {"Modified"})
  local ctx3 = buffer_ctx.get(bufnr)
  assert(ctx3.tick ~= ctx.tick, "Tick not updated after change")
  print("✓ Cache invalidation on change")

  -- Test 5: Helper methods
  assert(ctx:is_normal(), "Should be normal buffer")
  assert(ctx:has_filetype("lua"), "Filetype check failed")
  print("✓ Helper methods")

  -- Cleanup
  nvim_buf_delete(bufnr, {force = true})

  -- Print stats
  buffer_ctx.print_stats()

  print("✅ All buffer context tests passed")
end

--- Test window context
function M.test_window_context()
  print("\n=== Testing Window Context ===")

  local window_ctx = require("autocmds.benchmarks.context.window")

  local winid = api.nvim_get_current_win()

  -- Test 1: Context creation
  local ctx = window_ctx.get(winid)
  assert(ctx.winid == winid, "Window ID mismatch")
  assert(#ctx.cursor == 2, "Cursor should be [row, col]")
  print("✓ Context creation")

  -- Test 2: Visible range
  local visible = ctx:get_visible_lines()
  assert(visible > 0, "Should have visible lines")
  print("✓ Visible range calculation")

  -- Test 3: Cache
  local _ = window_ctx.get(winid) -- Just verify cache works
  local stats = window_ctx.get_stats()
  assert(stats.hits > 0, "Should have cache hit")
  print("✓ Cache working")

  print("✅ All window context tests passed")
end

--- Test cache infrastructure
function M.test_cache()
  print("\n=== Testing Cache Infrastructure ===")

  local cache_mod = require("autocmds.benchmarks.context.cache")

  -- Create namespace
  local test_cache = cache_mod.namespace("test", { ttl = 1 })

  -- Test 1: Set and get
  test_cache.set("key1", "value1")
  local val = test_cache.get("key1")
  assert(val == "value1", "Cache get failed")
  print("✓ Set and get")

  -- Test 2: TTL expiration
  vim.wait(1100, function() return false end)
  local expired = test_cache.get("key1")
  assert(expired == nil, "TTL not working")
  print("✓ TTL expiration")

  -- Test 3: Tick-based caching
  local bufnr = nvim_create_buf(false, true)
  vim.bo[bufnr].buftype = ""
  test_cache.set("buf_key", "buf_value", bufnr)

  local val2 = test_cache.get("buf_key", bufnr)
  assert(val2 == "buf_value", "Tick-based cache get failed")

  -- Modify buffer to change tick
  nvim_buf_set_lines(bufnr, 0, -1, false, {"changed"})
  local invalidated = test_cache.get("buf_key", bufnr)
  assert(invalidated == nil, "Tick-based invalidation failed")
  print("✓ Tick-based invalidation")

  -- Test 4: Statistics
  local stats = test_cache.stats()
  assert(stats.hits > 0, "Should have hits")
  assert(stats.misses > 0, "Should have misses")
  print("✓ Statistics tracking")

  -- Cleanup
  nvim_buf_delete(bufnr, {force = true})
  test_cache.clear()

  print("✅ All cache tests passed")
end

--- Performance comparison: with vs without context
function M.bench_context_overhead()
  print("\n=== Benchmarking Context Overhead ===")

  local buffer_ctx = require("autocmds.benchmarks.context.buffer")
  local iterations = 10000

  -- Create test buffer
  local bufnr = nvim_create_buf(false, true)
  local lines = {}
  for i = 1, 1000 do
    lines[i] = "Line " .. i
  end
  nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.bo[bufnr].buftype = ""

  -- Benchmark 1: Direct API calls
  local start1 = hrtime()
  for _ = 1, iterations do
    local _ = api.nvim_buf_get_name(bufnr)
    local _ = bo[bufnr].filetype
    local _ = bo[bufnr].buftype
  end
  local elapsed1 = (hrtime() - start1) / 1e6

  -- Benchmark 2: Context factory (first call = miss)
  buffer_ctx.clear_all()
  local start2 = hrtime()
  for _ = 1, iterations do
    local ctx = buffer_ctx.get(bufnr)
    local _ = ctx.name
    local _ = ctx.filetype
    local _ = ctx.buftype
  end
  local elapsed2 = (hrtime() - start2) / 1e6

  print(str_fmt("Direct API:        %.3fms (%.6fms/call)", elapsed1, elapsed1/iterations))
  print(str_fmt("Context (cached):  %.3fms (%.6fms/call)", elapsed2, elapsed2/iterations))
  print(str_fmt("Overhead:          %.1f%% (%.3fms total)",
    (elapsed2/elapsed1 - 1) * 100, elapsed2 - elapsed1))

  local stats = buffer_ctx.get_stats()
  print(str_fmt("Cache hit rate:    %.2f%%", stats.hit_rate))

  -- Cleanup
  nvim_buf_delete(bufnr, {force = true})

  print("✅ Benchmark complete")
end

--- Run all Phase 0 tests
---@param silent boolean? Suppress print output
---@return boolean success, table stats
function M.run_all(silent)
  if not silent then
    print("🚀 Starting Phase 0 Tests...")
  end

  local tests = {
    { name = "Buffer Context", fn = M.test_buffer_context },
    { name = "Window Context", fn = M.test_window_context },
    { name = "Cache Infrastructure", fn = M.test_cache },
    { name = "Performance Overhead", fn = M.bench_context_overhead },
  }

  local failed = 0
  for i, test in ipairs(tests) do
    if not silent then
      print(str_fmt("\n[%d/%d] Running: %s", i, #tests, test.name))
    end
    local ok, err = pcall(test.fn)
    if not ok then
      if not silent then
        print("❌ FAILED: " .. tostring(err))
      end
      failed = failed + 1
    end
  end

  if not silent then
    print("\n" .. string.rep("=", 60))
    if failed == 0 then
      print("✅ All tests passed!")
    else
      print(str_fmt("❌ %d/%d tests failed", failed, #tests))
    end
  end

  local stats = {
    buffer_ctx = require("autocmds.benchmarks.context.buffer").get_stats(),
    window_ctx = require("autocmds.benchmarks.context.window").get_stats(),
    total_tests = #tests,
    failed = failed,
  }

  return failed == 0, stats
end

return M---@module 'benchmarks.autocmds.phase0_tests'
