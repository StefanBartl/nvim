---@module 'wkdoptions.hl_config.utils.skip'
--- Build skip matchers and provide a robust UI-like buffer detector.
--- This keeps "filetypes" (exact equality) and "name_patterns" (Lua patterns)
--- separate, because they are semantically different match kinds.
---
-- Example integration:
-- local matchers = M.build_matchers(C.cfg.skip)
-- local function buffer_is_ui_like(bufnr) return M.buffer_is_ui_like(matchers, bufnr) end

local lazy = require("lib.lua.lazy")
local C = lazy.require("wkdoptions.config")

local M = {}

---@param cfg WKDOptions.HL_CFG.Utils.SkipCfg
---@return WKDOptions.HL_CFG.Utils.SkipMatchers
function M.build_matchers(cfg)
  -- Defensive defaults
  cfg = cfg or { filetypes = {}, name_patterns = {} }

  -- Build an O(1) set for filetypes
  local ftset = {} ---@type table<string, true>
  for i = 1, #cfg.filetypes do
    local ft = cfg.filetypes[i]
    if type(ft) == "string" and ft ~= "" then
      ftset[ft] = true
    end
  end

  -- Copy name patterns as-is (avoid reallocation by pre-sizing when length is known)
  ---@type string[]
  local npats = { [#cfg.name_patterns] = "" }
  for i = 1, #cfg.name_patterns do
    npats[i] = cfg.name_patterns[i]
  end

  return { ftset = ftset, npats = npats }
end

---@param matchers WKDOptions.HL_CFG.Utils.SkipMatchers
---@param bufnr integer|nil
---@return boolean
function M.buffer_is_ui_like(matchers, bufnr)
  -- Resolve buffer; defaults to current buffer
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  -- 1) Quick buftype heuristic
  --    Prefer an allowlist of UI-ish buftypes, instead of "bt ~= ''".
  --    This avoids misclassifying normal "acwrite" buffers etc.
  local bt = vim.api.nvim_get_option_value("buftype", { buf = bufnr })
  if bt == "nofile" or bt == "prompt" or bt == "help" or bt == "quickfix" or bt == "terminal" then
    return true
  end

  -- 2) Filetype exact match via set
  local ft = vim.api.nvim_get_option_value("filetype", { buf = bufnr })
  if matchers.ftset[ft] then
    return true
  end

  -- 3) Name pattern match (full buffer name; may be path or a scheme like term://, oil://)
  local name = vim.api.nvim_buf_get_name(bufnr)
  if type(name) == "string" and name ~= "" then
    for i = 1, #matchers.npats do
      local pat = matchers.npats[i]
      -- Use Lua patterns (plain=false); your config already escapes '-' as '%-'
      if name:match(pat) then
        return true
      end
    end
  end

  return false
end

function M.std_skip(bufnr)
  return M.buffer_is_ui_like(M.build_matchers(C.cfg.skip), bufnr)
end

return M
