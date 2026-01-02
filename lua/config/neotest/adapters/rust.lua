---@module 'config.neotest.adapters.rust'
---@brief Neotest adapter configuration for Rust testing with cargo test

local M = {}

--- Initialize Rust test adapter
---@return table|nil adapter Neotest adapter instance or nil on failure
local function create_adapter()
  local ok, neotest_rust = pcall(require, "neotest-rust")
  if not ok then
    return nil
  end

  return neotest_rust({
    args = { "--no-capture" },
    dap_adapter = "lldb",
  })
end

---@type table|nil
M.adapter = create_adapter()

---@type string[]
M.test_patterns = {
  "%.rs$",
}

--- Check if file is a Rust test file (any .rs file can contain tests)
---@param filepath string
---@return boolean
function M.is_test_file(filepath)
  if not filepath or filepath == "" then
    return false
  end

  -- In Rust, tests can be in any .rs file
  if not filepath:match("%.rs$") then
    return false
  end

  -- Check if file contains test module or #[test] attribute
  local ok, lines = pcall(vim.fn.readfile, filepath)
  if not ok or not lines then
    return false
  end

  for i = 1, #lines do
    local line = lines[i]
    if line:match("#%[test%]") or line:match("#%[cfg%(test%)%]") or line:match("mod tests") then
      return true
    end
  end

  return false
end

--- Get test patterns for Rust
---@return string[]
function M.get_test_patterns()
  return {
    "#%[test%]",
    "#%[tokio::test%]",
    "#%[async_std::test%]",
  }
end

return M
