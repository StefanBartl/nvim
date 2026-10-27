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
    "ai-desktop",
    "docmap-desktop",
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

  eq(#runner.REPOS, 11, "eleven runners are registered")

  -- autostart: the schtasks calls (built, not run: running them would change the real scheduled tasks)
  local on = runner.autostart_argv("on")
  ok(on ~= nil, "autostart on builds a call")
  eq(on[1], "schtasks", "autostart goes through schtasks")
  eq(on[2], "/Create", "on creates the task")
  eq(on[4], "ONLOGON", "the task runs at logon")
  eq(on[6], runner.AUTOSTART_TASK, "the task has the fixed name")
  H.has(on[8], "runners.ps1 ensure all", "the task runs runners.ps1 ensure all")
  H.has(
    on[8],
    "scripts\\runners.ps1",
    "the script path has backslashes (schtasks takes a Windows path)"
  )
  eq(on[#on], "/F", "an existing task is replaced, not an error")
  eq(
    runner.autostart_argv("off"),
    { "schtasks", "/Delete", "/TN", "GitHub Runners", "/F" },
    "off deletes the task"
  )
  eq(
    runner.autostart_argv("status"),
    { "schtasks", "/Query", "/TN", "GitHub Runners", "/FO", "LIST" },
    "status queries the task"
  )
  local argv, why = runner.autostart_argv("nonsense")
  eq(argv, nil, "an unknown action builds nothing")
  H.has(why, "unknown action", "and says why")

  -- the routes: the autostart paths exist and the old ones are still there
  local paths = {}
  for _, r in ipairs(runner.routes()) do
    paths[#paths + 1] = table.concat(r.path, " ")
  end
  for _, p in ipairs({
    "runner start",
    "runner stop",
    "runner status",
    "runner autostart on",
    "runner autostart off",
    "runner autostart status",
  }) do
    ok(vim.tbl_contains(paths, p), "route: " .. p)
  end
end
