---@module 'usrcmds.repos.update'
---Update all git repositories inside a given directory.
---If no directory is provided, vim.env.REPOS_DIR is used.
---Non-git directories are skipped automatically.
---Errors are collected and reported at the end.
--
---Asynchronously update all git repositories inside a directory.
---Uses non-blocking vim.system calls and a sequential job queue.

local notify = require("lib.notify").create("[usrcmds.update_repos] ")

local M = {}

local loop, fn, env = vim.loop, vim.fn, vim.env
local system, fnamemodify = vim.system, fn.fnamemodify

---Check whether a directory is a git repository.
---@param path string
---@return boolean
local function is_git_repo(path)
  local stat = loop.fs_stat(path .. "/.git")
  return stat ~= nil and stat.type == "directory"
end

---Resolve base directory.
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

---Collect all git repositories inside a directory.
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

---Run git fetch and pull for a single repository.
---@param repo string
---@param on_done fun(success: boolean, err: string|nil)
local function update_repo(repo, on_done)
  system(
    { "git", "fetch", "--all", "--prune" },
    { cwd = repo, text = true },
    function(fetch_res)
      if fetch_res.code ~= 0 then
        on_done(false, fetch_res.stderr or "git fetch failed")
        return
      end

      system(
        { "git", "pull", "--ff-only" },
        { cwd = repo, text = true },
        function(pull_res)
          if pull_res.code ~= 0 then
            on_done(false, pull_res.stderr or "git pull failed")
            return
          end

          on_done(true, nil)
        end
      )
    end
  )
end

---Update all repositories asynchronously.
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

  ---@type string[]
  local errors = {}
  local index = 1

  local function run_next()
    local repo = repos[index]
    if not repo then
      vim.schedule(function()
        if #errors > 0 then
          notify.error("Repository update finished with errors:\n\n" .. table.concat(errors, "\n\n"))
        else
          notify.info("All repositories updated successfully")
        end
      end)
      return
    end

    update_repo(repo, function(success, err)
      if not success then
        errors[#errors + 1] =
          fnamemodify(repo, ":t") .. ": " .. (err or "unknown error")
      end

      index = index + 1
      run_next()
    end)
  end

  notify.info("Updating repositories asynchronously...")
  run_next()
end

---@return nil
function M.enable()
  vim.api.nvim_create_user_command("UpdateRepos", function(opts)
    -- opts.args is an empty string if no argument was provided
    local path = opts.args ~= "" and opts.args or nil
    update_all(path)
  end, {
    desc = "[usrcmds.update_repos] Fetch and update all git repositories in a directory",
    nargs = "?",
  })
end

return M
