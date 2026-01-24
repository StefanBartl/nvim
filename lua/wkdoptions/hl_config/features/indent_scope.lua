---@module 'wkdoptions.hl_config.features.indent_scope'
--- Viewport-limited indent scope highlighting: tints full lines of the active indentation block.
--- Respects large_file_kb guard and skip rules.

local State = require("wkdoptions.hl_config.core.state")
local LargeFile = require("wkdoptions.hl_config.utils.large_file")
local is_ui = require("wkdoptions.hl_config.utils.skip").std_skip

local M = {}

--- Check if skip rules apply
---@nodiscard
---@param bufnr integer
---@param cfg WKDOptions.HL_CFG
---@return boolean
local function should_skip(bufnr, cfg)
  local rules = cfg.indent_scope_skip or {}

  -- UI buffers
  if is_ui(bufnr) then
    return true
  end

  -- Floating windows
  if rules.skip_floating then
    local wc = vim.api.nvim_win_get_config(0)
    if wc and type(wc) == "table" and wc.relative and wc.relative ~= "" then
      return true
    end
  end

  return false
end

--- Highlight full lines safely (handles end-of-buffer edge cases)
---@param buf integer
---@param ns integer
---@param hl string
---@param srow integer -- 0-based inclusive
---@param erow integer -- 0-based inclusive
---@param priority integer|nil
---@return nil
local function highlight_full_lines(buf, ns, hl, srow, erow, priority)
  if erow < srow then
    return
  end

  priority = priority or 50

  local ok_count, last0 = pcall(vim.api.nvim_buf_line_count, buf)
  if not ok_count then
    return
  end
  last0 = last0 - 1

  local has_next = erow < last0
  local end_row, end_col, inclusive

  if has_next then
    end_row, end_col, inclusive = erow + 1, 0, false
  else
    end_row, end_col, inclusive = erow, 2147483647, true
  end

  -- Try modern API first
  if vim.hl and type(vim.hl.range) == "function" then
    local ok = pcall(
      vim.hl.range,
      buf,
      ns,
      hl,
      { srow, 0 },
      { end_row, end_col },
      { inclusive = inclusive, priority = priority }
    )
    if ok then
      return
    end
  end

  if vim.highlight and type(vim.highlight.range) == "function" then
    local ok = pcall(
      vim.highlight.range,
      buf,
      ns,
      hl,
      { srow, 0 },
      { end_row, end_col },
      { inclusive = inclusive, priority = priority }
    )
    if ok then
      return
    end
  end

  -- Fallback: extmark per line
  for l = srow, erow do
    pcall(vim.api.nvim_buf_set_extmark, buf, ns, l, 0, {
      end_row = l,
      end_col = 0,
      hl_group = hl,
      hl_eol = true,
      priority = priority,
    })
  end
end

--- Update indent scope for current viewport
---@param cfg WKDOptions.HL_CFG
---@return nil
function M.refresh(cfg)
  local ns = State.get_namespace("IndentScope")
  local bufnr = 0

  -- Clear previous highlights
  pcall(vim.api.nvim_buf_clear_namespace, bufnr, ns, 0, -1)

  if not State.is_enabled("indent_scope") then
    return
  end

  if LargeFile.is_large(bufnr, cfg) then
    return
  end

  if should_skip(bufnr, cfg) then
    return
  end

  -- Get cursor and viewport
  local ok_cur, cur = pcall(vim.api.nvim_win_get_cursor, 0)
  if not ok_cur then
    return
  end

  local row = cur[1]
  local topl = vim.fn.line("w0")
  local botl = vim.fn.line("w$")

  local ok_lines, lines = pcall(vim.api.nvim_buf_get_lines, bufnr, topl - 1, botl, false)
  if not ok_lines or not lines then
    return
  end

  local ts = vim.bo.tabstop

  --- Calculate indent level (in columns)
  ---@param s string
  ---@return integer cols, integer bytes
  local function indent_of(s)
    local col, n = 0, 0
    for i = 1, #s do
      local ch = s:sub(i, i)
      if ch == " " then
        col = col + 1
      elseif ch == "\t" then
        col = col + (ts - (col % ts))
      else
        break
      end
      n = n + 1
    end
    return col, n
  end

  -- Get current line indent
  local ok_curline, curline = pcall(vim.api.nvim_buf_get_lines, bufnr, row - 1, row, false)
  if not ok_curline or not curline or #curline == 0 then
    return
  end

  curline = curline[1] or ""
  if curline:match("^%s*$") then
    return -- empty line
  end

  local curindent = indent_of(curline)

  --- Get indent for viewport line i (1-based in viewport)
  ---@param i integer
  ---@return integer -- -1 for blank lines
  local function line_indent_at(i)
    local s = lines[i] or ""
    if s:match("^%s*$") then
      return -1
    end
    return indent_of(s)
  end

  -- Find contiguous block with >= curindent
  local rel_cur = row - topl + 1
  local up, down = rel_cur, rel_cur

  while up > 1 and line_indent_at(up - 1) >= curindent do
    up = up - 1
  end

  while down < #lines and line_indent_at(down + 1) >= curindent do
    down = down + 1
  end

  local start_row = topl + up - 2 -- convert to 0-based
  local end_row = topl + down - 2

  highlight_full_lines(bufnr, ns, "IndentScope", start_row, end_row, 50)
end

--- Wrapper for config-free refresh (used by after_set)
---@return nil
function M.refresh_current()
  local C = require("wkdoptions.config")
  M.refresh(C.cfg.highlight)
end

--- Install autocmds
---@param cfg WKDOptions.HL_CFG
---@return nil
function M.enable(cfg)
  local aug = State.get_augroup("IndentScope", true)

  if not State.is_enabled("indent_scope") then
    return
  end

  vim.api.nvim_create_autocmd({ "BufEnter", "CursorMoved", "WinScrolled" }, {
    group = aug,
    callback = function()
      vim.schedule(function()
        M.refresh(cfg)
      end)
    end,
    desc = "Update indent scope on movement/scroll",
  })

  -- Initial refresh
  M.refresh(cfg)
end

return M
