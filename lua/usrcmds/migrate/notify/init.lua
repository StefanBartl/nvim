---@module 'usrcmds.migrate.notify'
---@brief Migrate vim.notify to lib.notify (with alias support)
---@description
--- Enhanced version with auto-write for CWD mode

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

local function should_exclude(filepath)
  local normalized = filepath:gsub("\\", "/")
  return normalized:match("/usrcmds/migrate/") ~= nil
end

--------------------------------------------------------------------------------
-- Conversion helpers
--------------------------------------------------------------------------------

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
-- Scan functions (unchanged)
--------------------------------------------------------------------------------

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
-- Application (FIXED with auto-write)
--------------------------------------------------------------------------------

---Apply migrations with optional auto-write
---@param matches MigrateCommon.Match[]
---@param module_name string|nil Optional module name for .create("")
---@param auto_write boolean|nil Auto-write modified buffers to disk
local function apply_matches(matches, module_name, auto_write)
  auto_write = auto_write or false

  -- Group by buffer with metadata
  local by_buffer = {}
  for _, match in ipairs(matches) do
    local bufnr = match.bufnr
    if bufnr then
      if not by_buffer[bufnr] then
        by_buffer[bufnr] = {
          matches = {},
          fname = match.fname,
          was_loaded = api.nvim_buf_is_loaded(bufnr),
        }
      end
      tbl_insert(by_buffer[bufnr].matches, match)
    end
  end

  local written_files = {}
  local total_applied = 0

  -- Apply per buffer
  for bufnr, data in pairs(by_buffer) do
    buffer_ops.create_undo_point(bufnr)

    -- Inject import
    refactor.inject_import(bufnr, module_name)

    -- RE-SCAN buffer
    local fresh_matches = parser.scan_buffer(bufnr)
    local updated_matches = to_common_matches(bufnr, fresh_matches)

    -- Sort DESCENDING
    table.sort(updated_matches, function(a, b)
      return a.extra.end_line > b.extra.end_line
    end)

    -- Apply each match
    local success_count = 0
    for _, match in ipairs(updated_matches) do
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

    -- Remove aliases
    refactor.remove_aliases(bufnr)

    total_applied = total_applied + success_count

    -- WRITE TO DISK if requested
    if success_count > 0 and auto_write and data.fname then
      -- Direct write to file WITHOUT any buffer switching
      local ok, err = pcall(function()
        -- Get all buffer lines
        local lines = api.nvim_buf_get_lines(bufnr, 0, -1, false)

        -- Write directly using vim.fn.writefile (handles all edge cases)
        local result = vim.fn.writefile(lines, data.fname)

        if result ~= 0 then
          error("writefile returned non-zero: " .. result)
        end

        -- Clear modified flag (buffer is now in sync with file)
        api.nvim_set_option_value("modified", false, { buf = bufnr })
      end)

      if ok then
        tbl_insert(written_files, data.fname)

        -- Unload buffer if it wasn't originally loaded (memory optimization)
        if not data.was_loaded then
          vim.schedule(function()
            if api.nvim_buf_is_valid(bufnr) then
              -- Force unload without prompting (file is saved, safe to unload)
              pcall(api.nvim_buf_delete, bufnr, { force = true, unload = true })
            end
          end)
        end
      else
        notify.warn(string.format("Failed to write %s: %s", data.fname, tostring(err)))
      end
    elseif success_count > 0 and auto_write and not data.fname then
      -- Unnamed buffer - cannot auto-write
      notify.warn(string.format("Buffer %d has no filename, skipping auto-write", bufnr))
    end
  end

  -- Summary notifications
  if total_applied > 0 then
    notify.info(string.format("Applied %d migration(s)", total_applied))
  end

  if #written_files > 0 then
    notify.info(string.format("✅ Written %d file(s) to disk", #written_files))
  elseif total_applied > 0 and not auto_write then
    notify.warn("Changes in memory only. Save with :wa or reopen files")
  end
end

--------------------------------------------------------------------------------
-- Picker
--------------------------------------------------------------------------------

local function show_picker_impl(matches, module_name, auto_write)
  -- Add helpful prompt suffix
  local title = string.format(
    "Migrate vim.notify → lib.notify (%d matches) | <C-a> Apply All",
    #matches
  )

  picker.show(matches, {
    title = title,
    single_apply = false,

    format_entry = function(match)
      local display_path

      if match.fname then
        -- Convert to relative path from CWD without extension
        -- :~  = replace $HOME with ~
        -- :.  = relative to current directory
        -- :r  = remove extension
        display_path = vim.fn.fnamemodify(match.fname, ":~:.:r")
      else
        -- Unnamed buffer
        display_path = "buf:" .. match.bufnr
      end

      local level = "INFO"
      if match.extra and match.extra.log_level then
        if type(match.extra.log_level) == "string" then
          level = match.extra.log_level
        elseif type(match.extra.log_level) == "number" then
          local level_map = { "TRACE", "DEBUG", "INFO", "WARN", "ERROR" }
          level = level_map[match.extra.log_level] or "INFO"
        end
      end

      -- Format with dynamic width based on path length
      local path_width = math.min(#display_path, 50)  -- Max 50 chars for path
      local location = string.format("%-" .. path_width .. "s:%d", display_path, match.lnum)

      return string.format(
        "%s  [%-5s]  %s",
        location,
        level:lower(),
        match.text:sub(1, 40)
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
      apply_matches(selections, module_name, auto_write)
    end,
  })
end

--------------------------------------------------------------------------------
-- Registration
--------------------------------------------------------------------------------

function M.enable()
  vim.api.nvim_create_user_command("MigrateNotify", function(cmd_opts)
    local args_str = cmd_opts.args
    local parts = vim.split(args_str, "%s+", { trimempty = true })

    local mode = parts[1] or ""
    local module_name = parts[2] or nil

    local bufnr = api.nvim_get_current_buf()

    -- Determine auto-write behavior
    local auto_write = false

    if cmd_opts.range > 0 then
      -- Range mode: no auto-write (single buffer, user can save manually)
      local matches = scan_range(bufnr, cmd_opts.line1, cmd_opts.line2)
      if #matches == 0 then
        notify.warn("No matches in range")
        return
      end
      apply_matches(matches, module_name, false)

    elseif mode == "" then
      -- Current line: no auto-write
      local cursor = api.nvim_win_get_cursor(0)
      local matches = scan_range(bufnr, cursor[1], cursor[1])
      if #matches == 0 then
        notify.warn("No matches on current line")
        return
      end
      apply_matches(matches, module_name, false)

    elseif mode == "%" then
      -- Buffer mode: no auto-write (user can save manually)
      local matches = scan_buffer(bufnr)
      if #matches == 0 then
        notify.warn("No matches in buffer")
        return
      end
      show_picker_impl(matches, module_name, false)

    elseif mode == "cwd" then
      -- ✅ CWD mode: AUTO-WRITE enabled
      auto_write = true

      local matches = scan_cwd()
      if #matches == 0 then
        notify.warn("No matches in cwd")
        return
      end

      show_picker_impl(matches, module_name, auto_write)

    else
      notify.error(string.format("Invalid argument: %s. Use: [empty], %%, or cwd", mode))
    end
  end, {
    nargs = "*",
    range = true,
    desc = "Migrate vim.notify to lib.notify",
    complete = function(arg_lead, cmd_line, _)
      local args = vim.split(cmd_line, "%s+", { trimempty = true })

      if #args <= 2 then
        local completions = { "%", "cwd" }
        if arg_lead == "" then
          return completions
        end

        local matches = {}
        for _, comp in ipairs(completions) do
          if comp:find(arg_lead, 1, true) == 1 then
            tbl_insert(matches, comp)
          end
        end
        return matches
      end

      return {}
    end,
  })
end

return M
