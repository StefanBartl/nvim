---@module 'sessions/commands'
---@brief User commands, keymaps, and autocmds for portable sessions.
---@description
--- This module provides a small UX layer on top of sessions.core:
--- - :SessionSave [name], :SessionLoad [name], :SessionList
--- - Keymaps under <leader>s*
--- - Autoload last session on empty start; autosave on exit
--- The module avoids global state and validates all external calls, following the checklists.

---@class SessionsCommands
local M = {}

---@return nil
local function define_commands()
  -- Save
  vim.api.nvim_create_user_command("SessionSave", function(cmd)
    local arg = (cmd and cmd.args or "")
    local ok, res = require("sessions.core").save(arg ~= "" and arg or nil)
    if ok then
      vim.notify("Session saved: " .. (res or "?"))
    else
      vim.notify("Session save failed: " .. (res or "?"), vim.log.levels.ERROR)
    end
  end, { nargs = "?", desc = "Save session to file" })

  -- Load
  vim.api.nvim_create_user_command("SessionLoad", function(cmd)
    local arg = (cmd and cmd.args or "")
    local ok, res = require("sessions.core").load(arg ~= "" and arg or nil)
    if ok then
      vim.notify("Session loaded: " .. (res or "?"))
    else
      vim.notify("Session load failed: " .. (res or "?"), vim.log.levels.ERROR)
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
  vim.api.nvim_create_user_command("SessionList", function()
    local list = require("sessions.core").list()
    if #list == 0 then
      print("No sessions.")
      return
    end
    for i = 1, #list do
      print("- " .. list[i])
    end
  end, { desc = "List available sessions" })
end

---@return nil
local function define_keymaps()
  local map = function(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { desc = desc, silent = true })
  end
  map("n", "<leader>ss", function() vim.cmd("SessionSave") end, "Session Save")
  map("n", "<leader>sl", function() vim.cmd("SessionLoad") end, "Session Load")
  map("n", "<leader>sn", function()
    local name = os.date("sess-%Y%m%d-%H%M%S")
    vim.cmd("SessionSave " .. name)
  end, "Session Save (timestamp)")
  map("n", "<leader>sh", function() vim.cmd("SessionList") end, "Session List")
end

---@return nil
local function define_autocmds()
  local aug = vim.api.nvim_create_augroup("PortableSessions", { clear = true })

  -- Autoload last session when starting without file args
  vim.api.nvim_create_autocmd("VimEnter", {
    group = aug,
    callback = function()
      if vim.fn.argc(-1) == 0 then
        local ok, _ = require("sessions.core").load(nil)
        if ok then vim.notify("Session autoloaded") end
      end
    end,
    desc = "Portable sessions startup hook",
    once = true,
  })

  -- Autosave default session on exit
  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = aug,
    callback = function()
      require("sessions.core").save(nil)
    end,
    desc = "Portable sessions shutdown hook",
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

