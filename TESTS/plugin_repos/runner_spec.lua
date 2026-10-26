-- TESTS/plugin_repos/runner_spec.lua -- :MyPlugins runner: the pure data functions (is_known, runner_dir,
-- terminal_name). start/stop/status are not tested here, same as ci.lua's own spec leaves M.run untested:
-- both drive a real terminal.nvim job (or gh api), not deterministic data in, data out.

return function(H)
  local eq, ok = H.eq, H.ok
  local runner = require("bindings.usrcmds.plugin_repos.runner")

  for _, name in ipairs({
    "casedesk.nvim",
    "my.nvim",
    "tasks.nvim",
    "rules.nvim",
    "tasks-vault",
    "rules-vault",
    "appkit",
    "tasks-desktop",
    "rules-desktop",
  }) do
    ok(runner.is_known(name), name .. " has a self-hosted runner")
  end
  ok(not runner.is_known("lib.nvim"), "a repo with no self-hosted runner is not known")

  local saved = vim.env.USERPROFILE
  vim.env.USERPROFILE = "C:\\Users\\tester"
  eq(
    runner.runner_dir("casedesk.nvim"),
    "C:/Users/tester/actions-runners/casedesk.nvim",
    "runner_dir is USERPROFILE/actions-runners/<name>, forward slashes"
  )
  vim.env.USERPROFILE = saved

  eq(
    runner.terminal_name("casedesk.nvim"),
    "runner-casedesk.nvim",
    "terminal name is runner-<repo>"
  )
end
