---@module 'config.neotest.adapters.typescript'
---@brief Neotest adapter configuration for TypeScript/JavaScript testing

local M = {}

--- Initialize TypeScript/JavaScript test adapter
---@return table|nil adapter Neotest adapter instance or nil on failure
local function create_adapter()
  -- Prefer Vitest for modern TypeScript projects
  local ok_vitest, vitest = pcall(require, "neotest-vitest")
  if ok_vitest then
    return vitest({
      vitestCommand = "npx vitest",
      env = { CI = "true" },
      cwd = function(_)
        return vim.fn.getcwd()
      end,
    })
  end

  -- Fallback to Jest
  local ok_jest, jest = pcall(require, "neotest-jest")
  if ok_jest then
    return jest({
      jestCommand = "npm test --",
      jestConfigFile = "jest.config.js",
      env = { CI = "true" },
      cwd = function(_)
        return vim.fn.getcwd()
      end,
    })
  end

  return nil
end

---@type table|nil
M.adapter = create_adapter()

---@type string[]
M.test_patterns = {
  "%.test%.ts$",
  "%.test%.tsx$",
  "%.spec%.ts$",
  "%.spec%.tsx$",
  "%.test%.js$",
  "%.test%.jsx$",
  "%.spec%.js$",
  "%.spec%.jsx$",
}

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
