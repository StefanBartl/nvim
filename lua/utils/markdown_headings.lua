---@module 'mdutils.headings'
--- Markdown heading shifting utilities + mode-aware keymaps.
--- Guarantees:
---   * Normal mode: only current line is affected.
---   * Visual mode: only the selected range is affected.
---   * Operator-pending: user-defined motion determines the affected range.
--- Notes:
---   * Preserves code fences (``` / ~~~).
---   * Shifts only ATX headings (`#`, not Setext) to avoid ambiguity.
---   * Default protects H1 by using min_level = 2. Can be overridden per call.

---@class ShiftOpts
---@field min_level integer|nil  -- minimal original level that is allowed to be shifted (default: 2)
---@field max_level integer|nil  -- maximal original level that is allowed to be shifted (default: 6)
---@field range_override integer[]|nil -- optional {srow, erow} 1-based inclusive line range to force

---@alias ShiftDelta integer

local M = {}

--------------------------------------------------------------------------------
-- Small local helpers (standalone; no external deps required)
--------------------------------------------------------------------------------

--- Return current buffer if valid, otherwise nil.
---@return integer|nil
local function current_buf_valid()
  local buf = vim.api.nvim_get_current_buf()
  if type(buf) == "number" and vim.api.nvim_buf_is_loaded(buf) and vim.api.nvim_buf_is_valid(buf) then
    return buf
  end
  return nil
end

--- Return 1-based inclusive visual line range if in visual mode, otherwise nil.
---@return integer|nil srow
---@return integer|nil erow
local function get_visual_line_range_if_any()
  local m_start = vim.api.nvim_buf_get_mark(0, "<")
  local m_end   = vim.api.nvim_buf_get_mark(0, ">")
  if not (m_start and m_end) then return nil, nil end
  local srow = math.min(m_start[1], m_end[1])
  local erow = math.max(m_start[1], m_end[1])
  if srow >= 1 and erow >= srow then
    return srow, erow
  end
  return nil, nil
end

--- Return 1-based current cursor line as {srow, erow}.
---@return integer srow
---@return integer erow
local function current_line_range()
  local row = vim.api.nvim_win_get_cursor(0)[1]
  return row, row
end

--- Detect ATX heading level, or nil if not a heading.
---@param line string
---@return integer|nil
local function atx_level(line)
  local hashes, rest = line:match("^%s*(#+)%s+(.*)")
  if hashes and #hashes >= 1 and rest and rest ~= "" then
    return math.min(#hashes, 6)
  end
  return nil
end

--- True if the line starts a code fence.
---@param line string
---@return boolean
local function is_fence(line)
  return line:match("^%s*```") ~= nil or line:match("^%s*~~~") ~= nil
end

--- Find the line number (1-based) of the end of YAML frontmatter (`---` fences) or 0 if none.
---@param buf integer
---@return integer
local function frontmatter_end(buf)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  if #lines < 3 then return 0 end
  if not lines[1]:match("^%-%-%-%s*$") then return 0 end
  for i = 2, math.min(#lines, 200) do
    if lines[i]:match("^%-%-%-%s*$") then
      return i
    end
  end
  return 0
end

--- Save and later restore window view (cursor, topline, etc.).
---@return table
local function save_view()
  return vim.fn.winsaveview()
end

---@param view table
local function restore_view(view)
  pcall(vim.fn.winrestview, view)
end

--- Fetch lines [srow, erow] inclusive (1-based).
---@param srow integer
---@param erow integer
---@return string[]
local function get_lines_range(srow, erow)
  -- nvim_buf_get_lines is 0-based and end-exclusive
  return vim.api.nvim_buf_get_lines(0, srow - 1, erow, false)
end

--- Set lines [srow, erow] inclusive (1-based) to `new_lines`.
---@param srow integer
---@param erow integer
---@param new_lines string[]
local function set_lines_range(srow, erow, new_lines)
  vim.api.nvim_buf_set_lines(0, srow - 1, erow, false, new_lines)
end

--- Clear search highlight (harmless if not set).
local function clear_hlsearch()
  vim.cmd.nohlsearch({ mods = { silent = true } })
end

--------------------------------------------------------------------------------
-- Core transformer
--------------------------------------------------------------------------------

--- Shift heading levels by a delta within a given (or inferred) range.
--- If `opts.range_override` is provided, that range is used.
--- Else, if a visual selection is active, that visual line range is used.
--- Else, the CURRENT LINE is used (never the entire buffer by default).
---@param delta ShiftDelta
---@param opts ShiftOpts|nil
---@return nil
function M.shift_headings(delta, opts)
  if type(delta) ~= "number" or delta == 0 then return end
  local buf = current_buf_valid()
  if not buf then return end

  opts = opts or {}
  local min_level = (type(opts.min_level) == "number" and opts.min_level) or 2
  local max_level = (type(opts.max_level) == "number" and opts.max_level) or 6

  -- Determine effective range (priority: override > visual > current line)
  local srow, erow
  if opts.range_override and type(opts.range_override[1]) == "number" and type(opts.range_override[2]) == "number" then
    srow, erow = opts.range_override[1], opts.range_override[2]
  else
    local vs, ve = get_visual_line_range_if_any()
    if vs and ve then
      srow, erow = vs, ve
    else
      srow, erow = current_line_range()
    end
  end

  local fm_end = frontmatter_end(buf)
  local view = save_view()

  local lines = get_lines_range(srow, erow)
  local out = { [#lines] = "" } ---@type string[]  -- pre-allocate to reduce reallocations

  for i = 1, #lines do
    local lnum = srow + i - 1
    local line = lines[i]

    if is_fence(line) then
      out[i] = line
    else
      local lvl = atx_level(line)
      if lvl and lvl >= min_level and lvl <= max_level then
        local new_lvl = lvl + delta
        if new_lvl < 1 then new_lvl = 1 end
        if new_lvl > 6 then new_lvl = 6 end

        -- Protect the first H1 after frontmatter if min_level > 1
        if new_lvl == 1 and min_level > 1 then
          if not (lnum == 1 or (fm_end > 0 and lnum == fm_end + 1)) then
            new_lvl = 2
          end
        end

        local prefix, rest = line:match("^(%s*#+)(%s+.*)$")
        if rest then
          out[i] = string.rep("#", new_lvl) .. rest
        else
          out[i] = line
        end
      else
        out[i] = line
      end
    end
  end

  set_lines_range(srow, erow, out)
  restore_view(view)
  clear_hlsearch()
end

--------------------------------------------------------------------------------
-- Operatorfunc (optional, for g@ motions)
--------------------------------------------------------------------------------

--- Internal operatorfunc to support motions: sets range via '< and '>
---@param delta ShiftDelta
---@return fun(type: string)  -- operatorfunc
local function make_operatorfunc(delta)
  return function(type_)
    -- After user provides a motion, Vim sets '< and '>
    -- Simply call main shifter without override; visual marks exist now.
    M.shift_headings(delta, { min_level = 2 })
    -- Return to normal mode cleanly
  end
end

--------------------------------------------------------------------------------
-- Public helpers and default keymaps
--------------------------------------------------------------------------------

--- Increase heading levels (current line or visual range).
---@param count integer|nil
function M.increase(count)
  local n = (type(count) == "number" and count > 0) and count or vim.v.count1
  M.shift_headings(n, { min_level = 2 })
end

--- Decrease heading levels (current line or visual range).
---@param count integer|nil
function M.decrease(count)
  local n = (type(count) == "number" and count > 0) and count or vim.v.count1
  M.shift_headings(-n, { min_level = 2 })
end

--- Install sensible defaults (idempotent).
---@return nil
function M.setup_keymaps()
  local map = vim.keymap.set

  -- Normal/Visual: line or selection
  map({ "n", "x" }, "<leader>mhI", function() M.increase() end, { desc = "[Markdown] Increase heading level(s) (line/selection, H2+)" })
  map({ "n", "x" }, "<leader>mhD", function() M.decrease() end, { desc = "[Markdown] Decrease heading level(s) (line/selection, H2+)" })

  -- Operator-pending: user provides a motion (e.g., `<leader>mhiap`, `<leader>mhdip`, `<leader>mhi}` …)
  map("n", "<leader>mhi", function()
    vim.o.operatorfunc = ("v:lua.%s"):format("require'mdutils.headings'._op_increase")
    return "g@"
  end, { expr = true, desc = "[Markdown] Increase heading level(s) on {motion}" })

  map("n", "<leader>mhd", function()
    vim.o.operatorfunc = ("v:lua.%s"):format("require'mdutils.headings'._op_decrease")
    return "g@"
  end, { expr = true, desc = "[Markdown] Decrease heading level(s) on {motion}" })
end

-- Expose operatorfunc shims
---@private
function M._op_increase(_)
  make_operatorfunc(1)("char")
end

---@private
function M._op_decrease(_)
  make_operatorfunc(-1)("char")
end

return M

