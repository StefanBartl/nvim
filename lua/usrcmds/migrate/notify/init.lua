---@module 'usrcmds.migrate.notify'
---@brief Migrate vim.notify to lib.notify (with alias support)
---@description
--- Enhanced version that detects both:
---   - vim.notify() direct calls
---   - Aliased calls (local notify = vim.notify)
--- Supports optional module name for .create() syntax

local command = require("usrcmds.migrate.common.command")
local picker = require("usrcmds.migrate.common.picker")
local buffer_ops = require("usrcmds.migrate.common.buffer")
local parser = require("usrcmds.migrate.notify.parser")
local refactor = require("usrcmds.migrate.notify.refactor")

local M = {}

local api = vim.api
local tbl_insert = table.insert
local notify = require("lib.notify").create("[migrate.notify]")

--------------------------------------------------------------------------------
-- Exclusion logic
--------------------------------------------------------------------------------

---Check if file should be excluded
---@param filepath string
---@return boolean
local function should_exclude(filepath)
  local normalized = filepath:gsub("\\", "/")
  return normalized:match("/usrcmds/migrate/") ~= nil
end

--------------------------------------------------------------------------------
-- Conversion helpers
--------------------------------------------------------------------------------

---Convert parser matches to common format
---@param bufnr integer
---@param parser_matches MigrateNotify.Match[]
---@return MigrateCommon.Match[]
local function to_common_matches(bufnr, parser_matches)
  local matches = {}
  local fname = api.nvim_buf_get_name(bufnr)

  for _, pm in ipairs(parser_matches) do
    tbl_insert(matches, {
      bufnr = bufnr,
      fname = fname ~= "" and fname or nil,
      lnum = pm.line,
      text = pm.original,
      migrated = pm.replacement,
      source = "buf",
      extra = {
        end_line = pm.end_line,
        col = pm.col,
        end_col = pm.end_col,
        log_level = pm.log_level,
      },
    })
  end

  return matches
end

--------------------------------------------------------------------------------
-- Scan functions
--------------------------------------------------------------------------------

---Scan buffer range
---@param bufnr integer
---@param line1 integer
---@param line2 integer
---@return MigrateCommon.Match[]
local function scan_range(bufnr, line1, line2)
  if not api.nvim_buf_is_valid(bufnr) then
    return {}
  end

  local fname = api.nvim_buf_get_name(bufnr)
  if fname ~= "" and should_exclude(fname) then
    notify.warn("Skipping migrate module file")
    return {}
  end

  local all_matches = parser.scan_buffer(bufnr)
  local range_matches = {}

  for _, match in ipairs(all_matches) do
    if match.line >= line1 and match.line <= line2 then
      tbl_insert(range_matches, match)
    end
  end

  return to_common_matches(bufnr, range_matches)
end

---Scan entire buffer
---@param bufnr integer
---@return MigrateCommon.Match[]
local function scan_buffer(bufnr)
  if not api.nvim_buf_is_valid(bufnr) then
    return {}
  end

  local fname = api.nvim_buf_get_name(bufnr)
  if fname ~= "" and should_exclude(fname) then
    notify.warn("Skipping migrate module file")
    return {}
  end

  local matches = parser.scan_buffer(bufnr)
  return to_common_matches(bufnr, matches)
end

---Scan cwd (excluding migrate module)
---@return MigrateCommon.Match[]
local function scan_cwd()
  local cwd = vim.fn.getcwd()
  local files = buffer_ops.find_lua_files(cwd)

  if #files == 0 then
    return {}
  end

  local all_matches = {}
  local excluded_count = 0

  for _, filepath in ipairs(files) do
    if should_exclude(filepath) then
      excluded_count = excluded_count + 1
    else
      local bufnr = buffer_ops.ensure_buffer(filepath)
      if bufnr then
        local file_matches = parser.scan_buffer(bufnr)

        for _, match in ipairs(file_matches) do
          tbl_insert(all_matches, {
            bufnr = bufnr,
            fname = filepath,
            lnum = match.line,
            text = match.original,
            migrated = match.replacement,
            source = "file",
            extra = {
              end_line = match.end_line,
              col = match.col,
              end_col = match.end_col,
              log_level = match.log_level,
            },
          })
        end
      end
    end
  end

  if excluded_count > 0 then
    notify.info(string.format("Excluded %d migrate module file(s)", excluded_count))
  end

  return all_matches
end

--------------------------------------------------------------------------------
-- Application (with module name support)
--------------------------------------------------------------------------------

---Apply migrations with optional module name
---@param matches MigrateCommon.Match[]
---@param module_name string|nil Optional module name for .create("")
local function apply_matches(matches, module_name)
  -- Group by buffer
  local by_buffer = {}
  for _, match in ipairs(matches) do
    local bufnr = match.bufnr
    if bufnr then
      if not by_buffer[bufnr] then
        by_buffer[bufnr] = {}
      end
      tbl_insert(by_buffer[bufnr], match)
    end
  end

  -- Apply per buffer
  for bufnr, _ in pairs(by_buffer) do
    buffer_ops.create_undo_point(bufnr)

    -- Inject import FIRST
    refactor.inject_import(bufnr, module_name)

    -- RE-SCAN buffer to get CORRECT line numbers
    local fresh_matches = parser.scan_buffer(bufnr)

    -- Convert to common format
    local updated_matches = to_common_matches(bufnr, fresh_matches)

    -- Sort DESCENDING
    table.sort(updated_matches, function(a, b)
      return a.extra.end_line > b.extra.end_line
    end)

    -- Apply each match (NO OFFSET NEEDED)
    local success_count = 0
    for _, match in ipairs(updated_matches) do
      ---@type MigrateNotify.Match
      local parser_match = {
        line = match.lnum,
        end_line = match.extra.end_line,
        col = match.extra.col,
        end_col = match.extra.end_col,
        replacement = match.migrated,
      }

      if refactor.apply_match(bufnr, parser_match) then
        success_count = success_count + 1
      end
    end

    if success_count > 0 then
      notify.info(string.format("Applied %d/%d migration(s)", success_count, #updated_matches))
    end
  end

  -- Remove aliases if present
  for bufnr, _ in pairs(by_buffer) do
    refactor.remove_aliases(bufnr)
  end
end
--------------------------------------------------------------------------------
-- Picker
--------------------------------------------------------------------------------

---Show picker with module name support
---@param matches MigrateCommon.Match[]
---@param module_name string|nil
local function show_picker_impl(matches, module_name)
  picker.show(matches, {
    title = "Migrate vim.notify → lib.notify",
    single_apply = false,

    format_entry = function(match)
      local filename = match.fname and vim.fn.fnamemodify(match.fname, ":t")
        or ("buf:" .. match.bufnr)

      -- FIXED: Ensure log_level is a string
      local level = "INFO" -- default
      if match.extra and match.extra.log_level then
        -- If it's already a string, use it; if it's somehow a number, convert
        if type(match.extra.log_level) == "string" then
          level = match.extra.log_level
        elseif type(match.extra.log_level) == "number" then
          -- Shouldn't happen, but handle it defensively
          local level_map = { "TRACE", "DEBUG", "INFO", "WARN", "ERROR" }
          level = level_map[match.extra.log_level] or "INFO"
        end
      end

      return string.format(
        "%s:%d  [%s]  %s",
        filename,
        match.lnum,
        level:lower(),
        match.text:sub(1, 50)
      )
    end,

    format_preview = function(match)
      return {
        "-- Before:",
        match.text,
        "",
        "-- After:",
        match.migrated,
      }
    end,

    on_apply = function(selections)
      apply_matches(selections, module_name)
    end,
  })
end

--------------------------------------------------------------------------------
-- Registration
--------------------------------------------------------------------------------

function M.enable()
  command.register({
    name = "MigrateNotify",
    scan_range = scan_range,
    scan_buffer = scan_buffer,
    scan_cwd = scan_cwd,

    -- Wrapper that extracts module name from args
    apply_matches = function(matches)
      apply_matches(matches, nil)
    end,

    -- Wrapper that passes module name to picker
    show_picker = function(matches)
      show_picker_impl(matches, nil)
    end,

    -- Custom completion
    ---@diagnostic disable-next-line: unused-local
    complete = function(arg_lead, cmd_line, cursor_pos)
      -- Extract what's already been typed
      local args = vim.split(cmd_line, "%s+", { trimempty = true })

      -- First argument: mode (%, cwd)
      if #args <= 2 then
        local completions = { "%", "cwd" }
        if arg_lead == "" then
          return completions
        end

        local matches = {}
        for _, comp in ipairs(completions) do
          if comp:find(arg_lead, 1, true) == 1 then
            table.insert(matches, comp)
          end
        end
        return matches
      end

      -- Second argument: module name (free text, no completion)
      return {}
    end,
  })

  vim.api.nvim_create_user_command("MigrateNotify", function(cmd_opts)
    local args_str = cmd_opts.args
    local parts = vim.split(args_str, "%s+", { trimempty = true })

    local mode = parts[1] or ""
    local module_name = parts[2] or nil

    -- Store module name in global for access by apply/picker functions
    _G._migrate_notify_module_name = module_name

    -- Reconstruct args without module name
    local new_args = mode
    cmd_opts.args = new_args

    -- Determine action based on mode
    local bufnr = api.nvim_get_current_buf()

    if cmd_opts.range > 0 then
      local matches = scan_range(bufnr, cmd_opts.line1, cmd_opts.line2)
      if #matches == 0 then
        notify.warn("No matches in range")
        return
      end
      apply_matches(matches, module_name)
      notify.info(string.format("Applied %d migration(s) in range", #matches))
    elseif mode == "" then
      local cursor = api.nvim_win_get_cursor(0)
      local matches = scan_range(bufnr, cursor[1], cursor[1])
      if #matches == 0 then
        notify.warn("No matches on current line")
        return
      end
      apply_matches(matches, module_name)
      notify.info(string.format("Applied %d migration(s) on line %d", #matches, cursor[1]))
    elseif mode == "%" then
      local matches = scan_buffer(bufnr)
      if #matches == 0 then
        notify.warn("No matches in buffer")
        return
      end
      show_picker_impl(matches, module_name)
    elseif mode == "cwd" then
      local matches = scan_cwd()
      if #matches == 0 then
        notify.warn("No matches in cwd")
        return
      end
      show_picker_impl(matches, module_name)
    else
      notify.error(string.format("Invalid argument: %s. Use: [empty], %%, or cwd", mode))
    end

    -- Cleanup
    _G._migrate_notify_module_name = nil
  end, {
    nargs = "*",
    range = true,
    desc = "Migrate vim.notify to lib.notify (with optional module name)",
    ---@diagnostic disable-next-line: unused-local
    complete = function(arg_lead, cmd_line, cursor_pos)
      local args = vim.split(cmd_line, "%s+", { trimempty = true })

      if #args <= 2 then
        local completions = { "%", "cwd" }
        if arg_lead == "" then
          return completions
        end

        local matches = {}
        for _, comp in ipairs(completions) do
          if comp:find(arg_lead, 1, true) == 1 then
            table.insert(matches, comp)
          end
        end
        return matches
      end

      return {}
    end,
  })
end

return M
