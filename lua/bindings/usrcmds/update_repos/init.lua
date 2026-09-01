---@module 'bindings.usrcmds.update_repos'
---@brief Update all git repositories inside a given directory.
---@description
--- Registers `:MyReposUpdate [path]`. Scans `path` (or `vim.env.REPOS_DIR` when
--- no argument is given) for git repositories and runs `git fetch --all --prune`
--- + `git pull --ff-only` on each, sequentially. Non-git directories are
--- skipped. Errors are collected and reported once all repos have been
--- attempted; a single hung/slow repo cannot silently block reporting on the
--- others. Progress is shown via lib.nvim.progress (soft dependency).

local notify = require("lib.nvim.notify").create("[usrcmds.update_repos]")
local usercmd = require("lib.nvim.bindings.usercmd")
local expand_path = require("lib.nvim.cross.fs.expand_path")

local M = {}

local loop, fn, env = vim.uv or vim.loop, vim.fn, vim.env
-- F5: an alias on a `vim.*` function reads as nil-bearing at its call
-- sites without an explicit type on the alias line.
---@type fun(cmd: string[], opts?: table, on_exit?: fun(out: vim.SystemCompleted)): vim.SystemObj
local system = vim.system
local fnamemodify = fn.fnamemodify

-- Optional: per-repo progress, since fetch+pull over a whole directory of
-- repos is exactly the kind of path-driven, potentially long-running
-- operation that benefits from visible feedback. No-op (returns nil) when
-- lib.nvim's ui.kit progress module isn't available. "statusline" reports
-- into the shared lib.nvim.progress registry, rendered by the statusline's
-- "plugin_progress" module — same convention as the personal plugins.
local ok_progress, progress_mod = pcall(require, "lib.nvim.progress")
local function new_progress()
  if not ok_progress then
    return nil
  end
  return progress_mod.create({ title = "[usrcmds.update_repos]", style = "statusline" })
end

---Check whether a directory is a git repository.
---@param path string
---@return boolean
local function is_git_repo(path)
  local stat = loop.fs_stat(path .. "/.git")
  return stat ~= nil and stat.type == "directory"
end

---@param override string|nil
---@return string|nil
local function resolve_base_dir(override)
  -- `expand_path` here (not just `fnamemodify`) is what makes the `$REPOS_DIR`
  -- candidate offered by completion actually work: `fnamemodify` alone treats
  -- "$REPOS_DIR" as a literal path segment, it does not resolve env vars.
  if override and override ~= "" then
    return fnamemodify(expand_path(override), ":p")
  end
  if env.REPOS_DIR and env.REPOS_DIR ~= "" then
    return fnamemodify(env.REPOS_DIR, ":p")
  end
  return nil
end

---@param base_dir string
---@return string[]
local function collect_repos(base_dir)
  ---@type string[]
  local repos = {}
  local handle = loop.fs_scandir(base_dir)
  if not handle then
    return repos
  end
  while true do
    local name, typ = loop.fs_scandir_next(handle)
    if not name then
      break
    end
    if typ == "directory" then
      local path = base_dir .. "/" .. name
      if is_git_repo(path) then
        repos[#repos + 1] = path
      end
    end
  end
  return repos
end

---@param repo string
---@param on_done fun(success: boolean, err: string|nil)
local function update_repo(repo, on_done)
  system({ "git", "fetch", "--all", "--prune" }, { cwd = repo, text = true }, function(fetch_res)
    if fetch_res.code ~= 0 then
      on_done(false, fetch_res.stderr or "git fetch failed")
      return
    end
    system({ "git", "pull", "--ff-only" }, { cwd = repo, text = true }, function(pull_res)
      if pull_res.code ~= 0 then
        on_done(false, pull_res.stderr or "git pull failed")
        return
      end
      on_done(true, nil)
    end)
  end)
end

---@param path string|nil
---@param only_name string|nil Restrict to the one repo whose directory
---       basename matches, if given. Unlike `:MyPlugins`'s `--only=<name>`,
---       there is no named list to validate against here -- this command
---       scans `base_dir` for *any* git repo, so "only" filters that scan's
---       result by basename instead of a plugin-list entry.
local function update_all(path, only_name)
  local base_dir = resolve_base_dir(path)
  if not base_dir then
    notify.error("No repository directory provided and REPOS_DIR is not set")
    return
  end

  local stat = loop.fs_stat(base_dir)
  if not stat or stat.type ~= "directory" then
    notify.error("Repository directory is not accessible: " .. base_dir)
    return
  end

  local repos = collect_repos(base_dir)
  if only_name then
    local filtered = {}
    for _, repo in ipairs(repos) do
      if fnamemodify(repo, ":t") == only_name then
        filtered[#filtered + 1] = repo
      end
    end
    repos = filtered
  end
  if #repos == 0 then
    if only_name then
      notify.info(("No repository named '%s' found in %s"):format(only_name, base_dir))
    else
      notify.info("No git repositories found in " .. base_dir)
    end
    return
  end

  ---@type string[]
  local errors = {}
  local index = 1
  local total = #repos
  local prog = new_progress()

  local function run_next()
    local repo = repos[index]
    if not repo then
      vim.schedule(function()
        if #errors > 0 then
          if prog then
            prog:finish(
              string.format("%d/%d updated, %d error(s)", total - #errors, total, #errors)
            )
          end
          notify.error(
            "Repository update finished with errors:\n\n" .. table.concat(errors, "\n\n")
          )
        else
          if prog then
            prog:finish(string.format("%d repositor%s updated", total, total == 1 and "y" or "ies"))
          end
          notify.info("All repositories updated successfully")
        end
      end)
      return
    end

    if prog then
      prog:update({ text = fnamemodify(repo, ":t"), current = index, total = total })
    end

    update_repo(repo, function(success, err)
      if not success then
        errors[#errors + 1] = fnamemodify(repo, ":t") .. ": " .. (err or "unknown error")
      end
      index = index + 1
      run_next()
    end)
  end

  notify.info("Updating repositories asynchronously...")
  run_next()
end

---Directory completion for the `[path]` argument: offers `$REPOS_DIR` up
---front when resolvable (mirroring `:MyPlugins`'s own `MYPLUGINS_DIR` type,
---the sibling command this one was missing completion relative to), plus
---real directory completion for everything else.
---@param arg_lead string
---@return string[]
local function complete_path(arg_lead)
  local candidates = {}
  if env.REPOS_DIR and env.REPOS_DIR ~= "" and ("$REPOS_DIR"):sub(1, #arg_lead) == arg_lead then
    candidates[#candidates + 1] = "$REPOS_DIR"
  end
  vim.list_extend(candidates, fn.getcompletion(arg_lead, "dir"))
  return candidates
end

---Extract whatever non-flag token is already on the command line, to resolve
---`--only=` completion's base_dir the same way the real run would (an
---explicit path if one was typed, `$REPOS_DIR` otherwise).
---@param cmdline string
---@return string|nil
local function typed_path(cmdline)
  local path
  for tok in cmdline:gmatch("%S+") do
    if tok ~= "MyReposUpdate" and tok:sub(1, 2) ~= "--" then
      path = tok
    end
  end
  return path
end

---`--only=<name>` completion: unlike `:MyPlugins`'s `MYPLUGINS_NAME`, there
---is no static list to complete against — `[path]` names an arbitrary
---directory of git repos, not a declared plugin set. So this scans
---`base_dir` the same way `update_all` will (cheap: a directory listing plus
---one `.git` stat per entry, no git subprocess), then offers basenames.
---@param name_lead string
---@param cmdline string
---@return string[]
local function complete_only(name_lead, cmdline)
  local base_dir = resolve_base_dir(typed_path(cmdline))
  if not base_dir then
    return {}
  end
  local out = {}
  for _, repo in ipairs(collect_repos(base_dir)) do
    local name = fnamemodify(repo, ":t")
    if name_lead == "" or name:sub(1, #name_lead) == name_lead then
      out[#out + 1] = "--only=" .. name
    end
  end
  return out
end

---@param arg_lead string
---@param cmdline string
---@return string[]
local function complete(arg_lead, cmdline)
  if arg_lead:sub(1, 7) == "--only=" then
    return complete_only(arg_lead:sub(8), cmdline)
  end
  if arg_lead == "" or arg_lead:sub(1, 1) == "-" then
    -- Bare/partial "-": offer the flag itself alongside path completion, same
    -- as leaving it out of the candidate list would just mean "unreachable
    -- without typing it blind".
    local out = { "--only=" }
    vim.list_extend(out, complete_path(arg_lead))
    return out
  end
  return complete_path(arg_lead)
end

---Register :MyReposUpdate.
function M.enable()
  usercmd.create("MyReposUpdate", function(args)
    local path, only_name
    for _, tok in ipairs(args.fargs) do
      local name = tok:match("^%-%-only=(.+)$")
      if name then
        only_name = name
      else
        path = tok
      end
    end
    update_all(path, only_name)
  end, {
    desc = "[usrcmds.update_repos] Fetch and update git repositories in a directory (or just --only=<name>)",
    nargs = "*",
    complete = complete,
  })
end

return M
