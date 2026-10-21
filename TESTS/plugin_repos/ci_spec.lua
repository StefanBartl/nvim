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

  vim.env.REPOS_DIR = saved
  vim.fn.delete(base, "rf")
end
