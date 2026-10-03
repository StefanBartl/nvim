---@module 'config.neotest.core'
---@brief Core configuration and utilities for neotest integration

local Autocmd = require("lib.nvim.bindings.autocmd")

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

--- Is any test in this buffer running right now (so `run.attach` has something to attach to)?
---@param neotest table  the neotest module
---@param bufnr integer
---@return boolean
function M.has_running(neotest, bufnr)
  local running = false
  pcall(function()
    for _, id in ipairs(neotest.state.adapter_ids() or {}) do
      local counts = neotest.state.status_counts(id, { buffer = bufnr })
      if counts and (counts.running or 0) > 0 then
        running = true
        return
      end
    end
  end)
  return running
end

--- Setup autocommands for test file detection
local function setup_autocommands()
  local aug = Autocmd.group("NeotestCore", true)

  if config.auto_attach_on_test_file then
    Autocmd.create({ "BufEnter", "BufNewFile" }, function()
      if is_test_file() then
        -- The buffer and its file are captured now: the scheduled callback may run
        -- after the user has moved on.
        local bufnr = vim.api.nvim_get_current_buf()
        local file = vim.api.nvim_buf_get_name(bufnr)
        vim.schedule(function()
          local ok, neotest = pcall(require, "neotest")
          if not ok then
            return
          end
          local nio = require("nio")
          nio.run(function()
            -- Asking for the file's tree starts neotest's client silently: that is what
            -- discovers the tests and places the status signs. `run.attach` does the same
            -- but always reports ("No running process found" / "No tests found") when
            -- nothing is running, which was every visit to a test buffer.
            -- neotest's own separator, as in plugins/neotest.lua.
            local native = file:gsub("/", package.config:sub(1, 1))
            pcall(neotest.run.get_tree_from_args, { native }, false)
            -- The wait above may resume in a libuv callback, where `vim.fn`/`vim.api` calls
            -- (neotest's buffer state does `vim.fn.bufname`) fail; a failure inside
            -- `has_running` would only read as "nothing running" and skip the attach.
            nio.scheduler()
            -- `run.attach` works on the CURRENT buffer's nearest test: skip it when the
            -- user has already moved on.
            if vim.api.nvim_get_current_buf() == bufnr and M.has_running(neotest, bufnr) then
              pcall(neotest.run.attach)
            end
          end)
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
        -- `neotest.state` exposes exactly `adapter_ids`, `positions` and
        -- `status_counts` -- there is no `get_results`, so the previous call
        -- threw "attempt to call a nil value" here on every
        -- `NeotestRunComplete`, inside a scheduled callback where nothing
        -- caught it.
        --
        -- `status_counts` is the closest the consumer API gets, but it is
        -- SUITE state, not this run's: the panel opens whenever anything is
        -- currently failing, which after a green run over a still-red suite
        -- is not quite "this run failed". There is no per-run result list on
        -- the public surface to be more precise with.
        local has_failed = false
        for _, adapter_id in ipairs(neotest.state.adapter_ids() or {}) do
          local counts = neotest.state.status_counts(adapter_id)
          if counts and (counts.failed or 0) > 0 then
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
---@return nil
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
