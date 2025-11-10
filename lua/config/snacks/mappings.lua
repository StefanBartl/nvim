---@module 'config.snacks.custom_dashboard.mappings'
--- Keymap definitions for custom Snacks dashboard.
--- Expose keys() which returns the array expected by the plugin spec.

local M = {}

--- Safe dispatcher to call snacks submodules safely.
--- @param mod string
--- @param fn string
--- @param ... any
--- @return boolean
local function safe_call(mod, fn, ...)
  local ok_mod, Mmod = pcall(require, "snacks." .. mod)
  if not ok_mod or type(Mmod[fn]) ~= "function" then
    vim.notify(string.format("[snacks] missing %s.%s()", mod, fn), vim.log.levels.WARN)
    return false
  end
  local ok_fn, err = pcall(Mmod[fn], ...)
  if not ok_fn then
    vim.notify(string.format("[snacks] %s.%s(): %s", mod, fn, tostring(err)), vim.log.levels.ERROR)
    return false
  end
  return true
end

--- Return keymap table for lazy spec.
--- @return (string|function|table)[]
function M.keys()
  ---@type (string|function|table)[]
  local maps = {}

  maps[1]  = { "<leader>ud", function() safe_call("debug", "open") end, desc = "Snacks Debug: Open Inspector" }
  maps[2]  = { "<leader>uD", function() safe_call("debug", "toggle") end, desc = "Snacks Debug: Toggle Overlay" }
  maps[3]  = { "<leader>uf", function() safe_call("dim", "toggle") end, desc = "Snacks Dim: Toggle Focus Scope" }
  maps[4]  = { "<leader>ps", function() safe_call("profiler", "start") end, desc = "Snacks Profiler: Start" }
  maps[5]  = { "<leader>pS", function() safe_call("profiler", "stop") end, desc = "Snacks Profiler: Stop" }
  maps[6]  = { "<leader>pr", function() safe_call("profiler", "report") end, desc = "Snacks Profiler: Report" }
  maps[7]  = { "<leader>uq", function() safe_call("quickfile", "disable") end, desc = "Snacks Quickfile: Disable (session)" }
  maps[8]  = { "]s", function() safe_call("scope", "jump_next") end, desc = "Snacks Scope: Next" }
  maps[9]  = { "[s", function() safe_call("scope", "jump_prev") end, desc = "Snacks Scope: Prev" }
  maps[10] = { "<leader>ns", function() safe_call("scratch", "open") end, desc = "Snacks Scratch: Open" }
  maps[11] = { "<leader>nS", function() safe_call("scratch", "new") end, desc = "Snacks Scratch: New" }

  return maps
end

return M
