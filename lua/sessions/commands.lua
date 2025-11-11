---@module 'sessions/commands'
---@brief User commands, keymaps, and autocmds for portable sessions.
---@description
--- This module provides a small UX layer on top of sessions.core:
--- - :SessionSave [name], :SessionLoad [name], :SessionList
--- - Keymaps under <leader>s*
--- - Autoload last session on empty start; autosave on exit
--- The module avoids global state and validates all external calls, following the checklists.

local api, fn, notify, cmd, levels = vim.api, vim.fn, vim.notify, vim.cmd, vim.log.levels

---@class SessionsCommands
local M = {}

local desc_tag = "[sessions] "

---@return nil
local function define_commands()
  -- Save
  api.nvim_create_user_command("SessionSave", function(_cmd)
    local arg = (_cmd and _cmd.args or "")
    local ok, res = require("sessions.core").save(arg ~= "" and arg or nil)
    if ok then
      notify("Session saved: " .. (res or "?"))
    else
      notify("Session save failed: " .. (res or "?"), levels.ERROR)
    end
  end, { nargs = "?", desc = desc_tag .. "Save session to file" })

  -- Save with timestamp
  api.nvim_create_user_command("SessionSaveTimestamp", function()
    local stamp = os.date("sess-%Y%m%d-%H%M%S")
    local ok, res = pcall(cmd("SessionSave " .. stamp))
    if ok then
      notify("Session saved with timestamp: " .. (res or "?"))
    else
      notify("Session saving with timestamp failed: " .. (res or "?"), levels.ERROR)
    end
  end, { nargs = "?", desc = desc_tag .. "Save session with timestamp to file" })

  -- Load
  api.nvim_create_user_command("SessionLoad", function(_cmd)
    local arg = (_cmd and _cmd.args or "last")
    local ok, res = require("sessions.core").load(arg ~= "" and arg or nil)
    if ok then
      notify("Session loaded: " .. (res or "?"))
    else
      notify("Session load failed: " .. (res or "?"), levels.ERROR)
    end
  end, {
    nargs = "?",
    complete = function()
      local list = require("sessions.core").list()
      ---@type string[]
      local out = { [#list] = "" }
      for i = 1, #list do
        out[i] = fn.fnamemodify(list[i], ":t:r")
      end
      return out
    end,
    desc = desc_tag .. "Load session from file",
  })

  -- List
  api.nvim_create_user_command("SessionList", function()
    local list = require("sessions.core").list()
    if #list == 0 then
      print("No sessions.")
      return
    end
    for i = 1, #list do
      print("- " .. list[i])
    end
  end, { desc = desc_tag .. "List available sessions" })

  -- Toggle tracking `/storage/last.vim`-file in git
  api.nvim_create_user_command("ToggleLastVimTrack", function()
    local last_vim_file = fn.stdpath("config") .. "/lua/sessions/storage/last.vim"

    local function is_skipped(file)
      local handle = io.popen("git ls-files -v " .. fn.fnameescape(file))
      if not handle then
        return false
      end
      local result = handle:read("*a")
      handle:close()
      return result:match("^S")
    end

    local file = last_vim_file
    if is_skipped(file) then
      local result = fn.system("git update-index --no-skip-worktree " .. vim.fn.fnameescape(file))
      if vim.v.shell_error ~= 0 then
        notify("Git command failed: " .. result, levels.ERROR)
      else
        notify("last.vim is now tracked in git", levels.INFO)
      end
    else
      local result = fn.system("git update-index --skip-worktree " .. vim.fn.fnameescape(file))
      if vim.v.shell_error ~= 0 then
        notify("Git command failed: " .. result, levels.ERROR)
      else
        notify("last.vim marked as skip-worktree", levels.INFO)
      end
    end
  end, {})
end

---@return nil
local function define_keymaps()
  local map = function(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { desc = desc, silent = true })
  end
  map("n", "<leader>ssa", function()
    cmd("SessionSave")
  end, "Session Save")
  map("n", "<leader>slo", function()
    cmd("SessionLoad")
  end, "Session Load")
  map("n", "<leader>sst", function()
    local stamp = os.date("sess-%Y%m%d-%H%M%S")
    cmd("SessionSave " .. stamp)
  end, "Session Save (timestamp)")
  map("n", "<leader>sli", function()
    cmd("SessionList")
  end, "Session List")
end

---@return nil
local function define_autocmds()
  local aug = api.nvim_create_augroup("PortableSessions", { clear = true })

  -- Autoload last session when starting without file args
  -- api.nvim_create_autocmd("VimEnter", {
  --   group = aug,
  --   callback = function()
  --     if fn.argc(-1) == 0 then
  --       local ok, _ = require("sessions.core").load(nil)
  --       if ok then notify("Session autoloaded") end
  --     end
  --   end,
  --   desc = desc_tag .. "Portable sessions startup hook",
  --   once = true,
  -- })

  -- Autosave default session on exit
  api.nvim_create_autocmd("VimLeavePre", {
    group = aug,
    callback = function()
      require("sessions.core").save(nil)
    end,
    desc = desc_tag .. "Portable sessions shutdown hook",
  })
end

---@return nil
function M.setup()
  define_commands()
  define_keymaps()
  define_autocmds()
end

M.setup()

return M
