---@module 'plugins.personal.machine'
---@brief Machine-role detection for per-machine plugin behavior overrides.
---@description
--- Reads the `NVIM_MACHINE_ROLE` environment variable (case-insensitive).
--- Cross-platform: `vim.env` works the same on Windows/Linux/macOS, only how
--- you *set* a persistent env var differs by OS/shell:
---   Windows (persists across sessions): setx NVIM_MACHINE_ROLE workstation
---   POSIX (add to shell rc, e.g. .bashrc/.zshrc):
---     export NVIM_MACHINE_ROLE=workstation
---
--- Unset/unknown → "default" (today's PC behavior: local dev checkouts,
--- full github_stats fetching, ...). Add a new role by adding it to ROLES
--- below; callers then gate behavior with `machine.is("that_role")`.

local M = {}

local notify = require("lib.nvim.notify").create("[plugins.personal.machine]")

---@alias MachineRole "default"|"workstation"

--- Known roles. Extend this when a new per-machine behavior split is needed.
---@type table<string, boolean>
local ROLES = {
  default = true,
  workstation = true,
}

---@type MachineRole
local role = "default"

do
  local env_value = vim.env.NVIM_MACHINE_ROLE
  if type(env_value) == "string" and env_value ~= "" then
    local normalized = env_value:lower()
    if ROLES[normalized] then
      role = normalized
    else
      notify.warn(
        ("Unknown NVIM_MACHINE_ROLE '%s', falling back to 'default'"):format(env_value)
      )
    end
  end
end

---@return MachineRole
function M.role()
  return role
end

---@param r MachineRole
---@return boolean
function M.is(r)
  return role == r
end

return M
