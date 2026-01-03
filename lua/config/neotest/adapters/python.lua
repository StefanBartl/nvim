---@module 'config.neotest.adapters.python'
---@brief Neotest adapter configuration for Python testing with pytest, unittest, or nose

local M = {}

local function detect_framework()
  if vim.fn.executable("pytest") == 1 then
    return "pytest"
  end

  if vim.fn.executable("nose2") == 1 then
    return "nose"
  end

  return "unittest"
end

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
    -- Explizite Test-Discovery
    is_test_file = function(file_path)
      return file_path:match("test_.*%.py$") or file_path:match(".*_test%.py$")
    end,
  })
end

M.adapter = create_adapter()

M.test_patterns = {
  "test_.*%.py$",
  ".*_test%.py$",
}

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

function M.get_test_patterns()
  return {
    "^def test_",
    "^class Test",
    "^async def test_",
  }
end

return M
