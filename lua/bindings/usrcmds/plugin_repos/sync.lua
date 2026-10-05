---@module 'bindings.usrcmds.plugin_repos.sync'
---@brief `:MyPlugins sync`: fetch every listed plugin repo, pull what can be pulled, collect the rest.
---@description
--- The thorough variant of `:MyPlugins update` for the two-machine `dir`-mode workflow: bring
--- every repo of `plugins.personal.core.list` level with its remote in one go, never stop at
--- the first problem, and end with the assurance that everything is up to date except what
--- the user deliberately skipped.
---
---   Phase 0  resolve   the list, the base dir, which folders are git repos
---   Phase 1  fetch     `git fetch --all --prune` of ALL repos first (`--jobs` at a time)
---   Phase 2  status    `git status --porcelain=v2 --branch` -> `sync_classify.classify`
---   Phase 3  pull      only repos that are behind: `git pull --ff-only`
---   Phase 4  re-check  a failed pull is classified from a second status (never from stderr)
---   Phase 5  result    state file, one closing line, the triage dashboard when something is left
---
--- Fetching everything before the first pull is the point: only then is it known which repos
--- have anything to pull, and the summary is complete before a single working tree changes.
---
--- The git primitives are in `ops.lua` (all async, with a timeout and no credential prompt),
--- the decisions in `sync_classify.lua` (pure), the saved result in `sync_state.lua`, the
--- triage list in `sync_dash.lua`. This module only sequences them.

local ops = require("bindings.usrcmds.plugin_repos.ops")
local classify = require("bindings.usrcmds.plugin_repos.sync_classify")
local state_mod = require("bindings.usrcmds.plugin_repos.sync_state")
local confirm = require("bindings.usrcmds.plugin_repos.confirm")
local notify = require("lib.nvim.notify").create("[usrcmds.plugin_repos.sync]")

local loop = vim.uv or vim.loop

local M = {}

---Defaults of the numeric options. The timeouts are per git call (a hung repo becomes a
---`fetch_failed`/`pull_failed`, not a hang).
M.DEFAULTS = {
  jobs = 2,
  max_jobs = 6,
  fetch_timeout_ms = 60000,
  status_timeout_ms = 30000,
  pull_timeout_ms = 60000,
}

---@class MyPlugins.SyncOpts
---@field dir? string          Base directory (default `$REPOS_DIR`).
---@field only? string         One repo of the list.
---@field dry_run? boolean     Fetch and classify, pull nothing.
---@field no_fetch? boolean    Classify (and pull) with what is already fetched.
---@field jobs? integer        Fetches in flight (default 2, at most 6).
---@field names? string[]      The repo names instead of `plugins.personal.core.list` (the picker's selection, specs).
---@field partial? boolean    The scope is a subset: keep the saved result of the other repos (`--only` implies it).
---@field state_path? string   Where the result is saved (specs).
---@field fetch_timeout_ms? integer
---@field status_timeout_ms? integer
---@field pull_timeout_ms? integer
---@field ui? boolean          false: never open the dashboard (specs).
---@field quiet? boolean       true: no notifications (specs).
---@field on_done? fun(records: MyPlugins.SyncRecord[], summary: MyPlugins.SyncSummary)

---@class MyPlugins.SyncSession
---@field dir string
---@field records MyPlugins.SyncRecord[]
---@field dry_run boolean
---@field opts MyPlugins.SyncOpts
---@field others? MyPlugins.SyncRecord[]  Saved records of repos outside this run's scope (kept when saving).

---The run in flight (one at a time).
---@type { stop: fun(), prog: table|nil }|nil
local active = nil

---@return boolean
function M.is_running()
  return active ~= nil
end

local ok_progress, progress_mod = pcall(require, "lib.nvim.progress")
---@param title string
---@return table|nil
local function new_progress(title)
  if not ok_progress then
    return nil
  end
  return progress_mod.create({ title = title, style = "statusline" })
end

---@param opts MyPlugins.SyncOpts
---@param key "fetch_timeout_ms"|"status_timeout_ms"|"pull_timeout_ms"
---@return integer
local function timeout_of(opts, key)
  return tonumber(opts[key]) or M.DEFAULTS[key]
end

---@param opts MyPlugins.SyncOpts
---@return integer
local function jobs_of(opts)
  local n = math.floor(tonumber(opts.jobs) or M.DEFAULTS.jobs)
  return math.max(1, math.min(M.DEFAULTS.max_jobs, n))
end

---@param opts MyPlugins.SyncOpts
---@param level "info"|"warn"|"error"
---@param msg string
local function say(opts, level, msg)
  if opts.quiet then
    return
  end
  notify[level](msg)
end

-- ── Phase 0: resolve ──────────────────────────────────────────────────────────

---@class MyPlugins.SyncRepo
---@field name string
---@field path string

---The base dir, the repos to sync and the records for the ones that cannot be synced.
---@param opts MyPlugins.SyncOpts
---@return string|nil base_dir
---@return MyPlugins.SyncRepo[] repos
---@return MyPlugins.SyncRecord[] absent
local function resolve_scope(opts)
  local base_dir = ops.resolve_base_dir(opts.dir)
  if not base_dir then
    say(opts, "error", "No repository directory provided and REPOS_DIR is not set")
    return nil, {}, {}
  end
  base_dir = base_dir:gsub("[/\\]+$", "")

  local names = opts.names
  if not names then
    local entries, err = require("plugins.personal.core.list").read()
    if not entries then
      say(opts, "error", tostring(err))
      return nil, {}, {}
    end
    names = {}
    for _, e in ipairs(entries) do
      names[#names + 1] = e.name
    end
  end

  local repos, absent = {}, {}
  for _, name in ipairs(names) do
    if not opts.only or opts.only == name then
      local path = base_dir .. "/" .. name
      if not loop.fs_stat(path) then
        absent[#absent + 1] = classify.absent(name, path, "missing")
      elseif not ops.is_git_repo(path) then
        absent[#absent + 1] = classify.absent(name, path, "not_git")
      else
        repos[#repos + 1] = { name = name, path = path }
      end
    end
  end
  return base_dir, repos, absent
end

-- ── One repo: fetch (optional), status, classify, pull, re-classify ───────────

---A handle whose `stop()` stops whichever git call of a chain is running right now.
---@return { stop: fun() } handle
---@return fun(next: { stop: fun() }|nil) set
local function chain()
  local current = nil
  local stopped = false
  local handle = {
    stop = function()
      stopped = true
      if current then
        current.stop()
      end
    end,
  }
  local function set(next_handle)
    current = next_handle
    if stopped and next_handle then
      next_handle.stop()
    end
  end
  return handle, set
end

---Status of one repo -> record. `fetch_err` makes it a `fetch_failed`.
---@param repo MyPlugins.SyncRepo
---@param fetch_err string|nil
---@param opts MyPlugins.SyncOpts
---@param on_done fun(record: MyPlugins.SyncRecord)
---@return { stop: fun() }
local function status_record(repo, fetch_err, opts, on_done)
  return ops.sync_status(repo.path, timeout_of(opts, "status_timeout_ms"), function(text, err)
    local st = text and classify.parse_status(text) or nil
    local rec = classify.classify(repo.name, repo.path, st, fetch_err)
    if not st and not fetch_err and err then
      rec.detail = err
    end
    on_done(rec)
  end)
end

---Pull a `behind` record and classify the outcome (a failed pull from a second status).
---@param rec MyPlugins.SyncRecord
---@param opts MyPlugins.SyncOpts
---@param on_done fun(record: MyPlugins.SyncRecord)
---@return { stop: fun() }
local function pull_record(rec, opts, on_done)
  local handle, set = chain()
  set(ops.sync_pull(rec.path, timeout_of(opts, "pull_timeout_ms"), function(ok, err)
    if ok then
      on_done(classify.after_pull(rec, true, nil, nil))
      return
    end
    set(ops.sync_status(rec.path, timeout_of(opts, "status_timeout_ms"), function(text)
      on_done(classify.after_pull(rec, false, err, text and classify.parse_status(text) or nil))
    end))
  end))
  return handle
end

---Re-check one record without a full run: fetch again only when the fetch was what failed,
---then status, then the pull when it is behind. `skipped` is kept.
---@param rec MyPlugins.SyncRecord
---@param opts MyPlugins.SyncOpts
---@param on_done fun(record: MyPlugins.SyncRecord)
---@return { stop: fun() }
local function recheck_record(rec, opts, on_done)
  local handle, set = chain()
  local repo = { name = rec.name, path = rec.path }

  local function finish(new_rec)
    new_rec.skipped = rec.skipped
    on_done(new_rec)
  end

  local function after_status(new_rec)
    if new_rec.state == "behind" and not opts.dry_run then
      set(pull_record(new_rec, opts, finish))
    else
      finish(new_rec)
    end
  end

  local function status(fetch_err)
    set(status_record(repo, fetch_err, opts, after_status))
  end

  if rec.state == "fetch_failed" or rec.state == "status_failed" then
    set(ops.sync_fetch(rec.path, timeout_of(opts, "fetch_timeout_ms"), function(ok, err)
      status(not ok and err or nil)
    end))
  else
    status(nil)
  end
  return handle
end

-- ── Result ────────────────────────────────────────────────────────────────────

---Records in the order of the list (absent ones included).
---@param names string[]
---@param by_name table<string, MyPlugins.SyncRecord>
---@return MyPlugins.SyncRecord[]
local function in_order(names, by_name)
  local out = {}
  for _, name in ipairs(names) do
    if by_name[name] then
      out[#out + 1] = by_name[name]
    end
  end
  return out
end

---Plain text of the unresolved problems for a notification (at most `limit` rows).
---@param records MyPlugins.SyncRecord[]
---@param limit integer
---@return string
local function unresolved_lines(records, limit)
  local lines = {}
  for _, r in ipairs(classify.sort(records)) do
    if classify.is_problem(r.state) and not r.skipped then
      if #lines == limit then
        lines[#lines + 1] = "..."
        break
      end
      lines[#lines + 1] = classify.format_line(r)
    end
  end
  return table.concat(lines, "\n")
end

---The one closing notification.
---@param records MyPlugins.SyncRecord[]
---@param opts MyPlugins.SyncOpts
function M.report(records, opts)
  local text, level = classify.summary_line(records, opts.dry_run)
  local rows = unresolved_lines(records, 15)
  if rows ~= "" then
    text = text .. "\n" .. rows .. "\n(:MyPlugins sync issues opens the list again)"
  end
  say(opts, level, text)
end

---Write the session's result to the state file (the records outside a partial run's scope
---are kept) and tell the statusline segment.
---@param session MyPlugins.SyncSession
---@return boolean ok
---@return string|nil err
local function save(session)
  local records = session.records
  if session.others and #session.others > 0 then
    records = classify.merge(session.others, session.records)
  end
  local ok, err = state_mod.save(session.dir, records, {
    path = session.opts.state_path,
    dry_run = session.dry_run,
  })
  pcall(function()
    require("bindings.usrcmds.plugin_repos.sync_status").refresh(session.opts.state_path)
  end)
  return ok, err
end

---Save the result, report it, open the dashboard when something is left unresolved.
---@param session MyPlugins.SyncSession
local function conclude(session)
  local opts = session.opts
  local saved, serr = save(session)
  if not saved then
    say(opts, "warn", "Sync: could not save the result: " .. tostring(serr))
  end
  local summary = classify.summarize(session.records)

  local opened = false
  if opts.ui ~= false and #summary.unresolved > 0 then
    local ok_dash, dash = pcall(require, "bindings.usrcmds.plugin_repos.sync_dash")
    if ok_dash then
      opened = dash.open(session) == true
    end
  end
  if not opened then
    M.report(session.records, opts)
  end
  if opts.on_done then
    opts.on_done(session.records, summary)
  end
end

-- ── The run ───────────────────────────────────────────────────────────────────

---Stop a running sync (kills the git processes in flight).
---@return boolean was_running
function M.cancel()
  if not active then
    return false
  end
  local run = active
  active = nil
  run.stop()
  if run.prog then
    run.prog:finish("sync cancelled")
  end
  return true
end

---Run a sync.
---@param opts? MyPlugins.SyncOpts
function M.run(opts)
  opts = opts or {}
  if active then
    confirm.yesno("A sync is already running. Cancel it and start over?", "restart", function(yes)
      if yes then
        M.cancel()
        M.run(opts)
      end
    end)
    return
  end

  local base_dir, repos, absent = resolve_scope(opts)
  if not base_dir then
    if opts.on_done then
      opts.on_done({}, classify.summarize({}))
    end
    return
  end
  if #repos + #absent == 0 then
    say(
      opts,
      "info",
      "Sync: no listed plugin repository in scope (remote mode, or --only names none)"
    )
    if opts.on_done then
      opts.on_done({}, classify.summarize({}))
    end
    return
  end

  local names = {}
  for _, r in ipairs(repos) do
    names[#names + 1] = r.name
  end
  for _, r in ipairs(absent) do
    names[#names + 1] = r.name
  end

  local prog = new_progress("[usrcmds.plugin_repos] sync")
  local run = { stop = function() end, prog = prog }
  active = run
  ---@param ctl { stop: fun() }
  local function set_ctl(ctl)
    run.stop = function()
      ctl.stop()
    end
  end
  local function alive()
    return active == run
  end
  ---@param text string
  ---@param current integer
  ---@param total integer
  local function tick(text, current, total)
    if prog then
      prog:update({ text = text, current = current, total = total })
    end
  end

  ---@type table<string, string>
  local fetch_errs = {}
  ---@type table<string, MyPlugins.SyncRecord>
  local by_name = {}
  for _, a in ipairs(absent) do
    by_name[a.name] = a
  end

  local function phase_result()
    if not alive() then
      return
    end
    active = nil
    local records = in_order(names, by_name)
    if prog then
      local s = classify.summarize(records)
      prog:finish(("%d pulled, %d unresolved"):format(s.pulled, #s.unresolved))
    end
    ---@type MyPlugins.SyncRecord[]|nil
    local others = nil
    if opts.partial or opts.only ~= nil then
      local saved = state_mod.load({ path = opts.state_path })
      if saved and saved.dir == base_dir then
        local mine = {}
        for _, n in ipairs(names) do
          mine[n] = true
        end
        others = {}
        for _, r in ipairs(saved.records) do
          if not mine[r.name] then
            others[#others + 1] = r
          end
        end
      end
    end
    if vim.iter(records):any(function(r)
      return r.state == "pulled"
    end) then
      -- A pull rewrote files a buffer may have open.
      vim.cmd("silent! checktime")
    end
    conclude({
      dir = base_dir,
      records = records,
      others = others,
      dry_run = opts.dry_run == true,
      opts = opts,
    })
  end

  local function phase_pull()
    if not alive() then
      return
    end
    local behind = {}
    for _, r in pairs(by_name) do
      if r.state == "behind" then
        behind[#behind + 1] = r
      end
    end
    table.sort(behind, function(a, b)
      return a.name < b.name
    end)
    if opts.dry_run or #behind == 0 then
      phase_result()
      return
    end
    set_ctl(ops.run_pool(behind, 1, function(rec, done)
      return pull_record(rec, opts, done)
    end, function(_, rec, new_rec, finished, total)
      by_name[rec.name] = new_rec
      tick("pull " .. rec.name, finished, total)
    end, phase_result))
  end

  local function phase_status()
    if not alive() then
      return
    end
    if #repos == 0 then
      phase_pull()
      return
    end
    set_ctl(ops.run_pool(repos, 1, function(repo, done)
      return status_record(repo, fetch_errs[repo.name], opts, done)
    end, function(_, repo, rec, finished, total)
      by_name[repo.name] = rec
      tick("status " .. repo.name, finished, total)
    end, phase_pull))
  end

  local function phase_fetch()
    if opts.no_fetch or #repos == 0 then
      phase_status()
      return
    end
    set_ctl(ops.run_pool(repos, jobs_of(opts), function(repo, done)
      return ops.sync_fetch(repo.path, timeout_of(opts, "fetch_timeout_ms"), function(ok, err)
        done({ ok = ok, err = err })
      end)
    end, function(_, repo, res, finished, total)
      if not res.ok then
        fetch_errs[repo.name] = res.err or "git fetch failed"
      end
      tick("fetch " .. repo.name, finished, total)
    end, phase_status))
  end

  phase_fetch()
end

-- ── Re-check, skip, rerun (used by the dashboard) ─────────────────────────────

---@param session MyPlugins.SyncSession
local function persist(session)
  save(session)
end

---@param session MyPlugins.SyncSession
---@param name string
---@return MyPlugins.SyncRecord|nil
---@return integer|nil index
local function find(session, name)
  for i, r in ipairs(session.records) do
    if r.name == name then
      return r, i
    end
  end
  return nil, nil
end

---Re-check (and pull again) the named repos, one after the other, without a fetch unless the
---fetch was what failed. Updates `session.records` in place and saves; `on_done` runs after.
---@param session MyPlugins.SyncSession
---@param names string[]
---@param on_done fun()
function M.recheck(session, names, on_done)
  local items = {}
  for _, name in ipairs(names) do
    local rec = find(session, name)
    if rec then
      items[#items + 1] = rec
    end
  end
  ops.run_pool(items, 1, function(rec, done)
    return recheck_record(rec, session.opts, done)
  end, function(_, rec, new_rec)
    local _, i = find(session, rec.name)
    if i then
      session.records[i] = new_rec
    end
  end, function()
    persist(session)
    on_done()
  end)
end

---Skip (or un-skip) the named repos for this synchronization.
---@param session MyPlugins.SyncSession
---@param names string[]
---@param skipped boolean
function M.set_skipped(session, names, skipped)
  for _, name in ipairs(names) do
    local rec = find(session, name)
    if rec and classify.is_problem(rec.state) then
      rec.skipped = skipped
    end
  end
  persist(session)
end

---Run an assist action (`sync_classify.ASSISTS`) on a record, say how it went, then re-check the
---record. The confirmation is the caller's job (the dashboard asks first).
---@param session MyPlugins.SyncSession
---@param name string
---@param id MyPlugins.SyncAssist
---@param on_done fun()
function M.assist(session, name, id, on_done)
  local rec = find(session, name)
  local info = classify.ASSISTS[id]
  if not rec or not info then
    on_done()
    return
  end
  ops.run_assist(rec.path, id, timeout_of(session.opts, "pull_timeout_ms"), function(ok, err)
    if ok then
      say(session.opts, "info", ("%s: %s done"):format(rec.name, info.label))
    else
      say(session.opts, "warn", ("%s: %s failed: %s"):format(rec.name, info.label, tostring(err)))
    end
    M.recheck(session, { name }, on_done)
  end)
end

---The closing line for a session (when the dashboard closes).
---@param session MyPlugins.SyncSession
function M.finish(session)
  M.report(session.records, session.opts)
end

---Open the last saved result again (`:MyPlugins sync issues`).
---@param opts? { state_path?: string, ui?: boolean, quiet?: boolean }
function M.issues(opts)
  opts = opts or {}
  local data, err = state_mod.load({ path = opts.state_path })
  if not data then
    say(opts, "info", tostring(err))
    return
  end
  ---@type MyPlugins.SyncSession
  local session = {
    dir = data.dir,
    records = data.records,
    dry_run = data.dry_run == true,
    opts = vim.tbl_extend("force", { dry_run = data.dry_run == true }, opts),
  }
  local summary = classify.summarize(session.records)
  if #summary.unresolved + #summary.skipped == 0 then
    say(
      opts,
      "info",
      ("Sync (%s): nothing unresolved"):format(os.date("%Y-%m-%d %H:%M", data.saved_at))
    )
    return
  end
  local ok_dash, dash = pcall(require, "bindings.usrcmds.plugin_repos.sync_dash")
  if not (ok_dash and dash.open(session)) then
    M.report(session.records, session.opts)
  end
end

return M
