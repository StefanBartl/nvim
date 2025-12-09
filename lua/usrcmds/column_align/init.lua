---@module 'utils.column_align'
--- Align visually selected character to a target column with a fill character.
--- This module sets up the keymap and user commands that call the core implementation.

---@class utils.column_align
local M = {}

---@type fun(base: table|nil, extra: table|nil): table
local with = require("lib.with")

--@param modes string|string[]
---@param lhs string
---@param rhs function|string
---@param desc string
---@param opts table|nil
local function map(modes, lhs, rhs, desc, opts)
  -- Build default options; ensure opts.buffer is a number if present
  local o = { noremap = true, silent = true, desc = desc }
  if opts then
    -- Only merge valid fields; protect against invalid `buffer` values
    if opts.buffer ~= nil and type(opts.buffer) ~= "number" then
      -- If buffer is present but not a number, drop it to avoid nvim error
      local safe_opts = {}
      for k, v in pairs(opts) do
        if k ~= "buffer" then
          safe_opts[k] = v
        end
      end
      o = with(o, safe_opts)
    else
      o = with(o, opts)
    end
  end
  vim.keymap.set(modes, lhs, rhs, o)
end

--- Setup function: installs visual-mode mapping and user commands.
--- The commands are created either buffer-local (when a markdown buffer is detected)
--- or global otherwise. Commands validate arguments and call core API functions.
---@return nil
function M.setup()
  -- call the is_markdown_buf module function to obtain a buffer number or nil
  local bufnr = require("lib.is_markdown_buf")()

  -- prepare opts only if bufnr is a valid number
  local o = (type(bufnr) == "number") and { buffer = bufnr } or nil

  -- Column alignment (visual mode) --------------------------------------------
  local ok_col, column_align = pcall(require, "usrcmds.column_align.core")
  if ok_col and column_align and type(column_align.align_interactive) == "function" then
    map("x", "<leader>ac", column_align.align_interactive, "[Utils.ColumnAlign] Align character to column", o)
  end

  -- Define user command wrappers ------------------------------------------------
  -- Helper: create a command with given name and function; use buffer-local options if bufnr present.
  local function create_command(name, cmd_fn, cmd_opts)
    cmd_opts = cmd_opts or {}
    cmd_opts.desc = cmd_opts.desc or ("[Utils.ColumnAlign] " .. name)
    -- If buf number exists and is valid, set buffer option to that number (safe)
    if type(bufnr) == "number" then
      cmd_opts.buffer = bufnr
    end
    -- Use nvim_create_user_command; wrap cmd_fn in a pcall for safety
    vim.api.nvim_create_user_command(name, function(cmd_args)
      local ok, err = pcall(cmd_fn, cmd_args)
      if not ok then
        vim.notify("[Utils.ColumnAlign] Command '" .. name .. "' failed: " .. tostring(err), vim.log.levels.ERROR)
      end
    end, cmd_opts)
  end

  -- Command: ColumnAlignInteractive
  -- Usage:
  --   :ColumnAlignInteractive
  -- Prompts for target column and optional fill character (delegates to align_interactive).
  if ok_col and type(column_align.align_interactive) == "function" then
    create_command("ColumnAlignInteractive", function(_)
      -- simply delegate to the interactive function
      column_align.align_interactive()
    end, { nargs = 0, desc = "Prompt for target column and fill char, align selected character" })
  end

  -- Command: ColumnAlignToColumn
  -- Usage:
  --   :ColumnAlignToColumn <target_col> [fill_char]
  -- Examples:
  --   :ColumnAlignToColumn 40
  --   :ColumnAlignToColumn 40 _
  -- This command expects the user to have a visual selection of a single character.
  if ok_col and type(column_align.align_to_column) == "function" then
    create_command(
      "ColumnAlignToColumn",
      function(cmd_args)
        local args = cmd_args.fargs or {}
        if #args < 1 then
          error("missing required argument: <target_col>")
        end
        local target_col = tonumber(args[1])
        if not target_col or target_col < 1 then
          error("invalid target_col: must be a positive integer")
        end
        local fill_char = args[2] or " "
        if type(fill_char) ~= "string" or #fill_char ~= 1 then
          error("fill_char must be exactly one character")
        end
        -- call core function
        column_align.align_to_column(target_col, fill_char)
      end,
      {
        nargs = "*",
        complete = nil,
        desc = "Align selected character to target column: ColumnAlignToColumn <col> [fill]",
      }
    )
  end
end

return M
