---@module 'bindings.usrcmds.strip_coauthor.git'
---@brief Git primitives behind `:StripCoauthor` — find the trailer, rebuild
---the affected commits without it, move the branch refs, push.
---@description
--- Pure git operations, no notify/confirm/UI — `init.lua` drives these and
--- owns all reporting, the same split `plugin_repos.ops` uses.
---
--- **Why `commit-tree` + `update-ref` and not a rebase.** Every affected
--- commit is rebuilt object by object and the branch refs are moved by hand.
--- Neither command touches a working tree, so a repository with uncommitted
--- changes — and the config has a live worktree per Claude session — is
--- rewritten without disturbing anything checked out. A `rebase` or a
--- `filter-branch` would refuse outright, or check out and stomp on it.
---
--- **Why one rewrite map per repository rather than per branch.** Several
--- config branches sit on the very same commits (a worktree branch created
--- from `main` and not yet advanced is literally `main`'s SHA). Rewriting
--- each branch on its own would mint a *different* new SHA per branch for one
--- and the same commit, quietly turning identical branches into diverged
--- ones, and the trailer would walk back in at the next merge. So the map is
--- built once for the whole repository and every branch reads out of it.
---
--- **Why the boundary is computed and not just "the oldest trailer commit's
--- parent".** Taking the parent of every trailer commit would be wrong when
--- one trailer commit sits on top of another: excluding the upper one's
--- parent excludes the lower one along with it, and the lower one keeps its
--- trailer. Only parents that are not themselves below another trailer commit
--- are boundaries.
---
--- Everything is discovered at run time — the commits, the branches, the
--- boundary — so this stays correct as new commits land and does nothing at
--- all on a repository that is already clean.

local M = {}

local loop, fn = vim.uv or vim.loop, vim.fn

---The trailer, as a git `--grep` basic regex (git-side) and as a Lua pattern
---(for the message rewrite). Anchored to the start of a line in both.
M.GREP = "^Co-Authored-By: Claude"
local LUA_PATTERN = "^Co%-Authored%-By: Claude"

---How far back to look. The trailer only ever came from recent sessions; a
---wider window would put history that has been shared for months at risk.
M.SEARCH_DEPTH = 120

-- =============================================================================
-- git plumbing
-- =============================================================================

---@param dir string
---@param args string[]
---@param opts? { stdin?: string, env?: table<string,string> }
---@return integer code
---@return string stdout Trailing newline removed.
---@return string stderr
local function git(dir, args, opts)
  opts = opts or {}
  local cmd = { "git", "-C", dir }
  vim.list_extend(cmd, args)
  local res = vim.system(cmd, { text = true, stdin = opts.stdin, env = opts.env }):wait()
  return res.code, (res.stdout or ""):gsub("\n$", ""), res.stderr or ""
end

---@param dir string
---@param args string[]
---@return string[] lines
local function git_lines(dir, args)
  local code, out = git(dir, args)
  if code ~= 0 or out == "" then
    return {}
  end
  return vim.split(out, "\n", { trimempty = true })
end

---Every local branch, by short name.
---@param dir string
---@return string[]
local function branches_of(dir)
  return git_lines(dir, { "for-each-ref", "--format=%(refname:short)", "refs/heads/" })
end

-- =============================================================================
-- Repository set
-- =============================================================================

---Every repository this command knows about: the config itself, plus every
---personal plugin that is actually checked out under `base_dir`. The plugin
---list comes from `plugins.personal.list`, so a plugin added to the spec is
---covered from then on without editing anything here.
---@param base_dir string|nil Already resolved (`ops.resolve_base_dir`), or nil.
---@return { name: string, path: string }[]
function M.repos(base_dir)
  local ops = require("bindings.usrcmds.plugin_repos.ops")
  local out = {}

  local config = fn.stdpath("config")
  if ops.is_git_repo(config) then
    out[#out + 1] = { name = fn.fnamemodify(config, ":t"), path = config }
  end

  if not base_dir then
    return out
  end

  local entries = require("plugins.personal.list").read() or {}
  for _, entry in ipairs(entries) do
    local path = base_dir .. "/" .. entry.name
    if loop.fs_stat(path) and ops.is_git_repo(path) then
      out[#out + 1] = { name = entry.name, path = path }
    end
  end

  return out
end

-- =============================================================================
-- Plan
-- =============================================================================

---@class StripCoauthor.Plan
---@field branches string[] Local branches whose recent history carries the trailer.
---@field tips string[] Their tip SHAs, index-aligned with `branches`.
---@field excl string[] Boundary commits: the rewrite stops below these.
---@field trailers string[] The trailer-carrying commits themselves.
---@field commits string[] Every commit to rebuild, oldest first, topo-ordered.

---What would have to change in `dir`. Returns nil when nothing does.
---@param dir string
---@return StripCoauthor.Plan|nil plan
---@return string|nil err
function M.plan(dir)
  local depth = "-" .. M.SEARCH_DEPTH

  local branches, tips = {}, {}
  for _, branch in ipairs(branches_of(dir)) do
    local hits = git_lines(dir, { "rev-list", depth, "--grep=" .. M.GREP, branch, "--" })
    if #hits > 0 then
      branches[#branches + 1] = branch
      local code, tip = git(dir, { "rev-parse", branch })
      if code ~= 0 then
        return nil, ("cannot resolve %s"):format(branch)
      end
      tips[#tips + 1] = tip
    end
  end

  if #branches == 0 then
    return nil, nil
  end

  local args = { "rev-list", depth, "--grep=" .. M.GREP }
  vim.list_extend(args, tips)
  args[#args + 1] = "--"
  local trailers = git_lines(dir, args)

  -- The boundary: parents of trailer commits that are not themselves below
  -- another trailer commit (see the module header for why the naive version
  -- silently leaves a trailer behind).
  local excl, seen = {}, {}
  for _, sha in ipairs(trailers) do
    local _, parents = git(dir, { "log", "-1", "--format=%P", sha })
    for parent in parents:gmatch("%S+") do
      local covered = false
      for _, other in ipairs(trailers) do
        if git(dir, { "merge-base", "--is-ancestor", other, parent }) == 0 then
          covered = true
          break
        end
      end
      if not covered and not seen[parent] then
        seen[parent] = true
        excl[#excl + 1] = parent
      end
    end
  end

  if #excl == 0 then
    return nil, "a trailer commit is a root commit — refusing to rewrite"
  end

  local list = { "rev-list", "--reverse", "--topo-order" }
  vim.list_extend(list, tips)
  list[#list + 1] = "--not"
  vim.list_extend(list, excl)
  list[#list + 1] = "--"

  return {
    branches = branches,
    tips = tips,
    excl = excl,
    trailers = trailers,
    commits = git_lines(dir, list),
  }
end

-- =============================================================================
-- Rewrite
-- =============================================================================

---`<rev> --not <excl...> --` as an argument list, the range every check below
---is expressed over. The trailing `--` is not cosmetic: without it git tries
---to stat the revisions as paths, which fails outright under the long paths
---this config lives at ("Filename too long").
---@param rev string
---@param excl string[]
---@param prefix string[]
---@return string[]
local function ranged(prefix, rev, excl)
  local args = vim.deepcopy(prefix)
  args[#args + 1] = rev
  args[#args + 1] = "--not"
  vim.list_extend(args, excl)
  args[#args + 1] = "--"
  return args
end

---The commit message without the trailer. `git stripspace` does the cleanup
---(the blank line that separated the trailer would otherwise be left dangling
---at the end), which is the same normalisation git applies to a message typed
---into an editor — `commit-tree` itself applies none.
---@param dir string
---@param sha string
---@return string
local function message_without_trailer(dir, sha)
  local _, body = git(dir, { "log", "-1", "--format=%B", sha })
  local kept = {}
  for _, line in ipairs(vim.split(body, "\n", { plain = true })) do
    if not line:match(LUA_PATTERN) then
      kept[#kept + 1] = line
    end
  end
  local _, cleaned = git(dir, { "stripspace" }, { stdin = table.concat(kept, "\n") .. "\n" })
  return cleaned .. "\n"
end

---@class StripCoauthor.Move
---@field branch string
---@field old string
---@field new string

---Rebuild every commit in the plan and move the affected refs. Verifies before
---it moves anything: nothing may change but the message.
---@param dir string
---@param plan StripCoauthor.Plan
---@return { rebuilt: integer, moves: StripCoauthor.Move[] }|nil result
---@return string|nil err
function M.rewrite(dir, plan)
  local map = {}

  for _, sha in ipairs(plan.commits) do
    local code, tree = git(dir, { "rev-parse", sha .. "^{tree}" })
    if code ~= 0 then
      return nil, ("cannot read the tree of %s"):format(sha:sub(1, 9))
    end

    -- Parents are remapped, so a merge commit keeps its shape.
    local args = { "commit-tree", tree }
    local _, parents = git(dir, { "log", "-1", "--format=%P", sha })
    for parent in parents:gmatch("%S+") do
      args[#args + 1] = "-p"
      args[#args + 1] = map[parent] or parent
    end

    -- Author and committer, both names, both mails, both dates, are carried
    -- over: the rewritten commit must differ from the original in its message
    -- and in nothing else.
    local _, ident = git(dir, { "log", "-1", "--format=%an%n%ae%n%aI%n%cn%n%ce%n%cI", sha })
    local f = vim.split(ident, "\n", { plain = true })
    local env = {
      GIT_AUTHOR_NAME = f[1],
      GIT_AUTHOR_EMAIL = f[2],
      GIT_AUTHOR_DATE = f[3],
      GIT_COMMITTER_NAME = f[4],
      GIT_COMMITTER_EMAIL = f[5],
      GIT_COMMITTER_DATE = f[6],
    }

    local msg = message_without_trailer(dir, sha)
    local ok, new, err = git(dir, args, { stdin = msg, env = env })
    if ok ~= 0 or new == "" then
      return nil, ("commit-tree failed on %s: %s"):format(sha:sub(1, 9), err)
    end
    map[sha] = new
  end

  -- Verify every branch before moving any of them: a repository left half
  -- rewritten is worse than one not touched at all.
  local fmt = "--format=%s|%an|%ae|%aI|%cn|%ce|%cI"
  local moves = {}
  for i, branch in ipairs(plan.branches) do
    local old = plan.tips[i]
    local new = map[old]
    if not new then
      return nil, ("%s was not rewritten"):format(branch)
    end

    local _, old_tree = git(dir, { "rev-parse", old .. "^{tree}" })
    local _, new_tree = git(dir, { "rev-parse", new .. "^{tree}" })
    if old_tree ~= new_tree then
      return nil, ("%s: the rewritten tree differs from the original"):format(branch)
    end

    local _, old_n = git(dir, ranged({ "rev-list", "--count" }, old, plan.excl))
    local _, new_n = git(dir, ranged({ "rev-list", "--count" }, new, plan.excl))
    if old_n ~= new_n then
      return nil, ("%s: the commit count changed (%s -> %s)"):format(branch, old_n, new_n)
    end

    local _, old_meta = git(dir, ranged({ "log", fmt }, old, plan.excl))
    local _, new_meta = git(dir, ranged({ "log", fmt }, new, plan.excl))
    if old_meta ~= new_meta then
      return nil, ("%s: subject, identity or dates changed"):format(branch)
    end

    local _, body = git(dir, ranged({ "log", "--format=%B" }, new, plan.excl))
    for _, line in ipairs(vim.split(body, "\n", { plain = true })) do
      if line:match(LUA_PATTERN) then
        return nil, ("%s: the trailer survived the rewrite"):format(branch)
      end
    end

    moves[#moves + 1] = { branch = branch, old = old, new = new }
  end

  -- `update-ref` is given the value it expects to replace, so a repository
  -- another session moved in the meantime aborts here rather than losing that
  -- session's commits.
  for _, move in ipairs(moves) do
    local code, _, err =
      git(dir, { "update-ref", "refs/heads/" .. move.branch, move.new, move.old })
    if code ~= 0 then
      return nil,
        ("%s moved while this ran, nothing further was changed: %s"):format(move.branch, err)
    end
  end

  return { rebuilt = #plan.commits, moves = moves }, nil
end

-- =============================================================================
-- Push
-- =============================================================================

---@class StripCoauthor.Pending
---@field branch string
---@field remote string The remote-tracking tip still holding the old history.

---Branches whose local history is clean but whose `origin/<branch>` still
---carries the trailer — exactly the branches a rewrite has left to push.
---
---Derived from the refs, not remembered from an earlier `rewrite` call: the
---push then also works in a fresh session, after a restart, or when the
---rewrite ran from somewhere else entirely. It is self-verifying too — a
---branch only appears here if the local side really is clean and the remote
---really is not.
---
---A `fetch` is deliberately *not* run first. `origin/<branch>` is the value
---`--force-with-lease` checks against, and refreshing it would replace an
---honest "this is what I last saw" with whatever is on the server right now,
---which is exactly the check the lease exists to make.
---@param dir string
---@return StripCoauthor.Pending[]
function M.pending_push(dir)
  local depth = "-" .. M.SEARCH_DEPTH
  local out = {}

  for _, branch in ipairs(branches_of(dir)) do
    local remote_ref = "refs/remotes/origin/" .. branch
    if git(dir, { "rev-parse", "--verify", "--quiet", remote_ref }) == 0 then
      local mine = git_lines(dir, { "rev-list", depth, "--grep=" .. M.GREP, branch, "--" })
      local theirs = git_lines(dir, { "rev-list", depth, "--grep=" .. M.GREP, remote_ref, "--" })
      if #mine == 0 and #theirs > 0 then
        local _, sha = git(dir, { "rev-parse", remote_ref })
        out[#out + 1] = { branch = branch, remote = sha }
      end
    end
  end

  return out
end

---@class StripCoauthor.PushResult
---@field branch string
---@field status "pushed"|"failed"
---@field detail string|nil

---Force-push the rewritten branches. `--force-with-lease` carries the exact
---remote tip this ran against, so a branch someone else advanced in the
---meantime is rejected rather than overwritten.
---@param dir string
---@param pending StripCoauthor.Pending[]
---@return StripCoauthor.PushResult[]
function M.push(dir, pending)
  local out = {}
  for _, item in ipairs(pending) do
    local lease = ("--force-with-lease=%s:%s"):format(item.branch, item.remote)
    local code, _, err = git(dir, { "push", lease, "origin", item.branch })
    if code == 0 then
      out[#out + 1] = { branch = item.branch, status = "pushed" }
    else
      out[#out + 1] = {
        branch = item.branch,
        status = "failed",
        detail = vim.split(err, "\n", { trimempty = true })[1],
      }
    end
  end
  return out
end

return M
