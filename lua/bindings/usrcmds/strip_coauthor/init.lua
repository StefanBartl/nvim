---@module 'bindings.usrcmds.strip_coauthor'
---@brief `:StripCoauthor {scan|rewrite|push} [dir]` — remove the
---`Co-Authored-By: Claude` trailer from the commits that carry it, across the
---config and the personal plugin checkouts.
---@description
--- An AI session that commits on this machine signs its commits with a
--- `Co-Authored-By: Claude …` trailer. That is not wanted in this author's
--- history, and by the time it is noticed the commits are usually already
--- pushed. Removing it means rewriting those commits — in nine repositories at
--- once, several of which have live worktrees with uncommitted work in them.
--- This is that operation, made repeatable.
---
--- **Three separate steps, on purpose.** `scan` only reports. `rewrite` only
--- rewrites, locally. `push` only pushes, and asks first, naming every branch
--- it is about to force-push. A single command doing all three would make a
--- force-push to GitHub the consequence of a keystroke, and there is no
--- undoing that for anyone who has already fetched.
---
--- **What it operates on.** The config repository itself, plus every plugin
--- `plugins.personal.list` declares that is actually checked out under `dir`
--- (or `$REPOS_DIR`). Deriving the set from the spec rather than a list kept
--- here means a plugin added to the spec is covered from then on, and one that
--- was never cloned is not reported as a failure. `--only=<name>` narrows to a
--- single repository, completed from that same live set.
---
--- **Branches, not just HEAD.** Every local branch is examined, not the
--- checked-out one — a config worktree branch carries the same commits as
--- `main` and would otherwise walk the trailer back in at the next merge.
--- `rewrite` reports which branches moved; `git.lua`'s header explains why they
--- have to move together, out of one shared map.
---
--- **`push` is not tied to the `rewrite` that preceded it.** It looks for
--- branches whose local history is clean while `origin/<branch>` still carries
--- the trailer, so it works after a restart, or in a session that did not do
--- the rewrite itself. That also makes it self-verifying: nothing shows up
--- unless the local side is genuinely already clean.
---
--- What this cannot undo: once pushed, the old commits stay reachable on the
--- forge by their SHA until it garbage-collects them. Rewriting removes the
--- trailer from the history everyone will *see*, not from everything that has
--- ever existed.

local notify = require("lib.nvim.notify").create("[usrcmds.strip_coauthor]")
local composer = require("lib.nvim.bindings.usercmd.composer")
local ops = require("bindings.usrcmds.plugin_repos.ops")
local gitx = require("bindings.usrcmds.strip_coauthor.git")

local M = {}

local fn = vim.fn

-- =============================================================================
-- Repository set
-- =============================================================================

---@param dir string|nil
---@param only string|nil
---@return { name: string, path: string }[]|nil repos
---@return string|nil err
local function collect(dir, only)
  local base = ops.resolve_base_dir(dir)
  local repos = gitx.repos(base)

  if not base then
    -- The config is found through `stdpath("config")` and needs no base
    -- directory; the plugin checkouts do. Say so rather than silently
    -- reporting a partial result as a complete one.
    notify.warn("REPOS_DIR is not set and no directory was given — only the config was examined")
  end

  if only then
    local filtered = {}
    for _, repo in ipairs(repos) do
      if repo.name == only then
        filtered[#filtered + 1] = repo
      end
    end
    repos = filtered
  end

  if #repos == 0 then
    return nil,
      only and ("'%s' is not a checked-out repository"):format(only) or "no repository to examine"
  end

  return repos, nil
end

-- =============================================================================
-- scan
-- =============================================================================

---@param dir string|nil
---@param only string|nil
local function scan(dir, only)
  local repos, err = collect(dir, only)
  if not repos then
    notify.error(tostring(err))
    return
  end

  local lines, affected, pending_total, failed = {}, 0, 0, 0

  for _, repo in ipairs(repos) do
    local plan, plan_err = gitx.plan(repo.path)
    local pending = gitx.pending_push(repo.path)
    pending_total = pending_total + #pending

    if plan_err then
      failed = failed + 1
      lines[#lines + 1] = ("  %-24s FEHLER: %s"):format(repo.name, plan_err)
    elseif plan then
      affected = affected + 1
      lines[#lines + 1] = ("  %-24s %d Commit(s), %d Branch(es)"):format(
        repo.name,
        #plan.commits,
        #plan.branches
      )
      for _, branch in ipairs(plan.branches) do
        lines[#lines + 1] = ("  %-24s   %s"):format("", branch)
      end
    elseif #pending > 0 then
      lines[#lines + 1] = ("  %-24s lokal sauber, %d Branch(es) noch zu pushen"):format(
        repo.name,
        #pending
      )
      for _, item in ipairs(pending) do
        lines[#lines + 1] = ("  %-24s   %s"):format("", item.branch)
      end
    else
      lines[#lines + 1] = ("  %-24s sauber"):format(repo.name)
    end
  end

  local head = ("%d Repo(s) geprüft, %d betroffen"):format(#repos, affected)
  if pending_total > 0 then
    head = head .. (", %d Branch(es) zu pushen"):format(pending_total)
  end
  if failed > 0 then
    head = head .. (", %d Fehler"):format(failed)
  end
  table.insert(lines, 1, head)

  if affected > 0 then
    lines[#lines + 1] = ""
    lines[#lines + 1] = "  :StripCoauthor rewrite  schreibt das lokal um (kein Push)"
  elseif pending_total > 0 then
    lines[#lines + 1] = ""
    lines[#lines + 1] = "  :StripCoauthor push  bringt das nach origin"
  end

  if failed > 0 then
    notify.warn(table.concat(lines, "\n"))
  else
    notify.info(table.concat(lines, "\n"))
  end
end

-- =============================================================================
-- rewrite
-- =============================================================================

---@param dir string|nil
---@param only string|nil
local function rewrite(dir, only)
  local repos, err = collect(dir, only)
  if not repos then
    notify.error(tostring(err))
    return
  end

  local lines, changed, rebuilt, failed = {}, 0, 0, 0

  for _, repo in ipairs(repos) do
    local plan, plan_err = gitx.plan(repo.path)
    if plan_err then
      failed = failed + 1
      lines[#lines + 1] = ("  %-24s FEHLER: %s"):format(repo.name, plan_err)
    elseif plan then
      local result, rewrite_err = gitx.rewrite(repo.path, plan)
      if not result then
        failed = failed + 1
        lines[#lines + 1] = ("  %-24s FEHLER: %s"):format(repo.name, rewrite_err)
      else
        changed = changed + 1
        rebuilt = rebuilt + result.rebuilt
        lines[#lines + 1] = ("  %-24s %d Commit(s) neu gebaut"):format(repo.name, result.rebuilt)
        for _, move in ipairs(result.moves) do
          lines[#lines + 1] = ("  %-24s   %-42s %s -> %s"):format(
            "",
            move.branch,
            move.old:sub(1, 9),
            move.new:sub(1, 9)
          )
        end
      end
    end
  end

  if changed == 0 and failed == 0 then
    notify.info(("%d Repo(s) geprüft — kein Commit trägt den Trailer."):format(#repos))
    return
  end

  table.insert(
    lines,
    1,
    ("%d Repo(s) umgeschrieben, %d Commit(s) neu gebaut%s"):format(
      changed,
      rebuilt,
      failed > 0 and (", %d Fehler"):format(failed) or ""
    )
  )

  local pending = 0
  for _, repo in ipairs(repos) do
    pending = pending + #gitx.pending_push(repo.path)
  end
  if pending > 0 then
    lines[#lines + 1] = ""
    lines[#lines + 1] = ("  %d Branch(es) haben auf origin noch die alte History."):format(pending)
    lines[#lines + 1] = "  :StripCoauthor push  fragt nach und macht den Force-Push."
  end

  if failed > 0 then
    notify.warn(table.concat(lines, "\n"))
  else
    notify.info(table.concat(lines, "\n"))
  end
end

-- =============================================================================
-- push
-- =============================================================================

---@param dir string|nil
---@param only string|nil
local function push(dir, only)
  local repos, err = collect(dir, only)
  if not repos then
    notify.error(tostring(err))
    return
  end

  -- Gather first, confirm once. A prompt per repository would train the
  -- answer out of the question.
  local work, total = {}, 0
  for _, repo in ipairs(repos) do
    local pending = gitx.pending_push(repo.path)
    if #pending > 0 then
      work[#work + 1] = { repo = repo, pending = pending }
      total = total + #pending
    end
  end

  if total == 0 then
    notify.info("Nichts zu pushen — origin hat den Trailer nirgends mehr.")
    return
  end

  local prompt = {
    ("Force-Push mit --force-with-lease auf %d Branch(es):"):format(total),
    "",
  }
  for _, item in ipairs(work) do
    for _, pending in ipairs(item.pending) do
      prompt[#prompt + 1] = ("  %-24s %s"):format(item.repo.name, pending.branch)
    end
  end
  prompt[#prompt + 1] = ""
  prompt[#prompt + 1] = "Die alte History bleibt auf der Forge über ihre SHA erreichbar,"
  prompt[#prompt + 1] = "bis diese sie einsammelt. Wer sie schon geholt hat, behält sie."

  if fn.confirm(table.concat(prompt, "\n"), "&Ja, pushen\n&Nein", 2) ~= 1 then
    notify.info("Abgebrochen — nichts gepusht.")
    return
  end

  local lines, pushed, failed = {}, 0, 0
  for _, item in ipairs(work) do
    for _, result in ipairs(gitx.push(item.repo.path, item.pending)) do
      if result.status == "pushed" then
        pushed = pushed + 1
        lines[#lines + 1] = ("  %-24s %-42s gepusht"):format(item.repo.name, result.branch)
      else
        failed = failed + 1
        lines[#lines + 1] = ("  %-24s %-42s FEHLER: %s"):format(
          item.repo.name,
          result.branch,
          result.detail or "push failed"
        )
      end
    end
  end

  table.insert(
    lines,
    1,
    ("%d Branch(es) gepusht%s"):format(pushed, failed > 0 and (", %d Fehler"):format(failed) or "")
  )

  if failed > 0 then
    notify.warn(table.concat(lines, "\n"))
  else
    notify.info(table.concat(lines, "\n"))
  end
end

-- =============================================================================
-- Command registration
-- =============================================================================

---Register `:StripCoauthor {scan|rewrite|push} [dir]`.
---@return nil
function M.enable()
  -- `--only=<name>` is validated and completed against the *live* repository
  -- set on every request rather than a snapshot taken here, the same principle
  -- `:MyPlugins`'s own name type follows: the set depends on what is checked
  -- out right now, which registration time cannot know.
  composer.register_type("STRIPCOAUTHOR_REPO", {
    validate = function(raw)
      for _, repo in ipairs(gitx.repos(ops.resolve_base_dir(nil))) do
        if repo.name == raw then
          return true, raw, nil
        end
      end
      return false, nil, ("'%s' is not a checked-out repository"):format(raw)
    end,
    complete = function(arg_lead)
      local out = {}
      for _, repo in ipairs(gitx.repos(ops.resolve_base_dir(nil))) do
        if arg_lead == "" or repo.name:sub(1, #arg_lead) == arg_lead then
          out[#out + 1] = repo.name
        end
      end
      return out
    end,
  })

  local dir_arg = { { name = "dir", type = "DIR", optional = true } }
  local only_flag = { { name = "only", type = "STRIPCOAUTHOR_REPO" } }

  composer.verb("StripCoauthor", {
    desc = "Find and remove the Co-Authored-By: Claude trailer across the config and the personal plugin checkouts",
    routes = {
      {
        path = { "scan" },
        args = dir_arg,
        flags = only_flag,
        desc = "Report which repositories, branches and commits carry the trailer, and what is still to push — changes nothing",
        run = function(ctx)
          scan(ctx.args.dir, ctx.flags.only)
        end,
      },

      {
        path = { "rewrite" },
        args = dir_arg,
        flags = only_flag,
        desc = "Rebuild the affected commits without the trailer and move the branch refs — local only, never pushes",
        run = function(ctx)
          rewrite(ctx.args.dir, ctx.flags.only)
        end,
      },

      {
        path = { "push" },
        args = dir_arg,
        flags = only_flag,
        desc = "Force-push (with lease) the branches whose origin still carries the trailer, after naming every one of them and asking",
        run = function(ctx)
          push(ctx.args.dir, ctx.flags.only)
        end,
      },
    },
  })
end

return M
