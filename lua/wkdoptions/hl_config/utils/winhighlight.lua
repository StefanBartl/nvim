---@module 'wkdoptions.hl_config.utils.winhighlight'
--- Safe winhighlight parsing and manipulation (prevents E5248).
--- Uses lib.string utilities and strict validation.

local lazy = require("lib.lazy")
local trim = lazy.require("lib.strings.core").trim
local memo = lazy.require("lib.memo")

local M = {}

--- Parse winhighlight string into validated pairs (memoized)
---@nodiscard
---@param wh string|nil
---@return WKDOptions.HL_CFG_WinhlPair[]
local parse = memo.fn(function(wh)
  local res = {}

  if type(wh) ~= "string" or wh == "" then
    return res
  end

  -- Split by comma, validate each pair
  for item in wh:gmatch("[^,]+") do
    local t = trim(item)
    -- Strict: only word characters and undrscore on both sides
    local from, to = t:match("^([%w_]+):([%w_]+)$")
    if from and to then
      res[#res + 1] = { from = from, to = to }
    end
  end

  return res
end, { size = 128 })

--- Serialize pairs back to winhighlight string
---@nodiscard
---@param _pairs WKDOptions.HL_CFG_WinhlPair[]
---@return string
function M.serialize(_pairs)
  local out = {}
  for i = 1, #_pairs do
    local p = _pairs[i]
    -- Re-validate before serializing (defensive)
    if p.from:match("^[%w_]+$") and p.to:match("^[%w_]+$") then
      out[i] = p.from .. ":" .. p.to
    end
  end
  return table.concat(out, ",")
end

--- Set or remove a single mapping in winhighlight
---@nodiscard
---@param wh string|nil -- current winhighlight
---@param from string   -- source group
---@param to string|nil -- target group (nil = remove mapping)
---@return string       -- new winhighlight
function M.set_pair(wh, from, to)
  local _pairs = parse(wh)
  local out = {}

  -- Filter out old mapping with same 'from'
  for i = 1, #_pairs do
    if _pairs[i].from ~= from then
      out[#out + 1] = _pairs[i]
    end
  end

  -- Add new mapping if 'to' is provided
  if type(to) == "string" and to ~= "" then
    out[#out + 1] = { from = from, to = to }
  end

  return M.serialize(out)
end

--- Merge new pairs into existing winhighlight (new pairs win)
---@nodiscard
---@param wh string|nil
---@param new_pairs table<string, string> -- map from->to
---@return string
function M.merge(wh, new_pairs)
  local _pairs = parse(wh)
  local seen = {}
  local out = {}

  -- Add new pairs first (they take precedence)
  for from, to in pairs(new_pairs) do
    if from:match("^[%w_]+$") and to:match("^[%w_]+$") then
      out[#out + 1] = { from = from, to = to }
      seen[from] = true
    end
  end

  -- Add old pairs if not overridden
  for i = 1, #_pairs do
    local p = _pairs[i]
    if not seen[p.from] then
      out[#out + 1] = p
    end
  end

  return M.serialize(out)
end

--- Remove multiple mappings at once
---@nodiscard
---@param wh string|nil
---@param from_keys string[] -- list of 'from' keys to remove
---@return string
function M.remove_keys(wh, from_keys)
  local _pairs = parse(wh)
  local blacklist = {}
  for i = 1, #from_keys do
    blacklist[from_keys[i]] = true
  end

  local out = {}
  for i = 1, #_pairs do
    local p = _pairs[i]
    if not blacklist[p.from] then
      out[#out + 1] = p
    end
  end

  return M.serialize(out)
end

--- Safe wrapper to set winhighlight on a window
---@param win integer
---@param wh string
---@return boolean success
function M.apply_to_window(win, wh)
  if not vim.api.nvim_win_is_valid(win) then
    return false
  end

  local ok = pcall(vim.api.nvim_set_option_value, "winhighlight", wh, { scope = "local", win = win })
  return ok
end

return M
