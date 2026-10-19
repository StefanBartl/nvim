---@brief Git primitives behind `scripts/strip_coauthor.lua` — find the trailer, rebuild
---the affected commits without it, move the branch refs, push.
---@description
--- Pure git operations, no notify/confirm/UI — `init.lua` drives these and
--- owns all reporting, the same split `plugin_repos.ops` uses.
---
--- Not on the runtimepath: `scripts/strip_coauthor.lua` loads this file with
--- `dofile`, so it must not `require` anything from this config's own modules
--- at all.
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
---git matches case-sensitively unless told otherwise (`-i` is passed where the
---grep is used), and trailers exist as `Co-authored-by:` too.
M.GREP = "^Co-Authored-By: Claude"
local LUA_PATTERN = "^co%-authored%-by: claude"

---Whether a message line is the trailer.
---@param line string
---@return boolean
local function is_trailer(line)
  return line:lower():match(LUA_PATTERN) ~= nil
end

---How many trailer commits to look for; nil means all of them. `rev-list -N`
---counts the commits that MATCH, not the history walked: the old default of 120
---left every trailer commit past the 120th standing (docmap-desktop has 155).
---The commits and their parents are read in one `rev-list`, so there is no
---cost reason to cap it.
---@type integer|nil
M.SEARCH_DEPTH = nil

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

---@param override string|nil
---@return string|nil
function M.resolve_base_dir(override)
  if override and override ~= "" then
    return fn.fnamemodify(override, ":p")
  end
  local env = vim.env.REPOS_DIR
  if env and env ~= "" then
    return fn.fnamemodify(env, ":p")
  end
  return nil
end

---@param path string
---@return boolean
function M.is_git_repo(path)
  local stat = loop.fs_stat(path .. "/.git")
  return stat ~= nil and stat.type == "directory"
end

---Repositories that are somebody else's and must never be rewritten (a fork of
---a third-party project: its history is not ours to change).
---@type table<string, true>
M.EXCLUDE = { ["plenary.nvim"] = true }

---Every repository this command knows about: the config itself, plus every
---git repository directly under `base_dir` (minus `M.EXCLUDE`).
---@param base_dir string|nil Already resolved (see `M.resolve_base_dir`), or nil.
---@return { name: string, path: string }[]
function M.repos(base_dir)
  local out = {}

  local config = fn.stdpath("config")
  if M.is_git_repo(config) then
    out[#out + 1] = { name = fn.fnamemodify(config, ":t"), path = config }
  end

  if not base_dir then
    return out
  end

  -- Every repository directly under `base_dir`, not only the plugins the spec
  -- lists: the biggest ones (docmap-desktop, tasks-vault, tasks-desktop,
  -- WKDBooks, Configs) are not plugins and were missed, ca. 330 trailer commits.
  local names = {}
  for name, kind in vim.fs.dir(base_dir) do
    if kind == "directory" and not M.EXCLUDE[name] and M.is_git_repo(base_dir .. "/" .. name) then
      names[#names + 1] = name
    end
  end
  table.sort(names)
  for _, name in ipairs(names) do
    out[#out + 1] = { name = name, path = base_dir .. "/" .. name }
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
  -- Three `git` processes in total, whatever the size of the repository. The
  -- first version spawned one `merge-base` per (trailer, parent, trailer)
  -- triple and one `rev-list` per branch: 37 s for lib.nvim alone, and a
  -- scan over all repositories looked hung.
  local depth = M.SEARCH_DEPTH and { "-" .. M.SEARCH_DEPTH } or {}

  -- 1. The trailer commits, over every local branch.
  local grep = { "rev-list", "-i", "--grep=" .. M.GREP }
  vim.list_extend(grep, depth)
  vim.list_extend(grep, { "--branches", "--" })
  local trailers = git_lines(dir, grep)
  if #trailers == 0 then
    return nil, nil
  end
  local is_trailer_commit = {}
  for _, sha in ipairs(trailers) do
    is_trailer_commit[sha] = true
  end

  -- 2. The whole graph, parents first. `has` is true for a commit that is a
  -- trailer commit or has one below it: exactly the commits a rewrite changes.
  local has, parents_of = {}, {}
  local graph = { "rev-list", "--parents", "--topo-order", "--reverse", "--branches", "--" }
  for _, line in ipairs(git_lines(dir, graph)) do
    local fields = vim.split(line, " ", { plain = true, trimempty = true })
    local sha = table.remove(fields, 1)
    parents_of[sha] = fields
    local below = false
    for _, parent in ipairs(fields) do
      if has[parent] then
        below = true
        break
      end
    end
    has[sha] = is_trailer_commit[sha] or below
  end

  -- 3. The branches that carry a trailer, with their tips.
  local branches, tips = {}, {}
  local heads = { "for-each-ref", "--format=%(objectname) %(refname:short)", "refs/heads/" }
  for _, line in ipairs(git_lines(dir, heads)) do
    local sha, branch = line:match("^(%x+) (.+)$")
    if sha and has[sha] then
      branches[#branches + 1] = branch
      tips[#tips + 1] = sha
    end
  end

  if #branches == 0 then
    return nil, nil
  end

  -- The boundary: parents of trailer commits that are not themselves below
  -- another trailer commit (see the module header for why the naive version
  -- silently leaves a trailer behind).
  local excl, seen = {}, {}
  for _, sha in ipairs(trailers) do
    for _, parent in ipairs(parents_of[sha] or {}) do
      if not has[parent] and not seen[parent] then
        seen[parent] = true
        excl[#excl + 1] = parent
      end
    end
  end

  -- No boundary at all means a trailer sits on a root commit (or below every
  -- other one): the rewrite then covers the whole history, which `commit-tree`
  -- handles like any other (a root simply has no `-p`). It used to be refused,
  -- which left three repositories (takt, tasks-vault, openinnvim) un-fixable.

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
    if not is_trailer(line) then
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
      if is_trailer(line) then
        return nil, ("%s: the trailer survived the rewrite"):format(branch)
      end
    end

    moves[#moves + 1] = { branch = branch, old = old, new = new }
  end

  -- Tags that sit on a rewritten commit move with it: a release tag left on
  -- the old history would keep the trailer reachable and point at a commit
  -- that is on no branch any more. A lightweight tag is just re-pointed; an
  -- annotated one gets a new tag object (same name, tagger, date and message,
  -- new `object` line) because the old object names the old commit.
  local tag_moves = {}
  local tag_fmt = "%(refname:short) %(objecttype) %(objectname) %(*objectname) %(*objecttype)"
  for _, line in ipairs(git_lines(dir, { "for-each-ref", "--format=" .. tag_fmt, "refs/tags" })) do
    local name, kind, obj, rest = line:match("^(%S+) (%S+) (%x+) ?(.*)$")
    local peeled, peeled_kind = (rest or ""):match("^(%x+) (%S+)$")
    local commit = (kind == "commit" and obj)
      or (kind == "tag" and peeled_kind == "commit" and peeled)
      or nil
    local new_commit = commit and map[commit]
    if name and new_commit then
      local new_ref = new_commit
      if kind == "tag" then
        local code, body = git(dir, { "cat-file", "tag", obj })
        if code ~= 0 then
          return nil, ("cannot read the tag %s"):format(name)
        end
        local text, replaced = body:gsub("^object %x+", "object " .. new_commit, 1)
        if replaced ~= 1 then
          return nil, ("the tag %s has an unexpected format"):format(name)
        end
        local mk_code, mk_sha, mk_err = git(dir, { "mktag" }, { stdin = text .. "\n" })
        if mk_code ~= 0 or mk_sha == "" then
          return nil, ("cannot recreate the tag %s: %s"):format(name, mk_err)
        end
        new_ref = mk_sha
      end
      tag_moves[#tag_moves + 1] =
        { tag = name, kind = kind, old = obj, new = new_ref, commit = new_commit }
    end
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
  for _, move in ipairs(tag_moves) do
    local code, _, err = git(dir, { "update-ref", "refs/tags/" .. move.tag, move.new, move.old })
    if code ~= 0 then
      return nil, ("the tag %s moved while this ran: %s"):format(move.tag, err)
    end
  end

  return { rebuilt = #plan.commits, moves = moves, tags = tag_moves, map = map }, nil
end

---Write a bundle of every ref of `dir` (branches, tags, remote-tracking refs)
---to `file` and verify it. The bundle is the way back: `git clone <file> x`
---restores the repository as it was before the rewrite.
---@param dir string
---@param file string
---@return boolean ok
---@return string|nil err
function M.backup(dir, file)
  vim.fn.mkdir(vim.fs.dirname(file), "p")
  local code, _, err = git(dir, { "bundle", "create", file, "--all" })
  if code ~= 0 then
    return false, err
  end
  local vcode, _, verr = git(dir, { "bundle", "verify", file })
  if vcode ~= 0 then
    return false, verr
  end
  return true, nil
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
  local out = {}

  ---The trailer commits reachable from `ref`.
  ---@param ref string
  ---@return string[]
  local function trailers_of(ref)
    local args = { "rev-list", "-i", "--grep=" .. M.GREP }
    if M.SEARCH_DEPTH then
      args[#args + 1] = "-" .. M.SEARCH_DEPTH
    end
    vim.list_extend(args, { ref, "--" })
    return git_lines(dir, args)
  end

  for _, branch in ipairs(branches_of(dir)) do
    local remote_ref = "refs/remotes/origin/" .. branch
    if git(dir, { "rev-parse", "--verify", "--quiet", remote_ref }) == 0 then
      local mine = trailers_of(branch)
      local theirs = trailers_of(remote_ref)
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
