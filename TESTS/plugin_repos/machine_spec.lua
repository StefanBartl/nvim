-- TESTS/plugin_repos/machine_spec.lua -- :MyPlugins machine: the argv that runs scripts/sync-machine.ps1.
--
-- The command is read-only unless --pull is given, so the one thing that must hold is that
-- -Pull appears in the argv exactly when asked for, and that the script it points at exists.

return function(H)
  local eq, ok = H.eq, H.ok
  local machine = require("bindings.usrcmds.plugin_repos.machine")

  local base = machine.build_cmd({ shell = "pwsh", script = "S.ps1" })
  eq(base, { "pwsh", "-NoProfile", "-File", "S.ps1" }, "report-only argv has no -Pull")

  local pull = machine.build_cmd({ shell = "pwsh", script = "S.ps1", pull = true })
  eq(pull[#pull], "-Pull", "--pull adds -Pull")

  local only = machine.build_cmd({ shell = "pwsh", script = "S.ps1", only = "a,b" })
  eq({ only[#only - 1], only[#only] }, { "-Only", "a,b" }, "--only passes the list as ONE argument")

  eq(
    #machine.build_cmd({ shell = "pwsh", script = "S.ps1", only = "" }),
    4,
    "empty --only adds nothing"
  )

  ok((vim.uv or vim.loop).fs_stat(machine.script_path()), "the script exists in this config")

  local routes = machine.routes()
  eq(routes[1].path, { "machine" }, "route path")
end
