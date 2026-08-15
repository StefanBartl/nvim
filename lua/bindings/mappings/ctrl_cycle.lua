---@module 'bindings.mappings.ctrl_cycle'
---@brief Cycle words (incl. booleans) under <cword> via <C-a>/<C-x>; fall back to native number inc/dec.

---@class CWCCycles
---@field cycles string[][]
local DEFAULTS = {
  cycles = {
    ----------------------------------------------------------------
    -- 2-state toggles
    ----------------------------------------------------------------
    { "true", "false" },
    { "on", "off" },
    { "yes", "no" },
    { "enabled", "disabled" },
    { "enable", "disable" },
    { "active", "inactive" },
    { "visible", "hidden" },
    { "show", "hide" },
    { "accept", "reject" },
    { "include", "exclude" },
    { "open", "closed" },
    { "lock", "unlock" },
    { "locked", "unlocked" },
    { "connected", "disconnected" },
    { "attach", "detach" },
    { "start", "stop" },
    { "pause", "resume" },
    { "mute", "unmute" },
    { "muted", "unmuted" },

    { "up", "down" },
    { "left", "right" },
    { "in", "out" },
    { "asc", "desc" },

    -- Deutsch
    -- { "wahr",       "falsch"      },
    -- { "ja",         "nein"        },
    -- { "an",         "aus"         },
    -- { "ein",        "aus"         },
    -- { "aktiv",      "inaktiv"     },
    -- { "sichtbar",   "unsichtbar"  },
    -- { "offen",      "geschlossen" },
    -- { "stumm",      "laut"        },
    --
    ----------------------------------------------------------------
    -- Multi-state cycles (wrap-around)
    ----------------------------------------------------------------
    { ".", "/", "\\" },
    -- { "dev", "stage", "prod" },
    -- { "alpha", "beta", "rc", "stable" },
    -- { "low", "medium", "high" },
    -- { "small", "medium", "large", "xlarge" },
    -- { "todo", "doing", "done" },
    -- { "draft", "review", "final" },
  },
}

local M = {}

-- ---------- helpers ----------

--- Check buffer writability.
--- @return boolean
local function _buf_writable()
  if vim.bo.buftype ~= "" then
    return false
  end
  if not vim.bo.modifiable then
    return false
  end
  if vim.bo.readonly then
    return false
  end
  return true
end

--- Feed native normal-mode key (no remap).
--- @param lhs string
local function _feed_native(lhs)
  vim.api.nvim_feedkeys(vim.keycode(lhs), "n", false)
end

--- Get <cword>-like span under cursor (respects 'iskeyword').
--- @return integer|nil s, integer|nil e, string|nil txt
local function _cword_span()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2] -- 0-based byte col
  local pat = [[\k\+]]
  local start_at = 0
  while true do
    local m = vim.fn.matchstrpos(line, pat, start_at) -- {match,start,end}
    local txt, s, e = m[1], m[2], m[3]
    if s == -1 then
      return nil, nil, nil
    end
    if col >= s and col < e then
      return s, e, txt
    end
    start_at = e
  end
end

--- Detect numbers: int, float (strict), hex.
--- @param s string|nil
--- @return boolean
local function _is_numeric_like(s)
  if not s or s == "" then
    return false
  end
  if s:match("^[-+]?%d+$") then
    return true
  end
  if s:match("^[-+]?%d+%.%d+$") then
    return true
  end
  if s:match("^0[xX][%da-fA-F]+$") then
    return true
  end
  return false
end

--- Case shape of token.
--- @param s string
--- @return "lower"|"upper"|"capital"|"mixed"
local function _case_shape(s)
  if s == "" then
    return "lower"
  end
  local first, rest = s:sub(1, 1), s:sub(2)
  if s == s:lower() then
    return "lower"
  end
  if s == s:upper() then
    return "upper"
  end
  if first == first:upper() and rest == rest:lower() then
    return "capital"
  end
  return "mixed"
end

--- Apply case shape to replacement.
--- @param repl string
--- @param shape "lower"|"upper"|"capital"|"mixed"
--- @return string
local function _apply_shape(repl, shape)
  if shape == "upper" then
    return repl:upper()
  elseif shape == "capital" then
    return repl:sub(1, 1):upper() .. repl:sub(2):lower()
  elseif shape == "mixed" then
    return repl
  else
    return repl:lower()
  end
end

--- Wrap index inside array with direction.
--- @param arr string[]
--- @param idx integer
--- @param dir integer  -- 1 next, -1 prev
--- @return integer
local function _wrap_index(arr, idx, dir)
  local n = #arr
  if n == 0 then
    return 1
  end
  return ((idx - 1 + dir) % n) + 1
end

-- ---------- core ----------

--- Try cycling <cword> using cycles; return true on change.
--- @param dir integer       -- 1 for forward (<C-a>), -1 for backward (<C-x>)
--- @param cycles string[][]
--- @return boolean
local function _try_cycle(dir, cycles)
  if not _buf_writable() then
    return false
  end

  local s, e, txt = _cword_span()
  if not s then
    return false
  end
  ---@cast s integer
  ---@cast e integer
  ---@cast txt string

  if _is_numeric_like(txt) then
    return false
  end

  local lower = txt:lower()
  local shape = _case_shape(txt)

  local found_arr, found_idx
  for i = 1, #cycles do
    local arr = cycles[i]
    for j = 1, #arr do
      if lower == arr[j]:lower() then
        found_arr, found_idx = arr, j
        break
      end
    end
    if found_arr then
      break
    end
  end
  if not found_arr then
    return false
  end

  local new_idx = _wrap_index(found_arr, found_idx, dir)
  local new_lower = found_arr[new_idx]:lower()
  local new_txt = _apply_shape(new_lower, shape)

  local row0 = vim.api.nvim_win_get_cursor(0)[1] - 1
  vim.api.nvim_buf_set_text(0, row0, s, row0, e, { new_txt })
  return true
end

--- Public entry: if no cycle, feed native key.
--- @param dir integer
--- @param fallback_key string
local function Apply(dir, fallback_key)
  local ok = _try_cycle(dir, DEFAULTS.cycles)
  if not ok then
    _feed_native(fallback_key)
  end
end

function M.setup()
  local map = vim.g.__map_helper

  -- use 1 (not +1) because Lua has no unary plus
  map("n", "<C-y>", function()
    Apply(1, "<C-a>")
  end, { silent = true, desc = "Increment number or cycle word forward" })

  map("n", "<C-x>", function()
    Apply(-1, "<C-x>")
  end, { silent = true, desc = "Decrement number or cycle word backward" })
end

return M
