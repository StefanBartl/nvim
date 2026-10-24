-- TESTS/plugin_repos/ci_spec.lua -- :MyPlugins ci: argv, status line, the pre-push hook and its safety rules.
--
-- The hook must never overwrite or delete a hook that is not ours; the argv must carry --fast exactly when asked.

return function(H)
  local eq, ok = H.eq, H.ok
  local ci = require("bindings.usrcmds.plugin_repos.ci")

  eq(ci.build_cmd("R", false, "B"), { "B", "R/scripts/ci.sh" }, "plain argv")
  eq(ci.build_cmd("R", true, "B"), { "B", "R/scripts/ci.sh", "--fast" }, "--fast is passed on")

  ok(
    ci.is_known("rules-vault")
      and ci.is_known("casedesk.nvim")
      and ci.is_known("tasks-vault")
      and ci.is_known("my.nvim"),
    "the four repos"
  )
  ok(not ci.is_known("lib.nvim"), "other repos have no local CI")

  eq(ci.parse_last("not json"), nil, "garbage is no result")
  local last = ci.parse_last('{"commit":"abc","time":"T","state":"green","note":""}')
  eq(last and last.state, "green", "state is read")

  ok(ci.status_line("r", nil, "abc"):find("no run yet", 1, true), "no file, no run")
  ok(ci.status_line("r", last, "abc"):find("current commit", 1, true), "same commit is current")
  ok(ci.status_line("r", last, "def"):find("older commit", 1, true), "moved HEAD is flagged")
  local dirty = { commit = "abc", dirty = true, time = "T", state = "green", note = "" }
  ok(
    ci.status_line("r", dirty, "abc"):find("uncommitted", 1, true),
    "a green run on uncommitted files is not current"
  )
  eq(
    ci.parse_last('{"commit":"a","dirty":true,"time":"T","state":"green"}').dirty,
    true,
    "dirty is read"
  )
  eq(
    ci.parse_last('{"commit":"a","time":"T","state":"green"}').dirty,
    false,
    "dirty defaults to false"
  )
  local red = { commit = "abc", time = "T", state = "red", note = "luacheck" }
  local line = ci.status_line("r", red, "abc")
  ok(line:find("RED", 1, true) and line:find("luacheck", 1, true), "red shows the failing step")

  -- The hook file in a throwaway repo below REPOS_DIR.
  local base = vim.fn.tempname()
  vim.fn.mkdir(base .. "/rules-vault", "p")
  vim.system({ "git", "init", "-q", base .. "/rules-vault" }):wait()
  local saved = vim.env.REPOS_DIR
  vim.env.REPOS_DIR = base
  local hooks = ci.hooks_dir(base .. "/rules-vault")
  ok(hooks and vim.fn.isdirectory(hooks) == 1, "git names the hook folder of a checkout")
  eq(ci.hooks_dir(base .. "/no-such-dir"), nil, "no checkout, no hook folder")
  local path = hooks .. "/pre-push"

  local function read()
    local fd = io.open(path, "r")
    if not fd then
      return nil
    end
    local text = fd:read("*a")
    fd:close()
    return text
  end

  ci.hook("install", "rules-vault")
  eq(read(), ci.hook_text(), "install writes our hook")
  ok(read():find("--fast", 1, true), "the hook runs the fast gates")
  ok(read():find('bash "$root/scripts/ci.sh"', 1, true), "the hook does not depend on the exec bit")

  ci.hook("install", "rules-vault")
  eq(read(), ci.hook_text(), "install twice is idempotent")

  ci.hook("remove", "rules-vault")
  eq(read(), nil, "remove deletes our hook")

  local foreign = "#!/bin/sh\necho foreign\n"
  local fd = assert(io.open(path, "wb"))
  fd:write(foreign)
  fd:close()
  ci.hook("install", "rules-vault")
  eq(read(), foreign, "a foreign hook is not overwritten")
  ci.hook("remove", "rules-vault")
  eq(read(), foreign, "a foreign hook is not removed")

  -- Where a run shows its output: a terminal.nvim split per repo by default, the quickfix list with --quiet
  -- or without a native terminal.nvim. A fake terminal.nvim stands in for the real one.
  local dir = base .. "/rules-vault"
  vim.fn.mkdir(dir .. "/scripts", "p")
  H.write(dir .. "/scripts/ci.sh", "exit 0\n")

  local topts = ci.terminal_opts("rules-vault", dir, function() end)
  eq(topts.name, "ci-rules-vault", "one terminal per repo")
  ok(topts.direct == true and topts.cwd == dir, "the script is the job, in the repo")
  ok(topts.focus == false and topts.start_insert == false, "the run does not take the focus")
  ok(
    topts.close == "never" and topts.session == false,
    "the output stays, a session never reruns it"
  )

  local saved_term = package.loaded["terminal"]
  local calls, closed = {}, {}
  local function fake(backend, behave)
    calls, closed = {}, {}
    package.loaded["terminal"] = {
      status = function()
        return { ready = true, backend = backend }
      end,
      run = function(cmd, o)
        calls[#calls + 1] = { cmd = cmd, opts = o }
        return behave(o)
      end,
      close = function(target)
        closed[#closed + 1] = target.name
      end,
    }
  end
  local function qf_text()
    return table.concat(
      vim.tbl_map(function(item)
        return item.text
      end, vim.fn.getqflist()),
      "\n"
    )
  end
  local function run_and_wait(opts)
    ci.run(opts)
    ok(
      vim.wait(10000, function()
        return not ci.busy()
      end, 20),
      "the run ends"
    )
    return ci.last_results
  end

  fake("native", function(o)
    o.on_exit(3)
    o.on_exit(3)
    return true
  end)
  local res = run_and_wait({ repo = "rules-vault", fast = true })
  eq(#calls, 1, "the native terminal runs the script")
  local argv = calls[1].cmd
  ok(
    argv[1] == ci.bash()
      and argv[2]:sub(-26) == "/rules-vault/scripts/ci.sh"
      and argv[3] == "--fast",
    "with the argv of the run"
  )
  eq(calls[1].opts.name, "ci-rules-vault", "in the terminal of the repo")
  eq(#res, 1, "a second exit report is ignored")
  eq(res[1].code, 3, "the exit code of the terminal is the verdict")

  fake("native", function()
    return false, "no window"
  end)
  vim.fn.setqflist({}, "r")
  res = run_and_wait({ repo = "rules-vault" })
  eq(res[1] and res[1].code, 1, "a terminal that does not start is a red run, not a hang")
  eq(res[1].shown, false, "and no terminal holds its output")
  ok(
    qf_text():find("cannot open a terminal: no window", 1, true),
    "the reason is in the quickfix list"
  )

  fake("native", function()
    error("boom")
  end)
  res = run_and_wait({ repo = "rules-vault" })
  eq(res[1] and res[1].code, 1, "a terminal.nvim that throws is a red run, not a crash")

  fake("native", function(o)
    o.on_exit(0)
    return true
  end)
  res = run_and_wait({ repo = "rules-vault", quiet = true })
  eq(#calls, 0, "--quiet opens no terminal")
  eq(res[1] and res[1].code, 0, "--quiet runs the script itself")

  fake("tmux", function(o)
    o.on_exit(0)
    return true
  end)
  eq(ci.terminal_module(), nil, "a backend that does not report the end of a job is not used")
  res = run_and_wait({ repo = "rules-vault" })
  eq(#calls, 0, "on tmux the run goes to the quickfix list")
  eq(res[1] and res[1].code, 0, "and still runs")

  -- The real order: the exit comes later (scheduled), and the next repo starts only after it. A repo
  -- without scripts/ci.sh has no terminal: its reason goes to the quickfix list, the others stay out.
  local saved_repos = ci.REPOS
  vim.fn.mkdir(base .. "/tasks-vault/scripts", "p")
  H.write(base .. "/tasks-vault/scripts/ci.sh", "exit 0\n")
  ci.REPOS = { "rules-vault", "casedesk.nvim", "tasks-vault" }
  local exits = 0
  fake("native", function(o)
    o.exits_before = exits
    vim.schedule(function()
      exits = exits + 1
      o.on_exit(o.name == "ci-tasks-vault" and 2 or 0)
    end)
    return true
  end)
  vim.fn.setqflist({}, "r")
  res = run_and_wait({})
  eq(#calls, 2, "a terminal for each repo that has a script")
  eq(calls[2].opts.exits_before, 1, "the next repo starts after the exit of the one before")
  eq(
    vim.tbl_map(function(r)
      return r.repo .. "=" .. r.code
    end, res),
    { "rules-vault=0", "casedesk.nvim=1", "tasks-vault=2" },
    "every repo has its verdict, in order"
  )
  local qf = qf_text()
  ok(qf:find("scripts/ci.sh not found", 1, true), "the missing script is in the quickfix list")
  ok(not qf:find("tasks-vault", 1, true), "a run with a terminal is not")

  -- A terminal that is still running after the timeout is closed, and the run goes on.
  local saved_timeout = ci.TIMEOUT_MS
  ci.TIMEOUT_MS = 50
  ci.REPOS = saved_repos
  fake("native", function()
    return true
  end)
  vim.fn.setqflist({}, "r")
  res = run_and_wait({ repo = "rules-vault" })
  ci.TIMEOUT_MS = saved_timeout
  eq(res[1] and res[1].code, 124, "a run that does not end times out")
  eq(closed, { "ci-rules-vault" }, "its terminal is closed")
  ok(qf_text():find("timed out", 1, true), "the timeout is in the quickfix list")

  package.loaded["terminal"] = saved_term

  vim.env.REPOS_DIR = saved
  vim.fn.delete(base, "rf")
end
