---@module 'bindings.usrcmds.telemetry_nvim_config'
---@brief `:RATelemetryNvimConfig` / `:RATelemetryNvimConfigFull` -- flat
---aliases for `:RATelemetry setup nvim-config` / `:RATelemetry full
---nvim-config`.
---@description
--- Aliases only. The mechanism is entirely runtime-analysis.nvim's own
--- (`opts.telemetry.extra`, wired in config/telemetry.lua and wrapped by the
--- plugin at VimEnter) -- these two commands exist purely because the
--- namespace is reached for often enough here to be worth a name that
--- completes in one Tab, the same reasoning the plugin's own
--- `:RATelemetryStartAll`/`SetupAll` flat aliases already document for the
--- bare subcommand forms.
---
--- Deliberately NOT a second implementation: an earlier version of this file
--- wrapped the config's prefixes itself, which meant two prefix lists (here
--- and in config/telemetry.lua) that could silently drift apart -- the list
--- lives in exactly one place now, and both commands route through the same
--- `:RATelemetry` the plugin registers, so backup prompts, reset semantics
--- and reporting stay identical to every other target.

local usercmd = require("lib.nvim.bindings.usercmd")

local M = {}

---Register both aliases.
function M.enable()
  usercmd.create("RATelemetryNvimConfig", function()
    vim.cmd("RATelemetry setup nvim-config")
  end, {
    desc = "runtime-analysis.telemetry: alias for :RATelemetry setup nvim-config",
  })

  usercmd.create("RATelemetryNvimConfigFull", function()
    vim.cmd("RATelemetry full nvim-config")
  end, {
    desc = "runtime-analysis.telemetry: alias for :RATelemetry full nvim-config",
  })
end

return M
