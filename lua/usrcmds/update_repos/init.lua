---@module 'usrcmds.repos.update'
---Update all git repositories inside a given directory.
---If no directory is provided, vim.env.REPOS_DIR is used.
---Non-git directories are skipped automatically.
---Errors are collected and reported at the end.

local M = {}

---Run a shell command and return success flag and output.
---@param cmd string[]
---@param cwd string
---@return boolean success
---@return string output
local function run_command(cmd, cwd)
  -- Execute a command using vim.system (Neovim >= 0.10)
  local result = vim.system(cmd, { cwd = cwd, text = true }):wait()

  if result.code ~= 0 then
    return false, result.stderr or result.stdout or "unknown error"
  end

  return true, result.stdout or ""
end

---Check whether a directory is a git repository.
---@param path string
---@return boolean
local function is_git_repo(path)
  local git_dir = path .. "/.git"
  local stat = vim.loop.fs_stat(git_dir)
  return stat ~= nil and stat.type == "directory"
end

---Resolve repository base directory.
---@param override string|nil
---@return string|nil
local function resolve_base_dir(override)
  if override and override ~= "" then
    return vim.fn.fnamemodify(override, ":p")
  end

  if vim.env.REPOS_DIR and vim.env.REPOS_DIR ~= "" then
    return vim.fn.fnamemodify(vim.env.REPOS_DIR, ":p")
  end

  return nil
end

---Update all repositories in the resolved directory.
---@param path string|nil
local function update_all(path)
  local base_dir = resolve_base_dir(path)

  if not base_dir then
    vim.notify("No repository directory provided and REPOS_DIR is not set", vim.log.levels.ERROR)
    return
  end

  local stat = vim.loop.fs_stat(base_dir)
  if not stat or stat.type ~= "directory" then
    vim.notify("Repository directory is not accessible: " .. base_dir, vim.log.levels.ERROR)
    return
  end

  local handle = vim.loop.fs_scandir(base_dir)
  if not handle then
    vim.notify("Failed to scan directory: " .. base_dir, vim.log.levels.ERROR)
    return
  end

  ---@type string[]
  local errors = {}

  while true do
    local name, typ = vim.loop.fs_scandir_next(handle)
    if not name then
      break
    end

    if typ == "directory" then
      local repo_path = base_dir .. "/" .. name

      if is_git_repo(repo_path) then
        local ok_fetch, fetch_out = run_command({ "git", "fetch", "--all", "--prune" }, repo_path)

        if not ok_fetch then
          errors[#errors + 1] = name .. ": fetch failed\n" .. fetch_out
          goto continue
        end

        local ok_pull, pull_out = run_command({ "git", "pull", "--ff-only" }, repo_path)

        if not ok_pull then
          errors[#errors + 1] = name .. ": pull failed\n" .. pull_out
        end
      end
    end

    ::continue::
  end

  if #errors > 0 then
    vim.notify("Repository update finished with errors:\n\n" .. table.concat(errors, "\n\n"), vim.log.levels.ERROR)
  else
    vim.notify("All repositories updated successfully", vim.log.levels.INFO)
  end
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
