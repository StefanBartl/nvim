---@module 'myterm.usercommands'
---@brief Command definitions for user-facing :Myterm* commands
---@description
--- This module defines all user-visible commands that interact with myterm.
--- It calls into the main myterm public API (`init.lua`) and handles argument parsing,
--- feedback messages, and completion logic.

-- Terminal State Access
local state = require("custom.myterm.state")

local function register(myterm)
  vim.api.nvim_create_user_command("MytermNew", function(opts)
    local mode = opts.args ~= "" and opts.args or "horizontal"
    myterm.new(mode)
  end, {
    nargs = "?",
    complete = function()
      return { "float", "horizontal", "vertical" }
    end,
    desc = "Open a new terminal (default: horizontal)",
  })

  vim.api.nvim_create_user_command("MytermToggle", function(opts)
    local arg = opts.args
    if arg == "" then
      myterm.toggle()
    else
      myterm.new(arg)
    end
  end, {
    nargs = "?",
    complete = function()
      return { "float", "horizontal", "vertical" }
    end,
    desc = "Toggle the last active terminal or open a new one with layout",
  })

  vim.api.nvim_create_user_command("MytermRun", function(opts)
    local id = tonumber(opts.args)
    local ok, err = myterm.run(id)
    if not ok then
      vim.notify("Failed to run command: " .. (err or "unknown error"), vim.log.levels.ERROR)
    end
  end, {
    nargs = "?",
    complete = function()
      local ids = {}
      for _, id in ipairs(state.valid_ids()) do
        table.insert(ids, tostring(id))
      end
      return ids
    end,
    desc = "Run stored command in active or given terminal",
  })

  vim.api.nvim_create_user_command("MytermSend", function(opts)
    local args = vim.split(opts.args or "", " ")
    local id = tonumber(table.remove(args, 1))
    local cmd = table.concat(args, " ")

    if not id then
      vim.notify("Please provide a valid terminal ID", vim.log.levels.WARN)
      return
    end
    if cmd == "" then
      vim.notify("Please provide a command to send", vim.log.levels.WARN)
      return
    end

    local ok, err = require("custom.myterm.command_runner").send_background(id, cmd)
    if not ok then
      vim.notify("Send failed: " .. (err or "unknown error"), vim.log.levels.ERROR)
    end
  end, {
    nargs = "+",
    desc = "Send a command to a terminal ID without showing it",
    complete = function()
      local ids = {}
      for _, id in ipairs(state.valid_ids()) do
        table.insert(ids, tostring(id))
      end
      return ids
    end,
  })

  vim.api.nvim_create_user_command("MytermSet", function()
    myterm.set_command()
  end, {
    desc = "Prompt for a command and store it",
  })

  vim.api.nvim_create_user_command("MytermClear", function()
    myterm.clear_command()
  end, {
    desc = "Clear the stored command",
  })

  vim.api.nvim_create_user_command("MytermFocus", function(opts)
    local id = tonumber(opts.args)
    if id then
      myterm.focus(id)
    else
      vim.notify("Please provide a valid terminal ID", vim.log.levels.WARN)
    end
  end, {
    nargs = 1,
    desc = "Switch focus to a specific terminal",
    complete = function()
      local ids = {}
      for _, id in ipairs(state.valid_ids()) do
        table.insert(ids, tostring(id))
      end
      return ids
    end,
  })

  vim.api.nvim_create_user_command("MytermInfo", function()
    myterm.show_active()
  end, {
    desc = "Print info about the currently focused terminal",
  })

  vim.api.nvim_create_user_command("MytermClose", function(opts)
    local id = tonumber(opts.args)
    if not id then
      vim.notify("Please provide a valid terminal ID", vim.log.levels.WARN)
      return
    end

    local ok, err = myterm.close(id)
    if not ok then
      vim.notify("Close failed: " .. (err or "unknown error"), vim.log.levels.ERROR)
    end
  end, {
    nargs = 1,
    desc = "Close a terminal by its ID",
    complete = function()
      local ids = {}
      for _, id in ipairs(state.valid_ids()) do
        table.insert(ids, tostring(id))
      end
      return ids
    end,
  })
end

return {
  register = register,
}
