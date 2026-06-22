---@module 'custom.format'
---@brief Unified formatting command interface for Neovim
---@description
--- Central :Format command with subcommands for various formatting operations.
---
--- Available subcommands:
---   :Format column <target_col> [fill_char]
---   :Format table [header_align] [entry_align]
---   :Format textwidth <width>
---   :Format filter <pattern> [...]
---   :Format clear
---   :Format markdown <subcommand>
---   :Format enum [STYLE] [sep=SEP] [start=N] [inline=true|false]
---   :Format trim | sort | unique | case | indent
---
--- Use :h format.txt for full documentation.

local notify = require("lib.nvim.notify").create("[custom.format]")

local M = {}

---@type Custom.Format.Config
local config = {
  enable_legacy_commands = true,
}

---@type Custom.Format.Registry
local registry = {
  subcommands = {},
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Internal helpers
-- ─────────────────────────────────────────────────────────────────────────────

---@param fn function
---@param ... any
---@return boolean, any
local function safe_call(fn, ...)
  local ok, result = pcall(fn, ...)
  if not ok then
    notify.error(string.format("[custom.format] Error: %s", tostring(result)))
  end
  return ok, result
end

---@param name Custom.Format.SubcommandName
---@param def  Custom.Format.SubcommandDef
local function register_subcommand(name, def)
  if registry.subcommands[name] then
    notify.warn(string.format("[custom.format] Subcommand '%s' already registered", name))
    return
  end
  if type(def.handler) ~= "function" then
    error(string.format("Subcommand '%s': handler must be a function", name))
  end
  if def.complete and type(def.complete) ~= "function" then
    error(string.format("Subcommand '%s': complete must be a function", name))
  end
  registry.subcommands[name] = def
end

---@param cmdline string
---@return string|nil, string[]
local function parse_command_line(cmdline)
  local args_str = cmdline:match("^%s*Format%s+(.*)$") or cmdline:match("^%s*(.*)$") or ""
  local tokens   = {}
  for token in args_str:gmatch("%S+") do tokens[#tokens + 1] = token end
  if #tokens == 0 then return nil, {} end
  local subcommand = tokens[1]
  local args = {}
  for i = 2, #tokens do args[#args + 1] = tokens[i] end
  return subcommand, args
end

---@param arg_lead  string
---@param cmdline   string
---@param cursor_pos integer
---@return string[]
local function format_complete(arg_lead, cmdline, cursor_pos)
  local subcommand, _ = parse_command_line(cmdline)
  if not subcommand or subcommand == arg_lead then
    local completions = {}
    for name in pairs(registry.subcommands) do
      if vim.startswith(name, arg_lead) then completions[#completions + 1] = name end
    end
    table.sort(completions)
    return completions
  end
  local def = registry.subcommands[subcommand]
  if def and def.complete then
    local ok, result = safe_call(def.complete, arg_lead, cmdline, cursor_pos)
    if ok and result then return result end
  end
  return {}
end

---@param opts table  args from nvim_create_user_command
local function format_handler(opts)
  local args = opts.fargs or {}
  if #args == 0 then
    if config.default_subcommand then
      args = { config.default_subcommand }
    else
      notify.info(
        "[custom.format] Usage: :Format <subcommand> [args...]\n"
        .. "Available subcommands: "
        .. table.concat(vim.tbl_keys(registry.subcommands), ", ")
      )
      return
    end
  end
  local subcommand = args[1]
  local subargs    = {}
  for i = 2, #args do subargs[#subargs + 1] = args[i] end
  local def = registry.subcommands[subcommand]
  if not def then
    notify.error(string.format(
      "[custom.format] Unknown subcommand: '%s'\nAvailable: %s",
      subcommand, table.concat(vim.tbl_keys(registry.subcommands), ", ")
    ))
    return
  end
  safe_call(def.handler, subargs)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Subcommand setup functions
-- ─────────────────────────────────────────────────────────────────────────────

local function setup_column_align()
  local ok, column_align = pcall(require, "custom.format.column_align.core")
  if not ok then return end
  register_subcommand("column", {
    handler = function(args)
      if #args == 0 then column_align.align_interactive(); return end
      local target_col = tonumber(args[1])
      if not target_col then
        notify.error("[custom.format.column] Invalid target column")
        return
      end
      column_align.align_to_column(target_col, args[2] or " ")
    end,
    ---@diagnostic disable-next-line: unused-local
    complete = function(arg_lead, cmdline, cursor_pos) return {} end,
    nargs = "*",
    range = true,
    desc  = "[custom.format.column_align] Align character to column: column <col> [fill]",
  })
end

local function setup_format_table()
  local ok, handler = pcall(require, "custom.format.table._handler")
  if not ok then
    local ok2, _ = pcall(require, "custom.format.table")
    if not ok2 then return end
    return
  end
  handler.setup(register_subcommand, notify)
end

local function setup_format_text_width()
  local ok, format_text_width = pcall(require, "custom.format.text_width")
  if not ok then return end
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
          notify.error("[custom.format.textwidth] Width must be a positive integer or 'max'")
          return
        end
      end
      vim.bo.textwidth = width
      format_text_width.reflow_buffer(0, width)
      notify.info(string.format("Set textwidth to %d and reflowed buffer", width))
    end,
    ---@diagnostic disable-next-line: unused-local
    complete = function(arg_lead, cmdline, cursor_pos) return { "max", "80", "120" } end,
    nargs = "1",
    desc  = "[custom.format.textwidth] Reflow text to width: textwidth <N|max>",
  })
end

local function setup_filter_lines()
  local ok, filter_lines = pcall(require, "custom.format.filter_lines")
  if not ok then return end
  register_subcommand("filter", {
    handler = function(args)
      if #args == 0 then
        notify.error("[custom.format.filter] Usage: filter [--remove] <pattern> ...")
        return
      end
      local remove_flag, conditions = filter_lines.parse_filter_args(args)
      if #conditions == 0 then
        notify.warn("[custom.format.filter] No conditions provided")
        return
      end
      local bufnr = vim.api.nvim_get_current_buf()
      local success, err = filter_lines.filter_lines(bufnr, conditions, remove_flag)
      if not success then
        notify.warn(string.format("[custom.format.filter] %s", err or "Unknown error"))
        return
      end
      local lines_before = vim.api.nvim_buf_line_count(bufnr)
      local lines_after  = #vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
      notify.info(string.format("[custom.format.filter] Filtered: %d → %d lines", lines_before, lines_after))
    end,
    complete = function(arg_lead)
      if vim.startswith("--remove", arg_lead) then return { "--remove" } end
      if vim.startswith("-r",       arg_lead) then return { "-r" }       end
      return {}
    end,
    nargs = "+",
    desc  = "[custom.format.filter_lines] filter [--remove] <pattern> ...",
  })
end

local function setup_misc()
  register_subcommand("clear", {
    ---@diagnostic disable-next-line: unused-local
    handler = function(args)
      vim.api.nvim_buf_set_lines(vim.api.nvim_get_current_buf(), 0, -1, false, {})
      notify.info("Buffer cleared")
    end,
    complete = function() return {} end,
    nargs = "0",
    desc  = "[custom.format.misc] Clear buffer content",
  })
end

local function setup_additional_features()
  local ok, additional = pcall(require, "custom.format.additional_features")
  if ok then additional.register_subcommands(register_subcommand) end
end

local function setup_markdown()
  local ok, markdown = pcall(require, "custom.format.markdown")
  if ok then markdown.register_subcommands(register_subcommand) end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- :Format enum
-- ─────────────────────────────────────────────────────────────────────────────

---Register the `enum` subcommand.
---
--- Syntax:
---   :Format enum [STYLE] [style=STYLE] [sep=SEP] [start=N] [inline=true|false]
---
--- STYLE     = decimal (default) | alpha | ALPHA | roman | ROMAN
--- sep       = separator placed after the counter (default: ". ")
--- start     = first counter value (default: 1)
--- inline    = true  → all tokens on ONE output line  (auto for single-line input)
---             false → each token on its OWN line
---
--- Examples:
---   :Format enum
---   :Format enum alpha
---   :Format enum roman sep=) start=2
---   :Format enum inline=false
---   :Format enum ROMAN sep=": "
---@return nil
local function setup_enum_lines()
  local ok, core = pcall(require, "custom.format.enum_lines.core")
  if not ok then
    vim.notify("custom.format.enum_lines.core is not valid", 4) ---REMOVE
    return
  end

  local VALID_STYLES = { "decimal", "alpha", "ALPHA", "roman", "ROMAN" }
  local STYLE_SET    = {}
  for _, s in ipairs(VALID_STYLES) do STYLE_SET[s] = true end

  ---@param args string[]
  ---@return Custom.Format.EnumLines.Opts, string|nil
  local function parse_enum_args(args)
    vim.notify("Parse enum lines start", 4) ---REMOVE

    ---@type Custom.Format.EnumLines.Opts
    local opts = {}
    for _, raw in ipairs(args) do
      local key, val = raw:match("^([%w_]+)=(.+)$")
      if key and val then
        key = key:lower()
        if key == "style" then
          if not STYLE_SET[val] then
            return opts, string.format(
              "Invalid style %q – valid: %s", val, table.concat(VALID_STYLES, ", ")
            )
          end
          opts.style = val
        elseif key == "sep" then
          opts.sep = val
        elseif key == "start" then
          local n = tonumber(val)
          if not n or n < 1 then
            return opts, string.format("start= must be a positive integer, got %q", val)
          end
          opts.start = math.floor(n)
        elseif key == "inline" then
          if val == "true" then opts.inline = true
          elseif val == "false" then opts.inline = false
          else return opts, string.format("inline= must be true or false, got %q", val)
          end
        else
          return opts, string.format("Unknown option %q", raw)
        end
      elseif STYLE_SET[raw] then
        -- bare style shorthand, e.g. ":Format enum alpha"
        opts.style = raw
      else
        return opts, string.format(
          "Unknown argument %q – expected a style (%s) or key=value.",
          raw, table.concat(VALID_STYLES, "|")
        )
      end
    end
    return opts, nil
  end

  register_subcommand("enum", {
    handler = function(args)
      local opts, err = parse_enum_args(args)
      if err then
        notify.error(string.format("[custom.format.enum] %s", err))
        return
      end
      core.enum_selection(opts)
    end,

    complete = function(arg_lead)
      local candidates = {
        "decimal", "alpha", "ALPHA", "roman", "ROMAN",
        "style=decimal", "style=alpha", "style=ALPHA", "style=roman", "style=ROMAN",
        "sep=.", "sep=)", "sep=:",
        "start=1",
        "inline=true", "inline=false",
      }
      local matches = {}
      for _, c in ipairs(candidates) do
        if vim.startswith(c, arg_lead) then matches[#matches + 1] = c end
      end
      return matches
    end,


    nargs = "*",
    range = true,
    desc  = "[custom.format.enum_lines] Enumerate tokens in visual selection. "
         .. "Usage: :Format enum [STYLE] [sep=SEP] [start=N] [inline=true|false]",
  })
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Public setup
-- ─────────────────────────────────────────────────────────────────────────────

---@param opts Custom.Format.Config|nil
function M.setup(opts)
  if opts and type(opts) == "table" then
    config = vim.tbl_extend("force", config, opts)
  end

  setup_column_align()
  setup_format_table()
  setup_format_text_width()
  setup_filter_lines()
  setup_misc()
  setup_additional_features()
  setup_markdown()
  setup_enum_lines()

  vim.api.nvim_create_user_command("Format", format_handler, {
    nargs    = "*",
    range    = true,
    complete = format_complete,
    desc     = "[custom.format] Unified formatting command with subcommands",
  })
end

return M
