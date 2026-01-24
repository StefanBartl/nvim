---@module 'wkdoptions.hl_config.breadcrumbs.winbar'
--- Winbar rendering with path + context, using memoized utilities and safe guards.

local trim = require("lib.string.core").trim
local PathCache = require("wkdoptions.hl_config.path_cache")
local Separator = require("wkdoptions.hl_config.utils.separator")

local M = {}

--- Escape `%` for statusline/winbar rendering
---@nodiscard
---@param s string
---@return string
local function stl_escape(s)
  return (tostring(s or ""):gsub("%%", "%%%%"))
end

--- Ellipsize string in the middle (ASCII-oriented)
---@nodiscard
---@param s string
---@param max integer
---@return string
local function ellipsize_middle(s, max)
  if #s <= max then
    return s
  end

  local head = math.floor((max - 1) / 2)
  local tail = max - head - 1
  return string.sub(s, 1, head) .. "…" .. string.sub(s, #s - tail + 1, #s)
end

--- Check if window should skip winbar
---@nodiscard
---@param bufnr integer
---@param cfg WKDOptions.HL_CFG
---@return boolean
local function should_skip(bufnr, cfg)
  local rules = cfg.winbar_skip or {}

  -- Floating windows
  if rules.skip_floating then
    local wc = vim.api.nvim_win_get_config(0)
    if wc and type(wc) == "table" and wc.relative and wc.relative ~= "" then
      return true
    end
  end

  -- Minimum height
  local height = vim.api.nvim_win_get_height(0)
  if rules.min_height and height < rules.min_height then
    return true
  end

  -- Buftype/filetype checks
  local ok_bt, bt = pcall(vim.api.nvim_get_option_value, "buftype", { buf = bufnr })
  local ok_ft, ft = pcall(vim.api.nvim_get_option_value, "filetype", { buf = bufnr })

  if not ok_bt or not ok_ft then
    return true
  end

  if rules.only_normal_buffers and bt and bt ~= "" then
    return true
  end

  -- Check blacklists
  local function in_list(list, val)
    if not list or not val or val == "" then
      return false
    end
    for i = 1, #list do
      if list[i] == val then
        return true
      end
    end
    return false
  end

  if in_list(rules.buftypes, bt) or in_list(rules.filetypes, ft) then
    return true
  end

  -- Name patterns
  local name = vim.api.nvim_buf_get_name(bufnr)
  if name and name ~= "" and rules.name_patterns then
    for i = 1, #rules.name_patterns do
      local pat = rules.name_patterns[i]
      local ok, matched = pcall(function()
        return name:match(pat) ~= nil
      end)
      if ok and matched then
        return true
      end
    end
  end

  return false
end

--- Build winbar string (path + separator + context)
---@nodiscard
---@param cfg WKDOptions.HL_CFG
---@param ctx_fn fun():string|nil -- context builder function
---@return string
function M.build(cfg, ctx_fn)
  local bufnr = 0

  if should_skip(bufnr, cfg) then
    return ""
  end

  -- Get path (cached)
  local path = vim.api.nvim_buf_get_name(bufnr)
  local rel = PathCache.repo_relative_cached(path, bufnr)

  -- Get context (may be expensive, so we pass it as a function)
  local ctx = nil
  if type(ctx_fn) == "function" then
    local ok, result = pcall(ctx_fn)
    if ok and type(result) == "string" and result ~= "" then
      ctx = result
    end
  end

  -- Build line
  local sep = Separator.resolve(cfg)
  local line = (ctx and #ctx > 0) and (rel .. sep .. ctx) or rel

  -- Ellipsize if needed
  local max_len = cfg.breadcrumbs_max_len or 120
  line = ellipsize_middle(line, max_len)

  -- Escape and add padding
  return " " .. stl_escape(trim(line))
end

--- Apply winbar to current window
---@param cfg WKDOptions.HL_CFG
---@param ctx_fn fun():string|nil
---@return nil
function M.apply(cfg, ctx_fn)
  local win = vim.api.nvim_get_current_win()
  if not vim.api.nvim_win_is_valid(win) then
    return
  end

  local line = M.build(cfg, ctx_fn)

  -- Schedule to avoid mid-event modification
  vim.schedule(function()
    if vim.api.nvim_win_is_valid(win) then
      vim.wo[win].winbar = line
    end
  end)
end

return M
