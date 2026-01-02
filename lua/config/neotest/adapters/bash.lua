---@module 'config.neotest.adapters.bash'
---@brief Neotest adapter configuration for Bash/Shell testing with bats or shunit2

local M = {}

--- Detect available shell test framework
---@return string|nil framework "bats", "shunit2", or nil
local function detect_framework()
  local uv = vim.uv or vim.loop

  -- Check for bats (Bash Automated Testing System)
  if vim.fn.executable("bats") == 1 then
    return "bats"
  end

  -- Check for shunit2
  local shunit2_paths = {
    "/usr/share/shunit2/shunit2",
    "/usr/local/share/shunit2/shunit2",
    "./shunit2",
  }

  for i = 1, #shunit2_paths do
    local path = shunit2_paths[i]
    if uv.fs_stat(path) then
      return "shunit2"
    end
  end

  return nil
end

--- Initialize Bash/Shell test adapter
---@return table|nil adapter Neotest adapter instance or nil on failure
local function create_adapter()
  local framework = detect_framework()
  if not framework then
    return nil
  end

  -- Use vim-test adapter as generic shell test runner
  local ok, vim_test = pcall(require, "neotest-vim-test")
  if not ok then
    return nil
  end

  return vim_test({
    ignore_file_types = { "python", "lua", "javascript", "typescript" },
    allow_file_types = { "sh", "bash", "zsh" },
  })
end

---@type table|nil
M.adapter = create_adapter()

---@type string[]
M.test_patterns = {
  "%.bats$",
  "test_.*%.sh$",
  ".*_test%.sh$",
  ".*%.test%.sh$",
}

--- Check if file is a Shell test file
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

return M
