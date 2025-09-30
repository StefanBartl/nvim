---@module 'custom.markdown.core.headings'
--- ATX heading navigation + level shifting. Pure logic, view preserved.

---@class MarkdownHeadings
local M = {}

local api, fn, cmd = vim.api, vim.fn, vim.cmd
local cfg = require("custom.markdown.config").get

---@return nil
function M.goto_prev_heading()
  fn.search("^##\\+\\s\\+.*$", "bWs")
  cmd("nohlsearch")
end

---@return nil
function M.goto_next_heading()
  fn.search("^##\\+\\s\\+.*$", "Ws")
  cmd("nohlsearch")
end

---@param line string
---@param delta integer
---@param min_level integer
---@return string, boolean
local function shift_heading_line(line, delta, min_level)
  if line == "" or line:match("^%s*$") then return line, false end
  local hashes, rest = line:match("^(%s*#+)%s+(.*)$")
  if not hashes then return line, false end
  local indent = hashes:match("^%s*") or ""
  local level = #hashes - #indent
  local new = math.max(min_level, math.min(6, level + delta))
  if new == level then return line, false end
  return string.format("%s%s %s", indent, string.rep("#", new), rest), true
end

---@param bufnr integer
---@param srow integer
---@param erow integer
---@param delta integer
---@param min_level integer
---@return integer
local function shift_range(bufnr, srow, erow, delta, min_level)
  local lines = api.nvim_buf_get_lines(bufnr, srow - 1, erow, false)
  local changed = 0
  local in_fence = false
  local fence_pat = "^%s*([`~]{3,})"
  for i = 1, #lines do
    local line = lines[i]
    local fence = line:match(fence_pat)
    if fence then in_fence = not in_fence end
    if not in_fence then
      local out, did = shift_heading_line(line, delta, min_level)
      if did then lines[i] = out; changed = changed + 1 end
    end
  end
  if changed > 0 then
    api.nvim_buf_set_lines(bufnr, srow - 1, erow, false, lines)
  end
  return changed
end

--- Public: shift a given 1-based line range (operator/whole-buffer use)
---@param srow integer
---@param erow integer
---@param delta integer  -- +1 / -1
---@return integer changed
function M.shift_range(srow, erow, delta)
  if delta ~= 1 and delta ~= -1 then return 0 end
  if vim.bo.filetype ~= "markdown" then return 0 end
  local bufnr = api.nvim_get_current_buf()
  if not (api.nvim_buf_is_loaded(bufnr) and api.nvim_buf_is_valid(bufnr)) then return 0 end
  local min_level = cfg().protect_h1 and 2 or 1
  local view = fn.winsaveview()
  local changed = shift_range(bufnr, srow, erow, delta, min_level)
  fn.winrestview(view)
  return changed
end

---@return nil
function M.shift(delta)
  if delta ~= 1 and delta ~= -1 then return end
  if vim.bo.filetype ~= "markdown" then return end
  local bufnr = api.nvim_get_current_buf()
  if not (api.nvim_buf_is_loaded(bufnr) and api.nvim_buf_is_valid(bufnr)) then return end

  local srow, erow
  if fn.mode(1):match("^[vV\022]$") then
    local ms = api.nvim_buf_get_mark(0, "<")
    local me = api.nvim_buf_get_mark(0, ">")
    srow = math.min(ms[1], me[1]); erow = math.max(ms[1], me[1])
  else
    local cur = api.nvim_win_get_cursor(0)
    srow, erow = cur[1], cur[1]
  end
  M.shift_range(srow, erow, delta)
end

function M.increase() M.shift(1) end
function M.decrease() M.shift(-1) end

-- Operator-pending helpers (use with g@)
---@param _ string
function M._op_increase(_)  -- kept simple for operatorfunc
  local srow = api.nvim_buf_get_mark(0, "[")[1]
  local erow = api.nvim_buf_get_mark(0, "]")[1]
  if srow and erow then M.shift_range(math.min(srow, erow), math.max(srow, erow), 1) end
end

---@param _ string
function M._op_decrease(_)
  local srow = api.nvim_buf_get_mark(0, "[")[1]
  local erow = api.nvim_buf_get_mark(0, "]")[1]
  if srow and erow then M.shift_range(math.min(srow, erow), math.max(srow, erow), -1) end
end

return M
