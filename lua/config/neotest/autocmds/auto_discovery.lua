---@module 'config.neotest.autocmds.auto_discovery'
--- Forces neotest to discover tests once on project open (deferred,
--- `neotest.state.clear` + a discovery pass) instead of waiting for the
--- first manual test run to trigger it.
--
--- CDX: parked -- M.attach() is never called (require in plugins/neotest.lua
--- commented out). Reactivate-or-retire decision: docs/ROADMAP/CDX/config-cdx-triage.md §3,
--- docs/ROADMAP/IDEAS/test.md §2/§10.

local Autocmd = require("lib.nvim.bindings.autocmd")

local M = {}

--- Force initial test discovery on project open
local function force_initial_discovery()
  vim.defer_fn(function()
    -- Only "is neotest there at all" matters: the work below is neo-tree's
    -- refresh, which is what actually drives discovery.
    local ok = pcall(require, "neotest")
    if not ok then
      return
    end

    -- There is no `neotest.state.clear` -- `neotest.state` exposes exactly
    -- `adapter_ids`, `positions` and `status_counts`. The call that used to
    -- stand here was `pcall(neotest.state.clear)`, i.e. `pcall(nil)`: it
    -- returned false and did nothing, every time, while reading as the step
    -- that triggers discovery. Discovery is what the neo-tree refresh below
    -- actually causes, so the dead call is gone rather than replaced.
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
