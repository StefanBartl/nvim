---@module 'bindings.usrcmds.plugin_repos.ci'
---@brief `:MyPlugins ci [repo] [--fast] [--quiet]`, `ci status`, `ci hook install|remove [repo]` - local CI for the private repos.
---@description
--- GitHub-hosted minutes of private repositories are limited, so the CI of the private repos
--- (`rules-vault`, `casedesk.nvim`, `tasks-vault`, `my.nvim`) runs on this machine. Each of them has a
--- `scripts/ci.sh` with exactly the steps of its workflow (the workflow calls the same script; `my.nvim`'s
--- workflow runs the same gates on a self-hosted runner instead), and writes `<repo>/.ci-last.json`
--- (commit, time, state) when it is done.
---
---  - `ci [repo]`            run `scripts/ci.sh` of one repo, or of all of them one after the other
---                           (never in parallel); each runs live in a terminal.nvim split `ci-<repo>`, the verdict
---                           goes to a notification
---  - `ci --quiet`           no terminal: the output goes to the quickfix list (for prompts and agents; also
---                           the way when terminal.nvim is not installed)
---  - `ci --fast`            pass `--fast` (the cheap gates only, what the pre-push hook runs)
---  - `ci status`            per repo: the last result and whether it is for the current commit
---  - `ci hook install|remove [repo]`   a `pre-push` hook that runs `scripts/ci.sh --fast` and blocks the push when
---                           it is red; `git push --no-verify` skips it. A hook that is not ours is never overwritten.
--- Doc: `tasks-vault/ALL/ROADMAP/tasks/lokales-ci-private-repos.md`.

local notify = require("lib.nvim.notify").create("[usrcmds.plugin_repos.ci]")
local ops = require("bindings.usrcmds.plugin_repos.ops")

local M = {}

local uv = vim.uv or vim.loop

---The private repos that have a local CI, in the order `ci` runs them.
M.REPOS = { "rules-vault", "casedesk.nvim", "tasks-vault", "my.nvim" }

---First line of the hook we write; `hook remove` only deletes a file that carries it.
M.HOOK_MARK = "# MyPlugins ci pre-push hook"

---@class MyPlugins.CiResult
---@field repo string
---@field code integer
---@field lines string[]
---@field shown boolean The output is in the terminal `ci-<repo>`, not in `lines`

---@param name string
---@return boolean
function M.is_known(name)
  return vim.tbl_contains(M.REPOS, name)
end

---Git Bash on Windows (the `bash` on PATH may be the WSL launcher, which cannot read Windows script paths).
---@return string
function M.bash()
  if vim.fn.has("win32") == 1 then
    for _, base in ipairs({ vim.env.ProgramFiles, vim.env.ProgramW6432, "C:/Program Files" }) do
      if base and base ~= "" then
        local candidate = base:gsub("\\", "/") .. "/Git/bin/bash.exe"
        if uv.fs_stat(candidate) then
          return candidate
        end
      end
    end
  end
  return "bash"
end

---@param repo_dir string
---@param fast? boolean
---@param bash? string
---@return string[]
function M.build_cmd(repo_dir, fast, bash)
  local cmd = { bash or M.bash(), repo_dir .. "/scripts/ci.sh" }
  if fast then
    cmd[#cmd + 1] = "--fast"
  end
  return cmd
end

---@param base string
---@param name string
---@return string
local function repo_dir(base, name)
  return base .. "/" .. name
end

---Decode the text of a `.ci-last.json`.
---@param text string
---@return { commit: string, dirty: boolean, time: string, state: string, note: string }|nil
function M.parse_last(text)
  local ok, doc = pcall(vim.json.decode, text)
  if not ok or type(doc) ~= "table" or type(doc.state) ~= "string" then
    return nil
  end
  return {
    commit = tostring(doc.commit or ""),
    dirty = doc.dirty == true,
    time = tostring(doc.time or ""),
    state = doc.state,
    note = tostring(doc.note or ""),
  }
end

---One line of `ci status`.
---@param repo string
---@param last { commit: string, dirty?: boolean, time: string, state: string, note: string }|nil
---@param head string|nil Current HEAD of the repo
---@return string
function M.status_line(repo, last, head)
  if not last then
    return ("%-14s no run yet"):format(repo)
  end
  local fresh = head ~= nil and head == last.commit and not last.dirty
  local when = last.time ~= "" and last.time or "?"
  local what = last.state == "green" and "GREEN" or "RED"
  local tail = "current commit"
  if last.dirty then
    tail = "uncommitted files (no proof for the commit)"
  elseif not fresh then
    tail = "an older commit (HEAD moved on)"
  end
  local note = (last.state ~= "green" and last.note ~= "") and (" - " .. last.note) or ""
  return ("%-14s %-5s %s  %s%s"):format(repo, what, when, tail, note)
end

---@param dir string
---@return string|nil
local function head_of(dir)
  local res = vim.system({ "git", "-C", dir, "rev-parse", "HEAD" }, { text = true }):wait()
  if res.code ~= 0 then
    return nil
  end
  return vim.trim(res.stdout or "")
end

---@param dir string
---@return { commit: string, dirty: boolean, time: string, state: string, note: string }|nil
local function read_last(dir)
  local fd = io.open(dir .. "/.ci-last.json", "r")
  if not fd then
    return nil
  end
  local text = fd:read("*a")
  fd:close()
  return M.parse_last(text)
end

---Report the last result of every repo (or of `only`).
---@param only? string
function M.status(only)
  local base = ops.resolve_base_dir(nil)
  if not base then
    notify.error("REPOS_DIR is not set")
    return
  end
  local out, red = {}, false
  for _, name in ipairs(only and { only } or M.REPOS) do
    local dir = repo_dir(base, name)
    if uv.fs_stat(dir) then
      local last = read_last(dir)
      out[#out + 1] = M.status_line(name, last, head_of(dir))
      red = red or (last ~= nil and last.state ~= "green")
    else
      out[#out + 1] = ("%-14s not cloned at %s"):format(name, dir)
    end
  end
  local text = table.concat(out, "\n")
  if red then
    notify.warn(text)
  else
    notify.info(text)
  end
end

---Fill the quickfix list with the output of the runs.
---@param results MyPlugins.CiResult[]
local function to_quickfix(results)
  local items = {}
  for _, res in ipairs(results) do
    items[#items + 1] =
      { text = ("== %s: %s"):format(res.repo, res.code == 0 and "green" or "RED") }
    for _, line in ipairs(res.lines) do
      items[#items + 1] = { text = line }
    end
  end
  vim.fn.setqflist({}, " ", { title = "MyPlugins ci", items = items })
end

local running = false

---What runs now, for the message of a second `ci` (the terminal to look at, or the repo).
---@type string|nil
local current

---Longest a single repo may run (casedesk.nvim needs about two minutes); a terminal that is still
---running then is closed. A field, so the specs can shorten it.
M.TIMEOUT_MS = 15 * 60 * 1000

---The results of the last finished run (for the specs).
---@type MyPlugins.CiResult[]
M.last_results = {}

---@return boolean
function M.busy()
  return running
end

---Name of the terminal that shows the run of a repo.
---@param name string
---@return string
function M.terminal_name(name)
  return "ci-" .. name
end

---Options of terminal.nvim's `run` for the run of one repo: the script is the job itself, in a split
---that keeps the focus where it is and stays open after the job ends, and that a saved session never
---starts again.
---@param name string
---@param dir string
---@param on_exit fun(code: integer)
---@return table # terminal.nvim's `Terminal.RunOpts`
function M.terminal_opts(name, dir, on_exit)
  return {
    name = M.terminal_name(name),
    direct = true,
    cwd = dir,
    layout = "split",
    focus = false,
    start_insert = false,
    close = "never",
    session = false,
    on_exit = on_exit,
  }
end

---terminal.nvim, when it can show a run: installed, set up, and on its `native` backend. The tmux and
---WezTerm backends never report the exit of a job, and the next repo waits for that report.
---@return table|nil term
---@return string|nil why Why there is none
function M.terminal_module()
  local ok, term = pcall(require, "terminal")
  if not ok or type(term) ~= "table" or type(term.run) ~= "function" then
    return nil, "terminal.nvim is not available"
  end
  local got, status = pcall(term.status)
  if not got or type(status) ~= "table" or not status.ready then
    return nil, "terminal.nvim is not set up"
  end
  if status.backend ~= "native" then
    return nil,
      ("terminal.nvim runs on the %s backend, which does not report the end of a job"):format(
        tostring(status.backend)
      )
  end
  return term, nil
end

---@param minutes number
---@return string
local function timed_out(minutes)
  return ("timed out after %s minutes"):format(minutes)
end

---Run one repo without a terminal: the output is collected for the quickfix list.
---@param name string
---@param dir string
---@param fast boolean|nil
---@param done fun(code: integer, lines: string[], shown: boolean)
local function start_quiet(name, dir, fast, done)
  -- vim.system throws when the executable cannot be started (no Git Bash): a red run, not a crash.
  local started, err = pcall(
    vim.system,
    M.build_cmd(dir, fast),
    { text = true, cwd = dir, timeout = M.TIMEOUT_MS },
    function(res)
      vim.schedule(function()
        local text = (res.stdout or "") .. (res.stderr or "")
        local lines = vim.split(text, "\r?\n", { trimempty = true })
        if res.code == 124 then
          lines[#lines + 1] = timed_out(M.TIMEOUT_MS / 60000)
        end
        done(res.code, lines, false)
      end)
    end
  )
  if not started then
    done(1, { name .. ": cannot start: " .. tostring(err) }, false)
  end
end

---Run one repo in a terminal.nvim buffer: the output is shown live and stays in that buffer
---(`shown`). A run that does not start, or that is still running after `TIMEOUT_MS` (its terminal is
---then closed; hiding the split does not end the job), reports why in `lines` instead.
---@param term table terminal.nvim
---@param name string
---@param dir string
---@param fast boolean|nil
---@param done fun(code: integer, lines: string[], shown: boolean)
local function start_terminal(term, name, dir, fast, done)
  local finished = false
  local function once(code, lines)
    if finished then
      return
    end
    finished = true
    vim.schedule(function()
      done(code, lines or {}, lines == nil)
    end)
  end
  local ok, started, err = pcall(term.run, M.build_cmd(dir, fast), M.terminal_opts(name, dir, once))
  if not ok or not started then
    once(1, { ("%s: cannot open a terminal: %s"):format(name, tostring(ok and err or started)) })
    return
  end
  vim.defer_fn(function()
    if finished then
      return
    end
    once(124, { timed_out(M.TIMEOUT_MS / 60000) .. ", the terminal was closed" })
    pcall(term.close, { name = M.terminal_name(name) })
  end, M.TIMEOUT_MS)
end

---Run the CI of one repo or of all, one after the other. By default every repo runs in a terminal.nvim
---buffer of its own (`ci-<repo>`) where its output is shown live; `quiet` (or a missing terminal.nvim)
---collects the output for the quickfix list instead.
---@param opts? { repo?: string, fast?: boolean, quiet?: boolean }
function M.run(opts)
  opts = opts or {}
  if running then
    notify.warn(("A CI run is already in progress (%s)"):format(current or "?"))
    return
  end
  local base = ops.resolve_base_dir(nil)
  if not base then
    notify.error("REPOS_DIR is not set")
    return
  end
  local term
  if not opts.quiet then
    local why
    term, why = M.terminal_module()
    if not term then
      notify.warn(("%s: the output goes to the quickfix list"):format(why))
    end
  end
  local names = opts.repo and { opts.repo } or M.REPOS
  local results = {}
  local index = 0

  local function finish()
    running = false
    current = nil
    M.last_results = results
    -- What no terminal shows (the quiet way, a missing script, a terminal that did not start or
    -- timed out) goes to the quickfix list; a red run in a terminal is pointed to by its name.
    local listed, failed, in_term, in_qf = {}, {}, {}, false
    for _, res in ipairs(results) do
      if not res.shown then
        listed[#listed + 1] = res
      end
      if res.code ~= 0 then
        failed[#failed + 1] = res.repo
        if res.shown then
          in_term[#in_term + 1] = M.terminal_name(res.repo)
        else
          in_qf = true
        end
      end
    end
    if #listed > 0 then
      to_quickfix(listed)
    end
    if #failed == 0 then
      notify.info(("CI green: %s"):format(table.concat(names, ", ")))
      return
    end
    local where = {}
    if #in_term > 0 then
      where[#where + 1] = "output in the terminal " .. table.concat(in_term, ", ")
    end
    if in_qf then
      where[#where + 1] = "quickfix has the output"
    end
    notify.error(("CI RED: %s (%s)"):format(table.concat(failed, ", "), table.concat(where, "; ")))
    if in_qf then
      vim.cmd("botright copen")
    end
  end

  local function next_repo()
    index = index + 1
    local name = names[index]
    if not name then
      finish()
      return
    end
    local dir = repo_dir(base, name)
    if not uv.fs_stat(dir .. "/scripts/ci.sh") then
      results[#results + 1] =
        { repo = name, code = 1, lines = { "scripts/ci.sh not found in " .. dir }, shown = false }
      next_repo()
      return
    end
    notify.info(("CI %d/%d: %s ..."):format(index, #names, name))
    current = term and ("terminal " .. M.terminal_name(name)) or name
    local function done(code, lines, shown)
      results[#results + 1] = { repo = name, code = code, lines = lines, shown = shown }
      next_repo()
    end
    if term then
      start_terminal(term, name, dir, opts.fast, done)
    else
      start_quiet(name, dir, opts.fast, done)
    end
  end

  running = true
  next_repo()
end

---Text of the pre-push hook (no backslashes: it runs in Git Bash and in Linux sh alike).
---@return string
function M.hook_text()
  return table.concat({
    "#!/bin/sh",
    M.HOOK_MARK .. " (git push --no-verify skips it)",
    'root="$(git rev-parse --show-toplevel)"',
    '[ -f "$root/scripts/ci.sh" ] || exit 0',
    'echo "pre-push: scripts/ci.sh --fast"',
    'bash "$root/scripts/ci.sh" --fast || { echo "pre-push: CI is red, push blocked" >&2; exit 1; }',
    "",
  }, "\n")
end

---Hook folder of a checkout, as git sees it (a worktree's `.git` is a file, `core.hooksPath` may move it).
---@param dir string
---@return string|nil
function M.hooks_dir(dir)
  local res = vim
    .system({ "git", "-C", dir, "rev-parse", "--git-path", "hooks" }, { text = true })
    :wait()
  local out = vim.trim(res.stdout or "")
  if res.code ~= 0 or out == "" then
    return nil
  end
  if out:match("^%a:[/\\]") or out:sub(1, 1) == "/" then
    return out
  end
  return dir .. "/" .. out
end

---@param base string
---@param name string
---@param action "install"|"remove"
local function hook_one(base, name, action)
  local dir = repo_dir(base, name)
  local hooks = uv.fs_stat(dir) and M.hooks_dir(dir)
  if not hooks then
    notify.warn(name .. ": not a git checkout at " .. dir)
    return
  end
  local path = hooks .. "/pre-push"

  local existing
  local fd = io.open(path, "r")
  if fd then
    existing = fd:read("*a")
    fd:close()
  end
  local ours = existing ~= nil and existing:find(M.HOOK_MARK, 1, true) ~= nil
  if action == "remove" then
    if not existing then
      notify.info(name .. ": no pre-push hook")
    elseif not ours then
      notify.warn(name .. ": the pre-push hook is not ours, left alone")
    else
      os.remove(path)
      notify.info(name .. ": hook removed")
    end
    return
  end
  if existing and not ours then
    notify.warn(name .. ": a pre-push hook that is not ours exists, left alone")
    return
  end
  local out = io.open(path, "wb")
  if not out then
    notify.error(name .. ": cannot write " .. path)
    return
  end
  out:write(M.hook_text())
  out:close()
  uv.fs_chmod(path, tonumber("755", 8))
  notify.info(name .. ": pre-push hook installed")
end

---@param action "install"|"remove"
---@param repo? string
function M.hook(action, repo)
  local base = ops.resolve_base_dir(nil)
  if not base then
    notify.error("REPOS_DIR is not set")
    return
  end
  for _, name in ipairs(repo and { repo } or M.REPOS) do
    hook_one(base, name, action)
  end
end

---The argument type of the repo name (the private repos with a local CI).
function M.register_types()
  require("lib.nvim.bindings.usercmd.composer").register_type("MYPLUGINS_CI_REPO", {
    -- No list of the repos here: completion shows them, and the text has to stay within the 80
    -- characters of the option float (`H.check_arg_texts`) as the list grows.
    desc = "A private repo with a local CI (<Tab> lists them)",
    validate = function(raw)
      if M.is_known(raw) then
        return true, raw, nil
      end
      return false, nil, ("'%s' has no local CI (%s)"):format(raw, table.concat(M.REPOS, ", "))
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
  local repo_arg = { { name = "repo", type = "MYPLUGINS_CI_REPO", optional = true } }
  return {
    {
      path = { "ci" },
      args = repo_arg,
      flags = {
        { name = "fast", bool = true, desc = "Only the cheap gates (what the pre-push hook runs)" },
        {
          name = "quiet",
          bool = true,
          desc = "No terminal: the output goes to the quickfix list (for prompts and agents)",
        },
      },
      desc = "Local CI of the private repos (rules-vault, casedesk.nvim, tasks-vault, my.nvim): runs scripts/ci.sh of one repo or of all one after the other, each live in a terminal.nvim split ci-<repo>. --quiet sends the output to the quickfix list instead, --fast runs the cheap gates only. Replaces GitHub minutes, which private repos have only a few of",
      run = function(ctx)
        M.run({
          repo = ctx.args.repo,
          fast = ctx.flags.fast == true,
          quiet = ctx.flags.quiet == true,
        })
      end,
    },
    {
      path = { "ci", "status" },
      args = repo_arg,
      desc = "Last local CI result per private repo (from .ci-last.json) and whether it is for the current commit",
      run = function(ctx)
        M.status(ctx.args.repo)
      end,
    },
    {
      path = { "ci", "hook", "install" },
      args = repo_arg,
      desc = "Install a pre-push hook that runs scripts/ci.sh --fast and blocks the push when it is red (git push --no-verify skips it)",
      run = function(ctx)
        M.hook("install", ctx.args.repo)
      end,
    },
    {
      path = { "ci", "hook", "remove" },
      args = repo_arg,
      desc = "Remove the pre-push hook installed by :MyPlugins ci hook install (a foreign hook is left alone)",
      run = function(ctx)
        M.hook("remove", ctx.args.repo)
      end,
    },
  }
end

return M
