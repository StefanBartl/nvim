---@module 'usrcmds.migrate.notify'
---@brief Main entry point for notify migration commands.
---@description
--- Provides three operation modes:
---   1. :MigrateNotify         → refactor current line
---   2. :MigrateNotify %       → refactor buffer (Telescope picker)
---   3. :MigrateNotify cwd     → refactor cwd (Telescope picker)
---
--- Architecture:
---   - parser: Treesitter-based pattern detection
---   - refactor: Atomic buffer modifications
---   - telescope: Interactive selection UI

local M = {}

local api = vim.api

--- Refactor current line or range
---@param line1 integer Start line (1-based)
---@param line2 integer End line (1-based)
local function migrate_line_or_range(line1, line2)
  local bufnr = api.nvim_get_current_buf()
  local parser = require("usrcmds.migrate.notify.parser")

  local matches = parser.scan_buffer(bufnr)

  -- Filter matches within range
  local range_matches = {}
  for _, match in ipairs(matches) do
    if match.line >= line1 and match.line <= line2 then
      table.insert(range_matches, match)
    end
  end

  if #range_matches == 0 then
    vim.notify("No vim.notify patterns found in range", vim.log.levels.WARN)
    return
  end

  -- Apply directly without picker for line/range mode
  local refactor = require("usrcmds.migrate.notify.refactor")

  -- Create undo point
  vim.cmd("undojoin")

  refactor.inject_import(bufnr)

  -- Sort descending
  table.sort(range_matches, function(a, b)
    return a.end_line > b.end_line
  end)

  local modified = 0
  for _, match in ipairs(range_matches) do
    if refactor.apply_match(bufnr, match) then
      modified = modified + 1
    end
  end

  vim.notify(
    string.format("Refactored %d match(es) in range", modified),
    vim.log.levels.INFO
  )
end

--- Refactor current buffer with Telescope
local function migrate_buffer()
  local bufnr = api.nvim_get_current_buf()
  local parser = require("usrcmds.migrate.notify.parser")

  local matches = parser.scan_buffer(bufnr)

  if #matches == 0 then
    vim.notify("No vim.notify patterns found in buffer", vim.log.levels.WARN)
    return
  end

  local path = api.nvim_buf_get_name(bufnr)
  local file_matches = {
    {
      path = path,
      matches = matches,
    },
  }

  local telescope = require("usrcmds.migrate.notify.telescope")
  telescope.show_picker(file_matches)
end

--- Refactor all Lua files in cwd
local function migrate_cwd()
  local cwd = vim.fn.getcwd()

  -- Find all Lua files
  local files = vim.fn.globpath(cwd, "**/*.lua", false, true)

  if #files == 0 then
    vim.notify("No Lua files found in cwd", vim.log.levels.WARN)
    return
  end

  local parser = require("usrcmds.migrate.notify.parser")
  local file_matches = parser.scan_files(files)

  if #file_matches == 0 then
    vim.notify("No vim.notify patterns found in cwd", vim.log.levels.WARN)
    return
  end

  local telescope = require("usrcmds.migrate.notify.telescope")
  telescope.show_picker(file_matches)
end

--- Setup user commands
function M.enable()
  api.nvim_create_user_command("MigrateNotify", function(opts)
    local arg = opts.args:match("%S+")

    -- Handle range mode (visual selection or :1,5MigrateNotify)
    if opts.range > 0 then
      migrate_line_or_range(opts.line1, opts.line2)
      return
    end

    if not arg or arg == "" then
      -- Single line mode (current line)
      local cursor = api.nvim_win_get_cursor(0)
      migrate_line_or_range(cursor[1], cursor[1])
    elseif arg == "%" then
      migrate_buffer()
    elseif arg == "cwd" then
      migrate_cwd()
    else
      vim.notify("Invalid argument. Use: [empty], %, or cwd", vim.log.levels.ERROR)
    end
  end, {
    nargs = "?",
    range = true, -- Enable range support
    desc = "Migrate vim.notify to lib.notify",
    complete = function()
      return { "%", "cwd" }
    end,
  })
end

return M
