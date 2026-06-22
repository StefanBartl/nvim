---@module 'custom.format.markdown'
---@brief Markdown-specific formatting operations
---@description
--- Provides markdown-specific formatting subcommands:
--- • headline_separators: Ensure proper spacing between H2+ sections

local notify = require("lib.nvim.notify").create("[custom.format.markdown]")

local M = {}

---Register markdown subcommands
---@param register_fn fun(name: string, def: table) Registration function
---@return nil
function M.register_subcommands(register_fn)
  local separators = require("custom.format.markdown.headlines.separators")

  -- Subcommand: headline_separators
  register_fn("markdown", {
    handler = function(args)
      if #args == 0 then
        notify.error("[custom.format.markdown] Usage: markdown <headline_separators>")
        return
      end

      local subcommand = args[1]

      if subcommand == "headline_separators" then
        local bufnr = vim.api.nvim_get_current_buf()
        separators.apply_headl_separators(bufnr, { notify = true })
      else
        notify.error(string.format( "[custom.format.markdown] Unknown markdown subcommand: %s", subcommand ))
      end
    end,
    ---@diagnostic disable-next-line: unused-local
    complete = function(arg_lead, cmdline, cursor_pos)
      return { "headline_separators" }
    end,
    nargs = "+",
    desc = "Markdown formatting: markdown <headline_separators>",
  })
end

return M
