---@module 'config.neotest.adapters.lua'
---@brief Neotest adapter configuration for Lua/Neovim plugin testing

local M = {}

--- Initialize Lua test adapter
---@return table|nil adapter Neotest adapter instance or nil on failure
local function create_adapter()
  local ok_plenary, plenary = pcall(require, "neotest-plenary")
  if not ok_plenary then
    return nil
  end

  return plenary({
    min_init = "./scripts/tests/minimal_init.lua",
  })
end

--- Public adapter reference (lazy-initialized)
---@type table|nil
M.adapter = create_adapter()

--- Lua-specific test patterns
---@type string[]
M.test_patterns = {
  "_spec%.lua$",
  "_test%.lua$",
  "spec/.*%.lua$",
  "test/.*%.lua$",
}

--- Check if file is a Lua test file
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
