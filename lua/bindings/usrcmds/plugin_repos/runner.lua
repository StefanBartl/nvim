---@module 'bindings.usrcmds.plugin_repos.runner'
---@brief `:MyPlugins runner start|stop|status [repo]`, `runner autostart on|off|status` - the GitHub Actions self-hosted runner of a private repo.
---@description
--- The private repos (casedesk.nvim, my.nvim, tasks.nvim, rules.nvim, tasks-vault, rules-vault, appkit, tasks-desktop,
--- rules-desktop, ai-desktop, docmap-desktop) have no paid GitHub
--- plan, so their CI runs on a self-hosted runner on this machine instead of GitHub-hosted minutes (tasks-vault/TOOLS/self-hosted-runner.md has the one-time setup).
--- The runner is a long-lived process (`run.cmd` in its own directory under
--- `%USERPROFILE%\actions-runners\<repo>`) that listens for jobs; nothing starts it automatically, so a push stays
--- "Queued" (discarded after 24h, no red mark) until someone starts it.
---
---  - `runner start [repo]`    launch run.cmd of one runner (or all) in a terminal.nvim split `runner-<repo>`;
---                             a no-op if that split is already running
---  - `runner stop [repo]`     stop the terminal's job (kills run.cmd and the Runner.Listener.exe it spawned)
---  - `runner status [repo]`   ask GitHub whether the runner is online/offline/busy (`gh api`)
---
---  - `runner autostart on|off|status`  a scheduled task "GitHub Runners" of this user that runs
---                             `scripts/runners.ps1 ensure all` at every logon (no elevated shell needed on most
---                             machines); `off` removes it
---
--- This is the GitHub-registered runner SERVICE, not local CI: `testing ci` / `:Testing ci` (testing.nvim) runs a
--- repo's pipeline on this machine without going through GitHub Actions at all -- the two are independent.
---
--- No "install as a Windows service" here on purpose: that needs an elevated shell
--- (`setup-runner.ps1 -Service`, see the doc) and is a one-time, manual, admin-rights step, not something a
--- usercmd should do on an ordinary Neovim session.

local notify = require("lib.nvim.notify").create("[usrcmds.plugin_repos.runner]")

local M = {}

local uv = vim.uv or vim.loop

---The repos with a registered self-hosted GitHub Actions runner.
M.REPOS = {
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
}

---Name of the scheduled task that starts the runners at logon (`runner autostart on`).
M.AUTOSTART_TASK = "GitHub Runners"

---@param name string
---@return boolean
function M.is_known(name)
  return vim.tbl_contains(M.REPOS, name)
end

---`%USERPROFILE%\actions-runners\<name>`, forward slashes.
---@param name string
---@return string
function M.runner_dir(name)
  return (vim.env.USERPROFILE or ""):gsub("\\", "/") .. "/actions-runners/" .. name
end

---Full "owner/repo" for `gh api`, resolved from the actual plugin spec rather than a hardcoded owner (falls
---back to this author's own account when the spec lookup fails, e.g. plugins.personal not loadable here).
---@param name string
---@return string
local function owner_repo(name)
  local ok, list = pcall(require, "plugins.personal.core.list")
  if ok then
    local entries = list.read()
    if entries then
      for _, e in ipairs(entries) do
        if e.name == name then
          return e.repo
        end
      end
    end
  end
  return "WKDSteve/" .. name
end

---Name of the terminal that shows a runner's listener output.
---@param name string
---@return string
function M.terminal_name(name)
  return "runner-" .. name
end

---Lua pattern of the dependency-checkout overrides (`LIB_NVIM_DIR=<local checkout>`, ...) that `scripts/test.sh`
---lets win over `.deps/`. Twin of the regex in `scripts/runners.ps1` (`^[A-Z0-9_]+_NVIM_DIR$`); the two cannot
---share code (PowerShell vs Lua), so a change goes into both. Known gaps, harmless today: no `.nvim` suffix
---(`SNACKS_DIR`, `NVIM_TREE_LUA_DIR`) and the old spelling `LIB_NVIM_PATH`.
M.OVERRIDE_PATTERN = "^[A-Z0-9_]+_NVIM_DIR$"

---The names in `environ` that are dependency overrides. Windows environment names are case-insensitive, so they
---are matched upper-cased there (the returned names keep their spelling, they are what `os_unsetenv` needs).
---@param environ table<string, string> Like `vim.fn.environ()`.
---@param case_insensitive? boolean Default: true on Windows.
---@return string[] names Sorted.
function M.override_names(environ, case_insensitive)
  if case_insensitive == nil then
    case_insensitive = require("lib.nvim.cross.platform.is_windows")()
  end
  local names = {}
  for name in pairs(environ) do
    local key = case_insensitive and name:upper() or name
    if key:match(M.OVERRIDE_PATTERN) then
      names[#names + 1] = name
    end
  end
  table.sort(names)
  return names
end

---Run `fn` with the dependency overrides taken out of THIS editor's environment, then put them back (also when
---`fn` throws). A runner started from the editor is a child of it and would inherit `LIB_NVIM_DIR`, so CI would
---test the working tree instead of ci-verified (same bug as `scripts/runners.ps1`, fixed there in e4b3147).
---`term.run` can only ADD to a child's environment (`env`), never remove, hence the in-process removal; it is
---safe because the native backend spawns the job synchronously inside `term.run`.
---@param fn fun(): ...
---@return any ... Whatever `fn` returned.
function M.without_overrides(fn)
  local saved = {}
  for _, name in ipairs(M.override_names(vim.fn.environ())) do
    saved[name] = vim.uv.os_getenv(name)
    vim.uv.os_unsetenv(name)
  end
  local res = vim.F.pack_len(pcall(fn))
  for name, value in pairs(saved) do
    vim.uv.os_setenv(name, value)
  end
  if not res[1] then
    error(res[2], 0)
  end
  return unpack(res, 2, res.n)
end

---terminal.nvim, when it can run a listener (same contract the former `ci.lua` used, minus the backend check: a runner's
---output is not time-critical the way a CI job's completion report is, so tmux/WezTerm are fine here too).
---`M._terminal` is a seam for specs (a fake with `names`/`run`).
---@return table|nil term
---@return string|nil why
local function terminal_module()
  if M._terminal then
    return M._terminal, nil
  end
  local ok, term = pcall(require, "terminal")
  if not ok or type(term) ~= "table" or type(term.run) ~= "function" then
    return nil, "terminal.nvim is not available"
  end
  local got, status = pcall(term.status)
  if not got or type(status) ~= "table" or not status.ready then
    return nil, "terminal.nvim is not set up"
  end
  return term, nil
end

---Start one runner's run.cmd in a terminal.nvim split. A no-op (warns) when that split is already running --
---run.cmd refuses a second instance of the same runner anyway, and a stray extra terminal would just confuse
---`stop`'s one-name-per-runner assumption.
---@param name string
local function start_one(name)
  local dir = M.runner_dir(name)
  if not uv.fs_stat(dir .. "/run.cmd") then
    notify.error(
      ("%s: no runner installed at %s (see tasks-vault/TOOLS/self-hosted-runner.md)"):format(
        name,
        dir
      )
    )
    return
  end
  local term, why = terminal_module()
  if not term then
    notify.error(("%s: cannot start without terminal.nvim (%s)"):format(name, why))
    return
  end
  if vim.tbl_contains(term.names(true), M.terminal_name(name)) then
    notify.warn(("%s: already running (terminal %s)"):format(name, M.terminal_name(name)))
    return
  end
  local ok, started, err = pcall(M.without_overrides, function()
    return term.run({ dir .. "/run.cmd" }, {
      name = M.terminal_name(name),
      direct = true,
      cwd = dir,
      layout = "split",
      focus = false,
      start_insert = false,
      close = "never",
      session = false,
    })
  end)
  if not ok or not started then
    notify.error(("%s: cannot start: %s"):format(name, tostring(ok and err or started)))
    return
  end
  notify.info(("%s: runner starting (terminal %s)"):format(name, M.terminal_name(name)))
end

---Start one runner (or all of them).
---@param repo? string
function M.start(repo)
  for _, name in ipairs(repo and { repo } or M.REPOS) do
    start_one(name)
  end
end

---Stop one runner's terminal job (or all of them). A no-op (info, not a warning: "already stopped" is the
---common, expected case) when it is not running.
---@param repo? string
function M.stop(repo)
  local term, why = terminal_module()
  if not term then
    notify.error("cannot stop without terminal.nvim (" .. why .. ")")
    return
  end
  for _, name in ipairs(repo and { repo } or M.REPOS) do
    if not vim.tbl_contains(term.names(true), M.terminal_name(name)) then
      notify.info(("%s: not running"):format(name))
    else
      local ok, err = term.close({ name = M.terminal_name(name) })
      if ok then
        notify.info(("%s: runner stopped"):format(name))
      else
        notify.error(("%s: could not stop: %s"):format(name, tostring(err)))
      end
    end
  end
end

---Ask GitHub whether one runner (or all) is online, and whether it is currently busy.
---@param repo? string
function M.status(repo)
  local names = repo and { repo } or M.REPOS
  local out, any_offline = {}, false
  for _, name in ipairs(names) do
    local res = vim
      .system({
        "gh",
        "api",
        ("repos/%s/actions/runners"):format(owner_repo(name)),
      }, { text = true })
      :wait()
    if res.code ~= 0 then
      out[#out + 1] = ("%-14s gh api failed: %s"):format(name, vim.trim(res.stderr or ""))
      any_offline = true
    else
      local ok, doc = pcall(vim.json.decode, res.stdout or "")
      local runner = ok and type(doc) == "table" and doc.runners and doc.runners[1]
      if not runner then
        out[#out + 1] = ("%-14s no runner registered"):format(name)
        any_offline = true
      else
        local state = runner.busy and (runner.status .. ", busy") or runner.status
        out[#out + 1] = ("%-14s %s"):format(name, state)
        any_offline = any_offline or runner.status ~= "online"
      end
    end
  end
  local text = table.concat(out, "\n")
  if any_offline then
    notify.warn(text)
  else
    notify.info(text)
  end
end

---The schtasks call for `runner autostart on|off|status`: a task of the current user that runs
---`runners.ps1 ensure all` at logon (hidden window). Not a Windows service: that runs as another account without
---this user's PATH (scoop shims, cargo, ...) and needs an elevated shell. Returns the argv, or nil and why.
---@param action "on"|"off"|"status"
---@return string[]|nil argv
---@return string|nil err
function M.autostart_argv(action)
  local task = M.AUTOSTART_TASK
  if action == "off" then
    return { "schtasks", "/Delete", "/TN", task, "/F" }
  elseif action == "status" then
    return { "schtasks", "/Query", "/TN", task, "/FO", "LIST" }
  elseif action == "on" then
    local path = vim.fs.normalize(vim.fn.stdpath("config") .. "/scripts/runners.ps1")
    local script = path:gsub("/", "\\")
    -- /TR is one string that schtasks splits itself; a space in the path would need quotes inside the quotes
    if script:find("%s") then
      return nil, "the path of runners.ps1 has a space (" .. script .. "): create the task by hand"
    end
    local run = ("pwsh -NoProfile -WindowStyle Hidden -File %s ensure all"):format(script)
    return { "schtasks", "/Create", "/SC", "ONLOGON", "/TN", task, "/TR", run, "/F" }
  end
  return nil, "unknown action '" .. tostring(action) .. "' (on, off, status)"
end

---Switch the start at logon on or off, or say whether it is set up.
---@param action "on"|"off"|"status"
function M.autostart(action)
  local argv, why = M.autostart_argv(action)
  if not argv then
    notify.error(why or "autostart: nothing to do")
    return
  end
  local res = vim.system(argv, { text = true }):wait()
  local text = vim.trim((res.stdout or "") .. (res.stderr or ""))
  if res.code == 0 then
    notify.info(("autostart %s: %s"):format(action, text ~= "" and text or "ok"))
  elseif action == "status" then
    notify.warn(
      ("autostart: no scheduled task '%s' (`:MyPlugins runner autostart on` creates it)"):format(
        M.AUTOSTART_TASK
      )
    )
  else
    notify.error(("autostart %s failed (exit %d): %s"):format(action, res.code, text))
  end
end

---The argument type of the repo name (the private repos with a self-hosted runner).
function M.register_types()
  require("lib.nvim.bindings.usercmd.composer").register_type("MYPLUGINS_RUNNER_REPO", {
    desc = "A private repo with a self-hosted GitHub Actions runner (<Tab> lists them)",
    validate = function(raw)
      if M.is_known(raw) then
        return true, raw, nil
      end
      return false,
        nil,
        ("'%s' has no self-hosted runner (%s)"):format(raw, table.concat(M.REPOS, ", "))
    end,
    complete = function(arg_lead)
      return vim.tbl_filter(function(name)
        return arg_lead == "" or name:sub(1, #arg_lead) == arg_lead
      end, M.REPOS)
    end,
  })
end

---@return table[]
function M.routes()
  local repo_arg = { { name = "repo", type = "MYPLUGINS_RUNNER_REPO", optional = true } }
  return {
    {
      path = { "runner", "start" },
      args = repo_arg,
      desc = "Start the self-hosted GitHub Actions runner of one private repo (or all of them: see M.REPOS) in a terminal.nvim split runner-<repo>",
      run = function(ctx)
        M.start(ctx.args.repo)
      end,
    },
    {
      path = { "runner", "stop" },
      args = repo_arg,
      desc = "Stop one runner's terminal job (or all of them)",
      run = function(ctx)
        M.stop(ctx.args.repo)
      end,
    },
    {
      path = { "runner", "status" },
      args = repo_arg,
      desc = "Ask GitHub whether one runner (or all) is online/offline and busy (gh api)",
      run = function(ctx)
        M.status(ctx.args.repo)
      end,
    },
    {
      path = { "runner", "autostart", "on" },
      desc = "Start all runners at every logon (a scheduled task 'GitHub Runners' running scripts/runners.ps1 ensure all)",
      run = function()
        M.autostart("on")
      end,
    },
    {
      path = { "runner", "autostart", "off" },
      desc = "Remove the scheduled task that starts the runners at logon",
      run = function()
        M.autostart("off")
      end,
    },
    {
      path = { "runner", "autostart", "status" },
      desc = "Is the scheduled task that starts the runners at logon set up?",
      run = function()
        M.autostart("status")
      end,
    },
  }
end

return M
