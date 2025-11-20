---@module 'sessions/usercmds'
---@brief Usercommands for portable sessions

local M = {}

local nvim_create_user_command = vim.api.nvim_create_user_command
local notify = vim.notify

---@return nil
function M.enable()
  -- Save
  nvim_create_user_command("SessionSave", function(cmd)
    local arg = (cmd and cmd.args or "")
    local ok, res = require("sessions.core").save(arg ~= "" and arg or nil)
    if ok then
      notify("Session saved: " .. (res or "?"))
    else
      notify("Session save failed: " .. (res or "?"), vim.log.levels.ERROR)
    end
  end, { nargs = "?", desc = "Save session to file" })

  -- Save with timestamp
  nvim_create_user_command("SessionSaveTimestamp", function()
    local stamp = os.date("sess-%Y%m%d-%H%M%S")
    local ok, res = pcall(vim.cmd("SessionSave " .. stamp))
    if ok then
      notify("Session saved with timestamp: " .. (res or "?"))
    else
      notify("Session saving with timestamp failed: " .. (res or "?"), vim.log.levels.ERROR)
    end
  end, { nargs = "?", desc = "Save session with timestamp to file" })

  -- Load
  nvim_create_user_command("SessionLoad", function(cmd)
    local arg = (cmd and cmd.args or "last")
    local ok, res = require("sessions.core").load(arg ~= "" and arg or nil)
    if ok then
      notify("Session loaded: " .. (res or "?"))
    else
      notify("Session load failed: " .. (res or "?"), vim.log.levels.ERROR)
    end
  end, {
    nargs = "?",
    complete = function()
      local list = require("sessions.core").list()
      ---@type string[]
      local out = { [#list] = "" }
      for i = 1, #list do
        out[i] = vim.fn.fnamemodify(list[i], ":t:r")
      end
      return out
    end,
    desc = "Load session from file",
  })

  -- List
  nvim_create_user_command("SessionList", function()
    local list = require("sessions.core").list()
    if #list == 0 then
      print("No sessions.")
      return
    end
    for i = 1, #list do
      print("- " .. list[i])
    end
  end, { desc = "List available sessions" })

  -- Toggle tracking `/storage/last.vim`-file in git
  vim.api.nvim_create_user_command("ToggleLastVimTrack", function()
    local last_vim_file = vim.fn.stdpath("config") .. "/lua/sessions/storage/last.vim"

    local function is_skipped(file)
      local handle = io.popen("git ls-files -v " .. vim.fn.fnameescape(file))
      if not handle then
        return false
      end
      local result = handle:read("*a")
      handle:close()
      return result:match("^S")
    end

    local file = last_vim_file
    if is_skipped(file) then
      local result = vim.fn.system("git update-index --no-skip-worktree " .. vim.fn.fnameescape(file))
      if vim.v.shell_error ~= 0 then
        notify("Git command failed: " .. result, vim.log.levels.ERROR)
      else
        notify("last.vim is now tracked in git", vim.log.levels.INFO)
      end
    else
      local result = vim.fn.system("git update-index --skip-worktree " .. vim.fn.fnameescape(file))
      if vim.v.shell_error ~= 0 then
        notify("Git command failed: " .. result, vim.log.levels.ERROR)
      else
        notify("last.vim marked as skip-worktree", vim.log.levels.INFO)
      end
    end
  end, {})
end

return M
