---@module 'bindings.usrcmds.native_repos.workstation'
---@brief The workstation block: nothing this config offers may build, install or start a native program there.
---@description
--- On the Tricentis workstation an own unsigned program is exactly what CrowdStrike Falcon reports
--- (since 2026-10-27). The config is the same on both machines, so every path that builds, installs
--- or starts a native app asks `refused()` first: `:MyNative build|install|deps` and `B` of
--- `:MyPlugins machine`. The lazy.nvim `build` hooks that compile native code (fzf-native's cmake,
--- mdview's Go server) go through `lazy_build()` and are left out there. Removing is still allowed (`:MyNative uninstall`), and so is everything
--- that only reads or copies (`list`, `clone`, `pull`, `b`).
---
--- The role comes from `machine.lua` (`NVIM_MACHINE_ROLE`), asked at call time and never cached,
--- so a spec can simulate the workstation by replacing `require("machine").is`.

local notify = require("lib.nvim.notify").create("[native workstation block]")

local M = {}

---Is this the workstation?
---@return boolean
function M.active()
  return require("machine").is("workstation")
end

---The message a refused action shows.
---@param what string  # e.g. ":MyNative install"
---@return string
function M.message(what)
  return (
    "%s is blocked on the workstation (NVIM_MACHINE_ROLE=workstation): no own unsigned program may be "
    .. "built, installed or started here (CrowdStrike Falcon / EDR). Build on the private machine; "
    .. ":MyNative uninstall still works."
  ):format(what)
end

---Refuse `what` on the workstation: shows the message and returns true; elsewhere false and silent.
---@param what string
---@return boolean refused
function M.refused(what)
  if not M.active() then
    return false
  end
  notify.error(M.message(what))
  return true
end

---The `build` value of a lazy.nvim spec whose hook compiles native code: `cmd` elsewhere, and on
---the workstation `instead` (nil = no build at all). Lazy runs a `build` on every install and update
---of the plugin, so without this the hook would build an unsigned program there unasked.
---Evaluated when the spec file is read; the role does not change while Neovim runs.
---@param cmd string|fun()
---@param instead? string|fun()  # what may still run on the workstation (no native compile step)
---@return string|fun()|nil
function M.lazy_build(cmd, instead)
  if M.active() then
    return instead
  end
  return cmd
end

return M
