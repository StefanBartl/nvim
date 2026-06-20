---@module 'custom.format.enum_lines.core'

---@see custom.format.enum_lines.@types

local M = {}

-- Lazy notify
local _notify
local function notify()
  if not _notify then
    local ok, n = pcall(require, "lib.notify")
    if not ok then
      vim.notify("DBG core.lua: lib.notify FAILED: " .. tostring(n), 4) ---REMOVE
      -- fallback so the rest doesn't break
      _notify = {
        error = function(m) vim.notify("[enum] ERR: " .. m, vim.log.levels.ERROR) end,
        warn  = function(m) vim.notify("[enum] WARN: " .. m, vim.log.levels.WARN)  end,
        info  = function(m) vim.notify("[enum] INFO: " .. m, vim.log.levels.INFO)  end,
      }
    else
      local ok2, created = pcall(function() return n.create("[custom.format.enum_lines]") end)
      if not ok2 then
        _notify = {
          error = function(m) vim.notify("[enum] ERR: " .. m, vim.log.levels.ERROR) end,
          warn  = function(m) vim.notify("[enum] WARN: " .. m, vim.log.levels.WARN)  end,
          info  = function(m) vim.notify("[enum] INFO: " .. m, vim.log.levels.INFO)  end,
        }
      else
        _notify = created
      end
    end
  end
  return _notify
end

local api = vim.api

-- ─────────────────────────────────────────────────────────────────────────────
-- Roman-numeral conversion
-- ─────────────────────────────────────────────────────────────────────────────

local function to_roman(n)
  if type(n) ~= "number" or n < 1 then return tostring(n) end
  local vals = { 1000,900,500,400,100,90,50,40,10,9,5,4,1 }
  local syms = { "m","cm","d","cd","c","xc","l","xl","x","ix","v","iv","i" }
  local buf  = {}
  for i, v in ipairs(vals) do
    while n >= v do
      buf[#buf + 1] = syms[i]
      n = n - v
    end
  end
  return table.concat(buf)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Label generation
-- ─────────────────────────────────────────────────────────────────────────────

---@param i       integer   1-based
---@param upper   boolean
---@return string
local function alpha_marker(i, upper)
  local base   = upper and 65 or 97
  local letters = {}
  local n = i - 1
  repeat
    letters[#letters + 1] = string.char(base + (n % 26))
    n = math.floor(n / 26) - 1
  until n < -1
  local lo, hi = 1, #letters
  while lo < hi do
    letters[lo], letters[hi] = letters[hi], letters[lo]
    lo, hi = lo + 1, hi - 1
  end
  return table.concat(letters)
end

---@param i     integer
---@param style Custom.Format.EnumLines.Style
---@param sep   string
---@return string
local function make_label(i, style, sep)
  local marker
  if     style == "decimal" then marker = tostring(i)
  elseif style == "alpha"   then marker = alpha_marker(i, false)
  elseif style == "ALPHA"   then marker = alpha_marker(i, true)
  elseif style == "roman"   then marker = to_roman(i)
  elseif style == "ROMAN"   then marker = to_roman(i):upper()
  else                           marker = tostring(i)
  end
  return marker .. sep
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Token extraction
-- ─────────────────────────────────────────────────────────────────────────────

---@param lines string[]
---@return string[] tokens, string indent
local function extract_tokens(lines)
  local tokens  = {}
  local indent  = ""
  local first   = true
  for _, line in ipairs(lines) do
    if line:match("%S") then
      if first then
        indent = line:match("^(%s*)") or ""
        first  = false
      end
      for tok in line:gmatch("%S+") do
        tokens[#tokens + 1] = tok
      end
    end
  end
  return tokens, indent
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Pure enumeration
-- ─────────────────────────────────────────────────────────────────────────────

---@param lines string[]
---@param opts  Custom.Format.EnumLines.Opts|nil
---@return Custom.Format.EnumLines.Result
function M.enumerate(lines, opts)
  vim.notify("DBG enumerate: called, #lines=" .. tostring(#lines), 4) ---REMOVE
  opts = opts or {}
  local style = opts.style  or "decimal"
  local sep   = opts.sep    or ". "
  local start = opts.start  or 1

  local tokens, indent = extract_tokens(lines)

  if #tokens == 0 then
    return { ok = false, lines = {}, count = 0, err = "No tokens found in selection" }
  end

  local inline
  if opts.inline ~= nil then
    inline = opts.inline
  else
    local non_empty = 0
    for _, l in ipairs(lines) do
      if l:match("%S") then non_empty = non_empty + 1 end
    end
    inline = (non_empty <= 1)
  end

  local labelled = {}
  for i, tok in ipairs(tokens) do
    labelled[#labelled + 1] = make_label(start + i - 1, style, sep) .. tok
  end

  local out_lines
  if inline then
    out_lines = { indent .. table.concat(labelled, " ") }
  else
    out_lines = {}
    for i, lbl in ipairs(labelled) do
      out_lines[#out_lines + 1] = (i == 1 and indent or "") .. lbl
    end
  end

  return { ok = true, lines = out_lines, count = #tokens }
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Buffer helpers
-- ─────────────────────────────────────────────────────────────────────────────

---@return integer|nil, integer|nil
local function get_visual_range()
  local ok_s, s = pcall(api.nvim_buf_get_mark, 0, "<")
  local ok_e, e = pcall(api.nvim_buf_get_mark, 0, ">")
  if not ok_s or not ok_e then
    vim.notify("DBG get_visual_range: mark API failed", 4) ---REMOVE
    return nil, nil
  end
  if not s or not e or s[1] == 0 or e[1] == 0 then return nil, nil end
  return s[1], e[1]
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Public API
-- ─────────────────────────────────────────────────────────────────────────────

---@param opts Custom.Format.EnumLines.Opts|nil
---@return nil
function M.enum_selection(opts)
  local start_line, end_line = get_visual_range()

  if not start_line then
    notify().error("No valid visual selection found")
    return
  end

  local lines  = api.nvim_buf_get_lines(0, start_line - 1, end_line, false)

  local result = M.enumerate(lines, opts)
  if not result.ok then
    notify().error(result.err or "Enumeration failed")
    return
  end

  local ok, err = pcall(api.nvim_buf_set_lines, 0, start_line - 1, end_line, false, result.lines)
  if not ok then
    notify().error("Failed to update buffer: " .. tostring(err))
    return
  end

  notify().info(string.format("Enumerated %d token(s)", result.count))
end

---@param bufnr      integer
---@param start_line integer
---@param end_line   integer
---@param opts       Custom.Format.EnumLines.Opts|nil
---@return Custom.Format.EnumLines.Result
function M.enum_range(bufnr, start_line, end_line, opts)
  bufnr = (not bufnr or bufnr == 0) and api.nvim_get_current_buf() or bufnr

  if not api.nvim_buf_is_valid(bufnr) then
    return { ok = false, lines = {}, count = 0, err = "Invalid buffer" }
  end

  local lines  = api.nvim_buf_get_lines(bufnr, start_line - 1, end_line, false)
  local result = M.enumerate(lines, opts)
  if not result.ok then return result end

  local ok, err = pcall(api.nvim_buf_set_lines, bufnr, start_line - 1, end_line, false, result.lines)
  if not ok then
    return { ok = false, lines = {}, count = 0, err = "Failed to update buffer: " .. tostring(err) }
  end

  return result
end

return M
