---@module 'config.neotest.adapters.c_ccp'
---@brief Neotest adapter configuration for C/C++ testing with Google Test, Catch2, or CTest

local M = {}

--- Detect available C/C++ test framework
---@return string|nil framework "gtest", "catch2", "ctest", or nil
local function detect_framework()
  local cwd = (vim.uv or vim.loop).cwd() or vim.fn.getcwd()

  -- Check for CMakeLists.txt (CTest)
  if vim.fn.filereadable(cwd .. "/CMakeLists.txt") == 1 then
    return "ctest"
  end

  -- Check for Google Test headers
  local include_dirs = { "/usr/include", "/usr/local/include", cwd .. "/include" }
  for i = 1, #include_dirs do
    local gtest_path = include_dirs[i] .. "/gtest/gtest.h"
    if vim.fn.filereadable(gtest_path) == 1 then
      return "gtest"
    end
  end

  -- Check for Catch2
  for i = 1, #include_dirs do
    local catch_path = include_dirs[i] .. "/catch2/catch.hpp"
    if vim.fn.filereadable(catch_path) == 1 then
      return "catch2"
    end
  end

  return nil
end

--- Initialize C/C++ test adapter
---@return table|nil adapter Neotest adapter instance or nil on failure
local function create_adapter()
  local framework = detect_framework()
  if not framework then
    return nil
  end

  -- Use vim-test as generic runner
  local ok, vim_test = pcall(require, "neotest-vim-test")
  if not ok then
    return nil
  end

  return vim_test({
    ignore_file_types = { "python", "lua", "javascript", "typescript", "go", "rust" },
    allow_file_types = { "c", "cpp", "cc", "cxx" },
  })
end

---@type table|nil
M.adapter = create_adapter()

---@type string[]
M.test_patterns = {
  "test_.*%.c$",
  "test_.*%.cpp$",
  "test_.*%.cc$",
  "test_.*%.cxx$",
  ".*_test%.c$",
  ".*_test%.cpp$",
  ".*_test%.cc$",
  ".*_test%.cxx$",
  ".*%.test%.c$",
  ".*%.test%.cpp$",
  ".*%.test%.cc$",
  ".*%.test%.cxx$",
}

--- Check if file is a C/C++ test file
---@param filepath string
---@return boolean
function M.is_test_file(filepath)
  if not filepath or filepath == "" then
    return false
  end

  for i = 1, #M.test_patterns do
    if filepath:match(M.test_patterns[i]) then
      return true
    end
  end

  return false
end

--- Get common C/C++ test macros
---@return string[]
function M.get_test_macros()
  return {
    "TEST",
    "TEST_F",
    "TEST_P",
    "TYPED_TEST",
    "TEST_CASE",
    "SCENARIO",
  }
end

return M
