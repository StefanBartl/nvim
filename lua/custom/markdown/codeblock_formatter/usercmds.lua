---@module 'custom.markdown.codeblock_formatter.usercmds'
--- User command glue for the formatter plugin.
--- Exposes SetupCommands(setup_table) that registers :FormatMdCodeblocks and range variant.
--- commands call into run module.
local M = {}

local run = require("custom.markdown.codeblock_formatter.run")

function M.SetupCommands()
  vim.api.nvim_create_user_command("FormatMdCodeblocks", function()
    run.format_buffer_async()
  end, { desc = "Async format supported fenced codeblocks in buffer" })

  vim.api.nvim_create_user_command("FormatMdCodeblocksRange", function(opts)
    local s = opts.line1
    local e = opts.line2
    if not s or not e then
      -- allow visual selection fallback inside run module
      run.format_range_async()
    else
      run.format_range_async(s, e)
    end
  end, { desc = "Async format supported fenced codeblocks inside given range", range = true })
end

return M
