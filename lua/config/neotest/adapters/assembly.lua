---@module 'config.neotest.adapters.assembly'
---@brief Neotest adapter configuration for Assembly testing (limited support)

local M = {}

--- Initialize Assembly test adapter
---@return table|nil adapter Neotest adapter instance or nil on failure
local function create_adapter()
  -- Assembly testing typically uses custom frameworks
  -- This is a placeholder for projects with test infrastructure
  local ok, vim_test = pcall(require, "neotest-vim-test")
  if not ok then
    return nil
  end

  return vim_test({
    ignore_file_types = {
      "python", "lua", "javascript", "typescript",
      "go", "rust", "c", "cpp", "zig"
    },
    allow_file_types = { "asm", "s", "S" },
  })
end

---@type table|nil
M.adapter = create_adapter()

---@type string[]
M.test_patterns = {
  "test_.*%.asm$",
  "test_.*%.s$",
  "test_.*%.S$",
  ".*_test%.asm$",
  ".*_test%.s$",
  ".*_test%.S$",
}

--- Check if file is an Assembly test file
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

--- Assembly testing note
---@return string
function M.get_note()
  return "Assembly testing support is limited. Requires custom test framework setup."
end

return M
