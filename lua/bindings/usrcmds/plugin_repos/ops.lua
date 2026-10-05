---@module 'bindings.usrcmds.plugin_repos.ops'
---@brief Shared git-operation primitives for `:MyPlugins` and its picker.
---@description
--- Pure git operations only — no notify/progress/confirm. `init.lua` (the
--- `:MyPlugins` subcommands) and `picker.lua` (the interactive multi-select)
--- both drive these, but want different reporting/UX around the same
--- underlying git calls, so that stays out of this module.

local M = {}

local loop, fn, env = vim.uv or vim.loop, vim.fn, vim.env
-- F5: an alias on a `vim.*` function reads as nil-bearing at its call
-- sites without an explicit type on the alias line.
---@type fun(cmd: string[], opts?: table, on_exit?: fun(out: vim.SystemCompleted)): vim.SystemObj
local system = vim.system
local fnamemodify = fn.fnamemodify
local is_windows = fn.has("win32") == 1 or fn.has("win64") == 1
local git = require("lib.nvim.git")

---@param override string|nil
---@return string|nil
function M.resolve_base_dir(override)
  if override and override ~= "" then
    return fnamemodify(override, ":p")
  end
  if env.REPOS_DIR and env.REPOS_DIR ~= "" then
    return fnamemodify(env.REPOS_DIR, ":p")
  end
  return nil
end

---@param path string
---@return boolean
function M.is_git_repo(path)
  local stat = loop.fs_stat(path .. "/.git")
  return stat ~= nil and stat.type == "directory"
end

---@param entry Plugins.Personal.Entry
---@param base_dir string
---@param on_done fun(status: "cloned"|"exists"|"failed", err: string|nil)
---@return nil
function M.clone_one(entry, base_dir, on_done)
  local target = base_dir .. "/" .. entry.name
  if loop.fs_stat(target) then
    on_done("exists", nil)
    return
  end

  -- entry.repo is the full "owner/repo" exactly as declared in the spec, not
  -- assembled from a hardcoded owner prefix.
  local url = "https://github.com/" .. entry.repo .. ".git"
  system({ "git", "clone", url, target }, { text = true }, function(res)
    if res.code ~= 0 then
      on_done("failed", res.stderr or "git clone failed")
    else
      on_done("cloned", nil)
    end
  end)
end

---Delegates to `lib.nvim.git.fetch_async` -- `changed` reports whether the
---fetch actually moved any remote-tracking ref (see its own doc comment for
---how that's derived), computed there rather than re-implemented here so
---this and every other `lib.nvim.git` consumer (e.g. gitsuite.nvim's
---dashboard) agree on exactly what "changed" means for a fetch.
---@param path string
---@param on_done fun(ok: boolean, err: string|nil, changed: boolean|nil)
---@return nil
function M.fetch_one(path, on_done)
  git.fetch_async({ dir = path }, on_done)
end

---Delegates to `lib.nvim.git.pull_async` (`--ff-only`) -- `changed` reports
---whether the pull actually fast-forwarded, via a before/after HEAD compare
---rather than the locale-fragile "Already up to date." string match this
---used to do itself.
---@param path string
---@param on_done fun(ok: boolean, err: string|nil, changed: boolean|nil)
---@return nil
function M.pull_one(path, on_done)
  git.pull_async({ dir = path }, on_done)
end

---Delegates to `lib.nvim.git.update_async` (fetch, then fast-forward pull) —
---the same sequence `:Git dashboard update` runs, scoped to a single
---already-resolved path. `changed` mirrors the pull's own — that's what
---"did this checkout actually move forward" means for the combined
---operation.
---@param path string
---@param on_done fun(ok: boolean, err: string|nil, changed: boolean|nil)
---@return nil
function M.update_one(path, on_done)
  git.update_async({ dir = path }, on_done)
end

---Reads `git status --porcelain --branch` and reports whether it's safe to
---delete: no uncommitted changes, and not ahead of its upstream (a repo with
---commits made since the last push would lose real work).
---@param path string
---@param on_done fun(safe: boolean, reason: string|nil)
---@return nil
function M.check_removable(path, on_done)
  system({ "git", "status", "--porcelain", "--branch" }, { cwd = path, text = true }, function(res)
    if res.code ~= 0 then
      on_done(false, "git status failed")
      return
    end
    local lines = vim.split(res.stdout or "", "\n", { plain = true })
    local branch_line = lines[1] or ""
    if branch_line:match("%[ahead") then
      on_done(false, "ahead of upstream (unpushed commits)")
      return
    end
    -- Anything past the branch line is a dirty/untracked file.
    for i = 2, #lines do
      if lines[i] ~= "" then
        on_done(false, "uncommitted changes")
        return
      end
    end
    on_done(true, nil)
  end)
end

---@param path string
---@return boolean ok
function M.delete_one(path)
  return fn.delete(path, "rf") == 0
end

---Runs `worker(item, on_done)` sequentially over `list` (never in parallel —
---git operations on the same machine contend for the same network/CPU
---budget, and sequential is what makes a single progress bar meaningful).
---`describe(item)` labels the progress bar; `on_finish` receives the items
---that succeeded and a list of `{item, err}` for the ones that didn't. A
---single slow/hung entry only delays the batch, it never drops the rest.
---@generic T
---@param list T[]
---@param worker fun(item: T, on_done: fun(ok: boolean, err: string|nil))
---@param describe fun(item: T): string
---@param on_finish fun(ok_items: T[], failed: {item: T, err: string}[])
---@param prog table|nil lib.nvim.progress handle, or nil to skip progress reporting
---@return nil
function M.run_sequential(list, worker, describe, on_finish, prog)
  -- No `---@type T[]` here: `@generic T` is scoped to the signature above,
  -- so `T` does not exist in the body. Inference from the two `insert`s is
  -- what carries the element type anyway.
  local ok_items = {}
  local failed = {}
  local index = 1
  local total = #list

  local function run_next()
    local item = list[index]
    if not item then
      vim.schedule(function()
        on_finish(ok_items, failed)
      end)
      return
    end
    if prog then
      prog:update({ text = describe(item), current = index, total = total })
    end
    worker(item, function(ok, err)
      if ok then
        ok_items[#ok_items + 1] = item
      else
        failed[#failed + 1] = { item = item, err = err or "unknown error" }
      end
      index = index + 1
      run_next()
    end)
  end

  run_next()
end

-- ── Sync primitives (`:MyPlugins sync`) ───────────────────────────────────────
--
-- Own `vim.system` calls instead of `lib.nvim.git.*_async`: sync needs what those do not
-- offer (a per-call timeout, no credential prompt) and must keep working with an older
-- lib.nvim on the other machine. Every call is async; nothing here blocks the editor.

---Environment that makes git fail fast instead of asking: a background job has no terminal to
---answer a credential prompt on (a private repo would hang unseen), and Git Credential Manager
---must not open a dialog.
---@type table<string, string>
M.NO_PROMPT_ENV = { GIT_TERMINAL_PROMPT = "0", GCM_INTERACTIVE = "never" }

---@class MyPlugins.GitRun
---@field code integer
---@field stdout string
---@field stderr string
---@field timed_out boolean

---Kill a job and the processes it started. `job:kill()` reaches only the process it spawned: git
---runs its transport (`git-remote-https`, `ssh`) as a child, and on Windows terminating the
---parent leaves that child alive, still holding the pipes -- so a hung fetch would outlive its
---own timeout. `taskkill /T` takes the whole tree.
---@param job vim.SystemObj
local function kill_tree(job)
  local pid = job.pid
  if is_windows and pid then
    pcall(system, { "taskkill", "/T", "/F", "/PID", tostring(pid) }, { text = true })
  end
  pcall(function()
    job:kill("sigkill")
  end)
end

---Run `git -C <path> <args>` asynchronously.
---`on_done` always runs on the main loop, exactly once. A spawn failure (git missing) arrives
---as `code = -1`.
---
---The timeout is our own timer, not `vim.system`'s: that one reports only once the child has
---exited AND closed its pipes, which a hung transport child prevents. On timeout the process
---tree is killed and `on_done` runs at once with `timed_out = true`.
---@param path string
---@param args string[]
---@param opts? { timeout_ms?: integer, read_only?: boolean }
---@param on_done fun(run: MyPlugins.GitRun)
---@return { stop: fun() } handle  `stop()` kills the process tree; `on_done` does not run afterwards.
function M.git_async(path, args, opts, on_done)
  opts = opts or {}
  local cmd = { "git" }
  if opts.read_only then
    -- A status must not take index.lock: it would make a concurrent `git commit` of the user fail.
    cmd[#cmd + 1] = "--no-optional-locks"
  end
  vim.list_extend(cmd, { "-C", path })
  vim.list_extend(cmd, args)

  local finished = false
  ---@type uv.uv_timer_t|nil
  local timer = nil

  ---@param run MyPlugins.GitRun
  local function finish(run)
    if finished then
      return
    end
    finished = true
    if timer then
      pcall(timer.stop, timer)
      pcall(timer.close, timer)
      timer = nil
    end
    vim.schedule(function()
      on_done(run)
    end)
  end

  local ok, spawned = pcall(system, cmd, { text = true, env = M.NO_PROMPT_ENV }, function(res)
    finish({
      code = res.code,
      stdout = res.stdout or "",
      stderr = res.stderr or "",
      timed_out = false,
    })
  end)
  if not ok then
    finish({ code = -1, stdout = "", stderr = tostring(spawned), timed_out = false })
    return { stop = function() end }
  end
  ---@type vim.SystemObj
  local job = spawned

  if opts.timeout_ms and opts.timeout_ms > 0 then
    timer = loop.new_timer()
    if timer then
      timer:start(opts.timeout_ms, 0, function()
        if finished then
          return
        end
        -- fast event context: hop to the main loop before spawning taskkill
        vim.schedule(function()
          if finished then
            return
          end
          kill_tree(job)
          finish({ code = 124, stdout = "", stderr = "", timed_out = true })
        end)
      end)
    end
  end

  return {
    stop = function()
      if finished then
        return
      end
      finished = true
      if timer then
        pcall(timer.stop, timer)
        pcall(timer.close, timer)
        timer = nil
      end
      kill_tree(job)
    end,
  }
end

---The first non-blank line of a git error text, with a hint when it reads like a missing login.
---Only ever shown to the user; no state is decided from it.
---@param run MyPlugins.GitRun
---@param what string
---@param timeout_ms? integer
---@return string
function M.describe_failure(run, what, timeout_ms)
  if run.timed_out then
    return ("%s timed out after %d s"):format(what, math.floor((timeout_ms or 0) / 1000))
  end
  local first = ""
  for line in (run.stderr .. "\n" .. run.stdout):gmatch("[^\r\n]+") do
    if line:match("%S") then
      first = vim.trim(line)
      break
    end
  end
  if first == "" then
    first = ("%s failed (exit code %d)"):format(what, run.code)
  end
  local low = first:lower()
  if
    low:find("terminal prompts disabled", 1, true)
    or low:find("could not read username", 1, true)
    or low:find("authentication failed", 1, true)
  then
    first = first .. " (needs a login: run git fetch in that repo once)"
  end
  return first
end

---`git fetch --all --prune`.
---@param path string
---@param timeout_ms integer
---@param on_done fun(ok: boolean, err: string|nil)
---@return { stop: fun() }
function M.sync_fetch(path, timeout_ms, on_done)
  return M.git_async(
    path,
    { "fetch", "--all", "--prune" },
    { timeout_ms = timeout_ms },
    function(run)
      if run.code == 0 then
        on_done(true, nil)
      else
        on_done(false, M.describe_failure(run, "git fetch", timeout_ms))
      end
    end
  )
end

---`git status --porcelain=v2 --branch -z`, the text `sync_classify.parse_status` reads.
---@param path string
---@param timeout_ms integer
---@param on_done fun(text: string|nil, err: string|nil)
---@return { stop: fun() }
function M.sync_status(path, timeout_ms, on_done)
  return M.git_async(
    path,
    { "status", "--porcelain=v2", "--branch", "-z" },
    { timeout_ms = timeout_ms, read_only = true },
    function(run)
      if run.code == 0 then
        on_done(run.stdout, nil)
      else
        on_done(nil, M.describe_failure(run, "git status", timeout_ms))
      end
    end
  )
end

---`git pull --ff-only`: never a merge commit, never a rewrite.
---@param path string
---@param timeout_ms integer
---@param on_done fun(ok: boolean, err: string|nil)
---@return { stop: fun() }
function M.sync_pull(path, timeout_ms, on_done)
  return M.git_async(path, { "pull", "--ff-only" }, { timeout_ms = timeout_ms }, function(run)
    if run.code == 0 then
      on_done(true, nil)
    else
      on_done(false, M.describe_failure(run, "git pull", timeout_ms))
    end
  end)
end

---Files the incoming commits touch (`HEAD...@{u}`), the other half of "what blocks this pull".
---@param path string
---@param timeout_ms integer
---@param on_done fun(files: string[]|nil)
---@return { stop: fun() }
function M.sync_incoming_files(path, timeout_ms, on_done)
  return M.git_async(
    path,
    { "diff", "--name-only", "-z", "HEAD...@{u}" },
    { timeout_ms = timeout_ms, read_only = true },
    function(run)
      if run.code ~= 0 then
        on_done(nil)
        return
      end
      local files = {}
      for _, f in ipairs(vim.split(run.stdout, "\0", { plain = true })) do
        if f ~= "" then
          files[#files + 1] = f
        end
      end
      on_done(files)
    end
  )
end

---`git log --oneline` of a revision range (for the triage preview).
---@param path string
---@param range string  e.g. `HEAD..@{u}`
---@param timeout_ms integer
---@param on_done fun(lines: string[])
---@return { stop: fun() }
function M.sync_log(path, range, timeout_ms, on_done)
  return M.git_async(
    path,
    { "log", "--oneline", "--no-color", "--max-count=30", range },
    { timeout_ms = timeout_ms, read_only = true },
    function(run)
      local lines = {}
      if run.code == 0 then
        for line in run.stdout:gmatch("[^\r\n]+") do
          lines[#lines + 1] = line
        end
      end
      on_done(lines)
    end
  )
end

---Run `worker(item, done)` over `items` with at most `jobs` in flight (unlike
---`run_sequential`, which is strictly one at a time). `worker` returns a handle with `stop()`
---(or nil); `done(result)` must be called once. Results come back in item order.
---The returned controller's `stop()` kills what is running and starts nothing new; neither
---callback fires after it.
---@generic T, R
---@param items T[]
---@param jobs integer
---@param worker fun(item: T, done: fun(result: R)): { stop: fun() }|nil
---@param on_each fun(index: integer, item: T, result: R, finished: integer, total: integer)|nil
---@param on_finish fun(results: R[])
---@return { stop: fun() } controller
function M.run_pool(items, jobs, worker, on_each, on_finish)
  local total = #items
  local results, handles = {}, {}
  local next_index, running, finished, stopped = 1, 0, 0, false
  jobs = math.max(1, math.floor(jobs or 1))

  local launch
  launch = function()
    while not stopped and running < jobs and next_index <= total do
      local i = next_index
      next_index = next_index + 1
      running = running + 1
      local called = false
      local handle = worker(items[i], function(result)
        if called or stopped then
          return
        end
        called = true
        handles[i] = nil
        results[i] = result
        running = running - 1
        finished = finished + 1
        if on_each then
          on_each(i, items[i], result, finished, total)
        end
        if finished == total then
          on_finish(results)
        else
          launch()
        end
      end)
      if not called then
        handles[i] = handle
      end
    end
  end

  if total == 0 then
    vim.schedule(function()
      if not stopped then
        on_finish(results)
      end
    end)
  else
    launch()
  end

  return {
    stop = function()
      stopped = true
      for _, h in pairs(handles) do
        if type(h) == "table" and h.stop then
          h.stop()
        end
      end
      handles = {}
    end,
  }
end

-- ── Assist actions (`sync_classify.ASSISTS`) ──────────────────────────────────

---Run one assist action in a repo. Every step is a plain git call; a failure undoes what the
---action started (the rebase/merge is aborted, the stash is popped again), so the repo is where
---it was unless a pop conflicts -- then the changes stay in the stash and the message says so.
---Never `reset --hard`, never `clean`.
---@param path string
---@param id "rebase"|"merge"|"stash_pull"
---@param timeout_ms integer
---@param on_done fun(ok: boolean, err: string|nil)
---@return { stop: fun() } handle
function M.run_assist(path, id, timeout_ms, on_done)
  local current = nil
  local stopped = false
  ---@param args string[]
  ---@param cb fun(run: MyPlugins.GitRun)
  local function run(args, cb)
    if stopped then
      return
    end
    current = M.git_async(path, args, { timeout_ms = timeout_ms }, function(result)
      if not stopped then
        cb(result)
      end
    end)
  end

  if id == "rebase" or id == "merge" then
    local args = id == "rebase" and { "rebase", "@{u}" } or { "merge", "--no-edit", "@{u}" }
    run(args, function(result)
      if result.code == 0 then
        on_done(true, nil)
        return
      end
      -- a conflict must not leave the repo in the middle of a rebase/merge
      run({ id, "--abort" }, function()
        on_done(
          false,
          M.describe_failure(result, "git " .. id, timeout_ms) .. " (aborted, nothing changed)"
        )
      end)
    end)
  elseif id == "stash_pull" then
    ---@param cb fun(ref: string)
    local function stash_ref(cb)
      run({ "rev-parse", "-q", "--verify", "refs/stash" }, function(result)
        cb(result.code == 0 and vim.trim(result.stdout) or "")
      end)
    end
    stash_ref(function(before)
      run({ "stash", "push", "--include-untracked", "-m", "myplugins sync" }, function(pushed)
        if pushed.code ~= 0 then
          on_done(false, M.describe_failure(pushed, "git stash", timeout_ms))
          return
        end
        stash_ref(function(after)
          -- "No local changes to save" exits 0 and stashes nothing: popping then would pop an
          -- older, unrelated stash of the user.
          local stashed = after ~= "" and after ~= before
          run({ "pull", "--ff-only" }, function(pulled)
            local pull_ok = pulled.code == 0
            local pull_err = (not pull_ok) and M.describe_failure(pulled, "git pull", timeout_ms)
              or nil
            if not stashed then
              on_done(pull_ok, pull_err)
              return
            end
            run({ "stash", "pop" }, function(popped)
              if popped.code ~= 0 then
                on_done(
                  false,
                  (pull_err or "pulled")
                    .. "; git stash pop failed -- your changes are still in the stash (git stash list)"
                )
              else
                on_done(pull_ok, pull_err)
              end
            end)
          end)
        end)
      end)
    end)
  else
    vim.schedule(function()
      on_done(false, "unknown assist action: " .. tostring(id))
    end)
  end

  return {
    stop = function()
      stopped = true
      if current then
        current.stop()
      end
    end,
  }
end

return M
