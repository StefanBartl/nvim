---@module 'bindings.usrcmds.case.render'
--- Pure token rendering: the SNOW-number derivation and the mandated H1.
--- No I/O, no vim.* state beyond string ops — everything here is a plain
--- function of its arguments, so it's the one piece of this module that
--- needs no Neovim instance to test.

local config = require("bindings.usrcmds.case.config")

local M = {}

--- Compact SNOW ticket id — the one used in URLs/copy-paste, no separators.
--- "SAP0000" .. short .. year, e.g. to_snow("940561", "2026") -> "SAP00009405612026"
---@param short string
---@param year string
---@return string
function M.to_snow(short, year)
  return config.snow_prefix .. tostring(short) .. tostring(year)
end

--- Human-readable spaced form, for display only (infocard) — never stored,
--- never used as a lookup key.
---@param short string
---@param year string
---@return string
function M.to_snow_display(short, year)
  return config.snow_prefix .. " " .. tostring(short) .. " " .. tostring(year)
end

--- Normalize any input (a full SNOW id copy-pasted from the ticket, or an
--- already-short case number) down to the short number. Idempotent: a
--- value that isn't a full SNOW id is returned unchanged.
---@param raw string|nil
---@return string short
function M.to_short(raw)
  raw = tostring(raw or ""):gsub("%s+", "")
  local prefix = config.snow_prefix:gsub("%s+", "")
  local short = raw:match("^" .. prefix .. "(%d+)%d%d%d%d$")
  return short or raw
end

--- Plausibility check for a short case number — all-digit, within
--- `config.case_number_min_digits`/`_max_digits`. NOT a check that the
--- number exists in SNOW (that's `registry.exists`); this only guards
--- against garbage (empty, "12", a stray word) reaching `registry.new_dir`
--- and being used as a folder name.
---@param short string|nil
---@return boolean
function M.is_plausible_case_number(short)
  if not short or short == "" then
    return false
  end
  if not short:match("^%d+$") then
    return false
  end
  local len = #short
  return len >= config.case_number_min_digits and len <= config.case_number_max_digits
end

--- The mandated level-1 headline for a case markdown file.
---@param case string
---@param title string|nil
---@param filename string  e.g. "00_Research" (basename, no extension)
---@return string
function M.headline(case, title, filename)
  return config.headline_format:format(case, title or "", filename)
end

--- Basename without extension, the {filename} headline token for a
--- blueprint node's relative path (e.g. "Research/00_Research.md").
---@param rel_path string
---@return string
function M.filename_token(rel_path)
  return vim.fn.fnamemodify(rel_path, ":t:r")
end

return M
