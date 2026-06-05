---@module 'custom.format.table._handler'
---@brief Drop-in replacement for setup_format_table() in custom/format/init.lua
---@description
--- Replace the existing `setup_format_table` function body in init.lua with this.
--- Everything else in init.lua stays unchanged.
---
--- New command syntax (all arguments optional, order-insensitive for key=value):
---
---   :Format table [header=ALIGN] [cell=ALIGN] [skip=COL,...] [scope=SCOPE]
---
--- Positional shorthand (backward-compatible):
---   :Format table                         → center center, cursor scope
---   :Format table left                    → left left
---   :Format table center left             → header=center cell=left
---   :Format table right right             → right right
---
--- Key=value arguments (can be mixed with positional, take precedence):
---   header=left|center|right
---   cell=left|center|right
---   skip=Name,Beschreibung      (comma-separated header names OR 1-based indices)
---   scope=cursor|buffer|cwd|<path>
---
--- Examples:
---   :Format table left
---   :Format table header=center cell=left
---   :Format table left skip=Beschreibung
---   :Format table center left skip=3,Beschreibung scope=buffer
---   :Format table scope=cwd

-- ─────────────────────────────────────────────────────────────────────────────
-- Argument parser
-- ─────────────────────────────────────────────────────────────────────────────

local VALID_ALIGN = { left = true, center = true, right = true }

---Parse the raw string[] args produced by nvim_create_user_command into an opts table.
---@param args string[]
---@return Custom.Fmt.FmtTbl.Opts opts, string|nil err
local function parse_args(args)
  ---@type Custom.Fmt.FmtTbl.Opts
  local opts = {}

  local positional = {}  -- collect bare alignment words for compat

  for _, raw in ipairs(args) do
    -- key=value form
    local key, val = raw:match("^([%w_]+)=(.+)$")

    if key and val then
      key = key:lower()

      if key == "header" then
        if not VALID_ALIGN[val] then
          return opts, string.format("Invalid alignment for header=: %q", val)
        end
        opts.header_align = val

      elseif key == "cell" or key == "entry" then
        if not VALID_ALIGN[val] then
          return opts, string.format("Invalid alignment for cell=: %q", val)
        end
        opts.entry_align = val

      elseif key == "skip" then
        opts.col_overrides = opts.col_overrides or {}
        for part in val:gmatch("[^,]+") do
          part = part:match("^%s*(.-)%s*$")  -- trim
          local num = tonumber(part)
          opts.col_overrides[#opts.col_overrides + 1] = {
            col   = num or part,
            align = "left",  -- "skip" = keep default left for that col
          }
        end

      elseif key == "scope" then
        opts.scope = val

      else
        return opts, string.format("Unknown option: %q", raw)
      end

    elseif VALID_ALIGN[raw:lower()] then
      positional[#positional + 1] = raw:lower()

    else
      return opts, string.format("Unknown argument: %q", raw)
    end
  end

  -- Apply positional arguments (backward-compatible).
  -- BUG FIX: one positional arg → apply to BOTH header AND cell.
  if #positional >= 1 and not opts.header_align then
    opts.header_align = positional[1]
  end
  if #positional >= 2 and not opts.entry_align then
    opts.entry_align = positional[2]
  elseif #positional == 1 and not opts.entry_align then
    -- Single positional → same alignment for both roles (the original bug fix).
    opts.entry_align = positional[1]
  end

  return opts, nil
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Completion helper
-- ─────────────────────────────────────────────────────────────────────────────

---@param arg_lead string
---@return string[]
local function table_complete(arg_lead)
  local candidates = {
    "left", "center", "right",
    "header=left", "header=center", "header=right",
    "cell=left",   "cell=center",   "cell=right",
    "skip=",
    "scope=cursor", "scope=buffer", "scope=cwd",
  }

  local matches = {}
  for _, c in ipairs(candidates) do
    if vim.startswith(c, arg_lead) then
      matches[#matches + 1] = c
    end
  end

  return matches
end

-- ─────────────────────────────────────────────────────────────────────────────
-- setup_format_table  (replaces the existing function in init.lua)
-- ─────────────────────────────────────────────────────────────────────────────

---@param register_subcommand fun(name: Custom.Format.SubcommandName, def: Custom.Format.SubcommandDef): nil
---@param notify_mod table  The notify handle from the parent module
---@return nil
local function setup_format_table(register_subcommand, notify_mod)
  local ok, format_table = pcall(require, "custom.format.table")
  if not ok then
    return
  end

  register_subcommand("table", {
    handler = function(args)
      local opts, parse_err = parse_args(args)

      if parse_err then
        notify_mod.error(string.format("[custom.format.table] %s", parse_err))
        return
      end

      local scope = opts.scope or "cursor"

      local success, err
      if scope == "cursor" then
        local bufnr = vim.api.nvim_get_current_buf()
        success, err = format_table.format_table_at_cursor(bufnr, opts)
      else
        success, err = format_table.format_tables_in_scope(opts)
      end

      if not success then
        notify_mod.warn(string.format("[custom.format.table] %s", err or "Unknown error"))
        return
      end

      if scope == "cursor" then
        notify_mod.info("Table formatted")
      end
    end,

    complete = function(arg_lead, _cmdline, _cursor_pos)
      return table_complete(arg_lead)
    end,

    nargs = "*",
    desc  = table.concat({
      "[custom.format.table] Format Markdown table(s).",
      "Usage: :Format table [ALIGN] [header=ALIGN] [cell=ALIGN] [skip=COL,...] [scope=cursor|buffer|cwd|PATH]",
      "  ALIGN = left | center | right",
      "  skip  = comma-separated column names or 1-based indices",
    }, " "),
  })
end

return {
  setup       = setup_format_table,
  parse_args  = parse_args,           -- exposed for testing
  complete    = table_complete,
}
