---@diagnostic disable
-- Test file to verify the Tree-sitter query works correctly
-- Run :GatherLua % on this file to test

-- Pattern 1: Top-level function declaration
function top_level_func()
  return "test"
end

-- Pattern 2: Local function declaration
local function local_func()
  return "test"
end

-- Pattern 3: Module method assignment
local M = {}
function M.module_method()
  return "test"
end

-- Pattern 4: Direct method assignment
M.direct_method = function()
  return "test"
end

-- Pattern 5: Local variable assignment
local my_func = function()
  return "test"
end

-- Pattern 6: Global variable assignment
global_func = function()
  return "test"
end

-- Pattern 7: Table constructor field
local obj = {
  table_field = function()
    return "test"
  end,

  another_field = function()
    return "test"
  end
}

-- Pattern 8: Nested module methods
M.nested = {}
M.nested.method = function()
  return "test"
end

-- Expected results when gathering functions:
-- - top_level_func
-- - local_func
-- - module_method
-- - direct_method
-- - my_func
-- - global_func
-- - table_field
-- - another_field
-- - method (from M.nested.method - only the last identifier)

return M
