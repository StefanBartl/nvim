---@module 'config.neotest.core'
---@brief Core configuration and utilities for neotest integration

local Autocmd = require("lib.nvim.autocmd")

local M = {}

---@class NeotestCoreConfig
---@field auto_attach_on_test_file boolean Automatically attach to test files
---@field show_output_on_fail boolean Open output window on test failure
---@field enable_watch_mode boolean Enable file watching for auto-run
---@field default_strategy string Default test execution strategy

---@type NeotestCoreConfig
local default_config = {
  auto_attach_on_test_file = true,
  show_output_on_fail = true,
  enable_watch_mode = false,
  default_strategy = "integrated",
}

---@type NeotestCoreConfig
local config = vim.deepcopy(default_config)

--- Check if current buffer is a test file
---@return boolean
local function is_test_file()
  local bufname = vim.api.nvim_buf_get_name(0)
  if bufname == "" then
    return false
  end

  local patterns = {
    "_test%.lua$",
    "_spec%.lua$",
    "%.test%.ts$",
    "%.test%.tsx$",
    "%.spec%.ts$",
    "%.spec%.tsx$",
    "%.test%.js$",
    "%.spec%.js$",
    "_test%.go$",
    "_test%.py$",
    "test_.*%.py$",
    "%.test%.rs$",
    "test_.*%.c$",
    "test_.*%.cpp$",
  }

  for i = 1, #patterns do
    if bufname:match(patterns[i]) then
      return true
    end
  end

  return false
end

--- Setup autocommands for test file detection
local function setup_autocommands()
  local aug = Autocmd.group("NeotestCore", true)

  if config.auto_attach_on_test_file then
    Autocmd.create({ "BufEnter", "BufNewFile" }, function()
      if is_test_file() then
        vim.schedule(function()
          local ok, neotest = pcall(require, "neotest")
          if ok then
            pcall(neotest.run.attach)
          end
        end)
      end
    end, {
      group = aug,
      desc = "Neotest: Auto-attach to test files",
    })
  end

  if config.show_output_on_fail then
    Autocmd.create("User", function()
      vim.schedule(function()
        local ok, neotest = pcall(require, "neotest")
        if not ok then
          return
        end
        local results = neotest.state.get_results()
        if not results then
          return
        end

        local has_failed = false
        for _, result in pairs(results) do
          if result.status == "failed" then
            has_failed = true
            break
          end
        end

        if has_failed then
          neotest.output.open({ enter = false })
        end
      end)
    end, {
      pattern = "NeotestRunComplete",
      group = aug,
      desc = "Neotest: Show output on test failure",
    })
  end
end

--- Setup core neotest configuration and autocommands
---@param user_config NeotestCoreConfig|nil User configuration overrides
function M.setup(user_config)
  if type(user_config) == "table" then
    config = vim.tbl_deep_extend("force", config, user_config)
  end

  setup_autocommands()
end

--- Get current core configuration
---@return NeotestCoreConfig
function M.get_config()
  return vim.deepcopy(config)
end

return M
