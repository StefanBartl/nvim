---@module 'bindings.usrcmds.plugin_repos.runner'
---@brief `:MyPlugins runner start|stop|status [repo]` - the GitHub Actions self-hosted runner of a private repo.
---@description
--- casedesk.nvim and my.nvim are private with no paid GitHub plan, so their CI runs on a self-hosted runner on
--- this machine instead of GitHub-hosted minutes (tasks-vault/TOOLS/self-hosted-runner.md has the one-time setup).
--- The runner is a long-lived process (`run.cmd` in its own directory under
--- `%USERPROFILE%\actions-runners\<repo>`) that listens for jobs; nothing starts it automatically, so a push stays
--- "Queued" (discarded after 24h, no red mark) until someone starts it.
---
---  - `runner start [repo]`    launch run.cmd of one runner (or all) in a terminal.nvim split `runner-<repo>`;
---                             a no-op if that split is already running
---  - `runner stop [repo]`     stop the terminal's job (kills run.cmd and the Runner.Listener.exe it spawned)
---  - `runner status [repo]`   ask GitHub whether the runner is online/offline/busy (`gh api`)
---
--- This is the GitHub-registered runner SERVICE, not `:MyPlugins ci` (`ci.lua`), which runs `scripts/ci.sh`
--- locally without going through GitHub Actions at all -- the two are independent and both exist.
---
--- No "install as a Windows service" here on purpose: that needs an elevated shell
--- (`setup-runner.ps1 -Service`, see the doc) and is a one-time, manual, admin-rights step, not something a
--- usercmd should do on an ordinary Neovim session.

local notify = require("lib.nvim.notify").create("[usrcmds.plugin_repos.runner]")

local M = {}

local uv = vim.uv or vim.loop

---The repos with a registered self-hosted GitHub Actions runner.
M.REPOS = { "casedesk.nvim", "my.nvim" }

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
  return "StefanBartl/" .. name
end

---Name of the terminal that shows a runner's listener output.
---@param name string
---@return string
function M.terminal_name(name)
  return "runner-" .. name
end

---terminal.nvim, when it can run a listener (same contract `ci.lua` uses, minus the backend check: a runner's
---output is not time-critical the way a CI job's completion report is, so tmux/WezTerm are fine here too).
---@return table|nil term
---@return string|nil why
local function terminal_module()
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
  local ok, started, err = pcall(term.run, { dir .. "/run.cmd" }, {
    name = M.terminal_name(name),
    direct = true,
    cwd = dir,
    layout = "split",
    focus = false,
    start_insert = false,
    close = "never",
    session = false,
  })
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
      desc = "Start the self-hosted GitHub Actions runner of one private repo (or all of them: casedesk.nvim, my.nvim) in a terminal.nvim split runner-<repo>",
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
  }
end

return M
