---@module 'usrcmds.migrate.common.command'
---@brief Generic command registration for migration tools.
---@description
--- Provides a unified command handler that supports:
---   - Line/range mode
---   - Buffer mode (%)
---   - CWD mode (cwd)
--- Each migration type provides callbacks for scanning and applying.

local M = {}

local api = vim.api

---@class MigrateCommon.CommandOpts
---@field name string                                    # Command name (e.g. "MigrateNotify")
---@field scan_range fun(bufnr: integer, line1: integer, line2: integer): table[] # Scan range
---@field scan_buffer fun(bufnr: integer): table[]      # Scan buffer
---@field scan_cwd fun(): table[]                       # Scan cwd
---@field apply_matches fun(matches: table[])           # Apply migrations
---@field show_picker fun(matches: table[])             # Show picker

--- Register migration command
---@param opts MigrateCommon.CommandOpts
function M.register(opts)
  api.nvim_create_user_command(opts.name, function(cmd_opts)
    local arg = cmd_opts.args:match("%S+")
    local bufnr = api.nvim_get_current_buf()

    -- Handle range mode
    if cmd_opts.range > 0 then
      local matches = opts.scan_range(bufnr, cmd_opts.line1, cmd_opts.line2)

      if #matches == 0 then
        vim.notify("No matches in range", vim.log.levels.WARN)
        return
      end

      opts.apply_matches(matches)
      return
    end

    -- Handle modes
    if not arg or arg == "" then
      -- Current line
      local cursor = api.nvim_win_get_cursor(0)
      local matches = opts.scan_range(bufnr, cursor[1], cursor[1])

      if #matches == 0 then
        vim.notify("No matches on line", vim.log.levels.WARN)
        return
      end

      opts.apply_matches(matches)

    elseif arg == "%" then
      -- Buffer with picker
      local matches = opts.scan_buffer(bufnr)
      opts.show_picker(matches)

    elseif arg == "cwd" then
      -- CWD with picker
      local matches = opts.scan_cwd()
      opts.show_picker(matches)

    else
      vim.notify("Invalid argument. Use: [empty], %, or cwd", vim.log.levels.ERROR)
    end
  end, {
    nargs = "?",
    range = true,
    desc = "Migration command: " .. opts.name,
    complete = function()
      return { "%", "cwd" }
    end,
  })
end

return M
