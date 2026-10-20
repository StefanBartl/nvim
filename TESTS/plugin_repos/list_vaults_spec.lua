-- TESTS/plugin_repos/list_vaults_spec.lua -- the vaults are cloned by :MyPlugins clone but are not plugins.
--
-- read() feeds remove/sync/picker/statusline and must never contain a vault; read_for_clone() adds them.

return function(H)
  local eq = H.eq
  local saved = package.loaded["plugins.personal"]
  package.loaded["plugins.personal"] = { { "Owner/a.nvim" }, { "Owner/b.nvim", enabled = false } }
  package.loaded["plugins.personal.core.list"] = nil
  local list = require("plugins.personal.core.list")

  local plain = list.read()
  eq(#plain, 1, "read() has the enabled plugin only")
  eq(plain[1].name, "a.nvim", "read() has no vault")

  local names = {}
  for _, entry in ipairs(list.read_for_clone()) do
    names[#names + 1] = entry.name
  end
  eq(names, { "a.nvim", "rules-vault", "tasks-vault" }, "read_for_clone() adds the vaults")
  eq(#list.read(), 1, "read_for_clone() does not leak into read()")

  package.loaded["plugins.personal"] = saved
  package.loaded["plugins.personal.core.list"] = nil
end
