---@module 'klingon_notify.plugin'
--- User commands and minimal default setup.
--- This file is auto-loaded by Neovim when placed under `plugin/`.

local ok, KN = pcall(require, "klingon_notify")
if not ok then
  return
end

-- Lazy default setup if user did not call setup()
KN.setup()

vim.api.nvim_create_user_command("KlingonShout", function(ctx)
  -- Usage: :KlingonShout success Optional extra message...
  local args = ctx.fargs
  local level = (args[1] or "info"):lower()
  local extra = table.concat(args, " ", 2)
  KN.shout(level, extra)
end, {
  nargs = "+",
  complete = function()
    return { "success", "error", "warn", "info" }
  end,
  desc = "Klingon shout (success|error|warn|info) [message]",
})

vim.api.nvim_create_user_command("KlingonSuccess", function(ctx)
  KN.success(table.concat(ctx.fargs, " "))
end, { nargs = "*", desc = "Klingon success shout" })

vim.api.nvim_create_user_command("KlingonError", function(ctx)
  KN.error(table.concat(ctx.fargs, " "))
end, { nargs = "*", desc = "Klingon error shout" })

vim.api.nvim_create_user_command("KlingonWarn", function(ctx)
  KN.warn(table.concat(ctx.fargs, " "))
end, { nargs = "*", desc = "Klingon warning shout" })

vim.api.nvim_create_user_command("KlingonInfo", function(ctx)
  KN.info(table.concat(ctx.fargs, " "))
end, { nargs = "*", desc = "Klingon info shout" })
