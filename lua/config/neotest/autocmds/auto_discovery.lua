---@module 'config.neotest.autocmds.auto_discovery'
--- Forces neotest to discover tests once on project open (deferred,
--- `neotest.state.clear` + a discovery pass) instead of waiting for the
--- first manual test run to trigger it.

local Autocmd = require("lib.nvim.bindings.autocmd")

local M = {}

--- Force initial test discovery on project open
local function force_initial_discovery()
  vim.defer_fn(function()
    local ok, neotest = pcall(require, "neotest")
    if not ok then
      return
    end

    -- Trigger discovery ohne Test auszuführen
    pcall(neotest.state.clear)

    vim.defer_fn(function()
      -- Refresh Neo-tree tests source
      pcall(function()
        require("neo-tree.sources.manager").refresh("tests")
      end)
    end, 1000)
  end, 2000) -- 2s Delay nach Startup
end

-- Auto-discovery beim VimEnter
---@return nil
function M.attach()
  Autocmd.create("VimEnter", force_initial_discovery, {
    once = true,
    desc = "[neotest] Initial test discovery",
  })
end

return M
