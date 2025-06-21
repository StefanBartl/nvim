---@module 'myterm.usercommands'
---@brief Command definitions for user-facing :Myterm* commands
---@description
--- This module defines all user-visible commands that interact with myterm.
--- It calls into the main myterm public API (`init.lua`) and handles argument parsing,
--- feedback messages, and completion logic.

local state = require("custom.myterm.state")

--- Helper to register a toggle-style command under a custom name
---@param name string The command name (e.g. "MytermToggle" or "Myterm")
local function make_toggle_command(name)
  vim.api.nvim_create_user_command(name, function(opts)
    local arg = opts.args
    local myterm = require("custom.myterm")

    if arg ~= "" then
      myterm.new(arg)
      return
    end

    -- No argument: try to toggle the last terminal, or open new horizontal if none
    local last = require("custom.myterm.state").get_last_focused()
    if last then
      myterm.toggle()
    else
      vim.notify("[myterm] No terminal active → creating new horizontal terminal", vim.log.levels.INFO)
      myterm.new("horizontal")
    end
  end, {
    nargs = "?",
    complete = function()
      return { "float", "horizontal", "vertical" }
    end,
    desc = "Toggle the last active terminal or open a new one with layout (default: horizontal)",
  })
end

-- Define aliases: both :Myterm and :MytermToggle work the same
make_toggle_command("MytermToggle")
make_toggle_command("Myterm")

--- Registers all user-facing :Myterm* commands
---@param myterm table The public myterm module (usually require("custom.myterm"))
local function register(myterm)
  --- Open a new terminal with optional layout argument
  vim.api.nvim_create_user_command("MytermNew", function(opts)
    local mode = opts.args ~= "" and opts.args or "horizontal"
    myterm.new(mode)
  end, {
    nargs = "?",
    complete = function() return { "float", "horizontal", "vertical" } end,
    desc = "Open a new terminal (default: horizontal)",
  })

  --- Run the stored command in the focused or given terminal
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

  --- Send a one-off command to a terminal without showing it
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

  --- Prompt for a new command and store it
  vim.api.nvim_create_user_command("MytermSet", function()
    myterm.set_command()
  end, {
    desc = "Prompt for a command and store it",
  })

  --- Clear the currently stored command
  vim.api.nvim_create_user_command("MytermClear", function()
    myterm.clear_command()
  end, {
    desc = "Clear the stored command",
  })

  --- Switch focus to a specific terminal ID
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

  --- Print info about the currently active terminal
  vim.api.nvim_create_user_command("MytermInfo", function()
    myterm.show_active()
  end, {
    desc = "Print info about the currently focused terminal",
  })

  --- Close a terminal by ID
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
