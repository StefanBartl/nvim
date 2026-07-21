---@module 'usrcmds.update_repos'
---@brief Update all git repositories inside a given directory.
---@description
--- Registers `:UpdateRepos [path]`. Scans `path` (or `vim.env.REPOS_DIR` when
--- no argument is given) for git repositories and runs `git fetch --all --prune`
--- + `git pull --ff-only` on each, sequentially. Non-git directories are
--- skipped. Errors are collected and reported once all repos have been
--- attempted; a single hung/slow repo cannot silently block reporting on the
--- others. Progress is shown via lib.nvim.progress (soft dependency).

local notify = require("lib.nvim.notify").create("[usrcmds.update_repos]")
local usercmd = require("lib.nvim.usercmd")

local M = {}

local loop, fn, env = vim.uv or vim.loop, vim.fn, vim.env
local system, fnamemodify = vim.system, fn.fnamemodify

-- Optional: per-repo progress, since fetch+pull over a whole directory of
-- repos is exactly the kind of path-driven, potentially long-running
-- operation that benefits from visible feedback. No-op (returns nil) when
-- lib.nvim's ui.kit progress module isn't available.
local ok_progress, progress_mod = pcall(require, "lib.nvim.progress")
local function new_progress()
  if not ok_progress then return nil end
  return progress_mod.create({ title = "[usrcmds.update_repos]" })
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
  if override and override ~= "" then
    return fnamemodify(override, ":p")
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
local function update_all(path)
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
  if #repos == 0 then
    notify.info("No git repositories found in " .. base_dir)
    return
  end

  local ok_progress, progress_mod = pcall(require, "lib.nvim.progress")
  local prog = ok_progress and progress_mod.create({ title = "[usrcmds.update_repos]" }) or nil

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
            prog:finish(string.format("%d/%d updated, %d error(s)", total - #errors, total, #errors))
          end
          notify.error("Repository update finished with errors:\n\n" .. table.concat(errors, "\n\n"))
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

---Register :UpdateRepos.
function M.enable()
  usercmd.create("UpdateRepos", function(args)
    local path = args.args ~= "" and args.args or nil
    update_all(path)
  end, {
    desc = "[usrcmds.update_repos] Fetch and update all git repositories in a directory",
    nargs = "?",
  })
end

return M
