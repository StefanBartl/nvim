---@module 'config.neotest.autocmds.auto_discovery'
--- Forces neotest to discover tests once on project open (deferred,
--- `neotest.state.clear` + a discovery pass) instead of waiting for the
--- first manual test run to trigger it.
--
--- CDX: M.attach() is never called -- the require in plugins/neotest.lua is
--- commented out, and this module is flagged unreferenced-module by
--- docs/map/overview.md. Whether auto-discovery should be reactivated or
--- kept deliberately off is an open decision, see
--- docs/ROADMAP/IDEAS/test.md §2/§10.

local Autocmd = require("lib.nvim.bindings.autocmd")

local M = {}

--- Force initial test discovery on project open
local function force_initial_discovery()
  vim.defer_fn(function()
    local ok, neotest = pcall(require, "neotest")
    if not ok then
      return
    end

    -- Trigger discovery without running a test
    pcall(neotest.state.clear)

    vim.defer_fn(function()
      -- Refresh Neo-tree tests source
      pcall(function()
        require("neo-tree.sources.manager").refresh("tests")
      end)
    end, 1000)
  end, 2000) -- 2s delay after startup
end

-- Auto-discovery on VimEnter
---@return nil
function M.attach()
  Autocmd.create("VimEnter", force_initial_discovery, {
    once = true,
    desc = "[neotest] Initial test discovery",
  })
end

return M
