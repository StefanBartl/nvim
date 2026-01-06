---@module 'lsp.usercmds'
--- LSP UserCommands - Main Registry
--- Delegates to specialized submodules for each command

local notify = require("lib.notify").create("[lsp.usrcmds] ")

local M = {}

local nvim_create_user_command = vim.api.nvim_create_user_command
local desc_tag = "[lps.usercmds] "

-- Lazy-loaded submodules
local commands = {
  start = function()
    return require("lsp.usercmds.start")
  end,
  stop = function()
    return require("lsp.usercmds.stop")
  end,
  restart = function()
    return require("lsp.usercmds.restart")
  end,
  info = function()
    return require("lsp.usercmds.info")
  end,
  debug = function()
    return require("lsp.usercmds.debug")
  end,
}

local completion = function()
  return require("lsp.usercmds.completion")
end

--- Register all LSP usercommands
function M.attach()
  pcall(nvim_create_user_command, "LspLog", function()
    local logfile = vim.lsp.log.get_filename()
    vim.cmd("split " .. vim.fn.fnameescape(logfile))
  end, { desc = desc_tag .. "Open LSP log file" })

  pcall(nvim_create_user_command, "LspStatus", function()
    local bufnr = 0
    local clients = vim.lsp.get_clients({ bufnr = bufnr })

    if #clients == 0 then
      notify.info("No LSP clients attached to current buffer")
      return
    end

    local lines = { "LSP Status for buffer " .. bufnr }
    for _, c in ipairs(clients) do
      table.insert(lines, string.format("\n[%s]", c.name))
      table.insert(lines, "  ID: " .. tostring(c.id))
      table.insert(lines, "  Root: " .. tostring(c.config and c.config.root_dir or "unknown"))
      table.insert(lines, "  Status: " .. (c.is_stopped() and "stopped" or "running"))
    end

    notify.info(table.concat(lines, "\n"))
  end, { desc = desc_tag .. "Show LSP status for current buffer" })

  -- LspRecover: Auto-recover missing servers
  pcall(nvim_create_user_command, "LspRecover", function()
    local recovery = require("lsp.usercmds.recovery")
    recovery.auto_recover(0)
  end, { desc = desc_tag .. "Auto-recover missing LSP servers" })

  -- LspForceRestart: Force-restart with cleanup
  pcall(nvim_create_user_command, "LspForceRestart", function(args)
    local recovery = require("lsp.usercmds.recovery")
    if args.args and args.args ~= "" then
      recovery.force_restart(args.args, 0)
    else
      notify.warn("Usage: :LspForceRestart <server_name>")
    end
  end, {
    nargs = 1,
    complete = function(arglead, cmdline, cursorpos)
      return completion().complete_restart(arglead, cmdline, cursorpos)
    end,
    desc = desc_tag .. "Force-restart LSP with full cleanup",
  })

  -- LspHealth: Show LSP health for current buffer
  pcall(nvim_create_user_command, "LspHealth", function()
    local recovery = require("lsp.usercmds.recovery")
    local health = recovery.health_check(0)

    local lines = { "LSP Health Check", "================", "" }

    for _, status in ipairs(health) do
      local icon = status.running and "✓" or "✗"
      local state = status.running and "running" or "not running"
      table.insert(lines, string.format("%s %s: %s", icon, status.name, state))

      if not status.config_exists then
        table.insert(lines, "  ⚠ Config not found in vim.lsp.config")
      end

      if status.attempts and status.attempts > 0 then
        table.insert(lines, string.format("  Retry attempts: %d", status.attempts))
      end

      if status.last_error then
        table.insert(lines, string.format("  Last error: %s", status.last_error))
      end
    end

    notify.info(table.concat(lines, "\n"))
  end, { desc = desc_tag .. "Show LSP health status" })

  -- LspStartHere: Start servers (auto-detect or specify)
  pcall(nvim_create_user_command, "LspStartHere", function(args)
    commands.start().execute(args)
  end, {
    nargs = "?",
    complete = function(arglead, cmdline, cursorpos)
      return completion().complete_start(arglead, cmdline, cursorpos)
    end,
    desc = desc_tag .. "Start LSP servers (auto-detect or specify name)",
  })

  -- LspStopHere: Stop servers
  pcall(nvim_create_user_command, "LspStopHere", function(args)
    commands.stop().execute(args)
  end, {
    nargs = "?",
    complete = function(arglead, cmdline, cursorpos)
      return completion().complete_stop(arglead, cmdline, cursorpos)
    end,
    desc = desc_tag .. "Stop LSP clients (all or specify name)",
  })

  -- LspRestartHere: Restart servers
  pcall(nvim_create_user_command, "LspRestartHere", function(args)
    commands.restart().execute(args)
  end, {
    nargs = "?",
    complete = function(arglead, cmdline, cursorpos)
      return completion().complete_restart(arglead, cmdline, cursorpos)
    end,
    desc = desc_tag .. "Restart LSP clients (all or specify name)",
  })

  -- LspInfo: Show detailed info
  pcall(nvim_create_user_command, "LspInfo", function()
    commands.info().execute()
  end, {
    desc = desc_tag .. "Show LSP information for current buffer",
  })

  -- LspDebug: Show debug info (completion, configs, etc.)
  pcall(nvim_create_user_command, "LspDebug", function()
    commands.debug().execute()
  end, {
    desc = desc_tag .. "Show LSP debug information",
  })
end

return M
