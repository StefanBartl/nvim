-- TESTS/plugin_repos/runner_spec.lua -- :MyPlugins runner: the pure data functions (is_known, runner_dir,
-- terminal_name). start/stop/status are not tested here: they drive a real terminal.nvim job (or gh api),
-- not deterministic data in, data out.

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

  -- the dependency overrides (`*_NVIM_DIR`) are not handed to a started runner (twin of runners.ps1, e4b3147)
  local environ = {
    LIB_NVIM_DIR = "x",
    TESTING_NVIM_DIR = "x",
    lib_nvim_dir = "x",
    SNACKS_DIR = "x", -- no .nvim suffix: a known gap, kept in step with the PowerShell regex
    NVIM_DIR_X = "x",
    PATH = "x",
  }
  eq(
    runner.override_names(environ, true),
    { "LIB_NVIM_DIR", "TESTING_NVIM_DIR", "lib_nvim_dir" },
    "case-insensitive: the overrides, in any spelling"
  )
  eq(
    runner.override_names(environ, false),
    { "LIB_NVIM_DIR", "TESTING_NVIM_DIR" },
    "case-sensitive: only the upper-case names"
  )

  local uv = vim.uv or vim.loop
  local win = require("lib.nvim.cross.platform.is_windows")()
  local mine =
    { "ZZSPEC_NVIM_DIR", win and "zzspec2_nvim_dir" or "ZZSPEC2_NVIM_DIR", "ZZSPEC_OTHER_DIR" }
  local before = {}
  for _, n in ipairs(mine) do
    before[n] = uv.os_getenv(n)
    uv.os_setenv(n, "keep:" .. n)
  end
  local seen
  local fake = {
    names = function()
      return {}
    end,
    run = function()
      seen = {}
      for _, n in ipairs(mine) do
        seen[n] = uv.os_getenv(n)
      end
      return true, nil, {}
    end,
  }
  local userprofile = vim.env.USERPROFILE
  local home = H.tmpdir()
  H.write(home .. "/actions-runners/casedesk.nvim/run.cmd", "@echo off\n")
  vim.env.USERPROFILE = home
  runner._terminal = fake
  local started = pcall(runner.start, "casedesk.nvim")
  runner._terminal = nil
  vim.env.USERPROFILE = userprofile
  local after = {}
  for _, n in ipairs(mine) do
    after[n] = uv.os_getenv(n)
    uv.os_unsetenv(n)
    if before[n] then
      uv.os_setenv(n, before[n])
    end
  end
  ok(started and seen, "runner start reached term.run")
  eq(seen.ZZSPEC_NVIM_DIR, nil, "the runner start has no *_NVIM_DIR override in its environment")
  eq(seen[mine[2]], nil, "... in either case spelling that this system treats as the same name")
  eq(seen.ZZSPEC_OTHER_DIR, "keep:ZZSPEC_OTHER_DIR", "... and other variables are kept")
  eq(
    after.ZZSPEC_NVIM_DIR,
    "keep:ZZSPEC_NVIM_DIR",
    "the editor's own environment is restored afterwards"
  )
  eq(after[mine[2]], "keep:" .. mine[2], "... also the second spelling")

  -- restored when the start throws, and the error comes through unchanged
  uv.os_setenv("ZZSPEC_NVIM_DIR", "again")
  local thrown, thrown_why = pcall(runner.without_overrides, function()
    error("boom", 0)
  end)
  eq(thrown, false, "an error inside the clean run propagates")
  eq(thrown_why, "boom", "... unchanged")
  eq(uv.os_getenv("ZZSPEC_NVIM_DIR"), "again", "... and the environment is restored")
  eq(
    { runner.without_overrides(function()
      return 1, nil, 3
    end) },
    { 1, nil, 3 },
    "the results of the function are returned"
  )
  uv.os_unsetenv("ZZSPEC_NVIM_DIR")
  if before.ZZSPEC_NVIM_DIR then
    uv.os_setenv("ZZSPEC_NVIM_DIR", before.ZZSPEC_NVIM_DIR)
  end
end
