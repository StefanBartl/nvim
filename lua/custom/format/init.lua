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
---   :Format markdown                         -- Markdown formatting
---
--- Use :h format.txt for full documentation.

local notify = require("lib.notify").create("[custom.format]")

local M = {}

---@type Custom.Format.Config
local config = {
  enable_legacy_commands = true,
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
    notify.error(string.format("[custom.format] Error: %s", tostring(result)))
  end
  return ok, result
end

---Register a subcommand in the format registry
---@param name Custom.Format.SubcommandName Subcommand name
---@param def Custom.Format.SubcommandDef Subcommand definition
---@return nil
local function register_subcommand(name, def)
  if registry.subcommands[name] then
    notify.warn(string.format("[custom.format] Warning: Subcommand '%s' already registered", name))
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
      notify.info("[custom.format] Usage: :Format <subcommand> [args...]\n" .. "Available subcommands: " .. table.concat(vim.tbl_keys(registry.subcommands), ", "))
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
    notify.error(string.format( "[custom.format] Unknown subcommand: '%s'\nAvailable: %s", subcommand, table.concat(vim.tbl_keys(registry.subcommands), ", ") ))
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
        notify.error("[custom.format.column] Invalid target column")
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

end

---Setup table formatting subcommand
---@return nil
local function setup_format_table()
  local ok, handler = pcall(require, "custom.format.table._handler")
  if not ok then
    -- Fallback: try to load without the handler module (older layout).
    local ok2, _ = pcall(require, "custom.format.table")
    if not ok2 then return end
  end

  handler.setup(register_subcommand, notify)
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
        notify.error("[custom.format.textwidth] Usage: textwidth <N|max>")
        return
      end

      local width
      if args[1] == "max" or args[1] == "MAX" then
        width = vim.api.nvim_win_get_width(0)
      else
        width = tonumber(args[1])
        if not width or width <= 0 then
          notify.error("[custom.format.textwidth] Width must be positive integer or 'max'")
          return
        end
      end

      vim.bo.textwidth = width
      format_text_width.reflow_buffer(0, width)
      notify.info(string.format("Set textwidth to %d and reflowed buffer", width))
    end,
    ---@diagnostic disable-next-line: unused-local
    complete = function(arg_lead, cmdline, cursor_pos)
      return { "max", "80", "120" }
    end,
    nargs = "1",
    desc = "[custom.format.textwidth] Reflow text to width: textwidth <N|max>",
  })
end

---Setup filter lines subcommand
---@return nil
local function setup_filter_lines()
  local ok, filter_lines = pcall(require, "custom.format.filter_lines")
  if not ok then
    return
  end

  register_subcommand("filter", {
    handler = function(args)
      if #args == 0 then
        notify.error("[custom.format.filter] Usage: filter [--remove] <pattern> ...")
        return
      end

      -- Parse arguments via filter_lines module
      local remove_flag, conditions = filter_lines.parse_filter_args(args)

      if #conditions == 0 then
        notify.warn("[custom.format.filter] No conditions provided")
        return
      end

      -- Call filter logic
      local bufnr = vim.api.nvim_get_current_buf()
      local success, err = filter_lines.filter_lines(bufnr, conditions, remove_flag)

      if not success then
        notify.warn(string.format("[custom.format.filter] %s", err or "Unknown error"))
        return
      end

      local lines_before = vim.api.nvim_buf_line_count(bufnr)
      local lines_after = #vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
      notify.info(string.format("[custom.format.filter] Filtered: %d → %d lines", lines_before, lines_after))
    end,
    ---@diagnostic disable-next-line: unused-local
    complete = function(arg_lead, cmdline, cursor_pos)
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
      local bufnr = vim.api.nvim_get_current_buf()
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {})
      notify.info("Buffer cleared")
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

---Setup markdown formatting subcommand
---@return nil
local function setup_markdown()
  local ok, markdown = pcall(require, "custom.format.markdown")
  if ok then
    markdown.register_subcommands(register_subcommand)
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
  setup_markdown()

  -- Create main :Format command
  vim.api.nvim_create_user_command("Format", format_handler, {
    nargs = "*",
    range = true,
    complete = format_complete,
    desc = "[custom.format] Unified formatting command with subcommands",
  })
end

return M
