---@module 'utils.markdown_headings'
--- Markdown ATX heading level shifter with mode-aware keymaps.
--- Guarantees
---   - Normal mode: operates on the current line.
---   - Visual mode: operates on the selected line range.
---   - Operator-pending: operates on the user motion.
--- Design notes
---   - Only ATX headings (`#`) are shifted; Setext (`===` / `---`) are ignored on purpose.
---   - Code fences (``` or ~~~) are preserved; lines inside a fence are skipped.
---   - H1 is protected by default (min_level = 2).

local M = {}

local api, fn = vim.api, vim.fn

--------------------------------------------------------------------------------
-- Mode helpers
--------------------------------------------------------------------------------

---@return boolean
local function in_visual_mode_now()
  local m = fn.mode(1)
  return m == "v" or m == "V" or m == "\22"
end

---@return integer|nil, integer|nil
local function get_visual_line_range_if_any()
  if not in_visual_mode_now() then
    return nil, nil
  end
  local ms = api.nvim_buf_get_mark(0, "<")
  local me = api.nvim_buf_get_mark(0, ">")
  if not (ms and me) then
    return nil, nil
  end
  local srow = math.min(ms[1], me[1])
  local erow = math.max(ms[1], me[1])
  if srow >= 1 and erow >= srow then
    return srow, erow
  end
  return nil, nil
end

--------------------------------------------------------------------------------
-- Core transformation
--------------------------------------------------------------------------------

--- Shift a single line if it is an ATX heading (skips fenced code).
---@param line string
---@param delta integer +1 to increase, -1 to decrease
---@param min_level integer minimum allowed level (default 2)
---@return string line_out, boolean changed
local function shift_heading_line(line, delta, min_level)
  -- Ignore empty/whitespace lines fast
  if line == "" or line:match("^%s*$") then
    return line, false
  end
  -- Match leading hashes + a space: e.g. "### Title"
  local hashes, rest = line:match("^(%s*#+)%s+(.*)$")
  if not hashes then
    return line, false
  end
  local indent = hashes:match("^%s*") or ""
  local level = #hashes - #indent
  local new = level + delta
  if new < min_level then
    new = min_level
  end
  if new > 6 then
    new = 6
  end
  if new == level then
    return line, false
  end
  return string.format("%s%s %s", indent, string.rep("#", new), rest), true
end

--- Iterate lines while skipping fenced code blocks.
---@param bufnr integer
---@param srow integer 1-based inclusive
---@param erow integer 1-based inclusive
---@param delta integer
---@param opts? { min_level?: integer }
---@return integer changed_count
local function shift_range(bufnr, srow, erow, delta, opts)
  local min_level = (opts and opts.min_level) or 2
  local lines = api.nvim_buf_get_lines(bufnr, srow - 1, erow, false)
  local changed = 0

  local in_fence = false
  local fence_pat = "^%s*([`~]{3,})" -- ``` or ~~~ (3 or more)
  for i, line in ipairs(lines) do
    local fence = line:match(fence_pat)
    if fence then
      -- toggle on fence lines; lines inside fences are skipped
      in_fence = not in_fence
    end
    if not in_fence then
      local out, did = shift_heading_line(line, delta, min_level)
      if did then
        lines[i] = out
        changed = changed + 1
      end
    end
  end

  if changed > 0 then
    api.nvim_buf_set_lines(bufnr, srow - 1, erow, false, lines)
  end
  return changed
end

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------

--- Shift headings over either the visual selection, an explicit range, or the
--- current line when no selection exists.
function M.shift_headings(delta, opts)
  if type(delta) ~= "number" or (delta ~= 1 and delta ~= -1) then
    return
  end
  local bufnr = api.nvim_get_current_buf()
  if not (api.nvim_buf_is_loaded(bufnr) and api.nvim_buf_is_valid(bufnr)) then
    return
  end
  if vim.bo[bufnr].filetype ~= "markdown" then
    return
  end

  local srow, erow

  if opts and opts.range_override then
    local r = opts.range_override()
    if r and r[1] and r[2] then
      srow, erow = r[1], r[2]
    end
  end

  if not srow then
    local vs, ve = get_visual_line_range_if_any()
    if vs and ve then
      srow, erow = vs, ve
    end
  end

  if not srow then
    local cur = api.nvim_win_get_cursor(0)
    srow, erow = cur[1], cur[1]
  end

  local view = fn.winsaveview()
  shift_range(bufnr, srow, erow, delta, { min_level = (opts and opts.min_level) or 2 })
  fn.winrestview(view)
end

function M.increase()
  M.shift_headings(1, { min_level = 2 })
end

function M.decrease()
  M.shift_headings(-1, { min_level = 2 })
end

--------------------------------------------------------------------------------
-- Operator-pending support
--------------------------------------------------------------------------------

--- Build an operatorfunc that applies the shift on a motion.
---@param delta integer
---@return fun(type:string)
local function make_operatorfunc(delta)
  return function(type)
    local bufnr = api.nvim_get_current_buf()
    local srow, scol = api.nvim_buf_get_mark(bufnr, "[")[1], api.nvim_buf_get_mark(bufnr, "[")[2]
    local erow, ecol = api.nvim_buf_get_mark(bufnr, "]")[1], api.nvim_buf_get_mark(bufnr, "]")[2]
    if not srow or not erow then
      return
    end
    if srow > erow or (srow == erow and scol > ecol) then
      srow, erow = erow, srow
    end
    M.shift_headings(delta, {
      min_level = 2,
      range_override = function() return { srow, erow } end,
    })
  end
end

--- These are kept global-ish but namespaced inside the module for tests.
function M._op_increase(_)
  make_operatorfunc(1)("char")
end

function M._op_decrease(_)
  make_operatorfunc(-1)("char")
end

--------------------------------------------------------------------------------
-- Keymaps
--------------------------------------------------------------------------------

local function whole_buffer_range()
  return { 1, api.nvim_buf_line_count(0) }
end

--- Buffer-local markdown mappings.
---@param bufnr integer
function M.setup_keymaps(bufnr)
  local opts = { silent = true, noremap = true, nowait = true, buffer = bufnr }

  -- Normal/Visual (line or selection)
  vim.keymap.set({ "n", "x" }, "<leader>mhI", function() M.increase() end,
    vim.tbl_extend("force", opts, { desc = "[Markdown] Increase heading level(s) (line/selection, H2+)" }))

  vim.keymap.set({ "n", "x" }, "<leader>mhD", function() M.decrease() end,
    vim.tbl_extend("force", opts, { desc = "[Markdown] Decrease heading level(s) (line/selection, H2+)" }))

  -- Operator-pending (use with a motion, e.g. <leader>mhiap)
  vim.keymap.set("n", "<leader>mhi", function()
    vim.go.operatorfunc = "v:lua.require'utils.markdown_headings'._op_increase"
    return "g@"
  end, vim.tbl_extend("force", opts, { expr = true, desc = "[Markdown] Increase headings (operator-pending)" }))

  vim.keymap.set("n", "<leader>mhd", function()
    vim.go.operatorfunc = "v:lua.require'utils.markdown_headings'._op_decrease"
    return "g@"
  end, vim.tbl_extend("force", opts, { expr = true, desc = "[Markdown] Decrease headings (operator-pending)" }))

  -- Whole buffer convenience
  vim.keymap.set("n", "<leader>mhIA", function()
    M.shift_headings(1, { min_level = 2, range_override = whole_buffer_range })
  end, vim.tbl_extend("force", opts, { desc = "[Markdown] Increase ALL headings (buffer, H2+)" }))

  vim.keymap.set("n", "<leader>mhDA", function()
    M.shift_headings(-1, { min_level = 2, range_override = whole_buffer_range })
  end, vim.tbl_extend("force", opts, { desc = "[Markdown] Decrease ALL headings (buffer, H2+)" }))
end

return M
