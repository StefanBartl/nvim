---@module 'sessions/usercmds'
---@brief Usercommands for portable sessions

local notify = require("lib.nvim.notify").create("[sessions.usercmds]")

local M = {}

local nvim_create_user_command = vim.api.nvim_create_user_command

---@return nil
function M.enable()
  -- Save
  nvim_create_user_command("SessionSave", function(cmd)
    local arg = (cmd and cmd.args or "")
    local ok, res = require("sessions.core").save(arg ~= "" and arg or nil)
    if ok then
      notify.info("Session saved: " .. (res or "?"))
    else
      notify.error("Session save failed: " .. (res or "?"))
    end
  end, { nargs = "?", desc = "Save session to file" })

  -- Save with timestamp
  nvim_create_user_command("SessionSaveTimestamp", function()
    local stamp = os.date("sess-%Y%m%d-%H%M%S")
    -- Call core.save directly (same as :SessionSave). The previous
    -- `pcall(vim.cmd("SessionSave " .. stamp))` was a bug: vim.cmd ran *before*
    -- pcall (its nil result was passed to pcall), so errors were never caught
    -- and `res` was always nil.
    local ok, res = require("sessions.core").save(stamp)
    if ok then
      notify.info("Session saved with timestamp: " .. (res or "?"))
    else
      notify.error("Session saving with timestamp failed: " .. (res or "?"))
    end
  end, { desc = "Save session with timestamp to file" })

  -- Load
  nvim_create_user_command("SessionLoad", function(cmd)
    local arg = (cmd and cmd.args or "last")
    local ok, res, hidden = require("sessions.core").load(arg ~= "" and arg or nil)
    if ok then
      notify.info("Session loaded: " .. (res or "?"))
          if hidden and #hidden > 0 then
      notify.info("Hidden (nicht verloren) wegen Session-Load: " .. table.concat(hidden, ", "))
    end
    else
      notify.error("Session load failed: " .. (res or "?"))
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
    local cfg_dir = vim.fn.stdpath("config")
    local file = cfg_dir .. "/lua/sessions/storage/last.vim"

    -- All git calls use argv arrays (no shell parsing) and run inside the config
    -- repo via cwd, avoiding quoting/injection issues with the file path.
    ---@param f string
    ---@return boolean
    local function is_skipped(f)
      local res = vim.system({ "git", "ls-files", "-v", "--", f }, { cwd = cfg_dir, text = true }):wait()
      if res.code ~= 0 then
        return false
      end
      return (res.stdout or ""):match("^S") ~= nil
    end

    local args = is_skipped(file)
        and { "git", "update-index", "--no-skip-worktree", "--", file }
        or { "git", "update-index", "--skip-worktree", "--", file }
    local res = vim.system(args, { cwd = cfg_dir, text = true }):wait()

    if res.code ~= 0 then
      notify.error("Git command failed: " .. (res.stderr or "unknown error"))
    elseif args[3] == "--no-skip-worktree" then
      notify.info("last.vim is now tracked in git")
    else
      notify.info("last.vim marked as skip-worktree")
    end
  end, {})
end

return M
