---@module 'config.neotest.adapters.go'
---@brief Neotest adapter configuration for Go testing with go test

local M = {}

--- Initialize Go test adapter
---@return table|nil adapter Neotest adapter instance or nil on failure
local function create_adapter()
  local ok, neotest_go = pcall(require, "neotest-go")
  if not ok then
    return nil
  end

  return neotest_go({
    experimental = {
      test_table = true,
    },
    args = { "-v", "-race", "-count=1", "-timeout=60s" },
    runner = "go",
  })
end

---@type table|nil
M.adapter = create_adapter()

---@type string[]
M.test_patterns = {
  "_test%.go$",
}

--- Check if file is a Go test file
---@param filepath string
---@return boolean
function M.is_test_file(filepath)
  if not filepath or filepath == "" then
    return false
  end

  return filepath:match("_test%.go$") ~= nil
end

--- Get test function patterns for Go
---@return string[]
function M.get_test_patterns()
  return {
    "^Test",
    "^Benchmark",
    "^Example",
  }
end

return M
