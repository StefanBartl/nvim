---@module 'usrcmds.migrate.opt'
-- Telescope-enabled UI for selecting occurrences of deprecated
-- buf/win option API calls and migrating them to the unified
-- nvim_get_option_value / nvim_set_option_value form.
--
-- Usage (after requiring and calling enable()):
--   :OptMigrateSelect            -> migrate current line if it matches
--   :OptMigrateSelect %          -> gather matches in current buffer and show picker
--   :OptMigrateSelect cwd        -> scan current working directory (requires `rg`) and show picker
--
-- Safety notes:
--  - Buffer edits are applied in-place using Neovim buffer API.
--  - File edits (cwd mode) are applied by loading the file, editing in-memory,
--    and writing it back. This requires write permissions.
--  - For large repositories, `cwd` mode uses ripgrep (`rg`) if available.

-- Early exit if Telescope is not available
-- local ok, _ = pcall(require, "telescope")
-- if not ok then
--   vim.notify("Telescope not found", vim.log.levels.ERROR)
--   return {}
-- end

-- Import Telescope modules
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local previewers = require("telescope.previewers")
local entry_display = require("telescope.pickers.entry_display")
local conf = require("telescope.config").values

local M = {}

local api = vim.api
local fn = vim.fn
local notify = vim.notify

---Migrate a single line of text by replacing deprecated option API calls
---with the unified nvim_get_option_value / nvim_set_option_value form.
---Handles three prefix variants:
---  - vim.api.nvim_buf_get_option(...)
---  - api.nvim_buf_get_option(...)      (when local api = vim.api)
---  - nvim_buf_get_option(...)          (when using _G or direct access)
---@param line string The line to migrate
---@return string migrated The migrated line (unchanged if no match)
local function migrate_line_text(line)
  local s = line

  -- Detect the prefix used in this line (vim.api., api., or nothing)
  -- We'll preserve the same prefix in the replacement
  local prefix_map = {
    ["vim%.api%."] = "vim.api.",
    ["api%."] = "api.",
    [""] = "",
  }

  -- Handle nvim_buf_set_option(bufnr, "optname", value)
  -- → nvim_set_option_value("optname", value, { buf = bufnr })
  -- Matches: vim.api.nvim_buf_set_option / api.nvim_buf_set_option / nvim_buf_set_option
  for pattern_prefix, replacement_prefix in pairs(prefix_map) do
    s = s:gsub(
      pattern_prefix .. 'nvim_buf_set_option%(%s*([%w_%.%:%%%(%)%[%]/\\%-%+%*\'"]-)%s*,%s*([\'"])(.-)%2%s*,%s*(.-)%s*%)',
      function(bufexpr, quote, optname, valueexpr)
        return string.format('%snvim_set_option_value(%s%s%s, %s, { buf = %s })',
          replacement_prefix, quote, optname, quote, valueexpr, bufexpr)
      end)
  end

  -- Handle nvim_win_set_option(winid, "optname", value)
  -- → nvim_set_option_value("optname", value, { win = winid })
  for pattern_prefix, replacement_prefix in pairs(prefix_map) do
    s = s:gsub(
      pattern_prefix .. 'nvim_win_set_option%(%s*([%w_%.%:%%%(%)%[%]/\\%-%+%*\'"]-)%s*,%s*([\'"])(.-)%2%s*,%s*(.-)%s*%)',
      function(winexpr, quote, optname, valueexpr)
        return string.format('%snvim_set_option_value(%s%s%s, %s, { win = %s })',
          replacement_prefix, quote, optname, quote, valueexpr, winexpr)
      end)
  end

  -- Handle nvim_buf_get_option(bufnr, "optname")
  -- → nvim_get_option_value("optname", { buf = bufnr })
  for pattern_prefix, replacement_prefix in pairs(prefix_map) do
    s = s:gsub(
      pattern_prefix .. 'nvim_buf_get_option%(%s*([%w_%.%:%%%(%)%[%]/\\%-%+%*\'"]-)%s*,%s*([\'"])(.-)%2%s*%)',
      function(bufexpr, quote, optname)
        return string.format('%snvim_get_option_value(%s%s%s, { buf = %s })',
          replacement_prefix, quote, optname, quote, bufexpr)
      end)
  end

  -- Handle nvim_win_get_option(winid, "optname")
  -- → nvim_get_option_value("optname", { win = winid })
  for pattern_prefix, replacement_prefix in pairs(prefix_map) do
    s = s:gsub(
      pattern_prefix .. 'nvim_win_get_option%(%s*([%w_%.%:%%%(%)%[%]/\\%-%+%*\'"]-)%s*,%s*([\'"])(.-)%2%s*%)',
      function(winexpr, quote, optname)
        return string.format('%snvim_get_option_value(%s%s%s, { win = %s })',
          replacement_prefix, quote, optname, quote, winexpr)
      end)
  end

  return s
end

---Collect all deprecated option API calls in a given buffer.
---@param bufnr number Buffer number to scan
---@return MigrateOpt.Match[] matches List of matches found
local function collect_matches_in_buffer(bufnr)
  local out = {}

  -- Validate buffer existence
  if not api.nvim_buf_is_valid(bufnr) then
    return out
  end

  -- Get all lines from buffer
  local ok2, lines = pcall(api.nvim_buf_get_lines, bufnr, 0, -1, false)
  if not ok2 or not lines then
    return out
  end

  local fname = api.nvim_buf_get_name(bufnr)

  -- Scan each line for deprecated API calls
  for i, line in ipairs(lines) do
    local migrated = migrate_line_text(line)
    if migrated ~= line then
      table.insert(out, {
        bufnr = bufnr,
        fname = fname ~= "" and fname or nil,
        lnum = i,
        text = line,
        migrated = migrated,
        source = "buf",
      })
    end
  end

  return out
end

---Collect all deprecated option API calls in the current working directory
---using ripgrep (rg). Requires rg to be installed and available in PATH.
---@return MigrateOpt.Match[] matches List of matches found
local function collect_matches_in_cwd()
  local out = {}

  -- Check if ripgrep is available
  if fn.executable("rg") == 0 then
    notify("ripgrep (rg) not found", vim.log.levels.ERROR)
    return out
  end

  -- Search pattern for deprecated API calls
  local pattern = "nvim_(buf|win)_(get|set)_option"

  -- Run ripgrep with vimgrep format for easy parsing
  local cmd = { "rg", "--vimgrep", "--no-heading", "--color=never", pattern }
  local result = fn.systemlist(cmd)

  -- Check if rg found any matches
  if vim.v.shell_error ~= 0 then
    notify("rg failed or no matches", vim.log.levels.WARN)
    return out
  end

  -- Parse each line from ripgrep output
  -- Format: filename:line:column:text
  for _, line_raw in ipairs(result) do
    local fname, lnum_str, text = line_raw:match("^(.+):(%d+):%d+:(.*)$")
    if fname and lnum_str and text then
      local migrated = migrate_line_text(text)
      if migrated ~= text then
        table.insert(out, {
          bufnr = nil,
          fname = fname,
          lnum = tonumber(lnum_str),
          text = text,
          migrated = migrated,
          source = "file",
        })
      end
    end
  end

  return out
end

---Apply migration to a list of selected entries.
---For buffer matches, updates the buffer directly.
---For file matches, reads the file, updates the line, and writes it back.
---@param selection table[] List of Telescope entries (each has a .value field)
local function apply_migration(selection)
  for _, entry in ipairs(selection) do
    if entry.value.source == "buf" then
      -- Buffer-local migration: update the buffer directly
      local idx = entry.value.lnum - 1 -- Convert to 0-indexed
      pcall(api.nvim_buf_set_lines,
        entry.value.bufnr, idx, idx + 1, false, { entry.value.migrated })
    else
      -- File-based migration: read file, update line, write back
      local lines = fn.readfile(entry.value.fname)
      local idx = entry.value.lnum
      if idx >= 1 and idx <= #lines then
        lines[idx] = entry.value.migrated
        fn.writefile(lines, entry.value.fname)
      end
    end
  end

  notify("Migration applied", vim.log.levels.INFO)
end

---Build Telescope entry objects from a list of matches.
---@param matches MigrateOpt.Match[] List of matches
---@return table[] entries Telescope-compatible entry objects
local function build_entries(matches)
  -- Define the display layout: location | text
  local displayer = entry_display.create({
    separator = " ",
    items = {
      { width = 40 },  -- Location (filename:line or buf:bufnr:line)
      { remaining = true },  -- Original text
    },
  })

  local entries = {}
  for _, m in ipairs(matches) do
    -- Build location label
    local label = m.fname
      and (m.fname .. ":" .. m.lnum)
      or ("buf:" .. m.bufnr .. ":" .. m.lnum)

    -- Create Telescope entry
    entries[#entries + 1] = {
      value = m,
      ordinal = (m.fname or tostring(m.bufnr or "")) .. " " .. m.text,
      display = function()
        return displayer({
          { label, "Comment" },
          { m.text, "Normal" }
        })
      end
    }
  end

  return entries
end

---Show Telescope picker for selecting and migrating entries.
---If only a single match exists, applies migration directly without picker.
---@param matches MigrateOpt.Match[] List of matches to display
local function show_picker(matches)
  -- If only one match, apply immediately without picker
  if #matches == 1 then
    apply_migration({ { value = matches[1] } })
    return
  end

  -- No matches found
  if #matches == 0 then
    notify("No deprecated option calls found", vim.log.levels.INFO)
    return
  end

  local entries = build_entries(matches)

  pickers.new({}, {
    prompt_title = "OptMigrator",

    -- Provide the list of entries to display
    finder = finders.new_table {
      results = entries,
      entry_maker = function(e) return e end
    },

    -- Preview shows the migrated version of the line
    previewer = previewers.new_buffer_previewer({
      define_preview = function(self, entry)
        api.nvim_buf_set_lines(
          self.state.bufnr, 0, -1, false, { entry.value.migrated })
        api.nvim_set_option_value("filetype", "lua", { buf = self.state.bufnr })
      end
    }),

    -- Use default sorter
    sorter = conf.generic_sorter({}),

    -- Custom selection symbol: use * instead of >
    selection_caret = "* ",

    -- Define key mappings for the picker
    attach_mappings = function(prompt_bufnr, map)
      ---Apply migration to selected or multi-selected entries.
      ---If no multi-selection exists, uses the currently highlighted entry.
      local migrate = function()
        local picker = action_state.get_current_picker(prompt_bufnr)
        local selections = picker:get_multi_selection()

        -- If no multi-selection, use current highlighted entry
        if vim.tbl_isempty(selections) then
          selections = { action_state.get_selected_entry() }
        end

        actions.close(prompt_bufnr)
        apply_migration(selections)
      end

      -- Map Enter key to apply migration
      map("i", "<CR>", migrate)
      map("n", "<CR>", migrate)

      return true
    end
  }):find()
end

---Enable the :OptMigrateSelect user command.
---This command allows migrating deprecated option API calls in three modes:
---  - No argument: migrate current line only
---  - "%": scan and pick from current buffer
---  - "cwd": scan and pick from entire working directory
function M.enable()
  api.nvim_create_user_command("MigrateOptSelect", function(opts)
    local arg = opts.args or ""
    local bufnr = api.nvim_get_current_buf()

    if arg == "" then
      -- Mode 1: Migrate current line only
      local row = api.nvim_win_get_cursor(0)[1]
      local line = api.nvim_buf_get_lines(bufnr, row - 1, row, false)[1]
      local migrated = migrate_line_text(line)

      if migrated ~= line then
        api.nvim_buf_set_lines(bufnr, row - 1, row, false, { migrated })
        notify("Line migrated", vim.log.levels.INFO)
      else
        notify("No deprecated call on line", vim.log.levels.INFO)
      end

    elseif arg == "%" then
      -- Mode 2: Scan current buffer
      show_picker(collect_matches_in_buffer(bufnr))

    elseif arg == "cwd" then
      -- Mode 3: Scan current working directory
      show_picker(collect_matches_in_cwd())

    else
      notify("Unknown argument: " .. arg, vim.log.levels.ERROR)
    end
  end, {
    nargs = "?",
    complete = function() return { "%", "cwd" } end
  })
end

return M
