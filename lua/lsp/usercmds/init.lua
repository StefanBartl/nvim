---@module 'lsp.usercmds'
--- LSP UserCommands - Main Registry
--- Delegates to specialized submodules for each command
require("@types.lsp")

local nvim_create_user_command = vim.api.nvim_create_user_command

local M = {}

local desc_tag = "[lsp.usercmds] "

-- Lazy-loaded submodules
local commands = {
  start = function() return require("lsp.usercmds.start") end,
  stop = function() return require("lsp.usercmds.stop") end,
  restart = function() return require("lsp.usercmds.restart") end,
  info = function() return require("lsp.usercmds.info") end,
}

local completion = function() return require("lsp.usercmds.completion") end

--- Register all LSP usercommands
function M.attach()
  -- LspStartHere: Start servers (auto-detect or specify)
  pcall(nvim_create_user_command, "LspStartHere", function(args)
    commands.start().execute(args)
  end, {
    nargs = "?",
    complete = function(arglead, cmdline, cursorpos)
      return completion().complete_start(arglead, cmdline, cursorpos)
    end,
    desc = desc_tag .. "Start LSP servers (auto-detect or specify name)"
  })

  -- LspStopHere: Stop servers
  pcall(nvim_create_user_command, "LspStopHere", function(args)
    commands.stop().execute(args)
  end, {
    nargs = "?",
    complete = function(arglead, cmdline, cursorpos)
      return completion().complete_stop(arglead, cmdline, cursorpos)
    end,
    desc = desc_tag .. "Stop LSP clients (all or specify name)"
  })

  -- LspRestartHere: Restart servers
  pcall(nvim_create_user_command, "LspRestartHere", function(args)
    commands.restart().execute(args)
  end, {
    nargs = "?",
    complete = function(arglead, cmdline, cursorpos)
      return completion().complete_restart(arglead, cmdline, cursorpos)
    end,
    desc = desc_tag .. "Restart LSP clients (all or specify name)"
  })

  -- LspInfo: Show detailed info
  pcall(nvim_create_user_command, "LspInfo", function()
    commands.info().execute()
  end, {
    desc = desc_tag .. "Show LSP information for current buffer"
  })
end

return M
