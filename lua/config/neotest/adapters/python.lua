---@module 'config.neotest.adapters.python'
---@brief Neotest adapter configuration for Python testing with pytest, unittest, or nose

local M = {}

--- Detect Python test framework
---@return string framework "pytest", "unittest", or "nose"
local function detect_framework()
  -- Check for pytest
  if vim.fn.executable("pytest") == 1 then
    return "pytest"
  end

  -- Check for nose2
  if vim.fn.executable("nose2") == 1 then
    return "nose"
  end

  -- Default to unittest (built-in)
  return "unittest"
end

--- Initialize Python test adapter
---@return table|nil adapter Neotest adapter instance or nil on failure
local function create_adapter()
  local ok, neotest_python = pcall(require, "neotest-python")
  if not ok then
    return nil
  end

  local framework = detect_framework()

  return neotest_python({
    dap = { justMyCode = false },
    runner = framework,
    python = "python3",
    args = framework == "pytest" and { "-v", "-s", "--log-level=DEBUG" } or {},
    pytest_discover_instances = true,
  })
end

---@type table|nil
M.adapter = create_adapter()

---@type string[]
M.test_patterns = {
  "test_.*%.py$",
  ".*_test%.py$",
}

--- Check if file is a Python test file
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

--- Get Python test patterns
---@return string[]
function M.get_test_patterns()
  return {
    "^def test_",
    "^class Test",
    "^async def test_",
  }
end

return M
