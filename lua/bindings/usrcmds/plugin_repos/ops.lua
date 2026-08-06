---@module 'bindings.usrcmds.plugin_repos.ops'
---@brief Shared git-operation primitives for `:MyPlugins` and its picker.
---@description
--- Pure git operations only — no notify/progress/confirm. `init.lua` (the
--- `:MyPlugins` subcommands) and `picker.lua` (the interactive multi-select)
--- both drive these, but want different reporting/UX around the same
--- underlying git calls, so that stays out of this module.

local M = {}

local loop, fn, env = vim.uv or vim.loop, vim.fn, vim.env
local system, fnamemodify = vim.system, fn.fnamemodify

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

---@param path string
---@param on_done fun(ok: boolean, err: string|nil)
function M.fetch_one(path, on_done)
  system({ "git", "fetch", "--all", "--prune" }, { cwd = path, text = true }, function(res)
    if res.code ~= 0 then
      on_done(false, res.stderr or "git fetch failed")
    else
      on_done(true, nil)
    end
  end)
end

---@param path string
---@param on_done fun(ok: boolean, err: string|nil)
function M.pull_one(path, on_done)
  system({ "git", "pull", "--ff-only" }, { cwd = path, text = true }, function(res)
    if res.code ~= 0 then
      on_done(false, res.stderr or "git pull failed")
    else
      on_done(true, nil)
    end
  end)
end

---Fetch then fast-forward pull — same sequence `:MyReposUpdate` runs, scoped
---to a single already-resolved path.
---@param path string
---@param on_done fun(ok: boolean, err: string|nil)
function M.update_one(path, on_done)
  M.fetch_one(path, function(ok, err)
    if not ok then
      on_done(false, err)
      return
    end
    M.pull_one(path, on_done)
  end)
end

---Reads `git status --porcelain --branch` and reports whether it's safe to
---delete: no uncommitted changes, and not ahead of its upstream (a repo with
---commits made since the last push would lose real work).
---@param path string
---@param on_done fun(safe: boolean, reason: string|nil)
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

---@class PluginRepoStatusRecord
---@field name string Repository directory name (tail of `path`)
---@field branch string Current branch, or "(detached)" when HEAD is detached
---@field ahead integer Commits ahead of the upstream (0 when no upstream)
---@field behind integer Commits behind the upstream (0 when no upstream)
---@field has_upstream boolean Whether the current branch tracks an upstream
---@field dirty integer Number of changed/untracked entries in the working tree
---@field state "clean"|"dirty"|"ahead"|"behind"|"diverged" Derived summary state

---Precedence mirrors `check_removable`: a dirty tree outranks upstream
---divergence, since that's the state that actually blocks a safe pull/reclone.
---@param dirty integer
---@param ahead integer
---@param behind integer
---@return "clean"|"dirty"|"ahead"|"behind"|"diverged"
local function derive_state(dirty, ahead, behind)
  if dirty > 0 then
    return "dirty"
  elseif ahead > 0 and behind > 0 then
    return "diverged"
  elseif ahead > 0 then
    return "ahead"
  elseif behind > 0 then
    return "behind"
  end
  return "clean"
end

---Parses `git status --porcelain=v2 --branch` output into a status record.
---@param name string Repository display name (already resolved by the caller)
---@param out string Raw stdout from the status command
---@return PluginRepoStatusRecord
local function parse_status(name, out)
  local branch = "(detached)"
  local ahead, behind = 0, 0
  local has_upstream = false
  local dirty = 0

  for line in (out .. "\n"):gmatch("(.-)\n") do
    if line ~= "" then
      if line:sub(1, 1) == "#" then
        local head = line:match("^# branch%.head (.+)$")
        if head then
          branch = head
        elseif line:match("^# branch%.upstream ") then
          has_upstream = true
        else
          local a, b = line:match("^# branch%.ab %+(%-?%d+) %-(%d+)$")
          if a then
            ahead, behind = tonumber(a) or 0, tonumber(b) or 0
          end
        end
      else
        dirty = dirty + 1
      end
    end
  end

  return {
    name = name,
    branch = branch,
    ahead = ahead,
    behind = behind,
    has_upstream = has_upstream,
    dirty = dirty,
    state = derive_state(dirty, ahead, behind),
  }
end

---Reads a single repository's branch/ahead-behind/dirty status — the
---read-only counterpart to `check_removable`, used by `:MyPlugins check`.
---@param path string
---@param name string Display name for the resulting record
---@param on_done fun(record: PluginRepoStatusRecord|nil, err: string|nil)
function M.status_one(path, name, on_done)
  system({ "git", "status", "--porcelain=v2", "--branch" }, { cwd = path, text = true }, function(res)
    if res.code ~= 0 then
      on_done(nil, (res.stderr ~= "" and res.stderr) or "git status failed")
      return
    end
    on_done(parse_status(name, res.stdout or ""), nil)
  end)
end

---Column-aligned overview of status records, one line per repository plus a
---header — same shape as reposcope.nvim's own status table.
---@param records PluginRepoStatusRecord[]
---@return string[] lines
function M.render_status(records)
  local name_w, branch_w = #"REPOSITORY", #"BRANCH"
  for _, r in ipairs(records) do
    name_w = math.max(name_w, #r.name)
    branch_w = math.max(branch_w, #r.branch)
  end

  local fmt = "%-" .. name_w .. "s  %-" .. branch_w .. "s  %-9s  %s"
  local lines = { fmt:format("REPOSITORY", "BRANCH", "AHEAD/BEH", "STATE") }

  for _, r in ipairs(records) do
    local ab = r.has_upstream and ("+%d/-%d"):format(r.ahead, r.behind) or "no upstream"
    local state = r.state == "dirty" and ("dirty (%d)"):format(r.dirty) or r.state
    lines[#lines + 1] = fmt:format(r.name, r.branch, ab, state)
  end

  return lines
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
function M.run_sequential(list, worker, describe, on_finish, prog)
  ---@type T[]
  local ok_items = {}
  ---@type {item: T, err: string}[]
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

return M
