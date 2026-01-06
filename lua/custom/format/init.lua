---@module 'custom.format'
---@brief Unified formatting command interface for Neovim
---@description
--- This module provides a central :Format command with subcommands for various
--- formatting operations. Each subcommand has its own completion and argument handling.
---
--- Available subcommands:
---   :Format column <target_col> [fill_char]  -- Align character to column
---   :Format table [header_align] [entry_align] -- Format Markdown table
---   :Format textwidth <width>                -- Reflow text to width
---   :Format filter <pattern> [...]           -- Filter lines by pattern
---   :Format clear                            -- Clear buffer content
---
--- Legacy commands are optionally preserved for backward compatibility.
--- Use :h format.txt for full documentation.

local M = {}

local api = vim.api

---@type Custom.Format.Config
local config = {
  enable_legacy_commands = true,
  default_subcommand = nil,
}

---@type Custom.Format.Registry
local registry = {
  subcommands = {},
}

---Safe wrapper for function calls with error reporting
---@param fn function Function to call
---@param ... any Arguments
---@return boolean success, any result_or_error
local function safe_call(fn, ...)
  local ok, result = pcall(fn, ...)
  if not ok then
    vim.notify(
      string.format("[custom.format] Error: %s", tostring(result)),
      vim.log.levels.ERROR
    )
  end
  return ok, result
end

---Register a subcommand in the format registry
---@param name Custom.Format.SubcommandName Subcommand name
---@param def Custom.Format.SubcommandDef Subcommand definition
---@return nil
local function register_subcommand(name, def)
  if registry.subcommands[name] then
    vim.notify(
      string.format("[custom.format] Warning: Subcommand '%s' already registered", name),
      vim.log.levels.WARN
    )
    return
  end

  -- Validate definition
  if type(def.handler) ~= "function" then
    error(string.format("Subcommand '%s': handler must be a function", name))
  end

  if def.complete and type(def.complete) ~= "function" then
    error(string.format("Subcommand '%s': complete must be a function", name))
  end

  registry.subcommands[name] = def
end

---Parse :Format command line into subcommand and arguments
---@param cmdline string Full command line
---@return Custom.Format.SubcommandName|nil subcommand, string[] args
local function parse_command_line(cmdline)
  -- Remove leading :Format
  local args_str = cmdline:match("^%s*Format%s+(.*)$") or cmdline:match("^%s*(.*)$") or ""

  -- Split into tokens (simple space-based split)
  local tokens = {}
  for token in args_str:gmatch("%S+") do
    table.insert(tokens, token)
  end

  if #tokens == 0 then
    return nil, {}
  end

  local subcommand = tokens[1]
  local args = {}
  for i = 2, #tokens do
    table.insert(args, tokens[i])
  end

  return subcommand, args
end

---Custom completion function for :Format command
---@param arg_lead string Current argument being completed
---@param cmdline string Full command line
---@param cursor_pos integer Cursor position in command line
---@return string[] completions
local function format_complete(arg_lead, cmdline, cursor_pos)
  local subcommand, _ = parse_command_line(cmdline)

  -- If no subcommand yet, complete subcommand names
  if not subcommand or subcommand == arg_lead then
    local completions = {}
    for name, _ in pairs(registry.subcommands) do
      if vim.startswith(name, arg_lead) then
        table.insert(completions, name)
      end
    end
    table.sort(completions)
    return completions
  end

  -- If subcommand has custom completion, delegate to it
  local def = registry.subcommands[subcommand]
  if def and def.complete then
    local ok, result = safe_call(def.complete, arg_lead, cmdline, cursor_pos)
    if ok and result then
      return result
    end
  end

  return {}
end

---Main handler for :Format command
---@param opts table Command arguments from nvim_create_user_command
---@return nil
local function format_handler(opts)
  local args = opts.fargs or {}

  if #args == 0 then
    if config.default_subcommand then
      args = { config.default_subcommand }
    else
      vim.notify(
        "[custom.format] Usage: :Format <subcommand> [args...]\n" ..
        "Available subcommands: " .. table.concat(vim.tbl_keys(registry.subcommands), ", "),
        vim.log.levels.INFO
      )
      return
    end
  end

  local subcommand = args[1]
  local subargs = {}
  for i = 2, #args do
    table.insert(subargs, args[i])
  end

  local def = registry.subcommands[subcommand]
  if not def then
    vim.notify(
      string.format(
        "[custom.format] Unknown subcommand: '%s'\nAvailable: %s",
        subcommand,
        table.concat(vim.tbl_keys(registry.subcommands), ", ")
      ),
      vim.log.levels.ERROR
    )
    return
  end

  -- Call handler with subcommand arguments
  safe_call(def.handler, subargs)
end

---Setup column alignment subcommand
---@return nil
local function setup_column_align()
  local ok, column_align = pcall(require, "custom.format.column_align.core")
  if not ok then
    return
  end

  register_subcommand("column", {
    handler = function(args)
      if #args == 0 then
        column_align.align_interactive()
        return
      end

      local target_col = tonumber(args[1])
      if not target_col then
        vim.notify(
          "[custom.format.column] Invalid target column",
          vim.log.levels.ERROR
        )
        return
      end

      local fill_char = args[2] or " "
      column_align.align_to_column(target_col, fill_char)
    end,
    ---@diagnostic disable-next-line: unused-local
    complete = function(arg_lead, cmdline, cursor_pos)
      -- No completion for numeric column or fill char
      return {}
    end,
    nargs = "*",
    range = true,
    desc = "[custom.format.colum_align] Align character to column: column <col> [fill]",
  })

  -- Legacy commands
  if config.enable_legacy_commands then
    vim.api.nvim_create_user_command("FormatColumnAlignInteractive", function()
      safe_call(column_align.align_interactive)
    end, {
      nargs = 0,
      desc = "[legacy custom.format.column_align] Use :Format column instead",
    })

    vim.api.nvim_create_user_command("FormatColumnAlignToColumn", function(cmd_opts)
      local args = cmd_opts.fargs or {}
      if #args < 1 then
        vim.notify("Missing target column", vim.log.levels.ERROR)
        return
      end
      local target_col = tonumber(args[1])
      local fill_char = args[2] or " "
      safe_call(column_align.align_to_column, target_col, fill_char)
    end, {
      nargs = "*",
      range = true,
      desc = "[legacy custom.format.colum_align] Use :Format column <col> [fill] instead",
    })
  end
end

---Setup table formatting subcommand
---@return nil
local function setup_format_table()
  local ok, _ = pcall(require, "custom.format.table")
  if not ok then
    return
  end

  register_subcommand("table", {
    handler = function(args)
      local header_align = args[1] or "center"
      local entry_align = args[2] or "center"

      -- Call internal format function (bypass user command)
      -- local bufnr = vim.api.nvim_get_current_buf()
      -- local cursor = vim.api.nvim_win_get_cursor(0)

      -- Delegate to module's internal API
      -- This requires exposing format_table's internal logic
      -- For now, construct args table and call via command
      vim.cmd(string.format("FormatTable %s %s", header_align, entry_align))
    end,
    ---@diagnostic disable-next-line: unused-local
    complete = function(arg_lead, cmdline, cursor_pos)
      return { "left", "center", "right" }
    end,
    nargs = "*",
    desc = "[custom.format.table] Format Markdown Table: table [header_align] [entry_align]",
  })
end

---Setup text width formatting subcommand
---@return nil
local function setup_format_text_width()
  local ok, format_text_width = pcall(require, "custom.format.text_width")
  if not ok then
    return
  end

  register_subcommand("textwidth", {
    handler = function(args)
      if #args == 0 then
        vim.notify(
          "[custom.format.textwidth] Usage: textwidth <N|max>",
          vim.log.levels.ERROR
        )
        return
      end

      local width
      if args[1] == "max" or args[1] == "MAX" then
        width = vim.api.nvim_win_get_width(0)
      else
        width = tonumber(args[1])
        if not width or width <= 0 then
          vim.notify(
            "[custom.format.textwidth] Width must be positive integer or 'max'",
            vim.log.levels.ERROR
          )
          return
        end
      end

      vim.bo.textwidth = width
      format_text_width.reflow_buffer(0, width)
      vim.notify(
        string.format("Set textwidth to %d and reflowed buffer", width),
        vim.log.levels.INFO
      )
    end,
    ---@diagnostic disable-next-line: unused-local
    complete = function(arg_lead, cmdline, cursor_pos)
      return { "max", "80", "120" }
    end,
    nargs = "1",
    desc = "[custom.format.textwidth] Reflow text to width: textwidth <N|max>",
  })
end

---Helper: check if line matches a condition
---@param line string Line content
---@param condition string|table Condition (string or OR-group)
---@return boolean matches
local function line_matches(line, condition)
  if type(condition) == "string" then
    return string.find(line, condition, 1, true) ~= nil
  elseif type(condition) == "table" then
    for _, str in ipairs(condition) do
      if type(str) == "string" and string.find(line, str, 1, true) then
        return true
      end
    end
    return false
  end
  return false
end

---Helper: parse filter argument (table syntax or plain string)
---@param arg string Argument string
---@return string|table parsed Parsed condition
local function parse_filter_argument(arg)
  local trimmed = arg:match("^%s*(.-)%s*$") or arg

  -- Detect table syntax: { ... }
  if trimmed:match("^%{.*%}$") then
    local list = {}
    -- Extract double-quoted strings
    for s in trimmed:gmatch([["(.-)"]]) do
      table.insert(list, s)
    end
    -- Extract single-quoted strings
    for s in trimmed:gmatch([['(.-)']]) do
      table.insert(list, s)
    end
    return list
  end

  return trimmed
end

---Setup filter lines subcommand
---@return nil
local function setup_filter_lines()
  local ok, _ = pcall(require, "custom.format.filter_lines")
  if not ok then
    return
  end

  register_subcommand("filter", {
    handler = function(args)
      if #args == 0 then
        vim.notify(
          "[custom.format.filter] Usage: filter [--remove] <pattern> ...",
          vim.log.levels.ERROR
        )
        return
      end

      -- Parse arguments directly here instead of delegating to command
      local remove_flag = false
      local conditions = {}

      -- Parse flags and conditions
      for _, arg in ipairs(args) do
        if arg == "--remove" or arg == "-r" then
          remove_flag = true
        else
          -- Parse table syntax: { "a", "b" } or plain string
          local parsed = parse_filter_argument(arg)
          table.insert(conditions, parsed)
        end
      end

      if #conditions == 0 then
        vim.notify(
          "[custom.format.filter] No conditions provided",
          vim.log.levels.WARN
        )
        return
      end

      -- Call filter logic directly
      local buf = api.nvim_get_current_buf()
      local lines = api.nvim_buf_get_lines(buf, 0, -1, false)
      local new_lines = {}
      local matched_any = false

      for _, line in ipairs(lines) do
        local matches_all = true
        for _, cond in ipairs(conditions) do
          if not line_matches(line, cond) then
            matches_all = false
            break
          end
        end

        if matches_all then
          matched_any = true
        end

        if remove_flag then
          if not matches_all then
            table.insert(new_lines, line)
          end
        else
          if matches_all then
            table.insert(new_lines, line)
          end
        end
      end

      -- Safety check
      if remove_flag and #new_lines == 0 and matched_any then
        vim.notify(
          "[custom.format.filter] Operation would remove all lines — aborted",
          vim.log.levels.WARN
        )
        return
      end

      if not remove_flag and not matched_any then
        vim.notify(
          "[custom.format.filter] No lines matched the given conditions",
          vim.log.levels.INFO
        )
        return
      end

      api.nvim_buf_set_lines(buf, 0, -1, false, new_lines)
      vim.notify(
        string.format("[custom.format.filter] Filtered: %d → %d lines", #lines, #new_lines),
        vim.log.levels.INFO
      )
    end,
    ---@diagnostic disable-next-line: unused-local
    complete = function(arg_lead, cmdline, cursor_pos)
      -- Basic completion for flags
      if vim.startswith("--remove", arg_lead) then
        return { "--remove" }
      end
      if vim.startswith("-r", arg_lead) then
        return { "-r" }
      end
      return {}
    end,
    nargs = "+",
    desc = "[custom.format.filter_lines] filter [--remove] <pattern> ...",
  })
end

---Setup misc formatting subcommand
---@return nil
local function setup_misc()
  register_subcommand("clear", {
    ---@diagnostic disable-next-line: unused-local
    handler = function(args)
      vim.api.nvim_buf_set_lines(0, 0, -1, false, {})
      vim.notify("Buffer cleared", vim.log.levels.INFO)
    end,
    complete = function()
      return {}
    end,
    nargs = "0",
    desc = "[custom.format.misc] Clear buffer content",
  })
end

---Setup additional formatting features
---@return nil
local function setup_additional_features()
  local ok, additional = pcall(require, "custom.format.additional_features")
  if ok then
    additional.register_subcommands(register_subcommand)
  end
end

---Setup the format module and register :Format command
---@param opts Custom.Format.Config|nil Configuration options
---@return nil
function M.setup(opts)
  -- Merge config
  if opts and type(opts) == "table" then
    config = vim.tbl_extend("force", config, opts)
  end

  -- Register all subcommands
  setup_column_align()
  setup_format_table()
  setup_format_text_width()
  setup_filter_lines()
  setup_misc()
  setup_additional_features()

  -- Create main :Format command
  vim.api.nvim_create_user_command("Format", format_handler, {
    nargs = "*",
    range = true,
    complete = format_complete,
    desc = "[custom.format] Unified formatting command with subcommands",
  })

  -- Setup legacy commands if enabled
  if config.enable_legacy_commands then
    -- Format table
    local ok, format_table = pcall(require, "custom.format.table")
    if ok then
      format_table.setup()
    end

    -- Filter lines
    local ok2, filter_lines = pcall(require, "custom.format.filter_lines")
    if ok2 then
      filter_lines.enable()
    end

    -- Format text width
    local ok3, format_text_width = pcall(require, "custom.format.text_width")
    if ok3 then
      format_text_width.setup_user_command()
      format_text_width.setup_range_command()
    end

    -- Misc
    local ok4, misc = pcall(require, "custom.format.misc")
    if ok4 then
      misc.enable_usercmds()
    end
  end
end

return M
