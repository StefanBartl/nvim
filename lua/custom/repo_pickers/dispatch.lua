---@module 'custom.repo_pickers.dispatch'
--- Engine resolution and invocation of this module's own user-commands.

local M = {}

--- Check if a user command exists and whether it allows a single optional argument.
--- @param cmd string
--- @return boolean exists, boolean allows_arg
local function cmd_capabilities(cmd)
  if type(cmd) ~= "string" or cmd == "" then return false, false end
  local exists = (vim.fn.exists(":" .. cmd) == 2) or (vim.fn.exists(":" .. cmd) == 1)
  if not exists then return false, false end
  local defs = vim.api.nvim_get_commands({ builtin = false })
  local spec = defs[cmd]
  if not spec then return true, true end -- builtin or opaque: assume ok
  local nargs = spec.nargs or "?"
  local allows = (nargs == "?" or nargs == "1" or nargs == "+" or nargs == "*")
  return true, allows
end

--- Execute a user command safely with an optional directory argument.
--- Uses structured API to avoid Ex-parser pitfalls.
--- @param cmd string
--- @param dir RepoDir
--- @return nil
local function exec_user_cmd(cmd, dir)
  local exists, allows_arg = cmd_capabilities(cmd)
  if not exists then
    vim.notify(("repo_pickers: command not found: %s"):format(tostring(cmd)), vim.log.levels.ERROR)
    return
  end
  local ok, err
  if dir and dir ~= "" and allows_arg then
    ok, err = pcall(function()
      vim.api.nvim_cmd({ cmd = cmd, args = { vim.fn.fnameescape(dir) } }, {})
    end)
  else
    ok, err = pcall(function()
      vim.api.nvim_cmd({ cmd = cmd }, {})
    end)
  end
  if not ok then
    vim.notify(("repo_pickers: failed to run %s: %s"):format(cmd, tostring(err)), vim.log.levels.ERROR)
  end
end

--- Resolve which command to call for "files".
--- @param cfg RepoPickersConfig
--- @return string
function M.resolve_cmd_files(cfg)
  local names = cfg.usercmd_names or {}
  local engine = cfg.engine or "auto"
  if engine == "telescope" then return names.find_files_telescope end
  if engine == "fzf"       then return names.find_files_fzf       end
  if pcall(require, "fzf-lua") then return names.find_files_fzf end
  if pcall(require, "telescope") or pcall(require, "telescope.builtin") then
    return names.find_files_telescope
  end
  return names.find_files_telescope
end

--- Resolve which command to call for "grep".
--- @param cfg RepoPickersConfig
--- @return string
function M.resolve_cmd_grep(cfg)
  local names = cfg.usercmd_names or {}
  local engine = cfg.engine or "auto"
  if engine == "telescope" then return names.grep_telescope end
  if engine == "fzf"       then return names.grep_fzf       end
  if pcall(require, "fzf-lua") then return names.grep_fzf end
  if pcall(require, "telescope") or pcall(require, "telescope.builtin") then
    return names.grep_telescope
  end
  return names.grep_telescope
end

--- Execute a repo_* user command with the selected directory as argument.
--- @param cmd string
--- @param dir RepoDir
--- @return nil
function M.run_usr_picker(cmd, dir)
  if type(cmd) ~= "string" or cmd == "" then
    vim.notify("repo_pickers: invalid command name", vim.log.levels.ERROR)
    return
  end
  if type(dir) ~= "string" or dir == "" then
    vim.notify("repo_pickers: invalid directory for picker", vim.log.levels.ERROR)
    return
  end
  exec_user_cmd(cmd, dir)
end

return M
