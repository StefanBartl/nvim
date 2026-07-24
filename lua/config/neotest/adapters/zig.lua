---@module 'config.neotest.adapters.zig'
---@brief Neotest adapter configuration for Zig testing with zig test

local M = {}

--- Initialize Zig test adapter
---@return table|nil adapter Neotest adapter instance or nil on failure
local function create_adapter()
  -- Zig has no dedicated neotest adapter yet; use vim-test
  local ok, vim_test = pcall(require, "neotest-vim-test")
  if not ok then
    return nil
  end

  return vim_test({
    ignore_file_types = { "python", "lua", "javascript", "typescript", "go", "rust", "c", "cpp" },
    allow_file_types = { "zig" },
  })
end

---@type table|nil
M.adapter = create_adapter()

---@type string[]
M.test_patterns = {
  "test_.*%.zig$",
  ".*_test%.zig$",
}

--- Check if file is a Zig test file
---@param filepath string
---@return boolean
function M.is_test_file(filepath)
  if not filepath or filepath == "" then
    return false
  end

  -- In Zig, any file with test blocks is a test file
  if not filepath:match("%.zig$") then
    return false
  end

  -- Check for test blocks
  local ok, lines = pcall(vim.fn.readfile, filepath)
  if not ok or not lines then
    return false
  end

  for i = 1, #lines do
    if lines[i]:match("^test%s+") then
      return true
    end
  end

  return false
end

--- Get Zig test patterns
---@return string[]
function M.get_test_patterns()
  return {
    "^test%s+",
  }
end

return M
