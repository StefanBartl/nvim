---@module 'custom.markdown.codeblock_formatter.usercmds'
--- User command glue for the formatter plugin.
--- Exposes SetupCommands(setup_table) that registers :FormatMdCodeblocks and range variant.
--- commands call into run module.
local M = {}

-- local run = require("custom.markdown.codeblock_formatter.run.async_worker")

-- function M.SetupCommands(opts)
--   opts = opts or {}
--   -- allow callers to override runtime config
--   if opts.notify_level then
--     run._config.notify_level = opts.notify_level
--   end
--   if opts.prefer_treesitter ~= nil then
--     run._config.prefer_treesitter = opts.prefer_treesitter
--   end
--   if opts.formatters then
--     run._config.formatters = vim.tbl_extend("force", run._config.formatters, opts.formatters)
--   end
--   if opts.lang_aliases then
--     run._config.lang_aliases = vim.tbl_extend("force", run._config.lang_aliases, opts.lang_aliases)
--   end
--
--   -- expose user commands here (keeps separation of concerns)
--   vim.api.nvim_create_user_command("FormatMdCodeblocks", function()
--     run.format_buffer_async()
--   end, { desc = "Async format fenced codeblocks in buffer" })
--   vim.api.nvim_create_user_command("FormatMdCodeblocksRange", function(opts2)
--     local s = opts2.line1
--     local e = opts2.line2
--     if not s or not e then
--       run.format_range_async()
--     else
--       run.format_range_async(s, e)
--     end
--   end, { range = true, desc = "Async format fenced codeblocks in range" })
--
--   vim.schedule(function()
--     vim.notify("md-codefmt run.init setup complete", vim.log.levels.INFO, { title = "md-codefmt" })
--   end)
-- end

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
