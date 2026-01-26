---@module 'wkdoptions.hl_config.utils.separator'
--- Breadcrumb separator resolution with Nerd Font fallback (memoized).

local lazy = require("lib.lazy")
local memo = lazy.require("lib.memo")

local M = {}

--- Convert hex codepoint to UTF-8 char (safe)
---@nodiscard
---@param hex string|nil
---@return string
local function codepoint_to_char(hex)
  if type(hex) ~= "string" or hex == "" then
    return ""
  end

  local n = tonumber(hex, 16)
  if not n then
    return ""
  end

  local ok, ch = pcall(vim.fn.nr2char, n)
  return (ok and type(ch) == "string") and ch or ""
end

--- Get Nerd Font glyph or Unicode fallback (memoized by hex)
---@nodiscard
---@param hex string
---@return string
local nerd_or_fallback = memo.fn(function(hex)
  local g = codepoint_to_char(hex)

  -- Accept only single display cell to avoid layout drift
  if g ~= "" and vim.fn.strdisplaywidth(g) == 1 then
    return " " .. g .. " "
  end

  -- Fallback: wider arrow on wide terminals
  local wide = (tonumber(vim.o.columns) or 0) >= 100
  return wide and " ⟶ " or " › "
end, { weak = "k", size = 16 })

--- Resolve effective separator from config
---@nodiscard
---@param cfg WKDOptions.HL_CFG
---@return string
function M.resolve(cfg)
  -- 1) Explicit string wins
  local sep = cfg.breadcrumbs_separator
  if type(sep) == "string" and sep ~= "" then
    return sep
  end

  -- 2) Nerd Font hex with fallback
  local hex = cfg.breadcrumbs_nerd_hex
  if type(hex) == "string" and hex ~= "" then
    return nerd_or_fallback(hex)
  end

  -- 3) Default
  return " ⟩ "
end

return M
