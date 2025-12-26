---@module 'lsp.diagnostics.commands'
--- User command definitions for diagnostics navigation.

local util = require("lsp.diagnostics.util")
local loclist = require("lsp.diagnostics.loclist")
local quickfix = require("lsp.diagnostics.quickfix")

local M = {}

--- Register all diagnostics-related user commands.
---@return nil
function M.enable()
  if vim.g._diagnostics_cmds_enabled == 1 then
    return
  end
  vim.g._diagnostics_cmds_enabled = 1

  -- Location list (buffer)
  vim.api.nvim_create_user_command("DiagLoc", function(ctx)
    loclist.to_loc({ open = true, severity = ctx.args })
  end, { nargs = "?" })

  vim.api.nvim_create_user_command("DiagNextLoc", function(ctx)
    local sev = util.to_severity(ctx.args)
    loclist.next_loc(sev)
  end, { nargs = "?" })

  vim.api.nvim_create_user_command("DiagPrevLoc", function(ctx)
    local sev = util.to_severity(ctx.args)
    loclist.prev_loc(sev)
  end, { nargs = "?" })

  -- Quickfix (workspace)
  vim.api.nvim_create_user_command("DiagQF", function(ctx)
    quickfix.to_qf({ open = true, severity = ctx.args })
  end, { nargs = "?" })

  vim.api.nvim_create_user_command("DiagNextQF", function()
    quickfix.next_qf()
  end, { bang = true })

  vim.api.nvim_create_user_command("DiagPrevQF", function()
    quickfix.prev_qf()
  end, { bang = true })
end

return M
