---@module 'usrcmds.migrate.notify'
---@brief Migrate vim.notify to lib.notify (simple regex approach)
---@description
--- Simplified approach using regex patterns instead of treesitter.
--- More robust and easier to debug.

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
  -- Normalize path separators
  local normalized = filepath:gsub("\\", "/")

  -- Exclude migrate module itself
  if normalized:match("/usrcmds/migrate/") then
    return true
  end

  return false
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

  -- Check exclusion
  local fname = api.nvim_buf_get_name(bufnr)
  if fname ~= "" and should_exclude(fname) then
    notify.warn("Skipping migrate module file")
    return {}
  end

  -- Get all matches then filter to range
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

  -- Check exclusion
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
-- Application
--------------------------------------------------------------------------------

---Apply migrations (descending order)
---@param matches MigrateCommon.Match[]
---@param use_create boolean|nil Use .create("") import syntax
local function apply_matches(matches, use_create)
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
  for bufnr, buf_matches in pairs(by_buffer) do
    buffer_ops.create_undo_point(bufnr)

    -- Inject import first (this adds 2 lines at top)
    local import_added = refactor.inject_import(bufnr, use_create or false)

    -- Adjust line numbers if import was added
    if import_added then
      for _, match in ipairs(buf_matches) do
        match.lnum = match.lnum + 2
        match.extra.end_line = match.extra.end_line + 2
      end
    end

    -- Sort DESCENDING by end_line to avoid offset issues
    table.sort(buf_matches, function(a, b)
      return a.extra.end_line > b.extra.end_line
    end)

    -- Apply each match
    local success_count = 0
    for _, match in ipairs(buf_matches) do
      local parser_match = {
        line = match.lnum,
        end_line = match.extra.end_line,
        replacement = match.migrated,
      }

      if refactor.apply_match(bufnr, parser_match) then
        success_count = success_count + 1
      end
    end

    if success_count > 0 then
      notify.info(string.format("Applied %d/%d migration(s)", success_count, #buf_matches))
    end
  end
end

--------------------------------------------------------------------------------
-- Picker
--------------------------------------------------------------------------------

---Show picker
---@param matches MigrateCommon.Match[]
---@param use_create boolean|nil
local function show_picker_impl(matches, use_create)
  picker.show(matches, {
    title = "Migrate vim.notify → lib.notify",
    single_apply = false,

    format_entry = function(match)
      local filename = match.fname
        and vim.fn.fnamemodify(match.fname, ":t")
        or ("buf:" .. match.bufnr)

      local level = match.extra and match.extra.log_level or "INFO"

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
      apply_matches(selections, use_create)
    end,
  })
end

--------------------------------------------------------------------------------
-- Registration
--------------------------------------------------------------------------------

function M.enable()
  -- Register with extended command handling
  api.nvim_create_user_command("MigrateNotify", function(cmd_opts)
    local args = vim.split(cmd_opts.args, "%s+")
    local mode_arg = nil
    local use_create = false

    -- Parse arguments
    for _, arg in ipairs(args) do
      if arg == "--create" then
        use_create = true
      elseif arg == "%" or arg == "cwd" then
        mode_arg = arg
      end
    end

    local bufnr = api.nvim_get_current_buf()

    -- Handle range mode
    if cmd_opts.range > 0 then
      local matches = scan_range(bufnr, cmd_opts.line1, cmd_opts.line2)

      if #matches == 0 then
        notify.warn("No matches in range")
        return
      end

      apply_matches(matches, use_create)
      notify.info(string.format("Applied %d migration(s) in range", #matches))
      return
    end

    -- Handle argument-based modes
    if not mode_arg then
      -- Current line mode
      local cursor = api.nvim_win_get_cursor(0)
      local matches = scan_range(bufnr, cursor[1], cursor[1])

      if #matches == 0 then
        notify.warn("No matches on current line")
        return
      end

      apply_matches(matches, use_create)
      notify.info(string.format("Applied %d migration(s) on line %d", #matches, cursor[1]))

    elseif mode_arg == "%" then
      -- Buffer mode with picker
      local matches = scan_buffer(bufnr)

      if #matches == 0 then
        notify.warn("No matches in buffer")
        return
      end

      show_picker_impl(matches, use_create)

    elseif mode_arg == "cwd" then
      -- CWD mode with picker
      local matches = scan_cwd()

      if #matches == 0 then
        notify.warn("No matches in cwd")
        return
      end

      show_picker_impl(matches, use_create)
    end
  end, {
    nargs = "*",
    range = true,
    desc = "Migrate vim.notify → lib.notify (use --create for .create() import)",
    ---@diagnostic disable-next-line: unused-local
    complete = function(arg_lead, cmd_line, cursor_pos)
      local options = { "%", "cwd", "--create" }
      local matches = {}
      for _, opt in ipairs(options) do
        if opt:find(arg_lead, 1, true) == 1 then
          table.insert(matches, opt)
        end
      end
      return matches
    end,
  })
end

return M
