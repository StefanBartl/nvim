---@module 'config.snacks.mappings.extended'
--- Keymap definitions for the optional Snacks submodules that are actually
--- enabled in `plugins/snacks.lua`: debug and quickfile.
--- Expose keys() which returns the array expected by the plugin spec.
---
--- This file used to bind keys for `dim`, `profiler`, `scope` and `scratch`
--- as well. All four are `enabled = false` in the spec, so every one of
--- those keys could only ever answer with `safe_call`'s "missing" warning --
--- and `<leader>ns` (scratch) sat on the same lhs as Neo-tree's source
--- switcher. Enable a module in the spec first; then its keys belong here.
--- The profiler's own-side home is runtime-analysis.nvim (`:RA`).

local notify = require("lib.nvim.notify").create("[config.snacks.mappings]")

local M = {}

--- Safely dispatch a call into a snacks submodule.
--- @param mod string
--- @param fn string
--- @param ... any
--- @return boolean
local function safe_call(mod, fn, ...)
  local ok_mod, Mmod = pcall(require, "snacks." .. mod)
  if not ok_mod or type(Mmod[fn]) ~= "function" then
    notify.warn(string.format("[snacks] missing %s.%s()", mod, fn))
    return false
  end
  local ok_fn, err = pcall(Mmod[fn], ...)
  if not ok_fn then
    notify.error(string.format("[snacks] %s.%s(): %s", mod, fn, tostring(err)))
    return false
  end
  return true
end

--- Return keymap table for lazy spec.
--- @return (string|function|table)[]
function M.keys()
  ---@type (string|function|table)[]
  local maps = {}

  maps[1] = {
    "<leader>ud",
    function()
      safe_call("debug", "open")
    end,
    desc = "Snacks Debug: Open Inspector",
  }
  maps[2] = {
    "<leader>uD",
    function()
      safe_call("debug", "toggle")
    end,
    desc = "Snacks Debug: Toggle Overlay",
  }
  maps[3] = {
    "<leader>uq",
    function()
      safe_call("quickfile", "disable")
    end,
    desc = "Snacks Quickfile: Disable (session)",
  }

  return maps
end

---@type Cfg.Snacks.Mappings.Module
return M
